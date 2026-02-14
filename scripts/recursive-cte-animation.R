# ============================================================================
# Recursive CTE Animation
# Generates a GIF showing how a recursive CTE works to traverse
# hierarchical data (e.g., organizational hierarchy)
#
# Style inspired by github.com/gadenbuie/tidyexplain
# ============================================================================

library(ggplot2)
library(gganimate)
library(dplyr)
library(tidyr)

# ---- 1. Build the source "table" -------------------------------------------

# Employee hierarchy
employees <- tibble(
  emp_id = c(1, 2, 3, 4, 5),
  name = c("CEO", "VP Sales", "VP Eng", "Manager", "Dev"),
  manager_id = c(NA, 1, 1, 2, 4)
)

# Build recursive result manually for animation
level_0 <- employees |> filter(is.na(manager_id)) |> mutate(level = 0)
level_1 <- employees |> filter(manager_id == 1) |> mutate(level = 1)
level_2 <- employees |> filter(manager_id == 2) |> mutate(level = 2)
level_3 <- employees |> filter(manager_id == 4) |> mutate(level = 3)

# ---- 2. Helper: build one frame's tile data --------------------------------

build_frame <- function(data, columns, state, state_label, 
                       highlight_rows = NULL, color_by_level = FALSE) {
  
  nr <- nrow(data)
  nc <- length(columns)
  
  level_colors <- c(
    "0" = "#FFE5B4",  # CEO - peach
    "1" = "#B4D7FF",  # VPs - light blue
    "2" = "#FFD4B4",  # Managers - light orange
    "3" = "#B4FFB4"   # Individual contributors - light green
  )
  
  cells <- list()
  
  # Data cells
  for (r in seq_len(nr)) {
    for (c_idx in seq_len(nc)) {
      col_name <- columns[c_idx]
      val <- data[[col_name]][r]
      if (is.na(val)) {
        val <- "NULL"
      } else {
        val <- as.character(val)
      }
      
      fill_color <- "#F5F5F5"
      alpha_val <- 1
      
      # Color by level if requested
      if (color_by_level && "level" %in% names(data)) {
        level_val <- as.character(data$level[r])
        if (level_val %in% names(level_colors)) {
          fill_color <- level_colors[level_val]
        }
      }
      
      if (!is.null(highlight_rows) && r %in% highlight_rows) {
        alpha_val <- 1
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

f1 <- build_frame(employees, c("emp_id", "name", "manager_id"), 1,
                  "1. Employee table with manager_id (self-reference)")

f2 <- build_frame(level_0, c("emp_id", "name", "manager_id", "level"), 2,
                  "2. Anchor: Find root (CEO, manager_id IS NULL)",
                  color_by_level = TRUE)

f3 <- build_frame(bind_rows(level_0, level_1), 
                  c("emp_id", "name", "manager_id", "level"), 3,
                  "3. Recursion 1: Find employees reporting to CEO",
                  color_by_level = TRUE)

f4 <- build_frame(bind_rows(level_0, level_1, level_2), 
                  c("emp_id", "name", "manager_id", "level"), 4,
                  "4. Recursion 2: Find employees reporting to VPs",
                  color_by_level = TRUE)

f5 <- build_frame(bind_rows(level_0, level_1, level_2, level_3), 
                  c("emp_id", "name", "manager_id", "level"), 5,
                  "5. Recursion 3: Find employees at next level",
                  color_by_level = TRUE)

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
    title    = "Recursive CTE: Traversing hierarchies",
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
  nframes  = 200,
  fps      = 20,
  width    = 900,
  height   = 600,
  res      = 96,
  renderer = magick_renderer()
)

out_path <- "images/recursive-cte.gif"
if (!dir.exists("images")) dir.create("images", recursive = TRUE)
anim_save(out_path, animation = anim)
cat("GIF saved to", out_path, "\n")
