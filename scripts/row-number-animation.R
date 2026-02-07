# ============================================================================
# ROW_NUMBER() + Filter Animation
# Generates a GIF showing how ROW_NUMBER() partitions data and how
# filtering on rn = 1 keeps only the first row per group.
#
# Style inspired by github.com/gadenbuie/tidyexplain
# ============================================================================

library(ggplot2)
library(gganimate)
library(dplyr)
library(tidyr)

# ---- 1. Build the source "table" -------------------------------------------

raw <- tibble(
  customer = c("Alice", "Alice", "Alice", "Bob", "Bob", "Carol", "Carol", "Carol", "Carol"),
  product  = c("Widget", "Gadget", "Gizmo", "Widget", "Gadget", "Gizmo", "Widget", "Gadget", "Gizmo"),
  amount   = c(120, 85, 200, 55, 340, 90, 150, 75, 410)
)

# Add ROW_NUMBER() PARTITION BY customer ORDER BY amount DESC
raw <- raw |>
  group_by(customer) |>
  mutate(rn = row_number(desc(amount))) |>
  ungroup() |>
  arrange(customer, rn)

# Group colours (one per customer)
fill_colours <- c(
  "Alice" = "#A8CCF0",
  "Bob"   = "#FDCF9E",
  "Carol" = "#A8DDA0"
)

# ---- 2. Helper: build one frame's tile data --------------------------------
# Each cell = one row in the plotting data with (col_x, row_y, label, fill, alpha)

build_frame <- function(data, show_rn, state, state_label) {

  columns <- c("customer", "product", "amount")
  if (show_rn) columns <- c(columns, "rn")

  # In state 4 keep only rn == 1 rows
  if (state == 4) {
    data <- data |> filter(rn == 1)
  }

  nr <- nrow(data)
  nc <- length(columns)

  # --- Data cells ---
  cells <- list()
  for (r in seq_len(nr)) {
    for (c_idx in seq_len(nc)) {
      col_name <- columns[c_idx]
      val <- as.character(data[[col_name]][r])
      cust <- data$customer[r]
      rn_val <- data$rn[r]

      a <- 1
      if (state == 3 && rn_val != 1) a <- 0.15

      cells[[length(cells) + 1]] <- tibble(
        col_x       = c_idx,
        row_y       = -r,
        label       = val,
        fill        = fill_colours[cust],
        alpha       = a,
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

# ---- 3. Build all four frames -----------------------------------------------

f1 <- build_frame(raw, show_rn = FALSE, state = 1,
                   state_label = "1. Original table")
f2 <- build_frame(raw, show_rn = TRUE,  state = 2,
                   state_label = "2. Add ROW_NUMBER() OVER(\n    PARTITION BY customer ORDER BY amount DESC)")
f3 <- build_frame(raw, show_rn = TRUE,  state = 3,
                   state_label = "3. WHERE rn = 1")
f4 <- build_frame(raw, show_rn = TRUE,  state = 4,
                   state_label = "4. Result: one row per customer")

all_frames <- bind_rows(f1, f2, f3, f4)

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
    title    = "Keeping one row per group with ROW_NUMBER()",
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
  nframes  = 160,
  fps      = 15,
  width    = 900,
  height   = 600,
  res      = 96,
  renderer = gifski_renderer()
)

out_path <- "images/row-number-filter.gif"
if (!dir.exists("images")) dir.create("images", recursive = TRUE)
anim_save(out_path, animation = anim)
cat("GIF saved to", out_path, "\n")
