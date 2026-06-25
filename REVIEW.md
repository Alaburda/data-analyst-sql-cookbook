# Review — *The Data Analyst SQL Cookbook*

*Reviewer pass: read every chapter source under `index.qmd`, `00-intro/`, `01-basics/`, `02-models/`, `03-recipes/`, `misc/`, and the build config. Date: 2026-06-25.*

---

## 1. Executive summary

There is a genuinely good book in here, and in two or three chapters it already exists. The voice is opinionated and practical, the interactive OJS walkthroughs are a real differentiator, and the editorial point of view (factless fact tables, "the analyst owns the semantic layer," EXPLAIN-driven anti-patterns) is something most SQL books lack. That is the asset worth protecting.

But as a *representative example of your work*, the book is not there yet, and the gap is not subtle. The book is roughly **30% finished prose, 70% scaffolding**. A reader who opens it today lands on a preface with unfinished sentences, clicks into "The Basics" and finds a page that uses tables named `fart` and `fart2`, then opens "Selecting Tables" and finds a single sentence about UNION. The strong chapters (Window Functions, Grouping Consecutive Rows, Anti-Patterns) are buried among stubs, so the average impression is much weaker than the best-case impression.

My honest framing: **this currently reads as an excellent set of working notes, not yet a resource you'd hand to a stranger.** The good news is that the distance between those two things is mostly *finishing and consistency work*, not rethinking. The structure and the best chapters prove the concept. Below is what to keep, what to fix, and the order I'd do it in.

**Top 5 things to fix first**
1. **A complete, polished chapter is missing from the book.** `03-recipes/customer-analytics.qmd` (16 working interactive queries) and `01-basics/schemaless-tables.qmd` are not listed in `_quarto.yml`, so they never render. Meanwhile `_quarto.yml:30` points to `02-models/models.qmd`, which doesn't exist — so a full book render fails. The TOC and the filesystem have drifted apart.
2. **Finish or hide the stubs.** ~10 chapters are headings with no body. Empty chapters in a published book read worse than fewer chapters.
3. **Consolidate to one dataset.** Four databases (`carwash`, `cookbook`, `stocks`, `subscriptions`) are used semi-interchangeably, and several chapters point at the wrong one. Pick one canonical story.
4. **Fix the broken interactive blocks.** Several `{.sql .interactive .X}` blocks reference a database class that isn't declared, or a DB whose schema doesn't match the query, so the ▶ Run button errors. Details in §6.
5. **One editorial polish pass.** Placeholder text (`fart`, "lol"), `[[ ]]` TODO markers, duplicated paragraphs, and a recurring set of typos undercut the credibility of the strong material.

---

## 2. What I liked (keep and lean into this)

- **The voice.** Opinionated, funny, human. "Loosely is a load-bearing word here." "If you are already thinking about indexes, congratulations — you're probably a software developer. Go ask for a promotion." This is the book's competitive advantage over the dozens of dry SQL references. Don't sand it off in editing.
- **The "Slack message" problem framing.** The callout blocks that open a recipe with a real stakeholder request — *"Hey Paulius, can you quickly create this table that shows our subscriber count over time?"*, *"Hi, can you please find users who were on premium last year real quick?"* — are excellent. They instantly establish *why the reader should care*. This should be a standard element on every recipe.
- **The interactive OJS step-throughs.** The anti-join walkthrough (`joining-tables.qmd`) and the gaps-and-islands walkthrough (`grouping-consecutive-rows.qmd`) are genuinely better than what most SQL books or blog posts offer. Stepping through rank-subtraction visually is the clearest explanation of islands I've seen. These are worth the effort; build more of them.
- **EXPLAIN-driven anti-patterns.** `anti-patterns.qmd` showing the actual DuckDB physical plan (NESTED_LOOP_JOIN, BLOCKWISE_NL_JOIN) before and after a rewrite is a rare and valuable teaching move. Most "SQL anti-patterns" content asserts; yours demonstrates.
- **A real point of view on data modeling.** The argument that the analyst should own an *expressive* semantic layer so KPIs are simple counts/sums — and the factless-fact-table evangelism tied to concrete Power BI / Tableau pain — is the intellectual core of the book. It's good. It just needs to be finished.
- **Honesty.** The AI disclaimer and the occasional "this section is more for my own self-learning" build trust rather than erode it.
- **The Window Functions chapter** (`01-basics/window-functions.qmd`) is, frankly, publishable as-is. Clear anatomy diagram, the RANK/DENSE_RANK and ROWS/RANGE callouts are exactly the right depth, examples build logically, and it uses the right dataset for each example (orders for ranking, stocks for moving averages). **Use this chapter as the template for everything else.**

---

## 3. Completeness audit (chapter by chapter)

Status legend: ✅ publishable · 🟡 substantial but unfinished · 🔴 stub/skeleton · ⚠️ exists but not in the book's TOC

| Chapter | Status | Notes |
|---|---|---|
| `index.qmd` (Preface) | 🔴 | Unfinished sentences ("It's " / "If the model is expressive and X"); the same "expressive model nets you" bullet list appears twice nearly verbatim. This is the **first page readers see**. |
| `00-intro/introduction.qmd` | 🔴 | Opens with a literal dangling sentence: "The section on recipes is a collection of". |
| `00-intro/meet-the-data.qmd` | 🟡 | New carwash ERD + interactive block are good. But the lower half still describes the *cookbook* SaaS DB, has an empty "Stocks" heading, and a table-overview for a third schema. One page, three databases — confusing. |
| `00-intro/meet-the-tools.qmd` | 🔴 | Tool list is fine; DuckDB / duckplyr / dbt / Learning Resources sections are empty headings. |
| `01-basics/basics.qmd` (part page) | 🔴 | Body uses placeholder table names `fart` / `fart2` and informal stream-of-consciousness. Not shippable. |
| `01-basics/oltp-vs-olap.qmd` | 🔴 | Two sentences, ends with "anyway lol". |
| `01-basics/using-sql-in-r.qmd` | 🔴 | Three links, no prose. |
| `01-basics/using-sql-in-dbt.qmd` | 🟡 | The incremental-model point is sharp and correct; just needs framing and a conclusion. |
| `01-basics/selecting-tables.qmd` | 🔴 | One sentence about UNION. Title promises "a lot of things between SELECT and FROM." |
| `01-basics/joining-tables.qmd` | 🟡 | Great anti-join OJS demo and the keys section is strong. But many sections are "For example:" with no example, and the range-join interactive block is mis-wired (see §6). |
| `01-basics/window-functions.qmd` | ✅ | The standout. Template for the rest. |
| `01-basics/filtering-tables.qmd` | 🔴 | Duplicates the anti-join topic from joining-tables, several empty interactive blocks, queries reference tables that don't exist in the attached DB, ends on two `[[ ]]` exercise TODOs. |
| `01-basics/structuring-queries.qmd` | 🔴 | Three headings (Subqueries / CTEs / Recursive CTEs), zero content — and these are *foundational*. |
| `01-basics/schemaless-tables.qmd` | 🟡 ⚠️ | Good intro on JSON/schemaless; **not in the TOC**, so it never renders. |
| `01-basics/anti-patterns.qmd` | 🟡 | Strong concept and execution; a few trailing empty `EXPLAIN` chunks and references to non-existent tables (`vip`, `plan_autorenew`). |
| `02-models/models.qmd` (part page) | 🔴 | **Missing from disk** but referenced in `_quarto.yml` → breaks full render. |
| `02-models/types-of-models.qmd` | 🔴 | All empty headings. |
| `02-models/calendar-date-dimension.qmd` | ✅ | Complete and good. Easter-macro and Nager.Date API touches are delightful and show range. |
| `02-models/factless-fact-tables.qmd` | 🟡 | Strong thesis, but visibly a draft: repeated paragraphs, a placeholder `[[ ]]` note, a "Hey Paulius" callout left mid-thought, and a broken interactive block class. The actual "build it" payoff is thin. |
| `02-models/ragged-depth-hierarchies.qmd` | 🟡 | Excellent setup and motivation — then stops at a recursive path CTE and never delivers the **bridge table**, which is the Kimball answer the chapter promised. Also uses `employee_name`, a column that doesn't exist. |
| `03-recipes/recipes.qmd` (part page) | ✅ | Short, but the ANTI JOIN framing is a nice intro to the section's philosophy. |
| `03-recipes/splitting-time-intervals.qmd` | 🟡 | Lots of material, but mostly `eval: false`, R-heavy, and includes a wall of unformatted T-SQL (one ~500-char line). Disjointed. |
| `03-recipes/querying-intersecting-dates.qmd` | ✅ | Short, focused, correct, well-explained. A good model for a "small recipe." |
| `03-recipes/pivoting-and-unpivoting.qmd` | 🔴 | The *content* is good but it's clearly accreted drafts: the definition of "pivoting" is restated ~5 times, two identical SQL blocks, three competing intros. Needs a hard de-dupe. |
| `03-recipes/grouping-consecutive-rows.qmd` | ✅/🟡 | Best recipe in the book. The OJS islands walkthrough is superb. Tail of the chapter has several `eval:false` half-queries (one ends literally `from `) that should be finished or cut. |
| `03-recipes/finding-gaps-in-ordered-data.qmd` | 🔴 | One T-SQL snippet against `dbo.NumSeq`, an undeclared `.chinook` DB, no DuckDB equivalent. |
| `03-recipes/occupancy.qmd` | 🟡 | Good idea (occupancy = factless fact table + count), but the code mixes SQLite/DuckDB syntax, points at a 404 DB path, and queries an `occupancy` table that doesn't exist. |
| `03-recipes/qualifying-events-in-time.qmd` | 🟡 | Actually has a *working* recursive CTE and a great hook (Erika Pullum's teaser). Mis-scoped — it's really "Recursive CTEs," which `structuring-queries.qmd` also claims. |
| `03-recipes/customer-analytics.qmd` | ✅ ⚠️ | **A finished, polished chapter with 16 working interactive queries — and it's not in the TOC.** This is your second-best chapter and nobody can see it. |
| `misc/goodies.qmd` | 🔴 | Duplicates snippets already in the filtering chapter. |
| `references.qmd` | 🔴 | Raw link dump. |

**Tally:** ~4 publishable, ~10 substantial-but-unfinished, ~12 stubs, **2 finished/near-finished chapters hidden from the build.**

---

## 4. What's missing (content gaps a reader will feel)

Given the stated goal — *"throw this at a fresh data analyst and say: here, this'll get you up to speed"* — these are the holes that contradict that promise:

- **The actual basics aren't written.** `SELECT`/`FROM`/`WHERE`, `GROUP BY`/`HAVING`, aggregate functions, `CASE`, `COALESCE`/NULL semantics, `ORDER BY`/`LIMIT`, and especially **CTEs and subqueries** (`structuring-queries.qmd` is empty) are the connective tissue every later chapter assumes. Right now Window Functions is rigorous but the reader has no grounded `GROUP BY` chapter to stand on.
- **A "How to use this book" / "How to run the examples."** There's no orientation: which database am I querying, how do the interactive blocks work, do I need anything installed, can I run these against my own warehouse. The interactivity is a headline feature and it's unexplained.
- **A single data dictionary.** Readers need one place that says "here are the tables and columns." `meet-the-data` gestures at it but across two schemas.
- **DuckDB-native goodies you clearly know.** `QUALIFY` (huge for all your `ROW_NUMBER() ... WHERE rn = 1` patterns), `EXCLUDE`/`REPLACE`, `GROUP BY ALL`, list/struct columns, `UNPIVOT`/`PIVOT`. The book leans on DuckDB but underuses its best ergonomics.
- **Set operations beyond UNION.** `EXCEPT`/`INTERSECT` deserve a mention — `EXCEPT` is a one-liner alternative to some anti-joins and ties directly into your "recipes act like functions" thesis.
- **Deduplication as an explicit recipe.** It's implicit in `ROW_NUMBER()`, but "remove duplicate rows / keep latest" is one of the most-Googled analyst tasks and deserves its own named recipe.
- **The lingo glossary you keep *almost* writing.** You complain (entertainingly) about "conformed" and "role-playing" dimensions. Turn that into a value-add: a short, opinionated glossary that demystifies Kimball jargon. That's on-brand and useful instead of just venting.
- **Closure on dbt/testing.** dbt is named repeatedly (incremental models, `unpivot` macro) but there's no section delivering on it — including data tests, which is exactly the "validate your semantic layer" idea you advocate.

---

## 5. What I didn't like / would change

- **The average experience is dragged down by stubs.** A reader judges a book by the page they happen to open, and too many pages are empty headings. **Fewer, finished chapters beat many skeletal ones.** I'd cut the TOC down to what's done (plus clearly-marked WIP), and keep the rest in a branch.
- **Professionalism slips that don't match the ambition.** `fart`/`fart2` table names on the Basics part page, "lol", and visible `[[ ]]` author-notes are fine in a Git draft but jarring in something you're presenting as a work sample. Replace `fart` with the carwash entities; the examples lose nothing.
- **Dialect mixing without signposting.** The book is DuckDB-first, but recipes paste raw T-SQL (`dbo.Sessions`, `CROSS APPLY`, `GO`, `dbo.NumSeq`) and SQLite (`datetime(...)`) without flagging the switch or porting it. A fresh analyst running these in DuckDB will hit errors. Either port everything to DuckDB or add a visible "this snippet is T-SQL" banner and a DuckDB equivalent.
- **Keyword-casing is inconsistent across chapters** (Window Functions is all-caps `SELECT`; recipes are lowercase `select`). Either is fine; pick one and apply it. Mixed casing reads as multiple authors.
- **Topic duplication without a canonical home.** Anti-joins are taught in `joining-tables`, again in `filtering-tables`, and referenced in `recipes`. Islands/gaps logic spans `grouping-consecutive-rows`, `finding-gaps-in-ordered-data`, and `splitting-time-intervals`. Decide the canonical location for each concept and cross-link to it instead of re-explaining.
- **Recipes don't share a shape.** The best ones implicitly follow *Problem → Data → Solution → How it works → Variations/Gotchas*. The weak ones are a pile of `eval:false` blocks. Standardizing on that template (you already have the perfect "Problem" device in the Slack callouts) would lift the whole Recipes section.
- **Stale preface meta-narrative.** The preface calls data modeling a "secret third part," but it's openly Part 2 in the TOC. The framing text and the actual structure have drifted.
- **Trailing dead code.** Multiple chapters end on empty ```` ```{sql} ```` chunks or queries that stop mid-statement (`grouping-consecutive-rows.qmd` ends a CTE with `from ` and nothing after). Each one is a small credibility leak.

---

## 6. Technical bugs & inconsistencies (concrete)

These are real correctness issues, mostly in the data plumbing. The interactive blocks are a headline feature, so broken ones are costly.

**Broken interactive `{.sql .interactive .X}` blocks** — the class `.X` must match a `name:` in that file's `databases:` front-matter, or the ▶ Run button errors:

- `01-basics/joining-tables.qmd:294` — block class is `.joins`, but the file only declares `name: cookbook`. **Won't run.**
- `02-models/factless-fact-tables.qmd:105` — block class is `.db`, but the file declares `name: cookbook`. **Won't run.** (Also the query uses `date_from`/`date_to`, while the cookbook `subscriptions` table uses `valid_from`/`valid_to`.)
- `03-recipes/finding-gaps-in-ordered-data.qmd:14` — block class is `.chinook`, but the file has **no `databases:` block at all**. **Won't run.** The SQL is also T-SQL against `dbo.NumSeq`.

**Wrong / mismatched database wiring:**

- `03-recipes/querying-intersecting-dates.qmd:8` — path typo `carwas.duckdb` (missing `h`). The remote DB would 404. (The chapter happens to use the local `con`, so it renders, but the front-matter is wrong and misleading.)
- `03-recipes/occupancy.qmd:8` — path is `.../master/db/cookbook.duckdb`; there is no `db/` folder (it's `databases/`). 404. The R `con` then connects to `subscriptions.duckdb`, and the `.cookbook` block queries an `occupancy` table that exists in none of the four DBs.
- `01-basics/filtering-tables.qmd` — `name: subscriptions` but `path:` → `carwash.duckdb`; the R `con` connects to `subscriptions.duckdb`. The interactive queries reference `subscribers`, `subscription_type`, `created_channel`, `users.id` — none of which exist in the carwash schema. These examples cannot return rows.
- `01-basics/selecting-tables.qmd:7-8` — `name: subscriptions` paired with `path:` → `carwash.duckdb`. Naming/data mismatch.
- General: `read_only = TRUE` is used in some setup chunks and omitted in others (`grouping-consecutive-rows`, `occupancy`, `ragged-depth-hierarchies`). For a read-only book DB it should be consistent (and `TRUE` avoids lock issues on rebuild).

**Schema/column mismatches in shown queries:**

- `02-models/ragged-depth-hierarchies.qmd:44,54` — selects `employee_name`; the carwash/cookbook `employees` tables have `first_name`/`last_name`, no `employee_name`. (The chunk is `eval:false`, so it doesn't error, but a reader copying it will fail.)
- `03-recipes/grouping-consecutive-rows.qmd:336+` — queries `requests.request_submitted_at`; the carwash `requests` table column is `submitted_at`. (`eval:false`.)
- `01-basics/anti-patterns.qmd` — `vip`, `plan_autorenew`, `plan_legacy` tables/columns don't exist in carwash. (`eval:false`, but the empty trailing `EXPLAIN` chunks should be removed.)

**Build / structure:**

- `_quarto.yml:30` references `02-models/models.qmd`, which does not exist on disk → full `quarto render` fails. (This is why only single-file renders have been happening, which is also how the 16 orphan HTML files in `docs/` accumulated.)
- `03-recipes/customer-analytics.qmd` and `01-basics/schemaless-tables.qmd` exist and are (mostly) finished but are **absent from `_quarto.yml`**, so they're invisible in the book.
- Broken cross-reference: `joining-tables.qmd:276` links to `03-recipes/filtering.qmd`; the file is `01-basics/filtering-tables.qmd`.

---

## 7. Editorial / polish

A non-exhaustive list of recurring typos to catch in a spell pass: *eldtrich* → eldritch (appears twice, spelled differently each time), *consistant* → consistent, *familliar* → familiar, *shorted* → shorter, *FOr* → For, *the [it]* (broken link text), *solution* vs *solutions* agreement in the factless chapter, *differ* → difference. A single pass with a spell-checker plus a read-aloud will catch most.

Beyond spelling: hunt down every `[[ ... ]]` author-note (there are several across `joining-tables`, `filtering-tables`, `factless-fact-tables`) and either resolve or delete before publish — they're invisible to you in the source but render as literal `[[ ]]` text on the live site (that's exactly how the stale `the-data-model.html` page was showing them).

---

## 8. Structural recommendations

1. **Pick one canonical dataset and commit to it.** `carwash` is the most thematically coherent and best-documented (it now has a real ERD). I'd make it *the* book database, port the cookbook/stocks examples onto it where possible, and keep `stocks` only where you genuinely need a time series (moving averages). Four datasets is three too many for a teaching book; every switch costs the reader context.
2. **Adopt the Window Functions chapter as the house style** and the recipe template: Slack-message Problem → "here's the data" → solution query (runnable) → "how it works" → callout for the gotcha → optional exercise. Retrofit the strong-but-messy chapters to it first (factless, pivoting, grouping).
3. **Triage the TOC.** Move every 🔴 stub out of `_quarto.yml` into a "drafts" branch or an explicitly-labeled *Work in progress* appendix. Add the two hidden finished chapters back in. The published book should contain only things you're proud of.
4. **Write the three foundational basics** (`SELECT/GROUP BY`, CTEs & subqueries, NULL handling) before anything else new — they're load-bearing for chapters you've already written.
5. **Add front-matter orientation:** a one-page "How to use this book / how the interactive examples work / meet the dataset," linked from the preface.
6. **Make the full render part of your loop.** Once `models.qmd` exists and the TOC is clean, a full `quarto render` (rather than per-file) keeps `docs/` consistent and would have prevented both the orphan-HTML mess and the hidden-chapter problem.

---

## 9. Suggested order of attack

**Phase 1 — Stop the bleeding (hours, not days).** Fix `_quarto.yml` (restore `models.qmd`, add the two hidden chapters, drop the worst stubs). Fix the 6 DB-wiring bugs in §6. Strip `[[ ]]` notes and the empty trailing chunks. Spell pass. *Outcome: the book builds fully, nothing is visibly broken, no embarrassing placeholders.*

**Phase 2 — Make the average page good (the real work).** Finish or remove every 🟡/🔴. Consolidate to one dataset. De-duplicate the pivoting and anti-join content. Deliver the bridge-table payoff in ragged hierarchies. *Outcome: a reader opening a random page gets something finished.*

**Phase 3 — Make it a destination.** Write the missing basics, add the DuckDB-native chapter (QUALIFY et al.), the Kimball glossary, the dedup recipe, and more OJS walkthroughs. *Outcome: the "hand it to a fresh analyst" promise is actually true.*

---

### Closing

The ceiling here is high — Window Functions, Grouping Consecutive Rows, and the EXPLAIN-driven Anti-Patterns chapter are already the kind of thing people bookmark and share. The job now is mostly *subtraction and finishing*: cut what isn't done, fix the plumbing so the interactive promise holds, and bring the median chapter up to the level of your best three. Do that and this stops being "good notes" and becomes a book you can put your name on the front of without caveats.
