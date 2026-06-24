# ============================================================================
# Benchmark: factless fact table creation via a range join
#   plain DATE keys           (date BETWEEN date_from AND date_to)
#   vs. integer "smart" keys  (20260101 BETWEEN 20260101 AND 20260131)
#
# Question: does DuckDB explode intervals into a factless fact table faster
# when the calendar/interval keys are INTEGER (YYYYMMDD) instead of DATE?
#
# Note up front: DuckDB stores DATE internally as a 4-byte int (days since the
# epoch), so a DATE comparison is already an integer comparison. The INTEGER
# smart key is also 4 bytes. So we'd *expect* them to be close — this script
# measures whether that's actually true for the range-join that builds the
# factless fact table.
# ============================================================================

library(duckdb)
library(DBI)
library(bench)
library(dplyr)

set.seed(2024)

# ---- knobs -----------------------------------------------------------------

n_intervals   <- 50000          # number of SCD2-style rows (e.g. subscriptions)
cal_from       <- as.Date("2020-01-01")
cal_to         <- as.Date("2025-12-31")
granularity    <- "day"         # "day" or "month": calendar grain to explode to
iterations     <- 10            # bench reps per approach

# ---- build the source data in R --------------------------------------------

# Random intervals within the calendar window; durations 30–540 days.
starts    <- cal_from + sample(0:as.integer(cal_to - cal_from - 30), n_intervals, replace = TRUE)
durations <- sample(30:540, n_intervals, replace = TRUE)
ends      <- pmin(starts + durations, cal_to)

to_key <- function(d) as.integer(format(d, "%Y%m%d"))   # 2026-01-01 -> 20260101

intervals <- tibble(
  interval_id   = seq_len(n_intervals),
  date_from     = starts,
  date_to       = ends,
  date_from_key = to_key(starts),
  date_to_key   = to_key(ends)
)

cal_dates <- seq(cal_from, cal_to, by = granularity)
calendar <- tibble(
  date     = cal_dates,
  date_key = to_key(cal_dates)
)

cat(sprintf("Intervals: %s   Calendar (%s grain): %s rows\n",
            format(n_intervals, big.mark = ","),
            granularity,
            format(nrow(calendar), big.mark = ",")))

# ---- load into an in-memory DuckDB -----------------------------------------

con <- dbConnect(duckdb(), dbdir = ":memory:")
dbWriteTable(con, "intervals", intervals, overwrite = TRUE)
dbWriteTable(con, "calendar",  calendar,  overwrite = TRUE)

# The two ways to build the factless fact table. Each materializes the full
# exploded result via CREATE TABLE AS (CTAS) so we time real table creation,
# then returns the row count so bench can verify both produce identical output.
build_factless <- function(join_clause) {
  dbExecute(con, "DROP TABLE IF EXISTS factless")
  dbExecute(con, paste0("
    CREATE TABLE factless AS
    SELECT i.interval_id, c.date_key
    FROM intervals i
    JOIN calendar  c ON ", join_clause))
  dbGetQuery(con, "SELECT COUNT(*) AS n FROM factless")$n
}

build_date      <- function() build_factless("c.date     BETWEEN i.date_from     AND i.date_to")
build_smart_key <- function() build_factless("c.date_key BETWEEN i.date_from_key AND i.date_to_key")

# Sanity check: both approaches must yield the same number of exploded rows.
n_date  <- build_date()
n_smart <- build_smart_key()
stopifnot(n_date == n_smart)
cat(sprintf("Factless fact rows produced: %s (both approaches agree)\n\n",
            format(n_date, big.mark = ",")))

# ---- benchmark -------------------------------------------------------------

results <- bench::mark(
  date_key  = build_date(),
  smart_key = build_smart_key(),
  iterations = iterations,
  check      = TRUE,            # both must return the same count
  filter_gc  = FALSE
)

print(results[, c("expression", "min", "median", "itr/sec", "mem_alloc")])

speedup <- as.numeric(results$median[1]) / as.numeric(results$median[2])
cat(sprintf("\nSmart key is %.2fx the speed of DATE (>1 = smart key faster, <1 = slower).\n",
            speedup))

dbDisconnect(con, shutdown = TRUE)
