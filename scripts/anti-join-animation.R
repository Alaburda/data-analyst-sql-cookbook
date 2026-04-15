# ============================================================================
# ANTI JOIN Animation
# Generates a GIF showing how an anti join works:
#   1. Show two tables side by side
#   2. Right table joins the left (LEFT JOIN result with NULLs)
#   3. Highlight the unmatched rows (NULL on the right side)
#   4. Filter to keep only unmatched rows = ANTI JOIN
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
  name        = c("Alice", "Bob", "Carol", "Dave", "Eve")
)

table_b <- tibble(
  customer_id = c(1, 3, 5, 6),
  order_date  = c("2024-01-15", "2024-01-20", "2024-01-25", "2024-01-30")
)

left_joined <- table_a |>
  left_join(table_b, by = "customer_id")

anti_result <- table_a |>
  anti_join(table_b, by = "customer_id")

# Distinct colours for each customer_id (shared across both tables)
id_colors <- c(
  "1" = "#E41A1C",   # red
  "2" = "#377EB8",   # blue
  "3" = "#4DAF4A",   # green
  "4" = "#FF7F00",   # orange
  "5" = "#984EA3",   # purple
  "6" = "#A65628"    # brown
)

# ---- 2. Helper: build one frame's tile data --------------------------------

build_cells <- function(data, columns, offset_x, offset_y,
                        state, state_label,
                        highlight_rows = NULL, fade_rows = NULL,
                        highlight_color = "#B8E6B8",
                        color_id_col = TRUE) {
  nr <- nrow(data)
  nc <- length(columns)
  cells <- list()

  for (r in seq_len(nr)) {
    for (c_idx in seq_len(nc)) {
      col_name <- columns[c_idx]
      val <- as.character(data[[col_name]][r])
      is_null <- is.na(data[[col_name]][r])
      if (is_null) val <- "NULL"

      fill_color <- "#F5F5F5"
      alpha_val  <- 1

      # Color the join-key column by ID
      if (color_id_col && col_name == "customer_id" && !is_null) {
        fill_color <- id_colors[val]
      }

      if (!is.null(highlight_rows) && r %in% highlight_rows) {
        if (!(color_id_col && col_name == "customer_id")) {
          fill_color <- highlight_color
        }
      } else if (is_null) {
        fill_color <- "#E8E8E8"
      }
      if (!is.null(fade_rows) && r %in% fade_rows) {
        alpha_val <- 0.15
      }

      cells[[length(cells) + 1]] <- tibble(
        col_x       = offset_x + c_idx,
        row_y       = offset_y - r,
        label       = val,
        fill        = fill_color,
        alpha       = alpha_val,
        is_header   = FALSE,
        is_title    = FALSE,
        is_id       = (color_id_col && col_name == "customer_id" && !is_null),
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
      is_id       = FALSE,
      state       = state,
      state_label = state_label
    )
  }

  bind_rows(cells)
}

add_title <- function(label, x, y, state, state_label) {
  tibble(
    col_x       = x,
    row_y       = y,
    label       = label,
    fill        = "white",
    alpha       = 1,
    is_header   = FALSE,
    is_title    = TRUE,
    is_id       = FALSE,
    state       = state,
    state_label = state_label
  )
}

# ---- 3. Build all frames ----------------------------------------------------

# --- Frame 1: Two tables side by side ---
s1 <- "1. Two tables: Customers and Orders"
f1 <- bind_rows(
  build_cells(table_a, c("customer_id", "name"),       0, 0, 1, s1),
  build_cells(table_b, c("customer_id", "order_date"), 4, 0, 1, s1),
  add_title("Customers", 1.5, 1.3, 1, s1),
  add_title("Orders",    5.5, 1.3, 1, s1)
)

# --- Frame 2: LEFT JOIN result (right table joined onto left) ---
s2 <- "2. LEFT JOIN orders onto customers"
f2 <- bind_rows(
  build_cells(left_joined, c("customer_id", "name", "order_date"),
              1.5, 0, 2, s2),
  add_title("LEFT JOIN Result", 3.5, 1.3, 2, s2)
)

# --- Frame 3: Highlight unmatched rows, fade matched ---
unmatched <- which(is.na(left_joined$order_date))
matched   <- which(!is.na(left_joined$order_date))

s3 <- "3. Highlight rows with no match (NULL)"
f3 <- bind_rows(
  build_cells(left_joined, c("customer_id", "name", "order_date"),
              1.5, 0, 3, s3,
              highlight_rows = unmatched, fade_rows = matched,
              highlight_color = "#B8E6B8"),
  add_title("WHERE order_date IS NULL", 3.5, 1.3, 3, s3)
)

# --- Frame 4: Anti join result — only unmatched rows ---
s4 <- "4. ANTI JOIN: keep only unmatched rows"
f4 <- bind_rows(
  build_cells(anti_result, c("customer_id", "name"),
              2.5, 0, 4, s4,
              highlight_rows = seq_len(nrow(anti_result)),
              highlight_color = "#B8E6B8"),
  add_title("Anti Join Result", 3.5, 1.3, 4, s4)
)

all_frames <- bind_rows(f1, f2, f3, f4)

# ---- 4. Plot ----------------------------------------------------------------

tw <- 0.94
th <- 0.82

p <- ggplot(all_frames, aes(x = col_x, y = row_y)) +
  geom_tile(
    data = \(d) d[!d$is_title, ],
    aes(fill = fill, alpha = alpha),
    width = tw, height = th,
    colour = "white", linewidth = 1.8
  ) +
  geom_text(
    data = \(d) d[!d$is_title & d$is_header, ],
    aes(label = label, alpha = alpha),
    size = 5, family = "sans", fontface = "bold"
  ) +
  geom_text(
    data = \(d) d[!d$is_title & !d$is_header & d$is_id, ],
    aes(label = label, alpha = alpha),
    size = 5, family = "sans", fontface = "bold", colour = "white"
  ) +
  geom_text(
    data = \(d) d[!d$is_title & !d$is_header & !d$is_id, ],
    aes(label = label, alpha = alpha),
    size = 5, family = "sans", fontface = "plain"
  ) +
  geom_text(
    data = \(d) d[d$is_title, ],
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
    plot.margin     = margin(20, 40, 20, 40),
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

out_path <- "images/anti-join.gif"
if (!dir.exists("images")) dir.create("images", recursive = TRUE)
anim_save(out_path, animation = anim)
cat("GIF saved to", out_path, "\n")
