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

SAVE_PATH4 = os.path.join(DATA_DIR2, 'normalized.csv')
SAVE_PATH5 = os.path.join(DATA_DIR2, 'masked3.csv')


# PATH4 = os.path.join(DATA_DIR2,'heatmap.tif')

def readTif(path):
    # 读取栅格数据
    with rasterio.open(path) as src:
        # 读取数据
        data = src.read(1)
        # 读取元数据
        meta = src.meta
    return data, meta


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

def assign_grid_counts(df_cleaned, df_population):
    # 将 lat 和 lng 转换为 0.01° × 0.01° 的格网
    df_cleaned['grid_lat'] = (df_cleaned['lat'] * 100).astype(int) / 100
    df_cleaned['grid_lng'] = (df_cleaned['lng'] * 100).astype(int) / 100
    
    # 统计每个格网内的充电桩数量
    grid_counts = df_cleaned.groupby(['grid_lat', 'grid_lng']).size().reset_index(name='evse_count')
    
    # 将格网统计结果与人口数据合并
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
    df = pd.read_csv(PATH)
    df = clean_data(df)
    save_as_csv(df, SAVE_PATH)

    # 2.
    # df_cleaned = pd.read_csv(SAVE_PATH) # 读取清洗后的数据
    # df = pd.read_csv(PATH2) # 读取人口数据 X,Y,Z
    # df_merged = assign_grid_counts(df_cleaned, df) # 合并数据
    # save_as_csv(df_merged, SAVE_PATH2) # 保存数据

    # 3.
    # df_cleaned = pd.read_csv(SAVE_PATH2) # 读取清洗后的数据
    # gdf = gpd.read_file(PATH3)
    # # "NAME_1" ILIKE '%Scotland%'
    # gdf = gdf[gdf['NAME_1'].str.contains('Scotland')]
    # gdf = gdf.to_crs(epsg=4326)


    # 3.5
    df_cleaned = pd.read_csv(SAVE_PATH) # 读取清洗后的数据
    # SAVE_PATH3 = os.path.join(DATA_DIR2, 'masked.csv')
    df2 = pd.read_csv(SAVE_PATH3)

    # print(data)
    # print(meta)

    # print(df2.head())
    # print(df_cleaned.head())  

    tol = 0.01

    # 使用 tqdm 包裹来遍历 df2
    for i in tqdm(range(len(df2))):
        # 获取每一行
        row = df2.iloc[i]
        # 获取经纬度
        lat = row['Y']
        lng = row['X']
        # 获取 Z 和 evse_count
        Z = row['Z']

    row['evse_count'] = df_cleaned.loc[(df_cleaned['lat'] > lat - tol) & (df_cleaned['lat'] < lat + tol) & (df_cleaned['lng'] > lng - tol) & (df_cleaned['lng'] < lng + tol), 'duplicate_count'].sum()

    save_as_csv(df2, SAVE_PATH5) # 保存数据


    # # 保存 gdf
    # # gdf.to_file(os.path.join(DATA_DIR2, 'Scotland_boundary.shp'))

    # res = mask(gdf, df_cleaned)
    # save_as_csv(res, SAVE_PATH3) # 保存数据

    # 4. 对 Z 和 evse_count 进行归一化处理 也是就说将 Z 和 evse_count 映射到 [0, 1] 区间
    # df = pd.read_csv(SAVE_PATH3)
    # df['Z'] = (df['Z'] - df['Z'].min()) / (df['Z'].max() - df['Z'].min())
    # df['evse_count'] = (df['evse_count'] - df['evse_count'].min()) / (df['evse_count'].max() - df['evse_count'].min())
    # save_as_csv(df, SAVE_PATH4) # 保存数据
    


    # 读取边界数据并打印属性表
    # gdf = gpd.read_file(PATH3)
    # print(gdf.head())
    # print(gdf.columns)

    # 答应第一行数据的所有属性
    # print(gdf.iloc[0])
    # 打印 NAME_2  的所有唯一值 并查找是否存在 Scotland highland，Edinburgh和Glasgow
    # print(gdf['NAME_2'].unique())
    # unique = gdf['NAME_2'].unique()
    # # 查找是否存在 Scotland highland，Edinburgh和Glasgow

    # for name in ['Scotland highland', 'Edinburgh', 'Glasgow']:
    #     print(name, name in unique)




