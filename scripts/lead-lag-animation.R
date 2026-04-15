# ============================================================================
# LEAD() and LAG() Window Functions Animation
# Generates a GIF showing how LEAD() and LAG() window functions work
# to access data from preceding and following rows.
#
# Style inspired by github.com/gadenbuie/tidyexplain
# ============================================================================

library(ggplot2)
library(gganimate)
library(dplyr)
library(tidyr)

# ---- 1. Build the source "table" -------------------------------------------

raw <- tibble(
  date = c("2024-01-01", "2024-01-02", "2024-01-03", "2024-01-04", "2024-01-05"),
  sales = c(100, 150, 120, 180, 140)
)

# Add LAG and LEAD columns
raw <- raw |>
  mutate(
    prev_sales = lag(sales, 1),
    next_sales = lead(sales, 1)
  )

# ---- 2. Helper: build one frame's tile data --------------------------------

build_frame <- function(data, show_cols, state, state_label, highlight_row = NULL) {
  
  columns <- show_cols
  nr <- nrow(data)
  nc <- length(columns)
  
  # --- Data cells ---
  cells <- list()
  for (r in seq_len(nr)) {
    for (c_idx in seq_len(nc)) {
      col_name <- columns[c_idx]
      val <- as.character(data[[col_name]][r])
      if (is.na(val)) val <- "NULL"
      
      # Determine cell color based on column and state
      fill_color <- "#F5F5F5"
      alpha_val <- 1
      
      if (!is.null(highlight_row) && r == highlight_row) {
        if (col_name == "sales") {
          fill_color <- "#FFE5B4"  # Peach for current row
        } else if (col_name == "prev_sales") {
          fill_color <- "#B4D7FF"  # Light blue for LAG
        } else if (col_name == "next_sales") {
          fill_color <- "#B4FFB4"  # Light green for LEAD
        }
      }
      
      cells[[length(cells) + 1]] <- tibble(
        col_x       = c_idx,
        row_y       = -r,
        label       = val,
        fill        = fill_color,
        alpha       = alpha_val,
        is_header   = FALSE,
        state       = state,
        state_label = state_label
      )
    }
  }
  
  # --- Header cells ---
  for (c_idx in seq_len(nc)) {
    cells[[length(cells) + 1]] <- tibble(
      col_x       = c_idx,
      row_y       = 0,
      label       = columns[c_idx],
      fill        = "#E0E0E0",
      alpha       = 1,
      is_header   = TRUE,
      state       = state,
      state_label = state_label
    )
  }
  
  bind_rows(cells)
}

# ---- 3. Build all frames ----------------------------------------------------

f1 <- build_frame(raw, c("date", "sales"), 1,
                  "1. Original table with date and sales")

f2 <- build_frame(raw, c("date", "sales", "prev_sales"), 2,
                  "2. Add LAG(sales, 1) as prev_sales")

f3 <- build_frame(raw, c("date", "sales", "prev_sales"), 3,
                  "3. LAG() accesses the previous row", highlight_row = 3)

f4 <- build_frame(raw, c("date", "sales", "prev_sales", "next_sales"), 4,
                  "4. Add LEAD(sales, 1) as next_sales")

f5 <- build_frame(raw, c("date", "sales", "prev_sales", "next_sales"), 5,
                  "5. LEAD() accesses the next row", highlight_row = 3)

all_frames <- bind_rows(f1, f2, f3, f4, f5)

# ---- 4. Plot ----------------------------------------------------------------

tw <- 0.94
th <- 0.82

p <- ggplot(all_frames, aes(x = col_x, y = row_y)) +
  geom_tile(
    aes(fill = fill, alpha = alpha),
    width = tw, height = th,
    colour = "white", linewidth = 1.8
  ) +
  geom_text(
    aes(label = label, alpha = alpha),
    size = 5, family = "sans",
    fontface = ifelse(all_frames$is_header, "bold", "plain")
  ) +
  scale_fill_identity() +
  scale_alpha_identity() +
  coord_cartesian(clip = "off") +
  labs(
    title    = "Window Functions: LAG() and LEAD()",
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
  nframes  = 200,
  fps      = 20,
  width    = 900,
  height   = 500,
  res      = 96,
  renderer = magick_renderer()
)

out_path <- "images/lead-lag.gif"
if (!dir.exists("images")) dir.create("images", recursive = TRUE)
anim_save(out_path, animation = anim)
cat("GIF saved to", out_path, "\n")
