# # 设置工作目录
# setwd("/Users/panzhiqing/Desktop/Rmap/")

# library(rayshader)
# library(ggplot2)
# library(sf)
# library(dplyr)
# library(raster)
# library(stars)

# # 加载充电桩位置数据和国家边界
# charger_data <- read.csv("data/us.csv")

# country_boundary <- st_read("data/GeoJSON/us.geojson")

# # 将充电桩数据转换为 sf 对象
# charger_data_sf <- st_as_sf(charger_data, coords = c("lon", "lat"), crs = st_crs(country_boundary))

# # 创建密度栅格
# # 定义栅格分辨率
# grid_resolution <- 0.1  # 单位为经纬度
# bounding_box <- st_bbox(country_boundary)  # 提取边界框

# # 创建空栅格
# empty_raster <- raster(
#   xmn = bounding_box["xmin"], xmx = bounding_box["xmax"],
#   ymn = bounding_box["ymin"], ymx = bounding_box["ymax"],
#   res = grid_resolution, crs = st_crs(country_boundary)$proj4string
# )

# # 将充电桩数据栅格化（计算密度）
# charger_density <- rasterize(
#   x = st_coordinates(charger_data_sf),
#   y = empty_raster,
#   fun = function(x, ...) length(x),  # 计算点密度
#   background = 0
# )

# # 裁剪栅格到国家边界
# charger_density <- mask(charger_density, as(country_boundary, "Spatial"))

# # 将栅格转换为矩阵
# density_matrix <- as.matrix(charger_density)

# # 转置矩阵（适配 rayshader）
# density_matrix <- t(density_matrix)

# # 自定义调色板
# texture <- grDevices::colorRampPalette(c( "#ffffff", "#9ecae1", "#6baed6", "#4292c6", "#2171b5", "#08519c", "#08306b"))(256)

# # 渲染3D密度图
# density_matrix %>%
#   height_shade(texture = texture) %>%
#   add_shadow(ray_shade(density_matrix, sunaltitude = 45, sunangle = 100, zscale = 5), max_darken = 0.7) %>%
#   plot_3d(heightmap = density_matrix,
#             zscale = 3,
#             solid = FALSE,
#             shadow = FALSE,
#             windowsize = c(1200, 1000), 
#             phi = 60, 
#             zoom = 0.7, 
#             theta = 360, 
#             background = "white") 

# # 保存渲染图像
# render_snapshot("us.png")


# 设置工作目录
setwd("/Users/panzhiqing/Desktop/Rmap/")

# 加载必要的库
library(ggplot2)
library(sf)
library(raster)
library(rayshader)

# 加载国家边界数据
country_boundary <- st_read("data/GeoJSON/us.geojson")

# 加载并处理充电桩数据
charger_data <- read.csv("data/us.csv")
charger_data_sf <- st_as_sf(charger_data, coords = c("lon", "lat"), crs = st_crs(country_boundary))

# 创建密度栅格
grid_resolution <- 0.1  # 单位为经纬度
bounding_box <- st_bbox(country_boundary)

empty_raster <- raster(
  xmn = bounding_box["xmin"], xmx = bounding_box["xmax"],
  ymn = bounding_box["ymin"], ymx = bounding_box["ymax"],
  res = grid_resolution, crs = st_crs(country_boundary)$proj4string
)

charger_density <- rasterize(
  x = st_coordinates(charger_data_sf),
  y = empty_raster,
  fun = function(x, ...) length(x),
  background = 0
)

charger_density <- mask(charger_density, as(country_boundary, "Spatial"))

# 转换栅格为矩阵
density_matrix <- as.matrix(charger_density)
density_matrix <- t(density_matrix)  # 转置以适配 rayshader

# 创建 ggplot 图
density_df <- as.data.frame(charger_density, xy = TRUE, na.rm = TRUE)
colnames(density_df) <- c("x", "y", "density")

density_plot <- ggplot() +
  # 绘制密度图
  geom_raster(data = density_df, aes(x = x, y = y, fill = density)) +
  scale_fill_gradientn(
    colors = c("#ffffff", "#4292c6", "#2171b5", "#08519c", "#08306b"),
    name = "Density"
  ) +
  # 绘制省级边界
  geom_sf(data = country_boundary, color = "grey80", size = 0.2, fill = NA)

# 渲染三维图
plot_gg(
  density_plot,
  width = 6, height = 6,
  scale = 250,  # 缩放比例
  multicore = TRUE,
  windowsize = c(800, 800),
  zoom = 0.75,
  phi = 40,
  theta = 30
)

# 保存三维渲染的快照
render_snapshot("output/us_density_map_3D.png")
