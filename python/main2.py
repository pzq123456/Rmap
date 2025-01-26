# 空间降采样

import pandas as pd
# import numpy as np
import os
import geopandas as gpd
from tqdm import tqdm
import rasterio
import numpy as np

# import dask.dataframe as dd
# from dask import compute, delayed
# # progress bar
# from dask.diagnostics import ProgressBar


DIR = os.path.dirname(__file__)

DATA_DIR = os.path.join(DIR, '..', 'data')

DATA_DIR2 = os.path.join(DATA_DIR, '人口-充电桩双变量地图')

# 苏格兰充电桩数据.csv

PATH = os.path.join(DATA_DIR2, '苏格兰充电桩数据.csv')
# data\人口-充电桩双变量地图\苏格兰人口数据.csv
PATH2 = os.path.join(DATA_DIR2, '苏格兰人口数据.csv')

# data\人口-充电桩双变量地图\GB_sample_boudary\gadm41_GBR_3.shp
PATH3 = os.path.join(DATA_DIR2, 'GB_sample_boudary', 'gadm41_GBR_3.shp')

SAVE_PATH = os.path.join(DATA_DIR2, 'cleaned.csv')
SAVE_PATH2 = os.path.join(DATA_DIR2, 'merged.csv')
SAVE_PATH3 = os.path.join(DATA_DIR2, 'masked.csv')

SAVE_PATH5 = os.path.join(DATA_DIR2, 'masked3.csv')


def save_as_csv(df, path):
    df.to_csv(path, index=False)
    print(f"Save DataFrame to {path} successfully!")

def re_sample(df, new_resolution):
    # 计算新的X和Y坐标
    df['X_new'] = np.round(df['X'] / new_resolution) * new_resolution
    df['Y_new'] = np.round(df['Y'] / new_resolution) * new_resolution

    # 聚合数据
    aggregated_df = df.groupby(['X_new', 'Y_new']).agg({
        'Z': 'mean',  # 你可以选择其他聚合函数，如 'sum', 'max', 'min' 等
        'evse_count': 'sum'  # 假设你想对evse_count求和
    }).reset_index()

    # 重命名列名
    aggregated_df.columns = ['X', 'Y', 'population', 'EVCharingCount']

    # X,Y 均保留两位小数
    aggregated_df['X'] = aggregated_df['X'].round(2)
    aggregated_df['Y'] = aggregated_df['Y'].round(2)

    # Population，EVCharingCount 保留整数
    aggregated_df['population'] = aggregated_df['population'].astype(int)
    aggregated_df['EVCharingCount'] = aggregated_df['EVCharingCount'].astype(int)
    

    return aggregated_df




if __name__ == '__main__':

    df_cleaned = pd.read_csv(SAVE_PATH3) # 读取清洗后的数据
    print(df_cleaned.head())
    new_resolution = 0.05
    aggregated_df = re_sample(df_cleaned, new_resolution)
    save_as_csv(aggregated_df, os.path.join(DATA_DIR, 'resampled.csv'))

