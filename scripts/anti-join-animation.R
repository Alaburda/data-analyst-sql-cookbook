# ============================================================================
# ANTI JOIN Animation
# Generates a GIF showing how an anti join works to keep rows from 
# the left table that don't have a match in the right table.
#
# Style inspired by github.com/gadenbuie/tidyexplain
# ============================================================================

library(ggplot2)
library(gganimate)
library(dplyr)
library(tidyr)

# ---- 1. Build the source tables ---------------------------------------------

table_a <- tibble(
  customer_id = c(1, 2, 3, 4, 5),
  name = c("Alice", "Bob", "Carol", "Dave", "Eve")
)

table_b <- tibble(
  customer_id = c(1, 3, 5, 6),
  order_date = c("2024-01-15", "2024-01-20", "2024-01-25", "2024-01-30")
)

# Result: customers without orders
anti_result <- table_a |>
  anti_join(table_b, by = "customer_id")

# ---- 2. Helper: build one frame's tile data --------------------------------

build_table_frame <- function(data, columns, offset_x, offset_y, title, 
                              state, state_label, highlight_rows = NULL, 
                              fade_rows = NULL) {
  
  nr <- nrow(data)
  nc <- length(columns)
  
  cells <- list()
  
  # Title row
  cells[[length(cells) + 1]] <- tibble(
    col_x       = offset_x + nc/2,
    row_y       = offset_y + 1.5,
    label       = title,
    fill        = "white",
    alpha       = 1,
    is_header   = FALSE,
    is_title    = TRUE,
    state       = state,
    state_label = state_label
  )
  
  # Data cells
  for (r in seq_len(nr)) {
    for (c_idx in seq_len(nc)) {
      col_name <- columns[c_idx]
      val <- as.character(data[[col_name]][r])
      
      fill_color <- "#F5F5F5"
      alpha_val <- 1
      
      if (!is.null(highlight_rows) && r %in% highlight_rows) {
        fill_color <- "#FFD4D4"  # Light red for no match
        alpha_val <- 1
      } else if (!is.null(fade_rows) && r %in% fade_rows) {
        alpha_val <- 0.3
      }
      
      cells[[length(cells) + 1]] <- tibble(
        col_x       = offset_x + c_idx,
        row_y       = offset_y - r,
        label       = val,
        fill        = fill_color,
        alpha       = alpha_val,
        is_header   = FALSE,
        is_title    = FALSE,
        state       = state,
        state_label = state_label
      )
    }
  }
  
  # Header cells
  for (c_idx in seq_len(nc)) {
    cells[[length(cells) + 1]] <- tibble(
      col_x       = offset_x + c_idx,
      row_y       = offset_y,
      label       = columns[c_idx],
      fill        = "#E0E0E0",
      alpha       = 1,
      is_header   = TRUE,
      is_title    = FALSE,
      state       = state,
      state_label = state_label
    )
  }
  
  bind_rows(cells)
}

# ---- 3. Build all frames ----------------------------------------------------

# Frame 1: Show both tables
f1_a <- build_table_frame(table_a, c("customer_id", "name"), 0, 0, 
                          "Table A: Customers", 1,
                          "1. Two tables: customers and orders")
f1_b <- build_table_frame(table_b, c("customer_id", "order_date"), 5, 0,
                          "Table B: Orders", 1,
                          "1. Two tables: customers and orders")
f1 <- bind_rows(f1_a, f1_b)

# Frame 2: LEFT JOIN - show matched rows
matched_ids <- intersect(table_a$customer_id, table_b$customer_id)
unmatched_ids <- setdiff(table_a$customer_id, table_b$customer_id)
matched_rows_a <- which(table_a$customer_id %in% matched_ids)
unmatched_rows_a <- which(table_a$customer_id %in% unmatched_ids)

f2_a <- build_table_frame(table_a, c("customer_id", "name"), 0, 0,
                          "Table A: Customers", 2,
                          "2. LEFT JOIN: some customers have orders (faded),\nsome don't (highlighted)",
                          highlight_rows = unmatched_rows_a,
                          fade_rows = matched_rows_a)
f2_b <- build_table_frame(table_b, c("customer_id", "order_date"), 5, 0,
                          "Table B: Orders", 2,
                          "2. LEFT JOIN: some customers have orders (faded),\nsome don't (highlighted)")
f2 <- bind_rows(f2_a, f2_b)

# Frame 3: Keep only unmatched - ANTI JOIN
f3 <- build_table_frame(anti_result, c("customer_id", "name"), 2, 0,
                        "Result: Customers without orders", 3,
                        "3. ANTI JOIN: keep only customers WITHOUT orders")

all_frames <- bind_rows(f1, f2, f3)

# ---- 4. Plot ----------------------------------------------------------------

tw <- 0.94
th <- 0.82

p <- ggplot(all_frames, aes(x = col_x, y = row_y)) +
  geom_tile(
    data = subset(all_frames, !is_title),
    aes(fill = fill, alpha = alpha),
    width = tw, height = th,
    colour = "white", linewidth = 1.8
  ) +
  geom_text(
    data = subset(all_frames, !is_title),
    aes(label = label, alpha = alpha),
    size = 5, family = "sans",
    fontface = ifelse(subset(all_frames, !is_title)$is_header, "bold", "plain")
  ) +
  geom_text(
    data = subset(all_frames, is_title),
    aes(label = label),
    size = 6, family = "sans", fontface = "bold", colour = "#333333"
  ) +
  scale_fill_identity() +
  scale_alpha_identity() +
  coord_cartesian(clip = "off") +
  labs(
    title    = "Anti Join: Keep rows without a match",
    subtitle = "{closest_state}"
  ) +
  theme_void(base_size = 14) +
  theme(
    plot.title    = element_text(face = "bold", size = 18, hjust = 0.5,
                                 margin = margin(b = 4), family = "sans"),
    plot.subtitle = element_text(size = 12, hjust = 0.5, colour = "#444",
                                  margin = margin(b = 10), lineheight = 1.15,
                                  family = "mono"),
    plot.margin   = margin(20, 40, 20, 40),
    plot.background = element_rect(fill = "white", colour = NA)
  ) +
  transition_states(state_label, transition_length = 2, state_length = 5,
                    wrap = FALSE) +
  enter_fade() +
  exit_fade() +
  ease_aes("cubic-in-out")

# ---- 5. Render ---------------------------------------------------------------

anim <- animate(
  p,
  nframes  = 120,
  fps      = 20,
  width    = 900,
  height   = 500,
  res      = 96,
  renderer = magick_renderer()
)

out_path <- "images/anti-join.gif"
if (!dir.exists("images")) dir.create("images", recursive = TRUE)
anim_save(out_path, animation = anim)
cat("GIF saved to", out_path, "\n")
