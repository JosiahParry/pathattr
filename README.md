
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Making R 200x + faster with Rust

<!-- badges: start -->
<!-- badges: end -->

The goal of pathattr is to demonstrate how extendr can be used in an R
project to speed up processing time and memory efficiency.

Sometime we can only get so far with R only code.

## Installation

You can install the development version of pathattr like so:

``` r
remotes::install_github("josiahparry/pathattr")
```

## Problem

Let’s look at the problem that we are trying to solve first. The package
includes some sample data that we can work with.

``` r
library(pathattr)

head(path10k)
#>                    path                                                  dates
#> 1 tiktok>blog>gs>fb>rtl 2023-04-17>2023-02-25>2023-01-24>2023-03-12>2023-03-09
#> 2     yt>blog>gs>fb>gda 2023-01-18>2023-01-27>2023-02-19>2023-01-01>2023-04-30
#> 3              fb>gs>yt                       2023-04-21>2023-02-20>2023-03-23
#> 4    gda>yt>tiktok>blog            2023-04-24>2023-03-01>2023-05-03>2023-04-29
#> 5                   rtl                                             2023-02-20
#> 6     gda>yt>rtl>tiktok            2023-02-04>2023-02-26>2023-01-09>2023-03-22
#>   leads    value
#> 1     1 6794.194
#> 2     1 5980.748
#> 3     1 5801.213
#> 4     1 4583.404
#> 5     1 6734.531
#> 6     1 7237.588
```

The desired output for a single row looks like:

    #>    channel_name   re conversion     value      dates
    #> 1:       tiktok 0.10 0.09615385  653.2879 2023-04-17
    #> 2:         blog 0.09 0.08653846  587.9591 2023-02-25
    #> 3:           gs 0.60 0.57692308 3919.7273 2023-01-24
    #> 4:           fb 0.20 0.19230769 1306.5758 2023-03-12
    #> 5:          rtl 0.05 0.04807692  326.6439 2023-03-09

The values of re are derived from a lookup table.

``` r
lu
#>     fb tiktok    gda     yt     gs    rtl   blog 
#>   0.20   0.10   0.30   0.10   0.60   0.05   0.09
```

Conversion rates and lead value are derived from these (I think).

## Bench mark:

``` r
path_data <- path10k[1:1000,]

bm <- bench::mark(
  original = data.table::rbindlist(
    purrr::pmap(
      list(path_str=path_data$path,date_str=path_data$dates,
           outcome=path_data$leads,value=path_data$value),
      attribute_path,
      removal_effects_table,
      .progress = 'path_level'
    )
  ),
  mine = data.table::rbindlist(
    purrr::pmap(
      list(path_str=path_data$path,date_str=path_data$dates,
           outcome=path_data$leads,value=path_data$value),
      attr_path2,
      lu,
      .progress = 'path2_level'
    )
  ),
  rust = data.table::rbindlist(attr_path(
    path_data$path,
    path_data$dates,
    path_data$leads,
    path_data$value,
    as.list(lu)
  ))
)
#> path_level ■■■■■■■■■                         27% |  ETA:  3spath_level ■■■■■■■■■■                        29% |  ETA:  3spath_level ■■■■■■■■■■■                       34% |  ETA:  3spath_level ■■■■■■■■■■■■■                     40% |  ETA:  2spath_level ■■■■■■■■■■■■■■■                   46% |  ETA:  2spath_level ■■■■■■■■■■■■■■■■                  51% |  ETA:  2spath_level ■■■■■■■■■■■■■■■■■■                57% |  ETA:  2spath_level ■■■■■■■■■■■■■■■■■■■■              63% |  ETA:  1spath_level ■■■■■■■■■■■■■■■■■■■■■■            69% |  ETA:  1spath_level ■■■■■■■■■■■■■■■■■■■■■■■■          75% |  ETA:  1spath_level ■■■■■■■■■■■■■■■■■■■■■■■■■         81% |  ETA:  1spath_level ■■■■■■■■■■■■■■■■■■■■■■■■■■■       87% |  ETA:  1spath_level ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■     92% |  ETA:  0spath_level ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■    98% |  ETA:  0s                                                             path_level ■■■■■■■■■■■■■                     39% |  ETA:  2s
#> path_level ■■■■■■■■■■■■■■■                   46% |  ETA:  2s
#> path_level ■■■■■■■■■■■■■■■■■■■■■■■           74% |  ETA:  1s
#> path_level ■■■■■■■■■■■■■■■■■■■■■■■■■         80% |  ETA:  1s
#> path_level ■■■■■■■■■■■■■■■■■■■■■■■■■■■       86% |  ETA:  0s
#> path_level ■■■■■■■■■■■■■■■■■■■■■■■■■■■■      91% |  ETA:  0s
#> path_level ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■    97% |  ETA:  0s
#> Warning: Some expressions had a GC in every iteration; so filtering is
#> disabled.


bm |> 
    dplyr::select(1:5) |> 
    dplyr::mutate(
        times_faster = dplyr::coalesce(
          as.double(dplyr::lag(median, 2) / median),
          as.double(dplyr::lag(median, 1) / median)
          )
    )
#> # A tibble: 3 × 6
#>   expression      min   median `itr/sec` mem_alloc times_faster
#>   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>        <dbl>
#> 1 original      3.05s    3.05s     0.328   33.01MB        NA   
#> 2 mine       442.09ms 445.02ms     2.25     1.28MB         6.85
#> 3 rust         7.59ms   9.42ms   102.     952.98KB       323.
```

## Testing with 1 million rows

``` r
path_data <- dplyr::sample_n(path10k, 1000000, replace = TRUE)

start <- Sys.time()
res <- data.table::rbindlist(attr_path(
    path_data$path,
    path_data$dates,
    path_data$leads,
    path_data$value,
    as.list(lu)
  ))

end <- Sys.time()
end - start
#> Time difference of 16.54759 secs
```
