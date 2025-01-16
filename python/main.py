import pandas as pd
# import numpy as np
import os
import geopandas as gpd
from tqdm import tqdm

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

def clean_data(df):
    # 统计每个 evse_id 出现的次数
    evse_count = df['evse_id'].value_counts().reset_index()
    evse_count.columns = ['evse_id', 'duplicate_count']
    
    # 将统计结果合并到原始 DataFrame 中
    df = df.merge(evse_count, on='evse_id', how='left')
    
    # 仅仅保留 lat, lng, evse_id, duplicate_count 几列并去重
    df = df[['lat', 'lng', 'evse_id', 'duplicate_count']]
    
    # 只对 evse_id 去重
    df = df.drop_duplicates(subset=['evse_id'])
    
    return df


def save_as_csv(df, path):
    df.to_csv(path, index=False)
    print(f"Save DataFrame to {path} successfully!")

# def assign_grid_counts(df_cleaned, df_population):
#     # 将 lat 和 lng 转换为 0.01° × 0.01° 的格网
#     df_cleaned['grid_lat'] = (df_cleaned['lat'] * 100).astype(int) / 100
#     df_cleaned['grid_lng'] = (df_cleaned['lng'] * 100).astype(int) / 100
    
#     # 统计每个格网内的充电桩数量
#     grid_counts = df_cleaned.groupby(['grid_lat', 'grid_lng']).size().reset_index(name='evse_count')
    
#     # 将格网统计结果与人口数据合并
#     df_population['grid_lat'] = (df_population['Y'] * 100).astype(int) / 100
#     df_population['grid_lng'] = (df_population['X'] * 100).astype(int) / 100
    
#     # 合并数据
#     df_merged = df_population.merge(grid_counts, on=['grid_lat', 'grid_lng'], how='left')
    
#     # 填充缺失值为 0（表示该格网内没有充电桩）
#     df_merged['evse_count'] = df_merged['evse_count'].fillna(0).astype(int)
    
#     # 删除临时列
#     df_merged.drop(columns=['grid_lat', 'grid_lng'], inplace=True)
    
#     return df_merged

def assign_grid_counts(df_cleaned, df_population):
    # 确保 lat 和 lng 列是浮点数类型
    df_cleaned['lat'] = df_cleaned['lat'].astype(float)
    df_cleaned['lng'] = df_cleaned['lng'].astype(float)
    
    # 将 lat 和 lng 转换为 0.01° × 0.01° 的格网
    df_cleaned['grid_lat'] = (df_cleaned['lat'] * 100).astype(int) / 100
    df_cleaned['grid_lng'] = (df_cleaned['lng'] * 100).astype(int) / 100
    
    # 统计每个格网内的充电桩数量，考虑 duplicate_count 列
    grid_counts = df_cleaned.groupby(['grid_lat', 'grid_lng'])['duplicate_count'].sum().reset_index(name='evse_count')
    
    # 确保 df_population 中的 X 和 Y 列是浮点数类型
    df_population['X'] = df_population['X'].astype(float)
    df_population['Y'] = df_population['Y'].astype(float)
    
    # 将 df_population 中的 X 和 Y 转换为 0.01° × 0.01° 的格网
    df_population['grid_lat'] = (df_population['Y'] * 100).astype(int) / 100
    df_population['grid_lng'] = (df_population['X'] * 100).astype(int) / 100
    
    # 合并数据
    df_merged = df_population.merge(grid_counts, on=['grid_lat', 'grid_lng'], how='left')
    
    # 填充缺失值为 0（表示该格网内没有充电桩）
    df_merged['evse_count'] = df_merged['evse_count'].fillna(0).astype(int)
    
    # 删除临时列
    df_merged.drop(columns=['grid_lat', 'grid_lng'], inplace=True)
    
    return df_merged

def mask(gdf, df):
    # 合并所有几何对象为一个几何对象
    gdf_union = gdf.geometry.unary_union
    
    # 获取外接矩形
    bounds = gdf_union.bounds
    (minX, minY, maxX, maxY) = bounds

    # 过滤掉不在外接矩形内的点
    df = df[(df['Y'] >= minY) & (df['Y'] <= maxY) & (df['X'] >= minX) & (df['X'] <= maxX)]
    return df

def geometryGetValue(gdf, df):
    # 合并所有几何对象为一个几何对象
    gdf_union = gdf.geometry.unary_union
    
    # 获取外接矩形
    bounds = gdf_union.bounds
    (minX, minY, maxX, maxY) = bounds

    # 过滤掉不在外接矩形内的点
    df = df[(df['Y'] >= minY) & (df['Y'] <= maxY) & (df['X'] >= minX) & (df['X'] <= maxX)]
    return df


if __name__ == '__main__':
    # 1.
    # df = pd.read_csv(PATH)
    # df = clean_data(df)
    # save_as_csv(df, SAVE_PATH)

    # 2.
    # df_cleaned = pd.read_csv(SAVE_PATH) # 读取清洗后的数据
    # df = pd.read_csv(PATH2) # 读取人口数据 X,Y,Z
    # df_merged = assign_grid_counts(df_cleaned, df) # 合并数据
    # save_as_csv(df_merged, SAVE_PATH2) # 保存数据

    # 3.
    df_cleaned = pd.read_csv(SAVE_PATH2) # 读取清洗后的数据
    gdf = gpd.read_file(PATH3)
    # "NAME_1" ILIKE '%Scotland%'
    gdf = gdf[gdf['NAME_1'].str.contains('Scotland')]
    gdf = gdf.to_crs(epsg=4326)

    # 保存 gdf
    # gdf.to_file(os.path.join(DATA_DIR2, 'Scotland_boundary.shp'))

    res = mask(gdf, df_cleaned)
    save_as_csv(res, SAVE_PATH3) # 保存数据

    # 4.


