## code to prepare `path10k` dataset goes here
#depends on data.table, tidyverse
#creates synthetic path to purchase data and removal effects table
#produces path level attribution results

#2023-05-10 TL



#create the removale effects table (retbl) input:
removal_effects_table <- dplyr::tibble(
  channel_name = c("fb","tiktok","gda","yt","gs","rtl","blog"),
  removal_effects_conversion = c(.2,.1,.3,.1,.6,.05,.09)
)

#create the data set of touchpoints, dates, outcomes, and values
records_desired = 1e5
max_path = 5

date_options <- seq(
  as.Date("2023-01-01"),
  as.Date("2023-05-10"),
  by = 1
)
path_data_list <- vector('list', records_desired)

for (nrec in 1:records_desired) {
  touch_number <- sample(1:max_path,1)
  path_data_list[[nrec]] <- dplyr::tibble(
    path = paste(
      sample(removal_effects_table$channel_name,touch_number),
      collapse = ">"
    ),
    dates = paste(
      sample(date_options,touch_number),
      collapse=">"
    ),
    leads=1,
    value=rnorm(1,mean=6000,sd=1000)
  )
}

path_data <- data.table::rbindlist(path_data_list)
# usethis::use_data(path10k, overwrite = TRUE)
