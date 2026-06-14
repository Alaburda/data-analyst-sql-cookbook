# ============================================================================
# Consecutive Rows / Islands Animation
# Generates a GIF showing how two row numbers create a stable difference
# that identifies islands of consecutive rows.
# ============================================================================

library(ggplot2)
library(gganimate)
library(dplyr)
library(tidyr)

# ---- 1. Build the source table ---------------------------------------------

subscriptions <- tibble(
  user_id = c("Alice", "Alice", "Alice", "Alice", "Bob", "Bob", "Bob"),
  date_from = c("2024-01-01", "2024-02-01", "2024-03-01", "2024-05-01", "2024-01-01", "2024-02-01", "2024-03-01"),
  tier = c("Basic", "Basic", "Premium", "Premium", "Basic", "Basic", "Basic")
) |>
  mutate(
    date_from = as.Date(date_from),
    month_label = format(date_from, "%Y-%m")
  )

ranked <- subscriptions |>
  group_by(user_id) |>
  arrange(date_from, .by_group = TRUE) |>
  mutate(user_rank = row_number()) |>
  ungroup() |>
  group_by(user_id, tier) |>
  arrange(date_from, .by_group = TRUE) |>
  mutate(tier_rank = row_number()) |>
  ungroup() |>
  mutate(island_id = user_rank - tier_rank)

grouped <- ranked |>
  group_by(user_id, tier, island_id) |>
  summarise(
    start_month = min(month_label),
    end_month = max(month_label),
    rows_in_island = n(),
    .groups = "drop"
  )

island_colors <- c(
  "0" = "#B8E0D2",
  "1" = "#F7D08A",
  "2" = "#D6C3F0"
)

# ---- 2. Helper: build one frame's tile data --------------------------------

build_frame <- function(data, columns, state, state_label,
                        color_islands = FALSE, fade_rows = NULL) {
  nr <- nrow(data)
  nc <- length(columns)
  cells <- list()

  for (r in seq_len(nr)) {
    for (c_idx in seq_len(nc)) {
      col_name <- columns[c_idx]
      value <- as.character(data[[col_name]][r])
      if (is.na(value)) value <- "NULL"

      fill_color <- "#F5F5F5"
      alpha_val <- 1

      if (color_islands && "island_id" %in% names(data)) {
        island_value <- as.character(data$island_id[r])
        if (island_value %in% names(island_colors)) {
          fill_color <- island_colors[[island_value]]
        }
      }

      if (!is.null(fade_rows) && r %in% fade_rows) {
        alpha_val <- 0.22
      }

      cells[[length(cells) + 1]] <- tibble(
        col_x = c_idx,
        row_y = -r,
        label = value,
        fill = fill_color,
        alpha = alpha_val,
        is_header = FALSE,
        state = state,
        state_label = state_label
      )
    }
  }

  for (c_idx in seq_len(nc)) {
    cells[[length(cells) + 1]] <- tibble(
      col_x = c_idx,
      row_y = 0,
      label = columns[c_idx],
      fill = "#E0E0E0",
      alpha = 1,
      is_header = TRUE,
      state = state,
      state_label = state_label
    )
  }

  bind_rows(cells)
}

# ---- 3. Build all frames ----------------------------------------------------

f1 <- build_frame(
  ranked,
  c("user_id", "month_label", "tier"),
  1,
  "1. Start with ordered rows for each user"
)

f2 <- build_frame(
  ranked,
  c("user_id", "month_label", "tier", "user_rank"),
  2,
  "2. ROW_NUMBER() over each user keeps counting forward"
)

f3 <- build_frame(
  ranked,
  c("user_id", "month_label", "tier", "user_rank", "tier_rank"),
  3,
  "3. A second ROW_NUMBER() resets inside each user + tier partition"
)

f4 <- build_frame(
  ranked,
  c("user_id", "month_label", "tier", "user_rank", "tier_rank", "island_id"),
  4,
  "4. The difference stays constant inside each island",
  color_islands = TRUE
)

f5 <- build_frame(
  grouped,
  c("user_id", "tier", "island_id", "start_month", "end_month", "rows_in_island"),
  5,
  "5. Group by the stable difference to collapse each island"
)

all_frames <- bind_rows(f1, f2, f3, f4, f5)

# ---- 4. Plot ----------------------------------------------------------------

tw <- 0.94
th <- 0.82

p <- ggplot(all_frames, aes(x = col_x, y = row_y)) +
  geom_tile(
    aes(fill = fill, alpha = alpha),
    width = tw,
    height = th,
    colour = "white",
    linewidth = 1.8
  ) +
  geom_text(
    aes(label = label, alpha = alpha),
    size = 4.4,
    family = "sans",
    fontface = ifelse(all_frames$is_header, "bold", "plain")
  ) +
  scale_fill_identity() +
  scale_alpha_identity() +
  coord_cartesian(clip = "off") +
  labs(
    title = "Islands: Grouping consecutive rows",
    subtitle = "{closest_state}"
  ) +
  theme_void(base_size = 14) +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 18,
      hjust = 0.5,
      margin = margin(b = 4),
      family = "sans"
    ),
    plot.subtitle = element_text(
      size = 12,
      hjust = 0.5,
      colour = "#444444",
      margin = margin(b = 10),
      lineheight = 1.15,
      family = "mono"
    ),
    plot.margin = margin(20, 40, 20, 40),
    plot.background = element_rect(fill = "white", colour = NA)
  ) +
  transition_states(state_label, transition_length = 2, state_length = 5, wrap = FALSE) +
  enter_fade() +
  exit_fade() +
  ease_aes("cubic-in-out")

# ---- 5. Render --------------------------------------------------------------

anim <- animate(
  p,
  nframes = 160,
  fps = 20,
  width = 1100,
  height = 560,
  res = 96,
  renderer = magick_renderer()
)

out_path <- "images/consecutive-rows.gif"
if (!dir.exists("images")) dir.create("images", recursive = TRUE)
anim_save(out_path, animation = anim)
cat("GIF saved to", out_path, "\n")