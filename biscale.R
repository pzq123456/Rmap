# 设置工作空间
setwd("F:/pzq/Rmap")

# 加载所需的包
library(sf)         # 用于处理空间数据
library(ggplot2)    # 用于绘图
library(biscale)    # 用于双变量分析
library(cowplot)    # 用于组合图和图例
library(dplyr)      # 用于数据处理

# 读取数据
data <- read.csv("data/normalized.csv")

# 读取苏格兰边界数据
boundary <- st_read("data/Scotland_boundary/Scotland_boundary.shp")

# 查看数据
head(data)

# 确保数据格式正确
data <- data %>%
  mutate(
    X = as.numeric(X),
    Y = as.numeric(Y),
    population = as.numeric(population),
    EVCharingCount = as.numeric(EVCharingCount)
  )

# library(dplyr)

# # 将经纬度坐标转换为新的分辨率
# data <- data %>%
#   mutate(
#     X_new = floor(X / 0.05) * 0.05 + 0.025,  # 将经度转换为0.05分辨率的中心点
#     Y_new = floor(Y / 0.05) * 0.05 + 0.025   # 将纬度转换为0.05分辨率的中心点
#   )

# # 按新的经纬度坐标进行分组，并累加population和EVCharingCount
# data_aggregated <- data %>%
#   group_by(X_new, Y_new) %>%
#   summarise(
#     population = sum(population, na.rm = TRUE),
#     EVCharingCount = sum(EVCharingCount, na.rm = TRUE)
#   ) %>%
#   ungroup()

# set.seed(123)  # 设置随机种子以确保可重复性
# data <- data %>%
#   mutate(
#     EVCharingCount = EVCharingCount + runif(n(), -0.0000001, 0.0000001)  # 添加微小噪声
#   )

# 手动定义分段区间
breaks_x <- c(0.027, 0.094, 0.182, 0.379, 1) # population
breaks_y <- c(0.011, 0.043, 0.095, 0.224, 1) # EVCharingCount
# 使用 cut 函数手动分段
data <- data %>%
  mutate(
    population_cut = cut(population, breaks = breaks_x, include.lowest = FALSE, labels = c("Low", "Medium", "High", "Very High")),
    eEVCharingCount_cut = cut(EVCharingCount, breaks = breaks_y, include.lowest = FALSE, labels = c("Low", "Medium", "High", "Very High"))
  )

# # 使用手动分段结果进行双变量分析
data <- bi_class(data, x = eEVCharingCount_cut, y = population_cut, dim = 4)

# data <- bi_class(data, x = EVCharingCount, y = population, style = "quantile", dim = 4)

# data <- bi_class(data, x = Z, y = evse_count, dim = 4)


# 查看分类结果
head(data)

# 设置双变量颜色调色板
pallet <- "BlueOr"

# 创建双变量地图
map <- ggplot() +
  theme_void(base_size = 14) +  # 设置简洁的主题
  xlim(min(data$X), max(data$X)) +  # 设置 X 轴范围
  ylim(min(data$Y), max(data$Y)) +  # 设置 Y 轴范围
  geom_raster(data = data, mapping = aes(x = X, y = Y, fill = bi_class), color = NA, linewidth = 0.1, show.legend = FALSE) +
  bi_scale_fill(pal = pallet, dim = 4, flip_axes = FALSE, rotate_pal = FALSE) +  # 应用双变量颜色
  geom_sf(data = boundary, fill = NA, color = "gray", linewidth = 0.1) +  # 添加苏格兰边界
  labs(title = "Bi-variate Map of population and EVCharingCount") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5),
        plot.caption = element_text(size = 10, face = "bold", hjust = 1))

# 创建图例
legend <- bi_legend(pal = pallet,
                    flip_axes = FALSE,
                    rotate_pal = FALSE,
                    dim = 4,
                    xlab = "EVCharingCount",
                    ylab = "population",
                    size = 10)

# 组合地图和图例
finalPlot <- ggdraw() +
  draw_plot(map, 0, 0, 1, 1) +  # 绘制主图
  # draw_plot(legend, 0.05, 0.05, 0.28, 0.28)  # 绘制图例
  # 在左上角绘制图例
  draw_plot(legend, 0.05, 0.55, 0.28, 0.28)


# 显示最终图
print(finalPlot)

# 保存地图
ggsave("bivariate_map.png", finalPlot, dpi = 400, width = 7, height = 7)