# The subscription database is a mock database of users who have subscriptions,
# make requests and then there are employees who answer the requests

library(tidyverse)
library(duckdb)

con <- dbConnect(duckdb(), "databases/subscriptions.duckdb")


generate_intervals <- function(date_from = "2024-07-01",
                               groups = 3,
                               duration = 10,
                               gaps = 1:2,
                               tiers,
                               tier_probs,
                               n = 10) {

  data.frame(id = 1:(n*groups),
             group_id = as.character(rep(1:groups,each = n))) %>%
    group_by(group_id) %>%
    mutate(duration = sample(duration, n, replace = TRUE),
           gap = c(0,sample(gaps, n-1, replace = TRUE)),
           tier = sample(tiers, n, replace = TRUE, prob = tier_probs),
           date_kernel = as.Date(date_from)) %>%
    mutate(lag_duration = replace_na(lag(duration),0),
           cumulative_duration = cumsum(duration),
           cumulative_gap = cumsum(gap)) %>%
    mutate(cumulative_lag_duration = cumsum(lag_duration)) %>%
    mutate(date_from = date_kernel %m+% days(cumulative_gap+cumulative_lag_duration),
           date_to = date_kernel %m+% days(cumulative_gap+cumulative_duration)) %>%
    select(id,
           user_id = group_id,
           date_from,
           date_to,
           tier)

}

# Generate subscriptions

subscriptions <- generate_intervals(date_from = "2025-01-01",
                                    groups = 100,
                                    duration = c(30,60,90,120),
                                    gaps = c(1,14,30),
                                    tiers = c("basic", "pro", "premium"),
                                    tier_probs = c(0.6,0.3,0.1),
                                    n = 100)

# Generate subscription tier

# Generate users for the subscriptions

# Generate employees

# Generate some user requests with employees, who answered them - like a helpdesk kind of thing

requests <- data.frame(request_user_id = rep(1:100, sample(c(0,5,10,20), size = 100, replace = TRUE))) %>%
  mutate(request_submitted_at = sample(seq(as.Date("2026-01-01"), as.Date("2026-12-31"), by="day"), size = n(), replace = TRUE))

dbWriteTable(con, "requests", requests, overwrite = TRUE)

# create random number of requests for each user, then assign an employee to each request


dbWriteTable(con, "subscriptions", subscriptions, overwrite = TRUE)


