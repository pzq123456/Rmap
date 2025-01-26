# 设置工作空间
setwd("F:/pzq/Rmap")

# 加载所需的包
library(sf)         # 用于处理空间数据
library(ggplot2)    # 用于绘图
library(biscale)    # 用于双变量分析
library(cowplot)    # 用于组合图和图例
library(dplyr)      # 用于数据处理

# 读取数据
data <- read.csv("data/resampled.csv")

# 读取苏格兰边界数据
boundary <- st_read("data/Scotland_boundary/Scotland_boundary.shp")

# 查看数据
# head(data)

# 确保数据格式正确
data <- data %>%
  mutate(
    X = as.numeric(X),
    Y = as.numeric(Y),
    population = as.numeric(population),
    EVCharingCount = as.numeric(EVCharingCount)
  )


breaks_x <- c(0, 2, 12, 500, 7638) # population
breaks_y <- c(0, 28, 88, 250, 5440) # EVCharingCount


# 使用 cut 函数手动分段
data <- data %>%
  mutate(
    population_cut = cut(population, breaks = breaks_x, include.lowest = TRUE, labels = c("25%", "50%", "75%", "100%")),
    EVCharingCount_cut = cut(EVCharingCount, breaks = breaks_y, include.lowest = TRUE, labels = c("25%", "50%", "75%", "100%"))
  )

# 使用手动分段结果进行双变量分析
data <- bi_class(data, x = EVCharingCount_cut, y = population_cut, dim = 4)


# 设置双变量颜色调色板
pallet <- "BlueOr"


# 提取需要高亮的多边形
highlight_boundary <- boundary %>%
  filter(NAME_2 %in% c("City of Edinburgh", "Glasgow City", "Highland"))

# 提取不需要高亮的多边形
non_highlight_boundary <- boundary %>%
  filter(!NAME_2 %in% c("City of Edinburgh", "Glasgow City", "Highland"))


# 创建双变量地图
map <- ggplot() +
  theme_void(base_size = 14) +  # 设置简洁的主题
  xlim(min(data$X), max(data$X)) +  # 设置 X 轴范围
  ylim(min(data$Y), max(data$Y)) +  # 设置 Y 轴范围

  # geom_raster(data = data, mapping = aes(x = X, y = Y, fill = bi_class), color = "white", linewidth = 0.5, show.legend = FALSE) +  # 绘制栅格数据并添加白色边框线
  # bi_scale_fill(pal = pallet, dim = 4, flip_axes = FALSE, rotate_pal = FALSE) +  # 应用双变量颜色

  geom_tile(data = data, mapping = aes(x = X, y = Y, fill = bi_class), color = "white", linewidth = 0.1, show.legend = FALSE) +  # 使用 geom_tile 绘制栅格数据并添加白色边框线
  bi_scale_fill(pal = pallet, dim = 4, flip_axes = FALSE, rotate_pal = FALSE) +  # 应用双变量颜色

  geom_sf(data = non_highlight_boundary, color = "black", fill = NA, linewidth = 0.2) +  # 绘制非高亮的多边形
  geom_sf(data = highlight_boundary, color = "#ff007f", fill = NA, linewidth = 0.2) +  # 绘制高亮的多边形

  labs(title = "Bi-variate Map of population and EVCharingCount") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5),
        plot.caption = element_text(size = 10, face = "bold", hjust = 1))

# 创建图例
legend <- bi_legend(pal = pallet,
                    flip_axes = FALSE,
                    rotate_pal = FALSE,
                    dim = 4,
                    xlab = "EVCP count",
                    ylab = "population count",
                    size = 10)

# 组合地图和图例
finalPlot <- ggdraw() +
  draw_plot(map, 0, 0, 1, 1) +  # 绘制主图
  draw_plot(legend, 0.05, 0.55, 0.28, 0.28)  # 在左上角绘制图例

# 找到颜色为 #7F7F7F 的位置 并将值打印出来
# print(which(finalPlot$labels$fill == "#7F7F7F"))

# 显示最终图
print(finalPlot)

# 保存地图为 SVG 格式
ggsave("bivariate_map.svg", finalPlot, width = 7, height = 7)
