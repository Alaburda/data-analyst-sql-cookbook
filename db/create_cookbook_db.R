library(dplyr)
library(RSQLite)

set.seed(42) # for reproducible data generation
num_subscribers <- 100

subscribers_df <- data.frame(
  subscriber_id = 1000:(1000 + num_subscribers - 1),
  first_name = sample(c("Alice", "Bob", "Charlie", "Diana", "Ethan", "Fiona", "George", "Hannah", "Ivan", "Jasmine"), num_subscribers, replace = TRUE),
  last_name = sample(c("Smith", "Jones", "Williams", "Brown", "Davis", "Miller", "Wilson", "Moore"), num_subscribers, replace = TRUE),
  email = paste0("user", 1:num_subscribers, "@example.com"),
  subscription_date = as.Date("2023-01-01") + sample(0:364, num_subscribers, replace = TRUE),
  is_active = sample(c(TRUE, FALSE), num_subscribers, replace = TRUE, prob = c(0.85, 0.15)),
  tier = sample(c("Basic", "Premium", "Trial"), num_subscribers, replace = TRUE, prob = c(0.6, 0.3, 0.1))
)

db_file <- "db/cookbook.sqlite"

con <- dbConnect(RSQLite::SQLite(), db_file)

dbWriteTable(con, "subscribers", subscribers_df, overwrite = TRUE)
