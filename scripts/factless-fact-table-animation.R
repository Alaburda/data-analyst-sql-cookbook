# ============================================================================
# Factless Fact Table Animation
# Generates a GIF showing how interval rows are exploded to calendar grain
# and then counted over time.
# ============================================================================

library(ggplot2)
library(gganimate)
library(dplyr)
library(tidyr)

# ---- 1. Build the source tables ---------------------------------------------

subscriptions <- tibble(
  subscription_id = c("S1", "S2", "S3"),
  valid_from = c("2024-01-01", "2024-02-01", "2024-03-01"),
  valid_to = c("2024-03-31", "2024-04-30", "2024-05-31")
) |>
  mutate(
    valid_from = as.Date(valid_from),
    valid_to = as.Date(valid_to),
    valid_from_label = format(valid_from, "%Y-%m"),
    valid_to_label = format(valid_to, "%Y-%m")
  )

calendar <- tibble(month_start = seq(as.Date("2024-01-01"), as.Date("2024-05-01"), by = "month")) |>
  mutate(month_label = format(month_start, "%Y-%m"))

exploded <- tidyr::crossing(subscriptions, calendar) |>
  filter(month_start >= valid_from, month_start <= valid_to) |>
  arrange(subscription_id, month_start) |>
  transmute(subscription_id, month_label)

counts <- exploded |>
  count(month_label, name = "active_subscriptions")

bar_data <- counts |>
  mutate(
    month_label = factor(month_label, levels = month_label),
    x = seq_len(n()),
    fill = "#7FB3D5"
  )

subscription_colors <- c(
  "S1" = "#A8DADC",
  "S2" = "#F4A261",
  "S3" = "#CDB4DB"
)

# ---- 2. Helper: build one frame's tile data --------------------------------

build_frame <- function(data, columns, state, state_label,
                        color_subscription = FALSE) {
  nr <- nrow(data)
  nc <- length(columns)
  cells <- list()

  for (r in seq_len(nr)) {
    for (c_idx in seq_len(nc)) {
      col_name <- columns[c_idx]
      value <- as.character(data[[col_name]][r])
      if (is.na(value)) value <- "NULL"

      fill_color <- "#F5F5F5"
      if (color_subscription && "subscription_id" %in% names(data) && col_name == "subscription_id") {
        sub_value <- as.character(data$subscription_id[r])
        if (sub_value %in% names(subscription_colors)) {
          fill_color <- subscription_colors[[sub_value]]
        }
      }

      cells[[length(cells) + 1]] <- tibble(
        col_x = c_idx,
        row_y = -r,
        label = value,
        fill = fill_color,
        alpha = 1,
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

build_bar_frame <- function(data, state, state_label) {
  chart_base_y <- -0.5
  bar_width <- 0.72

  title_row <- tibble(
    col_x = 2.5,
    row_y = 0.9,
    label = "active_subscriptions",
    fill = "white",
    alpha = 1,
    is_header = FALSE,
    is_title = TRUE,
    state = state,
    state_label = state_label
  )

  axis_labels <- tibble(
    col_x = data$x,
    row_y = chart_base_y - 0.35,
    label = as.character(data$month_label),
    fill = "white",
    alpha = 1,
    is_header = FALSE,
    is_title = TRUE,
    state = state,
    state_label = state_label
  )

  bar_rects <- tibble(
    xmin = data$x - bar_width / 2,
    xmax = data$x + bar_width / 2,
    ymin = chart_base_y,
    ymax = chart_base_y + data$active_subscriptions,
    fill = data$fill,
    alpha = 1,
    state = state,
    state_label = state_label
  )

  bar_labels <- tibble(
    col_x = data$x,
    row_y = chart_base_y + data$active_subscriptions + 0.25,
    label = as.character(data$active_subscriptions),
    fill = "white",
    alpha = 1,
    is_header = FALSE,
    is_title = TRUE,
    state = state,
    state_label = state_label
  )

  baseline <- tibble(
    x = 0.45,
    xend = max(data$x) + 0.55,
    y = chart_base_y,
    yend = chart_base_y,
    state = state,
    state_label = state_label
  )

  list(
    titles = bind_rows(title_row, axis_labels, bar_labels),
    bars = bar_rects,
    baseline = baseline
  )
}

# ---- 3. Build all frames ----------------------------------------------------

f1 <- build_frame(
  subscriptions |>
    select(subscription_id, valid_from_label, valid_to_label),
  c("subscription_id", "valid_from_label", "valid_to_label"),
  1,
  "1. Start with interval rows: one row per subscription",
  color_subscription = TRUE
)

f2 <- build_frame(
  calendar,
  c("month_label"),
  2,
  "2. Build a calendar table with one row per reporting month"
)

f3 <- build_frame(
  exploded,
  c("subscription_id", "month_label"),
  3,
  "3. Join the SCD2 table to the calendar to explode interval rows",
  color_subscription = TRUE
)

f4 <- build_bar_frame(
  bar_data,
  4,
  "4. Aggregate the exploded rows: now you can just count"
)

table_frames <- bind_rows(f1, f2, f3)

# ---- 4. Plot ----------------------------------------------------------------

tw <- 0.94
th <- 0.82

p <- ggplot() +
  geom_tile(
    data = table_frames,
    aes(x = col_x, y = row_y, fill = fill, alpha = alpha),
    width = tw,
    height = th,
    colour = "white",
    linewidth = 1.8
  ) +
  geom_text(
    data = table_frames,
    aes(x = col_x, y = row_y, label = label, alpha = alpha),
    size = 4.8,
    family = "sans",
    fontface = ifelse(table_frames$is_header, "bold", "plain")
  ) +
  geom_rect(
    data = f4$bars,
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill, alpha = alpha),
    colour = "white",
    linewidth = 1.2
  ) +
  geom_segment(
    data = f4$baseline,
    aes(x = x, xend = xend, y = y, yend = yend),
    linewidth = 1,
    colour = "#666666"
  ) +
  geom_text(
    data = f4$titles,
    aes(x = col_x, y = row_y, label = label, alpha = alpha),
    size = 4.6,
    family = "sans",
    fontface = "plain"
  ) +
  scale_fill_identity() +
  scale_alpha_identity() +
  coord_cartesian(clip = "off") +
  labs(
    title = "Factless Fact Table: Explode then count",
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
  nframes = 140,
  fps = 20,
  width = 1050,
  height = 540,
  res = 96,
  renderer = magick_renderer()
)

out_path <- "images/factless-fact-table.gif"
if (!dir.exists("images")) dir.create("images", recursive = TRUE)
anim_save(out_path, animation = anim)
cat("GIF saved to", out_path, "\n")