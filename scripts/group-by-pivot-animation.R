# ============================================================================
# GROUP BY for Pivoting Animation
# Generates a GIF showing how GROUP BY with CASE WHEN achieves pivoting
# from long to wide format
#
# Style inspired by github.com/gadenbuie/tidyexplain
# ============================================================================

library(ggplot2)
library(gganimate)
library(dplyr)
library(tidyr)

# ---- 1. Build the source "table" -------------------------------------------

raw <- tibble(
  product = c("Widget", "Widget", "Widget", "Gadget", "Gadget", "Gadget"),
  quarter = c("Q1", "Q2", "Q3", "Q1", "Q2", "Q3"),
  sales = c(100, 150, 120, 80, 95, 110)
)

# Result after pivoting
pivoted <- raw |>
  pivot_wider(names_from = quarter, values_from = sales)

# ---- 2. Helper: build one frame's tile data --------------------------------

build_frame <- function(data, columns, state, state_label, 
                       group_colors = NULL, show_groups = FALSE) {
  
  nr <- nrow(data)
  nc <- length(columns)
  
  cells <- list()
  
  # Data cells
  for (r in seq_len(nr)) {
    for (c_idx in seq_len(nc)) {
      col_name <- columns[c_idx]
      val <- as.character(data[[col_name]][r])
      if (is.na(val)) val <- "NULL"
      
      fill_color <- "#F5F5F5"
      
      # Color by product group if requested
      if (show_groups && col_name == "product") {
        product_name <- data$product[r]
        if (!is.null(group_colors) && product_name %in% names(group_colors)) {
          fill_color <- group_colors[product_name]
        }
      }
      
      cells[[length(cells) + 1]] <- tibble(
        col_x       = c_idx,
        row_y       = -r,
        label       = val,
        fill        = fill_color,
        alpha       = 1,
        is_header   = FALSE,
        state       = state,
        state_label = state_label
      )
    }
  }
  
  # Header cells
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

group_colors <- c(
  "Widget" = "#A8CCF0",
  "Gadget" = "#FDCF9E"
)

f1 <- build_frame(raw, c("product", "quarter", "sales"), 1,
                  "1. Original table: long format with product, quarter, sales")

f2 <- build_frame(raw, c("product", "quarter", "sales"), 2,
                  "2. GROUP BY product: group rows by product",
                  group_colors = group_colors, show_groups = TRUE)

f3 <- build_frame(pivoted, c("product", "Q1", "Q2", "Q3"), 3,
                  "3. Pivot result: one row per product,\ncolumns for each quarter")

all_frames <- bind_rows(f1, f2, f3)

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
    title    = "GROUP BY for Pivoting: Long to Wide",
    subtitle = "{closest_state}"
  ) +
  theme_void(base_size = 14) +
  theme(
    plot.title    = element_text(face = "bold", size = 18, hjust = 0.5,
                                 margin = margin(b = 4), family = "sans"),
    plot.subtitle = element_text(size = 12, hjust = 0.5, colour = "#444444",
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

out_path <- "images/group-by-pivot.gif"
if (!dir.exists("images")) dir.create("images", recursive = TRUE)
anim_save(out_path, animation = anim)
cat("GIF saved to", out_path, "\n")
