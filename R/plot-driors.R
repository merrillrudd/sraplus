#' Plot data and priors for sralpus
#'
#' @param driors a list of driors created by sraplus::format_driors
#' @param fontsize font size for plots
#'
#' @return a ggplot2 object
#' @export
#'
plot_driors <- function(driors,fontsize = 10) {
  timeseries <- dplyr::tibble(year = driors$years,
                              catch = driors$catch)
  
  if (any(!is.na(driors$index))) {
    index_frame <- dplyr::tibble(year = driors$index_years,
                                 index = driors$index)
    timeseries <- timeseries %>%
      dplyr::left_join(index_frame, by = "year")
    
  }
  
  if (any(!is.na(driors$u_v_umsy))) {
    u_frame <- dplyr::tibble(year = driors$u_v_umsy,
                             u_v_umsy = driors$u_years)
    timeseries <- timeseries %>%
      dplyr::left_join(u_frame, by = "year")
    
  }
  
  if (any(!is.na(driors$effort))) {
    e_frame <- dplyr::tibble(year = driors$effort,
                             effort = driors$effort_years)
    timeseries <- timeseries %>%
      dplyr::left_join(e_frame, by = "year")
    
  }
  
  timeseries_plot <- timeseries %>%
    tidyr::gather(metric, value, -year) %>%
    ggplot2::ggplot(aes(year, value, color = metric)) +
    ggplot2::geom_line(size = 1, show.legend = FALSE) +
    ggplot2::geom_point(size = 2, show.legend = FALSE) +
    ggplot2::facet_grid(metric ~ ., scales = "free_y") +
    ggplot2::scale_y_continuous(labels = scales::comma, name = "") +
    ggplot2::labs(x = "Year")  +
    theme_sraplus(base_size = 12)
  

  if (length(driors$log_final_u) > 1){
    
    driors$log_final_u1 = driors$log_final_u[1]
    
    driors$log_final_u1_cv = driors$log_final_u_cv[1]
    
    driors$log_final_u2 = driors$log_final_u[2]
    
    driors$log_final_u2_cv = driors$log_final_u_cv[2]
    
    driors <- purrr::list_modify(driors, "log_final_u" = NULL, "log_final_u_cv" = NULL)
    
  }
    
  
  vars <- names(driors)
  
  var_count <- table(stringr::str_replace_all(vars, "_cv", ""))
  
  plot_vars <- names(var_count)[var_count == 2]
  
  has_values <- purrr::map_lgl(plot_vars, ~ !all(is.na(driors[[.x]])))
  
  plot_vars <- plot_vars[has_values]
  
  
  
  foo <- function(var, driors, n = 1000) {
    sims <- rnorm(n, driors[[var]], driors[[paste0(var, "_cv")]])
    
  }
  
  sims <- dplyr::tibble(variable = plot_vars) %>%
    dplyr::mutate(draws = purrr::map(variable, foo, driors = driors)) %>%
    tidyr::unnest()
  
  var_plots <- sims %>%
    ggplot2::ggplot(aes(variable, draws)) +
    ggplot2::geom_boxplot() +
    ggplot2::facet_wrap( ~ variable, scales = "free") +
    ggplot2::labs(y = "", x = "") +
    theme_sraplus(base_size = fontsize) +
    ggplot2::theme(
      strip.text = ggplot2::element_blank(),
      strip.background = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 8)
    )
  
  
  
  patchwork::wrap_plots(timeseries_plot,
                        var_plots)
  
}