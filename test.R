# 设置工作目录
setwd("/Users/panzhiqing/Desktop/Rmap/")

library(rayshader)
library(ggplot2)
library(sf)
library(dplyr)
library(raster)

# 加载充电桩位置数据和国家边界
charger_data <- read.csv("data/cn.csv")
country_boundary <- st_read("data/GeoJSON/cn.geojson")

# 创建密度图
density_plot <- ggplot() +
  geom_density_2d_filled(data = charger_data, aes(x = lon, y = lat), contour_var = "density", alpha = 0.8) +
  geom_sf(data = country_boundary, fill = NA, color = "black", size = 0.2) +
  coord_sf() +
  theme_void()

# 保存密度图为栅格图像
ggsave("charger_density.png", density_plot, width = 8, height = 6, dpi = 300)

# 加载栅格图像
density_raster <- raster("charger_density.png")
density_matrix <- as.matrix(density_raster)

# 转置矩阵（适配rayshader）
density_matrix <- t(density_matrix)

# 自定义调色板
texture <- grDevices::colorRampPalette(c("#f4f1de", "#ffea00", "#F39C12", "#bc6c25", "#78290f", "#780000"))(256)

# 渲染3D密度图
density_matrix %>%
  height_shade(texture = texture) %>%
  add_shadow(ray_shade(density_matrix, sunaltitude = 20, sunangle = 220, zscale = 10), max_darken = 0.5) %>%
  plot_3d(heightmap = density_matrix,
          zscale = 10,
          solid = TRUE,
          solidcolor = "#d4d4d4",
          windowsize = c(1200, 1000),
          phi = 45,
          theta = 120,
          zoom = 0.75,
          background = "white")

# 保存渲染图像
render_snapshot("charger_density_3d.png")
