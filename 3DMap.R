library(rayshader)
library(ggplot2)
library(sf)
library(dplyr)
library(raster)


library(terra)
library(sf)
setwd("D:/Rworkspace/3DMap/")

pop_density <- raster("chn_ppp_2020.tif")
shenzhen_boundary <- st_read("Shenzhen_Map.shp")
shenzhen_boundary_sp <- as(shenzhen_boundary, "Spatial") # Shapefile->Spatial对象
cropped_pop_density <- crop(pop_density, shenzhen_boundary_sp)# 裁剪栅格数据
#plot(cropped_pop_density, main = "Cropped Shenzhen Population Density")

# 掩膜
shenzhen_pop_density <- mask(cropped_pop_density, shenzhen_boundary_sp)
writeRaster(shenzhen_pop_density, "shenzhen_population_density_masked.tif", overwrite = TRUE)
#plot(shenzhen_pop_density, main = "Shenzhen Population Density (Masked)")

# 栅格转矩阵-------------------------------------------------------------
pop_matrix <- as.matrix(shenzhen_pop_density)
pop_matrix <- t(pop_matrix)# 转置矩阵

# 自定义颜色调色板
colors <- c("#f4f1de","#ffea00","#F39C12","#bc6c25","#78290f","#780000")
#colors <- c("#dad7cd","#a3b18a","#588157","#3a5a40","#344e41")
texture <- grDevices::colorRampPalette(colors, bias = 2)(256)
# 使用 image() 显示颜色渐变
# image(1:256, 1, as.matrix(1:256), col = texture, axes = FALSE, xlab = "", ylab = "")

library(rgl)
try(rgl::close3d())  #防错

# Create the initial 3D object
pop_matrix[pop_matrix == min(pop_matrix)] <- 0
pop_matrix |> 
  height_shade(texture = texture) |> 
  add_shadow(ray_shade(heightmap = pop_matrix -1 ,sunaltitude=20,sunangle = 220,zscale=30),max_darken=0.5)|>
  plot_3d(heightmap = pop_matrix, 
          solid = FALSE,
          solidcolor = "#f4f1de",
          solidlinecolor = "#f4f1de",
          shadow = FALSE,
          linewidth = 0,
          lineantialias = TRUE,
          z = 15,
          windowsize = c(1200, 1000), 
          # This is the azimuth, like the angle of the sun.
          # 90 degrees is directly above, 0 degrees is a profile view.
          phi = 60, 
          zoom = 0.7, 
          # `theta` is the rotations of the map. Keeping it at 0 will preserve
          # the standard (i.e. north is up) orientation of a plot
          theta = 350, 
          background = "white") 
render_snapshot("Shenzhen_population_density_3d(4).png")
render_camera(phi = 45, zoom = .6, theta = 0)# Use this to adjust the view after building the window object

# 添加比例尺
render_scalebar(clear_scalebar = TRUE)
render_scalebar(
  limits = c(0, 5, 10),   # 设定比例尺范围
  label_unit = "km",      # 单位是公里
  position = "W",         # 位置在西侧
  y = 0,                 # 在 y 方向上的位置
  scale_length = c(0.2, 1)  # 设置比例尺的长度
)
#指南针
render_compass(clear_compass = TRUE)
#render_compass(position = "N",zscale = 1) 
# 保存渲染图像
render_snapshot("Shenzhen_population_density_3d(2).png")



#beijing----------------------------------------------------------------------------
pop_density <- raster("chn_ppp_2020.tif")
Beijing_boundary <- st_read("Beijing-2020/Beijing-2020.shp")
# 转换Shapefile为Spatial对象
Beijing_boundary_sp <- as(Beijing_boundary, "Spatial")
# 栅格数据数据太大可以先裁剪
cropped_pop_density <- crop(pop_density, Beijing_boundary_sp)
# 使用掩膜操作
Beijing_pop_density <- mask(cropped_pop_density, Beijing_boundary_sp)
# 可视化掩膜后的结果
plot(Beijing_pop_density, main = "Beijing Population Density (Masked)")

# 将栅格转换为矩阵-------------------------------------------------------------
pop_matrix <- as.matrix(Beijing_pop_density)
# 转置矩阵
pop_matrix <- t(pop_matrix)

# 创建颜色渐变
colors <- c("#F2F2ED","#dde5b6","#a3b18a","#588157","#3a5a40","#344e41")
texture <- grDevices::colorRampPalette(colors, bias = 2)(256)
library(rgl)
open3d()
try(rgl::close3d())
# Create the initial 3D object
#pop_matrix[pop_matrix == min(pop_matrix)] <- 0
pop_matrix |> 
  height_shade(texture = texture) |> 
  plot_3d(heightmap = pop_matrix, 
          solid = FALSE,
          soliddepth = 0,
          z = 5,
          shadowdepth = 0.01,
          windowsize = c(1200, 800), 
          phi = 60, 
          zoom = 0.6, 
          theta = 0, 
          background = "white") 

# Use this to adjust the view after building the window object
#render_camera(phi = 45, zoom = .6, theta = 0)
render_snapshot("Beijing_population_density_3d.png")
