library(tictoc)


con <- dbConnect(RSQLite::SQLite(), "db/subscribers.db")

users <- data.frame(id = 1:100000,
                    created_channel = sample(c(1:5), size = 100000, replace = TRUE),
                    created_at = seq.Date(from = as.Date("2023-01-01"), to = as.Date("2023-03-01"), length.out = 200))

subscriptions <- data.frame(id = sample(users$id, 10000, replace = FALSE),
                            subscription_type = sample(c(1:4), size = 10000, replace = TRUE))

dbWriteTable(con, "subscribers", subscriptions, overwrite = TRUE)

dbWriteTable(con, "users", users, overwrite = TRUE)

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

