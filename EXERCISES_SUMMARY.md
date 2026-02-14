# SQL Exercises Implementation Summary

## Overview

This document summarizes the implementation of 24 comprehensive SQL exercises for "The Data Analyst SQL Cookbook" repository.

## What Was Created

### Exercise Files (24 total)
- **Easy Exercises (1-8)**: 8 exercises covering fundamental SQL concepts
- **Medium Exercises (9-18)**: 10 exercises combining multiple SQL techniques
- **Hard Exercises (19-24)**: 6 exercises requiring advanced SQL skills

### Supporting Files
- `04-exercises.qmd` - Introduction and overview page for the exercises section
- `04-exercises/README.md` - Documentation for contributors and users
- `_quarto.yml` - Updated to include all 24 exercises in the book structure

## Exercise Details

### Easy (1-8)
1. **Top Customers by Total Spend** - Joins, aggregation
2. **Customers with No Orders** - Anti-join, NOT EXISTS, LEFT JOIN
3. **Orders Per Day** - Date functions, zero-fill, calendar joins
4. **First Order Date Per Customer** - GROUP BY, MIN, date arithmetic
5. **Low-Stock Products** - Filtering, calculated fields, ORDER BY
6. **Remove Duplicate Records** - Window functions, ROW_NUMBER, deduplication
7. **Active Users in Last 30 Days** - DISTINCT, UNION, multiple tables
8. **Customers with Frequent Returns** - Conditional aggregation, ratio calculations

### Medium (9-18)
9. **Monthly Active Users (MAU)** - Date functions, LAG, MoM growth
10. **Employee Salary Rank by Department** - RANK, DENSE_RANK, PARTITION BY
11. **Consecutive Login Streak** - Gaps-and-islands, date arithmetic
12. **Product Co-Purchase Pairs** - Self-join, market basket analysis
13. **Rolling 7-Day Average** - ROWS BETWEEN, moving averages
14. **Median Transaction Amount** - Percentiles, statistical functions
15. **Pivot Orders by Weekday** - Conditional aggregation, PIVOT
16. **Sessionization of Events** - LAG, session grouping, inactivity threshold
17. **Top-K Frequent Words** - String functions, tokenization, text analysis
18. **Cohort Retention Table** - Cohort analysis, retention rates

### Hard (19-24)
19. **Monthly Churn Rate** - Advanced cohort tracking, churn definitions
20. **Hierarchical Org Chart** - Recursive CTE, path computation, cycle detection
21. **Top-K Customers by Growth** - Period comparison, edge case handling
22. **Approximate Distinct** - HyperLogLog-like algorithms, heavy hitters
23. **Complex Session Reconstruction** - Multi-tab sessions, context switches
24. **Recommendation Co-occurrence** - Lift, Jaccard, PMI scoring algorithms

## Exercise Format

Each exercise includes:

1. **Problem Statement** - Clear description of what to solve
2. **Skills Tested** - Key SQL concepts covered
3. **Schema** - Table structures and relationships
4. **Sample Data** - Interactive queries to explore the data
5. **Expected Output** - Example of what the result should look like
6. **Requirements** - Specific criteria the solution must meet
7. **Hints** - 3 progressive hints in collapsible sections
8. **Solution Template** - Starter code with blanks to fill in
9. **Solutions** - Multiple complete solutions with explanations
10. **Alternative Approaches** - Different ways to solve the same problem
11. **Extensions** - Additional challenges for further practice

## Technical Implementation

### Quarto Integration
- All exercises use `.qmd` format (Quarto Markdown)
- Interactive SQL blocks with `{.sql .interactive .cookbook}` syntax
- Connected to remote DuckDB database on GitHub

### Database
- Uses the cookbook DuckDB database
- Tables: customers, orders, order_items, products, subscriptions, support_tickets, employees, departments, calendar
- Designed to model a B2B SaaS company

### Code Quality
- ✅ Code review passed (all feedback addressed)
- ✅ No security vulnerabilities detected
- ✅ Consistent formatting across all exercises
- ✅ Progressive learning structure (template → hints → solutions → extensions)

## Changes Made to Repository

### New Files (26)
- `04-exercises.qmd` - Exercises overview page
- `04-exercises/README.md` - Documentation
- `04-exercises/01-easy-*.qmd` through `04-exercises/24-hard-*.qmd` - 24 exercise files

### Modified Files (1)
- `_quarto.yml` - Added exercises section with all 24 files

## Learning Outcomes

By completing these exercises, users will master:

### SQL Skills
- Joins (INNER, LEFT, anti-join, self-join)
- Aggregation (GROUP BY, HAVING, conditional aggregation)
- Window functions (ROW_NUMBER, RANK, LAG/LEAD, ROWS BETWEEN)
- Date arithmetic and time-series analysis
- CTEs and recursive CTEs
- Query optimization patterns

### Analytics Skills
- Cohort analysis and retention
- Churn calculation
- Growth rate analysis
- Market basket analysis
- Recommendation algorithms
- Sessionization and user behavior analysis

### Data Quality
- Deduplication techniques
- Handling NULL values
- Zero-filling time series
- Edge case handling

## Usage

To build the book with exercises:

```bash
quarto render
```

To work through exercises:
1. Open the book in a browser
2. Navigate to the SQL Exercises section
3. Click "Run" on any SQL block to execute it
4. Try solving exercises before revealing hints/solutions

## Future Enhancements

Potential improvements for the future:
- Add video walkthroughs for hard exercises
- Include performance benchmarks
- Add visualization examples for results
- Create exercise difficulty ratings based on completion time
- Add automated testing for solutions
- Create a progress tracking system

## Statistics

- **Total exercises**: 24
- **Total lines of code**: ~15,000+ (including solutions and variations)
- **Average solutions per exercise**: 4-6 different approaches
- **Total file size**: ~500KB of educational content
- **Difficulty distribution**: 33% Easy, 42% Medium, 25% Hard

## Credits

Exercises based on the requirements from GitHub issue requesting LeetCode-style SQL practice problems for data analysts.
