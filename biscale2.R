# 设置工作空间
setwd("F:/pzq/Rmap")

# 加载所需的包
library(sf)         # 用于处理空间数据
library(ggplot2)    # 用于绘图
library(dplyr)      # 用于数据处理
library(cowplot)    # 用于组合图和图例

# 读取数据
data <- read.csv("data/normalized.csv")

# 读取苏格兰边界数据
boundary <- st_read("data/Scotland_boundary/Scotland_boundary.shp")

# 确保数据格式正确
data <- data %>%
  mutate(
    X = as.numeric(X),
    Y = as.numeric(Y),
    Z = as.numeric(Z),
    evse_count = as.numeric(evse_count)
  )

# 创建底图：人口分布密度图
base_map <- ggplot() +
  theme_void(base_size = 14) +  # 设置简洁的主题
  xlim(min(data$X), max(data$X)) +  # 设置 X 轴范围
  ylim(min(data$Y), max(data$Y)) +  # 设置 Y 轴范围
  geom_raster(data = data, mapping = aes(x = X, y = Y, fill = Z), color = NA, linewidth = 0.1) +
  scale_fill_gradient(low = "white", high = "blue", name = "Population Density") +  # 设置人口密度颜色
  geom_sf(data = boundary, fill = NA, color = "gray", linewidth = 0.1) +  # 添加苏格兰边界
  labs(title = "Population Density and EVSE Count",
       subtitle = "Population Density (X) with EVSE Count Overlay",
       caption = "Data Source: masked.csv") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5),
        plot.caption = element_text(size = 10, face = "bold", hjust = 1))


# 保存地图
ggsave("population_evse_map.png", base_map, dpi = 500, width = 7, height = 7)