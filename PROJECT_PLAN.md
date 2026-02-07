# Project Plan: The Data Analyst SQL Cookbook

## Database Schema

All chapters query a single **DuckDB** database (`db/cookbook.duckdb`) built by
`db/build_cookbook_db.R` using the `{dm}` package. The schema is designed to
model a typical B2B SaaS company so that every recipe feels grounded in
reality.

```
┌──────────────┐      ┌──────────────┐
│  departments │◄─────│  employees   │──┐ (manager_id → employee_id)
└──────────────┘      └──────┬───────┘  │
                             │          │
                             │ assigned_to
                             ▼          │
┌──────────────┐      ┌──────────────┐  │
│   products   │◄─────│support_ticket│──┘
└──────┬───────┘      └──────┬───────┘
       │                     │ customer_id
       │ product_id          │
       ▼                     ▼
┌──────────────┐      ┌──────────────┐
│ order_items  │─────►│  customers   │
└──────┬───────┘      └──────┬───────┘
       │ order_id            │ customer_id
       ▼                     ▼
┌──────────────┐      ┌──────────────┐
│    orders    │      │subscriptions │ (SCD2: valid_from / valid_to)
└──────────────┘      └──────────────┘

┌──────────────┐
│   calendar   │  (date dimension, 2022-01-01 → 2025-12-31)
└──────────────┘
```

### Tables at a glance

| Table | Rows (approx) | Purpose |
|---|---|---|
| `calendar` | ~1,461 | Date dimension for joins & aggregations |
| `departments` | 6 | Lookup / dimension |
| `employees` | 50 | Hierarchical (self-referencing `manager_id`) |
| `customers` | 200 | Customer dimension with segment & geography |
| `products` | 12 | Subscriptions, add‑ons, services, features |
| `subscriptions` | 300 | SCD2 style (`valid_from` / `valid_to`) |
| `orders` | 800 | Transactional fact |
| `order_items` | ~1,200 | Line-level detail |
| `support_tickets` | 400 | Tickets with priority, category, resolution |

---

## Book Structure & Chapter Plan

### Part I — The Basics

Audience: analysts writing their first real queries. Every section uses the
cookbook database so readers can run the code interactively.

| # | Chapter | Status | Key concepts | Tables used |
|---|---------|--------|-------------|-------------|
| 1.1 | **Things to Know Before Starting** | 🟡 Draft | NULLs, UNION vs UNION ALL, execution order | `employees` |
| 1.2 | **SELECT** | 🟡 Stub | Expressions, aliases, DISTINCT, CASE WHEN, COALESCE | `employees`, `customers` |
| 1.3 | **Filtering & WHERE** | 🟡 Draft | WHERE, IN, BETWEEN, LIKE, IS NULL, EXISTS | `orders`, `customers` |
| 1.4 | **Aggregation & GROUP BY** | 🔴 New | COUNT, SUM, AVG, MIN/MAX, HAVING, GROUPING SETS | `orders`, `order_items` |
| 1.5 | **Joins** | 🟡 Draft | INNER, LEFT, anti-joins, non-equi joins, self-joins | all tables |
| 1.6 | **Window Functions** | 🟡 Stub | ROW_NUMBER, RANK, LAG/LEAD, running totals, QUALIFY | `orders`, `subscriptions` |
| 1.7 | **CTEs & Subqueries** | 🔴 New | WITH, correlated subqueries, recursive CTEs | `employees` |
| 1.8 | **Using SQL in R** | 🟢 Done | DBI, dbplyr, duckdb | — |
| 1.9 | **Using SQL in dbt** | 🟡 Draft | Models, sources, refs | — |

### Part II — Data Modelling Techniques

Audience: analysts building star schemas and semantic layers.

| # | Chapter | Status | Key concepts | Tables used |
|---|---------|--------|-------------|-------------|
| 2.1 | **The Calendar / Date Dimension** | 🔴 New | Why you need one, how to build it, fiscal calendars | `calendar` |
| 2.2 | **Factless Fact Tables** | 🟡 Draft | Expanding SCD2 rows into time-grain facts | `subscriptions`, `calendar` |
| 2.3 | **Ragged-Depth Hierarchies** | 🟡 Draft | Bridge tables via recursive CTE, roll-up | `employees` |
| 2.4 | **Slowly Changing Dimensions** | 🔴 New | SCD Type 1 vs 2, snapshots vs factless | `subscriptions` |
| 2.5 | **Star Schema Basics for Analysts** | 🔴 New | Fact vs dimension, grain, conformed dims | all tables |

### Part III — Recipes

Audience: anyone who needs a ready-made pattern. Organised by problem type.

| # | Chapter | Status | Key concepts | Tables used |
|---|---------|--------|-------------|-------------|
| 3.1 | **Queries with Dates** | 🟡 Draft | Intersecting ranges, date arithmetic, age calculations | `subscriptions`, `calendar` |
| 3.2 | **Pivoting & Unpivoting** | 🟢 Done | CASE WHEN pivot, UNION ALL unpivot, PIVOT/UNPIVOT syntax | `order_items`, `products` |
| 3.3 | **Filtering Patterns** | 🟡 Draft | Anti-join, EXISTS vs IN, ON-clause filtering, QUALIFY | `customers`, `orders` |
| 3.4 | **Joins on Dates** | 🟡 Draft | ASOF joins, rolling attribution, calendar joins | `orders`, `support_tickets`, `calendar` |
| 3.5 | **Clustering Series of Rows (Islands & Gaps)** | 🟡 Stub | Sessionisation, consecutive grouping, gap detection | `support_tickets`, `orders` |
| 3.6 | **Splitting Time Intervals** | 🟡 Draft | Breaking date ranges across periods | `subscriptions`, `calendar` |
| 3.7 | **Qualifying Events in Time** | 🟡 Draft | Cooldown logic, first-event attribution, recursive CTE | `support_tickets` |
| 3.8 | **Counting Things Over Time** | 🔴 New | Running counts, MoM growth, YoY comparison, cumulative metrics | `orders`, `subscriptions`, `calendar` |
| 3.9 | **Customer Analytics Recipes** | 🔴 New | Cohort analysis, retention, churn, LTV, RFM segmentation | `customers`, `orders`, `subscriptions` |
| 3.10 | **Hierarchical Queries** | 🔴 New | Recursive CTE for org chart, tree traversal, path building | `employees`, `departments` |
| 3.11 | **Deduplication & Data Quality** | 🔴 New | Finding duplicates, picking canonical rows, fuzzy matching | `customers`, `support_tickets` |
| 3.12 | **Ranking & Top-N** | 🔴 New | Top-N per group, percentiles, dense rank use cases | `order_items`, `employees` |

### Extras

| Chapter | Status | Notes |
|---------|--------|-------|
| **Goodies** | 🟡 Draft | Miscellaneous tips and tricks |
| **Anti-Patterns** | 🟡 Draft | Common SQL mistakes and how to fix them |
| **References** | 🟢 Done | Bibliography |

---

## Recipe Ideas by Table

These are concrete query ideas that map onto the chapters above. Each one
should be a self-contained, runnable example.

### Employees (hierarchical)

1. **Org chart traversal** — recursive CTE that builds a path from CEO → leaf
2. **Count reports per manager** (direct & total)
3. **Salary roll-up by hierarchy level** — total cost per sub-tree
4. **Find skip-level reports** — employees whose manager's manager is X
5. **Tenure analysis** — average tenure by department, identify longest-serving

### Customers

6. **Cohort analysis** — group by sign-up month, track retention
7. **RFM segmentation** — recency / frequency / monetary scoring
8. **Customer lifetime value** — cumulative order value per customer
9. **Geographic breakdown** — orders and revenue by city/country
10. **Segment migration** — how customers move between segments over time

### Orders & Order Items

11. **Revenue over time** — daily, weekly, monthly using calendar dimension
12. **MoM & YoY growth** — using LAG window function
13. **Average order value** — overall and by segment
14. **Top-N products per month** — RANK + partition
15. **Market basket analysis** — products frequently ordered together
16. **Refund rate** — percentage of refunded orders by product

### Subscriptions (SCD2)

17. **Active subscribers per month** — factless fact table recipe
18. **Churn rate over time** — count cancelled / total active
19. **Subscription upgrades/downgrades** — track product changes per customer
20. **MRR (Monthly Recurring Revenue)** — sum of monthly_amount for active subs
21. **Subscription overlap** — customers with multiple concurrent subscriptions

### Support Tickets

22. **Average resolution time** — by category and priority
23. **Ticket volume trends** — daily/weekly using calendar dimension
24. **Agent workload analysis** — tickets per employee, resolution time per agent
25. **Repeat customers** — customers who open multiple tickets within 30 days
26. **Satisfaction score analysis** — average CSAT by category, priority, agent
27. **SLA compliance** — percentage of tickets resolved within X days by priority

### Cross-Table

28. **Customer 360 view** — join customers + orders + subscriptions + tickets
29. **Revenue vs support cost** — high-revenue customers who also have many tickets
30. **First order to first ticket** — time between first purchase and first support contact

---

## Milestones

### Milestone 1: Foundation ✅

- [x] Design relational schema
- [x] Build `db/build_cookbook_db.R` (dm model + data generation + DuckDB)
- [x] Write project plan

### Milestone 2: Database & Basics

- [ ] Run `build_cookbook_db.R` and verify DuckDB database
- [ ] Update `_quarto.yml` to point all chapters to the DuckDB database
- [ ] Write / finish Part I chapters (1.1–1.7)
- [ ] Ensure all interactive SQL chunks work against the new database

### Milestone 3: Data Modelling

- [ ] Write calendar dimension chapter (2.1)
- [ ] Finish factless fact table chapter (2.2)
- [ ] Finish ragged hierarchies chapter (2.3)
- [ ] Write SCD and star schema chapters (2.4–2.5)

### Milestone 4: Recipes

- [ ] Finish existing recipe drafts (3.1–3.7)
- [ ] Write new recipe chapters (3.8–3.12)
- [ ] Add at least 2–3 runnable examples per chapter

### Milestone 5: Polish

- [ ] Review all chapters for consistency
- [ ] Update README with database schema docs
- [ ] Publish updated book to GitHub Pages
