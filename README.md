# Containerized Applications Performance Benchmarking Scripts

This repository contains a collection of scripts designed to benchmark the performance of containerized applications. The scripts are written in Bash and Python, providing a comprehensive toolset for gathering and visualizing performance metrics.

## Overview

The Bash scripts are responsible for gathering performance metrics from the containerized applications. These metrics include CPU usage, memory usage, network I/O, and more. The Python scripts are used to visualize these metrics in a clear and understandable format, allowing for easy comparison and analysis.

## Installation

To use these scripts, you need to have the following software installed on your system:

### Container Engines

- [Docker](https://www.docker.com/): A container engine that is used to run the containerized applications.
- [Podman](https://podman.io/): A container engine that is used to run the containerized applications.
- [LXC](https://linuxcontainers.org/lxc/): A container engine that is used to run the containerized applications.
- [Kubernetes](https://kubernetes.io/): A container orchestration platform that is used to run the containerized applications.

### Visualisation

- [Python](https://www.python.org/): A programming language that is used to run the visualization scripts.
- [Matplotlib](https://matplotlib.org/): A Python library that is used to generate graphs and charts.
- [Pandas](https://pandas.pydata.org/): A Python library that is used to process and analyze data.
- [NumPy](https://numpy.org/): A Python library that is used for numerical computing.

Optionally you can use Jupyter Notebooks to display the visualizations in an interactive format.

## Usage

Before using these scripts, you need to manually install the necessary container engines. Please refer to the official documentation of the specific container engine for installation instructions.

Once the container engines are installed, you modify the commands in the `/commands.txt` file to modify the parameters and follow the steps below to use the scripts: 

1. Run the Bash scripts to gather performance metrics from your containerized applications. The scripts will output the metrics in a format that can be easily processed by the Python scripts.

2. Run the Python scripts to visualize the metrics. The scripts will generate graphs and charts that provide a visual representation of the performance of your containerized applications.

## How It Works

The Bash scripts use various system commands and tools to gather performance metrics from the containerized applications. The Python scripts use libraries such as matplotlib and pandas to process the metrics and generate visualizations.

This project can be modified to extend the functionality or add support for additional container engines. If you have any suggestions or improvements, please feel free to submit a pull request.

## Contributing

This project can be modified to extend the functionality or add support for additional container engines. If you have any suggestions or improvements, feel free to submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.