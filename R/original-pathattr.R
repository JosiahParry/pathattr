
# function below runs too long when using purrr to apply to real dataset of
# millions or paths


#create the removale effects table (retbl) input:
#' @export
removal_effects_table <- dplyr::tibble(
  channel_name = c("fb","tiktok","gda","yt","gs","rtl","blog"),
  removal_effects_conversion = c(.2,.1,.3,.1,.6,.05,.09)
)

#'function to convert a single path to conversion to a data frame with
#'one record for each touchpoint showing the value of that touchpoint
#'
#' @param path_str string of touchpoints like "social>organic>paid_search"
#' of interest.
#' @param date_str string of dates of touchpoints like  "2023-01-01>2023-01-05>2023-01-06"
#' @param outcome numeric value, number of successes for the path of touchpoints, like 1
#' @param value numeric value, intended to be profit for the outcomes, like 2061
#' @param retbl data.frame-a-like containing the removal effects of all touchpoints
#' @export
#' @import dplyr
attribute_path<-function(path_str,date_str,outcome,value,retbl){
  #break the path_str and date_str into vectors of touch points and dates
  touches <- stringr::str_split_1(path_str,">")
  dates <- stringr::str_split_1(date_str,">")
  #remove dates and touches where touches is an empty
  dates <- dates[touches != '']
  touches <- touches[touches != '']

  #create an output dataframe that shows the fraction of a lead due to each touch/channel_name
  #by
  #1 getting the removal_effects_conversion (renamed to re) value for each touch
  #2 normalizing re for reach touchpoint by dividing by the sum(re) for all touchpoints in the path_str
  #3 multiplying outcome and value by the renormalized re

  tidyr::tibble(channel_name=touches[touches!='']) |>
    dplyr::left_join(
      retbl |> dplyr::select(channel_name,removal_effects_conversion),
      'channel_name'
    ) |> dplyr::rename(
      re = removal_effects_conversion
    ) |>
    dplyr::mutate(
      conversion=outcome*re/sum(re,na.rm=T),
      value=value*re/sum(re,na.rm=T),
      date=dates
    )
}

# we're going to pass in the lookup table into the funcion
# similar to how retbl is passed in currently
#' @export
lu <- setNames(
  removal_effects_table[["removal_effects_conversion"]],
  removal_effects_table[["channel_name"]]
)

#' @export
attr_path2 <- function(path_str, date_str, outcome, value, lu) {

  #break the path_str and date_str into vectors of touch points and dates
  touches <- stringr::str_split_1(path_str,">")
  dates <- stringr::str_split_1(date_str,">")
  #remove dates and touches where touches is an empty
  dates <- dates[touches != '']
  touches <- touches[touches != '']

  re <- lu[touches]
  re_tot <- sum(re, na.rm = TRUE)
  conversion <- outcome * re / re_tot
  value <- value * re / re_tot

  tibble::tibble(
    channel_name = touches,
    re,
    conversion,
    value,
    date = dates
  )
}
#
#
# pre_split_df <- path_data |>
#   dplyr::mutate(
#     path_split = stringr::str_split(path, ">"),
#     date_split = stringr::str_split(dates, ">")
#   ) |>
#   dplyr::select(path_split, date_split, outcome = leads, value)
#
#
#
#
# attr_path3 <- function(path_split, date_split, outcome, value, lu) {
#
#   dates <- date_split[path_split != '']
#   touches <- path_split[path_split != '']
#
#   re <- lu[touches]
#   re_tot <- sum(re, na.rm = TRUE)
#   conversion <- outcome * re / re_tot
#   value <- value * re / re_tot
#
#   tibble::tibble(
#     channel_name = touches,
#     re,
#     conversion,
#     value,
#     date = dates
#   )
# }
#
#
# # bench marking original vs my immpl
# bench::mark(
#   original = data.table::rbindlist(
#     purrr::pmap(
#       list(path_str=path_data$path,date_str=path_data$dates,
#            outcome=path_data$leads,value=path_data$value),
#       attribute_path,
#       removal_effects_table,
#       .progress = 'path_level'
#     )
#   ),
#   mine = data.table::rbindlist(
#     purrr::pmap(
#       list(path_str=path_data$path,date_str=path_data$dates,
#            outcome=path_data$leads,value=path_data$value),
#       attr_path2,
#       lu,
#       .progress = 'path2_level'
#     )
#   ),
#   split_outside =
#     data.table::rbindlist(
#       purrr::pmap(
#         pre_split_df,
#         attr_path3,
#         lu,
#         .progress = 'path3_level'
#       )
#     ),
#   rust = data.table::rbindlist(attr_path(
#     path_data$path,
#     path_data$dates,
#     path_data$leads,
#     path_data$value,
#     as.list(lu)
#   ))
# )
#
# # rust median 13.09 miliseconds
#
#
# #
# #
# # y <- path_data |>
# #   as_tibble() |>
# #   dplyr::mutate(
# #     path_split = strsplit(path, ">"),
# #     date_split = strsplit(dates, ">")
# #   ) |>
# #   select(path_split, date_split, outcome = leads, value) |>
# #   # slice(2) |>
# #   purrr::pmap(attr_path3, lu,  .progress = 'path_level') |>
# #   data.table::rbindl
#
#
# debugonce()
# attr_path3(path_df$path_split[[1]], y$date_split[1], y$outcome[1], y$value[1], lu)
#
#
