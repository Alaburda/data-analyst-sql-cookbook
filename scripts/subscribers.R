library(lubridate)
library(tibble)
library(RSQLite)


con <- dbConnect(RSQLite::SQLite(), "db/subscribers.db")

calendar <- tibble(date = as.character(seq(as.Date('2023-01-01'),as.Date('2024-01-01'),by = 1)),
                         full_date_description = format(date, format="%Y m. %B %d d."),
                         day_of_week = wday(date, label=FALSE, week_start = 1),
                         day_of_week_name = wday(date, label=TRUE, abbr = FALSE),
                         calendar_iso_week = isoweek(date),
                         calendar_week = week(date),
                         calendar_month = month(date),
                         calendar_month_name = month(date, label = TRUE, abbr = FALSE),
                         calendar_quarter = quarter(date),
                         calendar_quarter_name = paste0("Q",quarter(date)),
                         calendar_year = year(date),
                         is_weekday = as.integer(wday(date, week_start = 1) < 6))

users <- data.frame(id = 1:100000,
                    created_channel = sample(c(1:5), size = 100000, replace = TRUE),
                    created_at = seq.Date(from = as.Date("2023-01-01"), to = as.Date("2023-03-01"), length.out = 200))

number_of_subscribers <- 10000

subscriptions <- tibble(subscription_id = 1:number_of_subscribers,
                            user_id = sample(users$id, number_of_subscribers, replace = FALSE),
                            subscription_type = sample(c(1:4), size = number_of_subscribers, replace = TRUE),
                            subscription_valid_from = sample(seq.Date(from = as.Date("2023-01-01"),
                                                                      to = as.Date("2023-03-01"),
                                                                      length.out = 100),
                                                             size = number_of_subscribers,
                                                             replace = TRUE),
                            subscription_valid_to = subscription_valid_from %m+% months(sample(1:10,
                                                                                               size = number_of_subscribers,
                                                                                               replace = TRUE)))

dbWriteTable(con, "subscribers", subscriptions, overwrite = TRUE)

dbWriteTable(con, "users", users, overwrite = TRUE)

dbWriteTable(con, "calendar", calendar, overwrite = TRUE)

dbDisconnect(con)

