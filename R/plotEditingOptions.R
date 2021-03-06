#' @title Get the editable options for a plot
#' @param plot a plot object
#' @param asJSON should the list be converted to JSON?
#'
#' @export
plotEditingOptions <- function(plot, asJSON = FALSE) {
  options <- tryCatch(
    expr = getPlotEditingOptions(plot),
    unsupportedFigureError = function(e) {
      plotEditingOptionsError(e[["message"]])
    },
    error = function(e) {
      plotEditingOptionsError(
        gettextf("Computing plotEditingOptions gave an error: %s",
                 .extractErrorMessage(e)),
        unexpected = TRUE
      )
    }
  )
  if (asJSON)
    return(rListToJson(options))
  else
    return(options)
}

getPlotEditingOptions <- function(graph) {
  UseMethod("getPlotEditingOptions", graph)
}

getPlotEditingOptions.gg <- function(graph) {
  # ensures    that loading an edited graph returns the final set of options
  if (!is.null(graph[["plot_env"]][[".____plotEditingOptions____"]][["oldOptions"]]))
    return(graph[["plot_env"]][[".____plotEditingOptions____"]][["oldOptions"]])
  return(getPlotEditingOptions.ggplot(graph))
}

getPlotEditingOptions.ggplot <- function(graph) {
  getPlotEditingOptions.ggplot_built(ggplot_build(graph))
}

getPlotEditingOptions.ggplot_built <- function(graph) {

  # TODO: test if graph can be edited at all!
  validateGraphType(graph)

  # only relevant for continuous scales?
  opts <- graph[["layout"]][["panel_params"]]
  axisTypes <- getAxisType(opts)

  currentAxis <- graph[["layout"]][["get_scales"]](1L)

  xSettings <- getAxisInfo(currentAxis[["x"]], opts, graph)
  ySettings <- getAxisInfo(currentAxis[["y"]], opts, graph)

  out <- list(
    xAxis = list(
      type     = axisTypes[["x"]],
      settings = xSettings
    ), yAxis = list(
      type     = axisTypes[["y"]],
      settings = ySettings
    ),
    error = ErrorType$Success
  )

  return(out)
}

getPlotEditingOptions.qgraph <- function(graph) {
  plotEditingOptionsError(gettext("This figure was created with qgraph."))
}

getPlotEditingOptions.jaspGraphsPlot <- function(graph) {
  plotEditingOptionsError(gettext("This figure consists of multiple smaller figures."))
}

getPlotEditingOptions.default <- function(graph) {
  plotEditingOptionsError(
    gettextf("cannot create plotEditingOptions for object of class: %s.", paste(class(graph), collapse = ",")),
    unexpected = TRUE
  )
}

rListToJson <- function(lst) {
  tryCatch(
    toJSON(lst),
    error = function(e) {
      toJSON(plotEditingOptionsError(
        gettextf("Converting plotEditingOptions to JSON gave an error: %s.",
                 .extractErrorMessage(e)),
        unexpected = TRUE
      ))
    }
  )
}

plotEditingOptionsError <- function(error, unexpected = FALSE) {
  reason <- if (unexpected) {
    list(
      reasonNotEditable = gettextf("Plot editing terminated unexpectedly. Fatal error in plotEditingOptions: %s To receive assistance with this problem, please report the message above at: https://jasp-stats.org/bug-reports", error),
      errorType = ErrorType$FatalError
    )
  } else {
    list(
      reasonNotEditable = gettextf("This plot can not be edited because: %s", error),
      errorType = ErrorType$ValidationError
    )
  }
}

validateGraphType <- function(graph) {

  # more to come!
  if (is.coordPolar(graph[["layout"]][["coord"]]))
    unsupportedFigureError("This plot uses polar coordinates (e.g., pie chart)")

}

is.coordPolar <- function(x) inherits(x, "CoordPolar")

unsupportedFigureError <- function(message) {
  e <- structure(class = c("unsupportedFigureError", "error", "condition"),
                 list(message=message, call=sys.call(-1)))
  stop(e)
}
