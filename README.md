# The Data Analyst SQL Cookbook

This repository contains the files for [The Data Analyst SQL Cookbook](https://alaburda.github.io/data-analyst-sql-cookbook/).


## What's missing?

* gifs, more gifs, lots more gifs!
* I think SQL proficiency is related to having a mental model of how SQL data models can behave. Some sort of troubleshooting problems could be cool?

## The book repository

Each chapter has is configured to work locally as well as when it's rendered and published on GitHub Pages. Each chapter has a setup chunk that connects to the local duckdb database and has a remote connection config defined in the front matter. When working locally, we are connecting to local duckdb files. A code sample that is still being worked on (i.e. WIP or draft) will point to the local database. A chunk pointing to the interactive-duckdb connection is final, i.e. I'm not planning on making further changes apart from linting.

Instead of having one singular data model, I am using multiple different data models, each is stored in a separate duckdb file. The R script contains an end-to-end script to reproduce the database file. 



