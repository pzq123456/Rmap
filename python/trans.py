import pandas as pd
import numpy as np
import os
import geopandas as gpd
from tqdm import tqdm
from pykrige.ok import OrdinaryKriging
import matplotlib.pyplot as plt

DIR = os.path.dirname(__file__)

DATA_DIR = os.path.join(DIR, '..', 'data')

DATA_DIR2 = os.path.join(DATA_DIR, '人口-充电桩双变量地图')

# 苏格兰充电桩数据.csv

PATH = os.path.join(DATA_DIR2, '苏格兰充电桩数据.csv')
# data\人口-充电桩双变量地图\苏格兰人口数据.csv
PATH2 = os.path.join(DATA_DIR2, '苏格兰人口数据.csv')

# data\人口-充电桩双变量地图\GB_sample_boudary\gadm41_GBR_3.shp
# PATH3 = os.path.join(DATA_DIR2, 'GB_sample_boudary', 'gadm41_GBR_3.shp')

SAVE_PATH = os.path.join(DATA_DIR2, 'cleaned.csv')
SAVE_PATH3 = os.path.join(DATA_DIR2, 'masked.csv')

if __name__ == "__main__":
        
    # df = pd.read_csv(SAVE_PATH3)

    # # 定义新的分辨率
    # new_resolution = 0.05

    # # 计算新的X和Y坐标
    # df['X_new'] = np.round(df['X'] / new_resolution) * new_resolution
    # df['Y_new'] = np.round(df['Y'] / new_resolution) * new_resolution

    # # 聚合数据
    # aggregated_df = df.groupby(['X_new', 'Y_new']).agg({
    #     'Z': 'mean',  # 你可以选择其他聚合函数，如 'sum', 'max', 'min' 等
    #     'evse_count': 'sum'  # 假设你想对evse_count求和
    # }).reset_index()

    # # 保存结果
    # aggregated_df.to_csv('aggregated_file.csv', index=False)
        # 读取CSV文件
    df = pd.read_csv('aggregated_file.csv')

    # 提取坐标和值
    x = df['X_new'].values
    y = df['Y_new'].values
    z = df['evse_count'].values

    # 创建克里金插值模型
    # 使用线性变差函数模型（variogram_model），也可以选择 'spherical', 'gaussian' 等
    ok = OrdinaryKriging(
        x, y, z,
        variogram_model='linear',  # 变差函数模型
        verbose=False,             # 是否打印详细信息
        enable_plotting=False      # 是否绘制变差函数图
    )

    # 生成插值后的网格
    grid_x = np.linspace(min(x), max(x), 100)  # X方向的网格点
    grid_y = np.linspace(min(y), max(y), 100)  # Y方向的网格点
    grid_z, _ = ok.execute('grid', grid_x, grid_y)  # 执行插值

    # 将插值结果保存为CSV文件
    grid_x_mesh, grid_y_mesh = np.meshgrid(grid_x, grid_y)  # 生成网格
    interpolated_df = pd.DataFrame({
        'X': grid_x_mesh.ravel(),
        'Y': grid_y_mesh.ravel(),
        'evse_count': grid_z.ravel()
    })
    interpolated_df.to_csv('interpolated_evse_count.csv', index=False)

    # 可视化插值结果
    plt.figure(figsize=(10, 6))
    plt.scatter(x, y, c=z, cmap='viridis', label='Original Data', edgecolor='black')
    plt.imshow(grid_z.T, extent=(min(x), max(x), min(y), max(y)), origin='lower', alpha=0.6, cmap='viridis')
    plt.colorbar(label='evse_count')
    plt.title('Kriging Interpolation of evse_count')
    plt.xlabel('X')
    plt.ylabel('Y')
    plt.legend()
    plt.show()