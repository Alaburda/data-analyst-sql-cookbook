# ============================================================================
# Build the Data Analyst SQL Cookbook DuckDB database
# Uses {dm} to define the relational model and {duckdb} to persist it.
# ============================================================================

library(dm)
library(dplyr)
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
 "London", "Berlin", "Paris", "Amsterdam", "Dublin", "Madrid", "Lisbon",
  "Vienna", "Prague", "Warsaw"
)

countries <- c(
  "UK", "Germany", "France", "Netherlands", "Ireland", "Spain", "Portugal",
  "Austria", "Czech Republic", "Poland"
)

city_country <- setNames(countries, cities)

# ============================================================================
# 1. CALENDAR / DATE DIMENSION
# ============================================================================

date_range  <- seq(as.Date("2022-01-01"), as.Date("2025-12-31"), by = "day")

calendar <- tibble(
  date_key        = as.integer(format(date_range, "%Y%m%d")),
  date            = date_range,
  year            = year(date_range),
  quarter         = quarter(date_range),
  month           = month(date_range),
  month_name      = month(date_range, label = TRUE, abbr = FALSE),
  week            = isoweek(date_range),
  day_of_week     = wday(date_range, label = TRUE, abbr = FALSE),
  day_of_month    = mday(date_range),
  day_of_year     = yday(date_range),
  is_weekend      = wday(date_range) %in% c(1, 7),
  fiscal_year     = ifelse(month(date_range) >= 4, year(date_range), year(date_range) - 1),
  fiscal_quarter  = ((quarter(date_range) + 2) %% 4) + 1
)

# ============================================================================
# 2. DEPARTMENTS
# ============================================================================

departments <- tibble(
  department_id   = 1:6,
  department_name = c("Engineering", "Sales", "Marketing", "Support", "HR", "Finance")
)

# ============================================================================
# 3. EMPLOYEES  (hierarchical via manager_id → employee_id)
# ============================================================================

n_employees <- 50

employees <- tibble(
  employee_id   = 1:n_employees,
  first_name    = sample(first_names, n_employees, replace = TRUE),
  last_name     = sample(last_names, n_employees, replace = TRUE),
  email         = paste0("emp", 1:n_employees, "@company.com"),
  department_id = sample(departments$department_id, n_employees, replace = TRUE,
                         prob = c(0.25, 0.20, 0.15, 0.20, 0.10, 0.10)),
  hire_date     = as.Date("2019-01-01") + sample(0:1800, n_employees, replace = TRUE),
  salary        = round(runif(n_employees, 35000, 120000), -2),
  city          = sample(cities, n_employees, replace = TRUE),
  is_active     = sample(c(TRUE, FALSE), n_employees, replace = TRUE, prob = c(0.88, 0.12)),
  manager_id    = NA_integer_
)

# Build a simple hierarchy: the first employee per department is the director
# (manager_id = NULL), everyone else reports to them or to a random senior.
for (dept in departments$department_id) {
  idx <- which(employees$department_id == dept)
  if (length(idx) == 0) next
  # first person is dept head — reports to CEO (employee 1) unless they ARE employee 1
  employees$manager_id[idx[1]] <- ifelse(idx[1] == 1L, NA_integer_, 1L)
  if (length(idx) > 1) {
    for (i in idx[-1]) {
      # random manager among earlier employees in same dept
      employees$manager_id[i] <- sample(idx[idx < i], 1)
    }
  }
}

# Employee 1 is the CEO — no manager
employees$manager_id[1] <- NA_integer_

# ============================================================================
# 4. CUSTOMERS
# ============================================================================

n_customers <- 200

customers <- tibble(
  customer_id    = 1:n_customers,
  first_name     = sample(first_names, n_customers, replace = TRUE),
  last_name      = sample(last_names, n_customers, replace = TRUE),
  email          = paste0("customer", 1:n_customers, "@example.com"),
  city           = sample(cities, n_customers, replace = TRUE),
  country        = city_country[city],
  signup_date    = as.Date("2022-03-01") + sample(0:1200, n_customers, replace = TRUE),
  customer_segment = sample(c("Consumer", "Business", "Enterprise"),
                             n_customers, replace = TRUE,
                             prob = c(0.60, 0.30, 0.10))
)

# ============================================================================
# 5. PRODUCTS
# ============================================================================

products <- tibble(
  product_id    = 1:12,
  product_name  = c(
    "Starter Plan", "Pro Plan", "Enterprise Plan",
    "Analytics Add‑on", "Storage Add‑on", "API Access",
    "Onboarding Package", "Training Session", "Premium Support",
    "Data Export Tool", "Custom Integrations", "White‑Label"
  ),
  category      = c(
    rep("Subscription", 3), rep("Add‑on", 3),
    rep("Service", 3), rep("Feature", 3)
  ),
  unit_price    = c(
    29, 79, 199,
    15, 10, 25,
    500, 250, 150,
    20, 350, 800
  ),
  is_recurring  = c(
    TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE,
    FALSE, FALSE, TRUE,
    TRUE, FALSE, FALSE
  )
)

# ============================================================================
# 6. SUBSCRIPTIONS  (SCD2-style with valid_from / valid_to)
# ============================================================================

n_subscriptions <- 300

sub_start <- as.Date("2022-06-01") + sample(0:1000, n_subscriptions, replace = TRUE)

# Some subscriptions are still active (valid_to = NULL / 9999-12-31),
# others have churned.
is_churned <- sample(c(TRUE, FALSE), n_subscriptions, replace = TRUE, prob = c(0.30, 0.70))
sub_end    <- ifelse(is_churned,
                     as.character(sub_start + sample(30:365, n_subscriptions, replace = TRUE)),
                     NA_character_)

subscriptions <- tibble(
  subscription_id = 1:n_subscriptions,
  customer_id     = sample(customers$customer_id, n_subscriptions, replace = TRUE),
  product_id      = sample(products$product_id[products$is_recurring], n_subscriptions, replace = TRUE),
  status          = ifelse(is_churned, sample(c("cancelled", "expired"), n_subscriptions, replace = TRUE), "active"),
  valid_from      = sub_start,
  valid_to        = as.Date(sub_end),
  monthly_amount  = products$unit_price[match(
    sample(products$product_id[products$is_recurring], n_subscriptions, replace = TRUE),
    products$product_id
  )]
)

# Re-derive monthly_amount correctly from the product
subscriptions$monthly_amount <- products$unit_price[match(subscriptions$product_id, products$product_id)]

# ============================================================================
# 7. ORDERS
# ============================================================================

n_orders <- 800

order_dates <- as.Date("2022-06-01") + sample(0:1200, n_orders, replace = TRUE)

orders <- tibble(
  order_id     = 1:n_orders,
  customer_id  = sample(customers$customer_id, n_orders, replace = TRUE),
  order_date   = order_dates,
  status       = sample(c("completed", "pending", "cancelled", "refunded"),
                        n_orders, replace = TRUE,
                        prob = c(0.75, 0.10, 0.10, 0.05))
)

# ============================================================================
# 8. ORDER ITEMS (line items)
# ============================================================================

# Each order has 1-4 line items
order_items_list <- lapply(orders$order_id, function(oid) {
  n_items <- sample(1:4, 1, prob = c(0.50, 0.30, 0.15, 0.05))
  pids    <- sample(products$product_id, n_items)
  tibble(
    order_id   = oid,
    product_id = pids,
    quantity   = sample(1:5, n_items, replace = TRUE, prob = c(0.60, 0.25, 0.10, 0.03, 0.02)),
    unit_price = products$unit_price[match(pids, products$product_id)]
  )
})

order_items <- bind_rows(order_items_list) |>
  mutate(
    order_item_id = row_number(),
    line_total    = quantity * unit_price
  ) |>
  select(order_item_id, order_id, product_id, quantity, unit_price, line_total)

# ============================================================================
# 9. SUPPORT TICKETS
# ============================================================================

n_tickets <- 400

ticket_created <- as.Date("2022-08-01") + sample(0:1100, n_tickets, replace = TRUE)

# Resolved date is 0-30 days after creation, or NULL if still open
is_resolved   <- sample(c(TRUE, FALSE), n_tickets, replace = TRUE, prob = c(0.80, 0.20))
ticket_resolved <- ifelse(is_resolved,
                          as.character(ticket_created + sample(0:30, n_tickets, replace = TRUE)),
                          NA_character_)

support_tickets <- tibble(
  ticket_id       = 1:n_tickets,
  customer_id     = sample(customers$customer_id, n_tickets, replace = TRUE),
  assigned_to     = sample(employees$employee_id[employees$department_id == 4],
                           n_tickets, replace = TRUE),
  category        = sample(c("Billing", "Technical", "Account", "Feature Request", "Bug Report"),
                           n_tickets, replace = TRUE,
                           prob = c(0.25, 0.30, 0.15, 0.15, 0.15)),
  priority        = sample(c("Low", "Medium", "High", "Critical"),
                           n_tickets, replace = TRUE,
                           prob = c(0.30, 0.40, 0.20, 0.10)),
  status          = ifelse(is_resolved,
                           sample(c("resolved", "closed"), n_tickets, replace = TRUE),
                           sample(c("open", "in_progress"), n_tickets, replace = TRUE)),
  created_date    = ticket_created,
  resolved_date   = as.Date(ticket_resolved),
  satisfaction_score = ifelse(is_resolved, sample(1:5, n_tickets, replace = TRUE), NA_integer_)
)

# ============================================================================
# 10. BUILD THE {dm} OBJECT
# ============================================================================

cookbook_dm <- dm(
  calendar,
  departments,
  employees,
  customers,
  products,
  subscriptions,
  orders,
  order_items,
  support_tickets
) |>
  # ---- primary keys ----
  dm_add_pk(calendar,        date_key) |>
  dm_add_pk(departments,     department_id) |>
  dm_add_pk(employees,       employee_id) |>
  dm_add_pk(customers,       customer_id) |>
  dm_add_pk(products,        product_id) |>
  dm_add_pk(subscriptions,   subscription_id) |>
  dm_add_pk(orders,          order_id) |>
  dm_add_pk(order_items,     order_item_id) |>
  dm_add_pk(support_tickets, ticket_id) |>
  # ---- foreign keys ----
  dm_add_fk(employees,       department_id, departments) |>
  dm_add_fk(employees,       manager_id,    employees, ref_columns = employee_id) |>
  dm_add_fk(subscriptions,   customer_id,   customers) |>
  dm_add_fk(subscriptions,   product_id,    products) |>
  dm_add_fk(orders,          customer_id,   customers) |>
  dm_add_fk(order_items,     order_id,      orders) |>
  dm_add_fk(order_items,     product_id,    products) |>
  dm_add_fk(support_tickets, customer_id,   customers) |>
  dm_add_fk(support_tickets, assigned_to,   employees, ref_columns = employee_id)

cat("✓ dm object built successfully\n")

# Quick integrity check
dm_examine_constraints(cookbook_dm) |> print()

# ============================================================================
# 11. WRITE TO DUCKDB
# ============================================================================
# DuckDB does not support ALTER TABLE ADD PK/FK, so we CREATE tables with
# constraints first, then INSERT the data.

db_path <- "db/cookbook.duckdb"

# Remove old database if it exists
if (file.exists(db_path)) file.remove(db_path)

con <- dbConnect(duckdb::duckdb(), dbdir = db_path)

# --- Create tables with constraints ---
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
  is_weekend     BOOLEAN,
  fiscal_year    INTEGER,
  fiscal_quarter INTEGER
)")

dbExecute(con, "
CREATE TABLE departments (
  department_id   INTEGER PRIMARY KEY,
  department_name VARCHAR
)")

dbExecute(con, "
CREATE TABLE products (
  product_id   INTEGER PRIMARY KEY,
  product_name VARCHAR,
  category     VARCHAR,
  unit_price   DOUBLE,
  is_recurring BOOLEAN
)")

dbExecute(con, "
CREATE TABLE customers (
  customer_id      INTEGER PRIMARY KEY,
  first_name       VARCHAR,
  last_name        VARCHAR,
  email            VARCHAR,
  city             VARCHAR,
  country          VARCHAR,
  signup_date      DATE,
  customer_segment VARCHAR
)")

dbExecute(con, "
CREATE TABLE employees (
  employee_id   INTEGER PRIMARY KEY,
  first_name    VARCHAR,
  last_name     VARCHAR,
  email         VARCHAR,
  department_id INTEGER REFERENCES departments(department_id),
  hire_date     DATE,
  salary        DOUBLE,
  city          VARCHAR,
  is_active     BOOLEAN,
  manager_id    INTEGER  -- self-ref FK omitted: DuckDB validates on bulk insert
)")
# Note: manager_id -> employee_id integrity is validated by {dm} above

dbExecute(con, "
CREATE TABLE subscriptions (
  subscription_id INTEGER PRIMARY KEY,
  customer_id     INTEGER REFERENCES customers(customer_id),
  product_id      INTEGER REFERENCES products(product_id),
  status          VARCHAR,
  valid_from      DATE,
  valid_to        DATE,
  monthly_amount  DOUBLE
)")

dbExecute(con, "
CREATE TABLE orders (
  order_id    INTEGER PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(customer_id),
  order_date  DATE,
  status      VARCHAR
)")

dbExecute(con, "
CREATE TABLE order_items (
  order_item_id INTEGER PRIMARY KEY,
  order_id      INTEGER REFERENCES orders(order_id),
  product_id    INTEGER REFERENCES products(product_id),
  quantity      INTEGER,
  unit_price    DOUBLE,
  line_total    DOUBLE
)")

dbExecute(con, "
CREATE TABLE support_tickets (
  ticket_id          INTEGER PRIMARY KEY,
  customer_id        INTEGER REFERENCES customers(customer_id),
  assigned_to        INTEGER REFERENCES employees(employee_id),
  category           VARCHAR,
  priority           VARCHAR,
  status             VARCHAR,
  created_date       DATE,
  resolved_date      DATE,
  satisfaction_score INTEGER
)")

cat("✓ Tables created with constraints\n")

# --- Insert data in dependency order ---
dbAppendTable(con, "calendar",      calendar)
dbAppendTable(con, "departments",   departments)
dbAppendTable(con, "products",      products)
dbAppendTable(con, "customers",     customers)

# employees must be inserted in hierarchy order (managers before reports)
emp_ordered <- employees[order(employees$employee_id), ]
dbAppendTable(con, "employees",     emp_ordered)

dbAppendTable(con, "subscriptions", subscriptions)
dbAppendTable(con, "orders",        orders)
dbAppendTable(con, "order_items",   order_items)
dbAppendTable(con, "support_tickets", support_tickets)

cat("✓ DuckDB database written to:", db_path, "\n")

# Verify table counts
for (tbl in dbListTables(con)) {
  n <- dbGetQuery(con, paste0("SELECT COUNT(*) AS n FROM ", tbl))$n
  cat(sprintf("  %-20s %d rows\n", tbl, n))
}

dbDisconnect(con, shutdown = TRUE)
cat("✓ Done!\n")
