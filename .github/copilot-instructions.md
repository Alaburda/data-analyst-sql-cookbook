This repo contains code to a book called "Data Analyst SQL Cookbook".

The front matter for each .qmd file should look something like this:


---
title: "Window Functions"
engine: knitr
filters:
  - interactive-duckdb
databases:
  - name: cookbook
    path: "https://raw.githubusercontent.com/Alaburda/data-analyst-sql-cookbook/master/databases/cookbook.duckdb"
    format: duckdb
---

```{r setup}
#| echo: false
#| message: false
#| warning: false

library(duckdb)

con <- dbConnect(duckdb(), "../databases/cookbook.duckdb", read_only = TRUE)

```

The database may vary but it should be there.
