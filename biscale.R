# 设置工作空间
setwd("F:/pzq/Rmap")

# 加载所需的包
library(sf)         # 用于处理空间数据
library(ggplot2)    # 用于绘图
library(biscale)    # 用于双变量分析
library(cowplot)    # 用于组合图和图例
library(dplyr)      # 用于数据处理

# 读取数据
data <- read.csv("data/masked.csv")

# 读取苏格兰边界数据
boundary <- st_read("data/Scotland_boundary/Scotland_boundary.shp")

# 查看数据
head(data)

# 确保数据格式正确
data <- data %>%
  mutate(
    X = as.numeric(X),
    Y = as.numeric(Y),
    Z = as.numeric(Z),
    evse_count = as.numeric(evse_count)
  )

# 检查重复值
sum(duplicated(data$Z))  # 检查 Z 列的重复值
sum(duplicated(data$evse_count))  # 检查 evse_count 列的重复值

# 如果数据中有大量重复值，可以添加少量随机噪声
set.seed(123)  # 设置随机种子以确保可重复性
data <- data %>%
  mutate(
    Z = Z + runif(n(), -0.0001, 0.0001),  # 对 Z 列添加随机噪声
    evse_count = evse_count + runif(n(), -0.0001, 0.0001)  # 对 evse_count 列添加随机噪声
  )

# 双变量分类
# 使用 Fisher 自然间断点分类
data <- bi_class(data, x = Z, y = evse_count, style = "fisher", dim = 4)

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
  geom_sf(data = boundary, fill = NA, color = "black", linewidth = 0.5) +  # 添加苏格兰边界
  labs(title = "双变量地图: Z 和 evse_count",
       subtitle = "基于 Z 和 evse_count 的双变量分析",
       caption = "数据来源: masked.csv") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5),
        plot.caption = element_text(size = 10, face = "bold", hjust = 1))

# 创建图例
legend <- bi_legend(pal = pallet,
                    flip_axes = FALSE,
                    rotate_pal = FALSE,
                    dim = 4,
                    xlab = "Z",
                    ylab = "evse_count",
                    size = 10)

# 组合地图和图例
finalPlot <- ggdraw() +
  draw_plot(map, 0, 0, 1, 1) +  # 绘制主图
  # draw_plot(legend, 0.05, 0.05, 0.28, 0.28)  # 绘制图例
  # 在左上角绘制图例
  draw_plot(legend, 0.05, 0.75, 0.28, 0.28)


# 显示最终图
print(finalPlot)

# 保存地图
ggsave("bivariate_map.png", finalPlot, dpi = 400, width = 7, height = 7)