# ============================================================================
# Build the "carwash" DuckDB database
#
# A mock car-wash business: users subscribe to plans (with consecutive or
# gapped subscription intervals), visit locations for wash sessions, redeem
# vouchers, and raise support requests answered by employees.
#
# Uses {dm} to define the relational model and {duckdb} to persist it.
# The subscription intervals are produced by generate_intervals(), which lets
# you control whether a user's subscriptions are consecutive or have gaps.
# ============================================================================

library(dm)
library(dplyr)
library(tidyr)
library(lubridate)
library(duckdb)
library(DBI)

set.seed(2024)

# ---- helper vectors --------------------------------------------------------

first_names <- c(
  "Alice", "Bob", "Charlie", "Diana", "Ethan", "Fiona", "George", "Hannah",
  "Ivan", "Jasmine", "Karen", "Leo", "Mia", "Nathan", "Olivia", "Peter",
  "Quinn", "Rachel", "Sam", "Tina", "Uma", "Victor", "Wendy", "Xander",
  "Yara", "Zane", "Amelia", "Brian", "Chloe", "Derek", "Eva", "Felix",
  "Gina", "Hugo", "Iris", "Jake", "Lena", "Marco", "Nina", "Oscar"
)

last_names <- c(
  "Smith", "Jones", "Williams", "Brown", "Davis", "Miller", "Wilson", "Moore",
  "Taylor", "Anderson", "Thomas", "Jackson", "White", "Harris", "Martin",
  "Garcia", "Clark", "Lewis", "Hall", "Young", "Walker", "King", "Wright",
  "Lopez", "Hill", "Scott", "Green", "Adams", "Baker", "Nelson"
)

cities <- c(
  "Vilnius", "Kaunas", "Zarasai", "Trakai", "Palanga", "Nida", "Kretinga",
  "Jonava", "Liepoja", "Ryga"
)

countries <- c(
  "Lithuania", "Lithuania", "Lithuania", "Lithuania", "Lithuania", "Lithuania", "Lithuania",
  "Lithuania", "Latvia", "Latvia"
)

city_country <- setNames(countries, cities)

# ============================================================================
# generate_intervals()
#
# Builds n consecutive (or gapped) intervals per group. Each group (user) gets
# `n` back-to-back subscription rows; `gaps` controls the spacing between one
# interval ending and the next beginning:
#   * gaps = 0          -> perfectly consecutive intervals (no gap)
#   * gaps = c(1, 14)   -> small random gaps between intervals
#   * gaps = c(30, 90)  -> larger churn-and-return gaps
# Setting some gaps to 0 and others positive mixes consecutive runs with gaps,
# which is handy for testing streak / gap-and-island style queries.
# ============================================================================

generate_intervals <- function(date_from   = "2024-07-01",
                               groups      = 3,
                               duration    = 10,
                               gaps        = 1:2,
                               tiers,
                               tier_probs,
                               n           = 10) {

  data.frame(id       = 1:(n * groups),
             group_id = as.integer(rep(1:groups, each = n))) %>%
    group_by(group_id) %>%
    mutate(duration    = sample(duration, n, replace = TRUE),
           gap         = c(0, sample(gaps, n - 1, replace = TRUE)),
           tier        = sample(tiers, n, replace = TRUE, prob = tier_probs),
           date_kernel = as.Date(date_from)) %>%
    mutate(lag_duration       = replace_na(lag(duration), 0),
           cumulative_duration = cumsum(duration),
           cumulative_gap      = cumsum(gap)) %>%
    mutate(cumulative_lag_duration = cumsum(lag_duration)) %>%
    mutate(date_from = date_kernel %m+% days(cumulative_gap + cumulative_lag_duration),
           date_to   = date_kernel %m+% days(cumulative_gap + cumulative_duration)) %>%
    ungroup() %>%
    select(id,
           user_id = group_id,
           date_from,
           date_to,
           tier)
}

# ============================================================================
# 0. CALENDAR / DATE DIMENSION
# ============================================================================

date_range <- seq(as.Date("2020-01-01"), as.Date("2025-12-31"), by = "day")

calendar <- tibble(
  date_key       = as.integer(format(date_range, "%Y%m%d")),
  date           = date_range,
  year           = year(date_range),
  quarter        = quarter(date_range),
  month          = month(date_range),
  month_name     = as.character(month(date_range, label = TRUE, abbr = FALSE)),
  week           = isoweek(date_range),
  day_of_week    = as.character(wday(date_range, label = TRUE, abbr = FALSE)),
  day_of_month   = mday(date_range),
  day_of_year    = yday(date_range),
  start_of_month = floor_date(date_range, "month"),
  is_weekend     = wday(date_range) %in% c(1, 7)
)

# ============================================================================
# 1. LOCATIONS
# ============================================================================

n_locations <- 8

locations <- tibble(
  location_id  = 1:n_locations,
  location_name = paste0("Sparkle Wash ", cities[1:n_locations]),
  city         = cities[1:n_locations],
  country      = city_country[cities[1:n_locations]],
  n_bays       = sample(2:6, n_locations, replace = TRUE),
  opened_date  = as.Date("2020-01-01") + sample(0:1500, n_locations, replace = TRUE)
)

# ============================================================================
# 2. PLANS  (subscription tiers)
# ============================================================================

plans <- tibble(
  plan_id         = 1:4,
  plan_name       = c("Basic", "Pro", "Premium", "Unlimited"),
  tier            = c("basic", "pro", "premium", "unlimited"),
  monthly_price   = c(19.0, 29.0, 49.0, 79.0),
  washes_included = c(2L, 4L, 8L, NA_integer_)   # NA = unlimited washes
)

# ============================================================================
# 3. USERS  (customers)
# ============================================================================

n_users <- 100

signup_date <- as.Date("2023-01-01") + sample(0:700, n_users, replace = TRUE)

# Signup -> confirmation -> activation funnel. Not everyone who signs up confirms
# their email, and not everyone who confirms goes on to activate (finish
# onboarding / first wash). A NA date models a user who dropped out at that
# stage, so you can query e.g. "signed up but never activated".
confirmed         <- runif(n_users) < 0.80                 # ~80% confirm email
confirmation_date <- rep(as.Date(NA), n_users)
confirmation_date[confirmed] <- signup_date[confirmed] +
  sample(0:7, sum(confirmed), replace = TRUE)              # confirm 0-7 days later

activated         <- confirmed & runif(n_users) < 0.70     # ~70% of confirmed activate
activation_date   <- rep(as.Date(NA), n_users)
activation_date[activated] <- confirmation_date[activated] +
  sample(0:30, sum(activated), replace = TRUE)             # activate 0-30 days later

users <- tibble(
  user_id           = 1:n_users,
  first_name        = sample(first_names, n_users, replace = TRUE),
  last_name         = sample(last_names, n_users, replace = TRUE),
  email             = paste0("user", 1:n_users, "@example.com"),
  signup_date       = signup_date,
  confirmation_date = confirmation_date,
  activation_date   = activation_date
)

# ============================================================================
# 4. EMPLOYEES  (head-office / support staff — carwashes are self-service, so
#    employees are NOT tied to a location. Hierarchical via manager_id.)
# ============================================================================

n_employees <- 30

employees <- tibble(
  employee_id = 1:n_employees,
  first_name  = sample(first_names, n_employees, replace = TRUE),
  last_name   = sample(last_names, n_employees, replace = TRUE),
  email       = paste0("emp", 1:n_employees, "@sparklewash.com"),
  role        = sample(c("Support Agent", "Field Technician", "Operations", "Finance", "Manager"),
                       n_employees, replace = TRUE,
                       prob = c(0.35, 0.25, 0.15, 0.10, 0.15)),
  hire_date   = as.Date("2020-06-01") + sample(0:1500, n_employees, replace = TRUE),
  salary      = round(runif(n_employees, 24000, 55000), -2),
  is_active   = sample(c(TRUE, FALSE), n_employees, replace = TRUE, prob = c(0.9, 0.1)),
  manager_id  = NA_integer_
)

# A handful of managers; everyone else reports to a random manager.
employees$role[1] <- "Manager"                       # employee 1 is the top of the tree
manager_ids <- employees$employee_id[employees$role == "Manager"]
non_managers <- setdiff(employees$employee_id, manager_ids)
employees$manager_id[non_managers] <- sample(manager_ids, length(non_managers), replace = TRUE)
# Managers (other than employee 1) report to employee 1
employees$manager_id[employees$employee_id %in% setdiff(manager_ids, 1L)] <- 1L
employees$manager_id[1] <- NA_integer_

support_agents <- employees$employee_id[employees$role == "Support Agent"]
if (length(support_agents) == 0) support_agents <- employees$employee_id  # fallback

# ============================================================================
# 5. SUBSCRIPTIONS  (consecutive / gapped intervals via generate_intervals)
# ============================================================================

subscriptions_raw <- generate_intervals(
  date_from  = "2023-06-01",
  groups     = n_users,                 # one group of intervals per user
  duration   = c(30, 60, 90, 120, 180), # subscription length in days
  gaps       = c(0, 0, 0, 14, 30, 90),  # mostly consecutive, occasional gaps
  tiers      = plans$tier,
  tier_probs = c(0.45, 0.30, 0.15, 0.10),
  n          = 4                         # up to 4 subscription spells per user
)

subscriptions <- subscriptions_raw %>%
  mutate(plan_id = plans$plan_id[match(tier, plans$tier)]) %>%
  transmute(
    subscription_id = id,
    user_id,
    plan_id,
    date_from,
    date_to
  )

# ============================================================================
# 6. VOUCHERS  (discount codes, some tied to a user)
# ============================================================================

n_vouchers <- 60

voucher_user <- sample(c(users$user_id, rep(NA_integer_, 20)), n_vouchers, replace = TRUE)
voucher_from <- as.Date("2024-01-01") + sample(0:300, n_vouchers, replace = TRUE)

vouchers <- tibble(
  voucher_id   = 1:n_vouchers,
  code         = sprintf("WASH-%04d", sample(1000:9999, n_vouchers)),
  user_id      = voucher_user,           # NA = public / promo voucher
  discount_pct = sample(c(10, 15, 20, 25, 50), n_vouchers, replace = TRUE,
                        prob = c(0.35, 0.25, 0.2, 0.15, 0.05)),
  valid_from   = voucher_from,
  valid_to     = voucher_from + sample(c(30, 60, 90), n_vouchers, replace = TRUE),
  is_redeemed  = sample(c(TRUE, FALSE), n_vouchers, replace = TRUE, prob = c(0.4, 0.6))
)

# ============================================================================
# 7. SESSIONS  (individual wash visits)
# ============================================================================

n_sessions <- 1200

session_user  <- sample(users$user_id, n_sessions, replace = TRUE)
session_start <- as.POSIXct("2024-01-01 08:00:00", tz = "UTC") +
  sample(0:(86400 * 540), n_sessions, replace = TRUE)   # ~18 months of visits

# Match each session to one of the user's active subscriptions, if any.
sub_lookup <- subscriptions %>% select(subscription_id, user_id, date_from, date_to)

sessions <- tibble(
  session_id   = 1:n_sessions,
  user_id      = session_user,
  location_id  = sample(locations$location_id, n_sessions, replace = TRUE),
  started_at   = session_start,
  duration_min = sample(10:60, n_sessions, replace = TRUE),
  list_price   = sample(c(8, 14, 22, 45), n_sessions, replace = TRUE,
                        prob = c(0.4, 0.3, 0.2, 0.1))
) %>%
  mutate(ended_at = started_at + minutes(duration_min)) %>%
  rowwise() %>%
  mutate(subscription_id = {
    sd <- as.Date(started_at)
    cand <- sub_lookup$subscription_id[
      sub_lookup$user_id == user_id &
        sub_lookup$date_from <= sd &
        sub_lookup$date_to   >= sd
    ]
    if (length(cand) > 0) cand[1] else NA_integer_
  }) %>%
  ungroup()

# Some sessions redeem a voucher; covered-by-subscription sessions pay nothing.
sessions <- sessions %>%
  mutate(
    voucher_id  = ifelse(runif(n()) < 0.15,
                         sample(vouchers$voucher_id, n(), replace = TRUE),
                         NA_integer_),
    amount_paid = case_when(
      !is.na(subscription_id) ~ 0,                       # included in plan
      !is.na(voucher_id)      ~ round(list_price * 0.8, 2),
      TRUE                    ~ list_price
    )
  ) %>%
  select(session_id, user_id, location_id, subscription_id, voucher_id,
         started_at, ended_at, duration_min, amount_paid)

# ============================================================================
# 8. REQUESTS  (support tickets answered by employees)
# ============================================================================

n_requests <- 300

req_created  <- as.Date("2024-01-01") + sample(0:540, n_requests, replace = TRUE)
is_resolved  <- sample(c(TRUE, FALSE), n_requests, replace = TRUE, prob = c(0.8, 0.2))
req_resolved <- as.Date(ifelse(is_resolved,
                               as.character(req_created + sample(0:14, n_requests, replace = TRUE)),
                               NA_character_))

requests <- tibble(
  request_id    = 1:n_requests,
  user_id       = sample(users$user_id, n_requests, replace = TRUE),
  employee_id   = sample(support_agents, n_requests, replace = TRUE),
  category      = sample(c("Billing", "Booking", "Complaint", "Voucher", "Other"),
                         n_requests, replace = TRUE,
                         prob = c(0.3, 0.25, 0.2, 0.15, 0.1)),
  status        = ifelse(is_resolved, "resolved", "open"),
  submitted_at  = req_created,
  resolved_at   = req_resolved,
  satisfaction  = ifelse(is_resolved, sample(1:5, n_requests, replace = TRUE), NA_integer_)
)

# ============================================================================
# 9. BUILD THE {dm} OBJECT  (declares the relational model + integrity)
# ============================================================================

carwash_dm <- dm(
  calendar,
  locations,
  plans,
  users,
  employees,
  subscriptions,
  vouchers,
  sessions,
  requests
) |>
  # ---- primary keys ----
  dm_add_pk(calendar,      date_key)        |>
  dm_add_pk(locations,     location_id)     |>
  dm_add_pk(plans,         plan_id)         |>
  dm_add_pk(users,         user_id)         |>
  dm_add_pk(employees,     employee_id)     |>
  dm_add_pk(subscriptions, subscription_id) |>
  dm_add_pk(vouchers,      voucher_id)      |>
  dm_add_pk(sessions,      session_id)      |>
  dm_add_pk(requests,      request_id)      |>
  # ---- foreign keys ----
  dm_add_fk(subscriptions, user_id,         users)         |>
  dm_add_fk(subscriptions, plan_id,         plans)         |>
  dm_add_fk(vouchers,      user_id,         users)         |>
  dm_add_fk(sessions,      user_id,         users)         |>
  dm_add_fk(sessions,      location_id,     locations)     |>
  dm_add_fk(sessions,      subscription_id, subscriptions) |>
  dm_add_fk(sessions,      voucher_id,      vouchers)      |>
  dm_add_fk(requests,      user_id,         users)         |>
  dm_add_fk(requests,      employee_id,     employees)

cat("✓ dm object built successfully\n")
dm_examine_constraints(carwash_dm) |> print()

# ============================================================================
# 10. WRITE TO DUCKDB
# ============================================================================
# DuckDB does not support ALTER TABLE ADD PK/FK, so we CREATE tables with
# constraints first, then INSERT the data in dependency order.

db_path <- "databases/carwash.duckdb"
if (file.exists(db_path)) file.remove(db_path)

con <- dbConnect(duckdb::duckdb(), dbdir = db_path)

dbExecute(con, "
CREATE TABLE calendar (
  date_key       INTEGER PRIMARY KEY,
  date           DATE,
  year           INTEGER,
  quarter        INTEGER,
  month          INTEGER,
  month_name     VARCHAR,
  week           INTEGER,
  day_of_week    VARCHAR,
  day_of_month   INTEGER,
  day_of_year    INTEGER,
  start_of_month DATE,
  is_weekend     BOOLEAN
)")

dbExecute(con, "
CREATE TABLE locations (
  location_id   INTEGER PRIMARY KEY,
  location_name VARCHAR,
  city          VARCHAR,
  country       VARCHAR,
  n_bays        INTEGER,
  opened_date   DATE
)")

dbExecute(con, "
CREATE TABLE plans (
  plan_id         INTEGER PRIMARY KEY,
  plan_name       VARCHAR,
  tier            VARCHAR,
  monthly_price   DOUBLE,
  washes_included INTEGER
)")

dbExecute(con, "
CREATE TABLE users (
  user_id           INTEGER PRIMARY KEY,
  first_name        VARCHAR,
  last_name         VARCHAR,
  email             VARCHAR,
  signup_date       DATE,
  confirmation_date DATE,
  activation_date   DATE
)")

dbExecute(con, "
CREATE TABLE employees (
  employee_id INTEGER PRIMARY KEY,
  first_name  VARCHAR,
  last_name   VARCHAR,
  email       VARCHAR,
  role        VARCHAR,
  hire_date   DATE,
  salary      DOUBLE,
  is_active   BOOLEAN,
  manager_id  INTEGER  -- self-ref FK validated by {dm} above
)")

dbExecute(con, "
CREATE TABLE subscriptions (
  subscription_id INTEGER PRIMARY KEY,
  user_id         INTEGER REFERENCES users(user_id),
  plan_id         INTEGER REFERENCES plans(plan_id),
  date_from       DATE,
  date_to         DATE
)")

dbExecute(con, "
CREATE TABLE vouchers (
  voucher_id   INTEGER PRIMARY KEY,
  code         VARCHAR,
  user_id      INTEGER REFERENCES users(user_id),
  discount_pct INTEGER,
  valid_from   DATE,
  valid_to     DATE,
  is_redeemed  BOOLEAN
)")

dbExecute(con, "
CREATE TABLE sessions (
  session_id      INTEGER PRIMARY KEY,
  user_id         INTEGER REFERENCES users(user_id),
  location_id     INTEGER REFERENCES locations(location_id),
  subscription_id INTEGER REFERENCES subscriptions(subscription_id),
  voucher_id      INTEGER REFERENCES vouchers(voucher_id),
  started_at      TIMESTAMP,
  ended_at        TIMESTAMP,
  duration_min    INTEGER,
  amount_paid     DOUBLE
)")

dbExecute(con, "
CREATE TABLE requests (
  request_id   INTEGER PRIMARY KEY,
  user_id      INTEGER REFERENCES users(user_id),
  employee_id  INTEGER REFERENCES employees(employee_id),
  category     VARCHAR,
  status       VARCHAR,
  submitted_at DATE,
  resolved_at  DATE,
  satisfaction INTEGER
)")

cat("✓ Tables created with constraints\n")

# --- Insert data in dependency order ---
dbAppendTable(con, "calendar",      calendar)
dbAppendTable(con, "locations",     locations)
dbAppendTable(con, "plans",         plans)
dbAppendTable(con, "users",         users)
dbAppendTable(con, "employees",     employees[order(employees$employee_id), ])
dbAppendTable(con, "subscriptions", subscriptions)
dbAppendTable(con, "vouchers",      vouchers)
dbAppendTable(con, "sessions",      sessions)
dbAppendTable(con, "requests",      requests)

cat("✓ DuckDB database written to:", db_path, "\n")

# Verify table counts
for (tbl in dbListTables(con)) {
  n <- dbGetQuery(con, paste0("SELECT COUNT(*) AS n FROM ", tbl))$n
  cat(sprintf("  %-16s %d rows\n", tbl, n))
}

dbDisconnect(con, shutdown = TRUE)
cat("✓ Done!\n")
