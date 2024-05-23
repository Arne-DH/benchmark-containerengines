# Dependencies
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
import os

# Data
results = ["processing/results/resultsContainerd.csv", "processing/results/resultsCRI-O.csv", "processing/results/resultsLXC.csv", "processing/results/resultsPodman.csv"]
# Engines
engines = {'containerd': 'blue', 'CRI-O': 'red', 'lxc': 'green', 'podman': 'orange'}

# Create the directory if it does not exist
graphs_dir = os.path.join('processing', 'graphs')
if not os.path.exists(graphs_dir):
    os.makedirs(graphs_dir)

# ------------------------------
# Sysbench & Iperf3
# ------------------------------

# Function to visualize CPU, RAM, and Throughput
def plot_performance(engines, results, metric, title, filename):
        
    # Loop over the results and calculate the average values
    averages = []
    for engine, res in zip(engines.keys(), results):
        df = pd.read_csv(res)
        avg = {metric: df[metric].mean()}
        avg['Engine'] = engine
        averages.append(avg)

    # Create the dataframe with the average values
    df_averages = pd.DataFrame(averages)
    df_averages.set_index('Engine', inplace=True)

    # Create the graph
    plt.figure(figsize=(10, 6))

    # Loop over all the engines and add the correct values
    for engine, color in engines.items():
        plt.bar(engine, df_averages.loc[engine, metric], color=color)

    # Add correct labels
    plt.title(title)
    plt.xlabel('Container Engine')
    plt.ylabel('Average Value')
    plt.savefig(os.path.join(graphs_dir, filename))
    plt.close()

# CPU performance
plot_performance(engines, results, 'CPU_Events/s', 'Sysbench - Single Core CPU Performance (higher is better)', 'sysbench_cpu_performance.png')

# RAM performance
plot_performance(engines, results, 'Memory_Operations/s', 'Sysbench - RAM Performance (higher is better)', 'sysbench_ram_performance.png')

# Network Throughput performance
plot_performance(engines, results, 'Sender_troughput_Gb/s', 'Iperf3 - Network Throughput (higher is better)', 'iperf3_network_throughput_performance.png')

# ------------------------------
# FiloIO read/write Performance
# ------------------------------

def plot_fileio(metrics, title, file_name):
    averages = []
    for res in results:
        df = pd.read_csv(res)
        averages.append({metric: df[metric].mean() for metric in metrics})

    df_averages = pd.DataFrame(averages, index=engines.keys())

    barWidth = 0.10
    r = np.arange(len(metrics))

    plt.figure(figsize=(12, 8))

    for engine, color in engines.items():
        plt.bar(r + barWidth * list(engines.keys()).index(engine), df_averages.loc[engine], width=barWidth, color=color, label=engine)

    plt.xticks([r + barWidth for r in range(len(metrics))], [metric.split('_')[1] for metric in metrics])
    plt.ylabel('Average Value')
    plt.title(title)
    plt.legend()
    plt.savefig(os.path.join(graphs_dir, file_name))
    plt.close()

# Simultaneous Random Read/Write Performance
metrics = ['rndrw_Reads/s', 'rndrw_Writes/s', 'rndrw_Fsyncs/s', 'rndrw_Read_MiB/s', 'rndrw_Written_MiB/s']
plot_fileio(metrics, 'FileIO - Gelijktijdig Random Read/Write Performantie (meer is beter)', 'fileio_simultaneous_randomreadwrite_performance.png')

# Individual Random Read/Write Performance
metrics = ['rndrd_Reads/s', 'rndwr_Writes/s','rndwr_Fsyncs/s','rndrd_Read_MiB/s','rndwr_Written_MiB/s']
plot_fileio(metrics, 'FileIO - Individuele Random Read/Write Performantie (meer is beter)', 'fileio_individual_randomreadwrite_performance.png')

# Sequential Read/Write Performance
metrics = ['seqrd_Reads/s', 'seqwr_Writes/s', 'seqwr_Fsyncs/s', 'seqrd_Read_MiB/s', 'seqwr_Written_MiB/s']
plot_fileio(metrics, 'FileIO - Sequentiële Read/Write Performantie (meer is beter)', 'fileio_sequential_readwrite_performance.png')

# Sequential rewrite performance
metrics = ['seqrewr_Writes/s', 'seqrewr_Fsyncs/s' ,'seqrewr_Written_MiB/s']
plot_fileio(metrics, 'FileIO - Sequentiuele Rewrite Performantie (meer is beter)', 'fileio_sequential_rewrite_performance.png')

# ------------------------------
# Network Latency
# ------------------------------

# dataset
metrics = ['Minimaal', 'Gemiddelde', 'Maximaal']
metric_mapping = {'Minimum_rtt': 'Minimaal', 'Average_rtt': 'Gemiddelde', 'Max_rtt': 'Maximaal'}

# Calculate the average of all metrics
averages = []
for engine, res in zip(engines.keys(), results):
    df = pd.read_csv(res)
    averages.append({metric_mapping[metric]: df[metric].mean() for metric in metric_mapping})

# Create the dataframe
df_averages = pd.DataFrame(averages, index=engines.keys())

# Create the bar graph
barWidth = 0.10
r = np.arange(len(metrics))

plt.figure(figsize=(12, 8))

for i in range(len(df_averages)):
    plt.bar(r + barWidth * i, df_averages.iloc[i], width=barWidth, color=engines[df_averages.index[i]], label=df_averages.index[i])

plt.xticks([r + barWidth for r in range(len(metrics))], metrics)
plt.ylabel('Latency (ms)')
plt.title('Ping - Netwerk Latency')
plt.legend()
plt.savefig(os.path.join(graphs_dir, 'ping_network_latency_performance.png'))
plt.close()