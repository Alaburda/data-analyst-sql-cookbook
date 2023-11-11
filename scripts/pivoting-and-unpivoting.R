library(odbc)
library(DBI)
library(RSQLite)
library(duckdb)
library(dplyr)

con <- dbConnect(duckdb::duckdb(), ":memory:")

generate_ts <- function(con, n, date_from, date_to, interval = "1 hour") {

  dbGetQuery(con, glue::glue_sql(.con = con, "
  with date_range as (
    select
    generate_series as ts_id,
    {date_from}::date as start_timestamp,
    {date_to}::date as stop_timestamp
    from
    generate_series(1, {n})
  )
  select
  ts_id,
  unnest(generate_series(start_timestamp, stop_timestamp, interval {interval})) as ts_timestamp,
  random() as ts_value
  from
  date_range
"))


}

rs <- generate_ts(con, 10, "2020-12-01", "2021-01-01", "1 day") %>%
  group_by(ts_id, ts_year = lubridate::year(ts_timestamp)) %>%
  summarise(ts_value = sum(ts_value))

rs_wide <- rs %>%
  tidyr::pivot_wider(names_from = ts_year, values_from = ts_value)

con <- dbConnect(RSQLite::SQLite(), "../db/pivot.db")

dbWriteTable(con, "yearly_values_long", rs, overwrite = TRUE)
dbWriteTable(con, "yearly_values_wide", rs_wide, overwrite = TRUE)


dbGetQuery(con, "
           select
            ts_id,
            sum(case when ts_year = 2020 then ts_value end) as ts_2020,
            sum(case when ts_year = 2021 then ts_value end) as ts_2021
           from yearly_values_long
           group by ts_id")

dbGetQuery(con, "SELECT
  ts_id,
  ts_year,
  ts_value
FROM yearly_values_wide
  CROSS JOIN ( VALUES(2020, [2020]),
                      (2021, [2021])) AS A(ts_year, ts_value);")
