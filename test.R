# 设置工作目录
setwd("/Users/panzhiqing/Desktop/Rmap/")
print(getwd())  # 打印当前工作目录，确保文件保存到这里

library(rayshader)

# 加载地形数据
loadzip = tempfile() 
download.file("https://tylermw.com/data/dem_01.tif.zip", loadzip)
localtif = raster::raster(unzip(loadzip, "dem_01.tif"))
unlink(loadzip)

# 转换为矩阵
elmat = raster_to_matrix(localtif)

# 创建图形设备，将图片保存为 PNG
png("rayshader_plot.png", width = 800, height = 600)

# 生成并绘制地图
elmat %>%
  sphere_shade(texture = "desert") %>%
  plot_map()

# 关闭图形设备
dev.off()

# 提示文件已保存
cat("Image saved as 'rayshader_plot.png' in:", getwd(), "\n")
