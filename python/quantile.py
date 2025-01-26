import numpy as np
import pandas as pd
import os
import matplotlib.pyplot as plt

DIR = os.path.dirname(__file__)

DATA_DIR = os.path.join(DIR, '..', 'data')
DATA_DIR2 = os.path.join(DATA_DIR, '人口-充电桩双变量地图')
SAVE_PATH4 = os.path.join(DATA_DIR2, 'normalized.csv')
SAVE_PATH5 = os.path.join(DATA_DIR, 'resampled.csv')



def generate_breaks(data, quantiles):
    """
    生成间断点（忽略最小值）
    
    参数:
    data (list or np.array): 输入数据
    quantiles (list): 分位数列表，例如 [0, 0.25, 0.5, 0.75, 1]
    
    返回:
    breaks (list): 生成的间断点
    """
    # 计算分位数
    breaks = np.quantile(data, quantiles)
    
    # 忽略最小值（第一个元素）
    breaks = breaks[1:]
    
    return breaks.tolist()

def generate_breaks2(data, num_breaks):
    """
    生成间断点（忽略最小值），确保尽可能多的点有颜色
    
    参数:
    data (list or np.array): 输入数据
    num_breaks (int): 区间数量（每个方向的分段数）
    
    返回:
    breaks (list): 生成的间断点
    """
    # 计算分位数
    quantiles = np.linspace(0, 1, num_breaks + 1)  # 生成均匀分位数
    breaks = np.quantile(data, quantiles)
    
    # 忽略最小值（第一个元素）
    breaks = breaks[1:]
    
    return breaks.tolist()

def generate_breaks3(data, intervals=4):
    """
    生成间断点（忽略最小值），用于双变量地图的分区间
    
    参数:
    data (list or np.array): 输入数据
    intervals (int): 区间数量，默认为 4
    
    返回:
    breaks (list): 生成的间断点
    """
    # 计算分位数
    quantiles = np.linspace(0, 1, intervals + 1)  # 生成 [0, 0.25, 0.5, 0.75, 1] 的分位数
    breaks = np.quantile(data, quantiles)
    
    # 忽略最小值（第一个元素）
    breaks = breaks[1:]
    
    return breaks.tolist()

def bar_chart(df,name):
    # 绘制柱状图
    plt.hist(df, bins=20, color='steelblue', edgecolor='black')
    plt.title(name)
    plt.xlabel('Value')
    plt.ylabel('Frequency')
    plt.show()






# # 示例数据
# population = [0, 0.0001, 0.182, 0.379, 1]
# ev_charging_count = [0, 0.0001, 0.095, 0.224, 1]

# # 定义分位数
# quantiles = [0, 0.25, 0.5, 0.75, 1]

# # 生成间断点
# breaks_x = generate_breaks(population, quantiles)
# breaks_y = generate_breaks(ev_charging_count, quantiles)

# print("Breaks for population:", breaks_x)
# print("Breaks for EV Charging Count:", breaks_y)

if __name__ == "__main__":
    df = pd.read_csv(SAVE_PATH5)
    # print(df.head())
    # 分别统计 Z 和 evse_count 两列的分位数间断点
    # breaks_x = generate_breaks(df['Z'], [0, 0.1, 0.25, 0.5, 0.75, 1])
    # breaks_y = generate_breaks(df['evse_count'][df['evse_count'] > 0] , [0, 0.1, 0.25, 0.5, 0.75, 1])

    # breaks_x = generate_breaks2(df['Z'], 5)
    # breaks_y = generate_breaks2(df['evse_count'][df['evse_count'] > 0], 5)

    breaks_x = generate_breaks3(df['population'], 4)
    breaks_y = generate_breaks3(df['EVCharingCount'][df['EVCharingCount'] > 0], 4)

    # 打印出最大值
    print("Max population:", df['population'].max())
    print("Max EV Charging Count:", df['EVCharingCount'].max())

    # 打印最小值
    print("Min population:", df['population'].min())
    print("Min EV Charging Count:", df['EVCharingCount'].min())

    print("Breaks for population:", breaks_x)
    print("Breaks for EV Charging Count:", breaks_y)

    # # 绘制柱状图
    # bar_chart(df['Z'][df['Z'] > 0], 'Breaks for Z')
    # bar_chart(df['evse_count'][df['evse_count'] > 0], 'Breaks for EV Charging Count')
