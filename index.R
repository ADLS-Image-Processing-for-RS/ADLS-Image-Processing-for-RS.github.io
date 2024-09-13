
library(readr)

library(dplyr)
library(ggplot2)
library(ggrepel)
library(forcats)
library(stringr)
library(scales)
# timings <- read_csv("https://raw.githubusercontent.com/kadyb/raster-benchmark/main/timings.csv")
# write_csv(timings, "timings.csv")

data(wind, package = "gstat")
data(Produc, package = "plm")

write_csv(wind, "data/wind.csv")
write_csv(Produc, "data/Produc.csv")

timings <- read_csv("timings.csv")


timings |> 
  group_by(task) |> 
  arrange(task) |> 
  mutate(
    min = min(median),
    fac = median/min,
    rank = rank(fac),
    # package = str_replace(package, "-", "\n"),
    # package = str_replace(package, "exactextractr","ee")
  ) |> 
  # mutate(label = package == "terra" | rank <= Inf) |> 
  ungroup() |> 
  mutate(task = (fct_reorder(task, fac, max))) |> 
  ggplot(aes(task, fac)) +
  geom_point() +
  geom_line() +
  geom_text_repel(
    # data = \(x) filter(x, label), 
    aes(label = package), 
    hjust = 0, 
    # ylim = c(1,NA),
    # angle = 90, 
    direction = "y",
    # nudge_y = .2, 
    nudge_x = .1, 
    min.segment.length = 0, 
    force_pull = 0,
  ) +
  scale_y_continuous(
    trans  = compose_trans("log10", "reverse"),
    # breaks = seq(0, 300, 50)
    # labels = label_log(),
    labels = \(x)paste0(x,"×")
  ) +
  # annotation_logticks(sides = 'lr') +
  facet_wrap(~task, scales = "free_x", nrow = 1) +
  # theme_minimal() +
  theme(
    axis.title = element_blank(), 
    panel.grid.major.x = element_blank(),
    # panel.background = element_blank()
  ) 


