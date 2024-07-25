#' Launch the Shiny App
#'
#' This function launches the Shiny app.
#'
#' @export
launch_app <- function() {
  app_dir <- system.file("app", package = "EhrDHP")
  shiny::runApp(app_dir)
}
