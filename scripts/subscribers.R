library(lubridate)
library(tibble)


con <- dbConnect(RSQLite::SQLite(), "db/subscribers.db")

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

dbDisconnect(con)

tic()
dbGetQuery(con, "explain query plan
           select *
           from users
           left join subscribers
            on subscribers.id = users.id
           where subscribers.id is null")
toc()

tic()
dbGetQuery(con, "explain query plan
           select *
           from users
           where id not in (select id from subscribers)")
toc()

dbGetQuery(con, "explain query plan
           select *
           from users
           where not exists (select * from subscribers where subscribers.id = users.id)")

