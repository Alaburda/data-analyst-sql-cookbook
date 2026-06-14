library(quantmod)
library(tibble)
library(dplyr)
library(duckdb)

get_ticker <- function(ticker_name) {

  df <- getSymbols(ticker_name, auto.assign = FALSE)

  df <- as_tibble(df, rownames = "date") %>%
    mutate(ticker = ticker_name)

  colnames(df) <- c("date", "open", "high", "low", "close", "volume", "adjusted","ticker")

  return(df)

}

stocks <- purrr::map_df(c("AAPL", "^VIX"), get_ticker)

con <- dbConnect(duckdb(), "databases/stocks.duckdb")

dbWriteTable(con, "stocks", stocks, overwrite = TRUE)





