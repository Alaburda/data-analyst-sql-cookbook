# SQL Exercises

This directory contains 24 comprehensive SQL exercises organized by difficulty level (Easy, Medium, Hard). Each exercise follows a LeetCode-style format with:

- Problem statement and skills tested
- Schema definitions
- Sample data exploration queries
- Expected output format
- Requirements
- Progressive hints (collapsible)
- Solution template
- Detailed solutions with multiple approaches
- Extensions for additional practice

## Exercise List

### Easy (1-8)
1. **Top Customers by Total Spend** - Joins, aggregation
2. **Customers with No Orders** - Anti-join, NOT EXISTS
3. **Orders Per Day** - Date functions, zero-fill
4. **First Order Date Per Customer** - GROUP BY, MIN
5. **Low-Stock Products** - Filtering, calculated fields
6. **Remove Duplicate Records** - Window functions, ROW_NUMBER
7. **Active Users in Last 30 Days** - DISTINCT, UNION
8. **Customers with Frequent Returns** - Conditional aggregation

### Medium (9-18)
9. **Monthly Active Users (MAU)** - LAG, MoM growth
10. **Employee Salary Rank by Department** - RANK, DENSE_RANK, PARTITION BY
11. **Consecutive Login Streak** - Gaps-and-islands pattern
12. **Product Co-Purchase Pairs** - Self-join, market basket analysis
13. **Rolling 7-Day Average of Sales** - ROWS BETWEEN window functions
14. **Median Transaction Amount** - Percentiles, window functions
15. **Pivot Orders by Weekday** - Conditional aggregation, PIVOT
16. **Sessionization of Events** - LAG, session reconstruction
17. **Top-K Frequent Words** - String functions, tokenization
18. **Cohort Retention Table** - Cohort analysis, retention rates

### Hard (19-24)
19. **Monthly Churn Rate and Cohort Analysis** - Advanced cohort tracking
20. **Path and Depth in Hierarchical Org Chart** - Recursive CTE, cycle detection
21. **Top-K Customers by Growth Rate** - Period comparison, edge cases
22. **Approximate Distinct and Heavy Hitters** - HyperLogLog-like algorithms
23. **Complex Session Reconstruction** - Multi-tab sessions, context switches
24. **Recommendation Co-Occurrence** - Lift, Jaccard, PMI scoring

## Using the Exercises

All exercises are designed to work with the interactive SQL extension for Quarto. They connect to the cookbook DuckDB database hosted on GitHub.

To build the book with these exercises included:

```bash
quarto render
```

## File Naming Convention

Files follow the pattern: `{number}-{difficulty}-{name}.qmd`

Examples:
- `01-easy-top-customers-by-spend.qmd`
- `12-medium-product-co-purchase-pairs.qmd`
- `24-hard-recommendation-co-occurrence.qmd`

## Database Schema

Exercises use the cookbook database with these tables:
- `customers` - Customer dimension
- `orders` - Order transactions
- `order_items` - Order line items
- `products` - Product catalog
- `subscriptions` - SCD Type 2 subscription data
- `support_tickets` - Support ticket records
- `employees` - Employee hierarchy
- `departments` - Department lookup
- `calendar` - Date dimension (2022-2025)

## Contributing

When adding new exercises:
1. Follow the existing format and structure
2. Use the same YAML header with interactive-duckdb
3. Include progressive hints in collapsible sections
4. Provide multiple solution approaches
5. Add extensions for further practice
6. Test all SQL queries against the cookbook database
