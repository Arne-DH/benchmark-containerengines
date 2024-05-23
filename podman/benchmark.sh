#!/usr/bin/env bash

# Check if the directories exist, if not create them
if [ ! -d "../processing/results" ]; then
  mkdir -p "../processing/results"
fi

if [ ! -d "raw" ]; then
  mkdir "raw"
fi

# docker image name
image="docker.io/arnedh/dockerbench:latest"

# Pull the docker image
podman pull $image

# Create custom network
podman network create net

# Import commands
source ../commands.txt

# Assign and create the CSV file
csv_file="../processing/results/resultsPodman.csv"
touch $csv_file

# Write header into results
echo "Index,CPU_Events/s,Memory_Operations/s,rndrw_Reads/s,rndrw_Read_MiB/s,rndrw_Writes/s,rndrw_Written_MiB/s,rndrw_Fsyncs/s,rndrd_Reads/s,rndrd_Read_MiB/s,rndwr_Writes/s,rndwr_Written_MiB/s,rndwr_Fsyncs/s,seqrd_Reads/s,seqrd_Read_MiB/s,seqwr_Writes/s,seqwr_Written_MiB/s,seqwr_Fsyncs/s,seqrewr_Writes/s,seqrewr_Written_MiB/s,seqrewr_Fsyncs/s,Sender_troughput_Gb/s,Minimum_rtt,Average_rtt,Max_rtt,mdev" > $csv_file

for i in {0..9}
do
    # Create and start the Podman container for CPU test
    podman run --runtime runc --name=podman_cpu_$i $image $cpu_sysbench_command > raw/podmanSys_cpu_$i.txt
    # Delete the container
    podman rm podman_cpu_$i
    echo "Podman CPU benchmark-$i done"

    # Create and start the Podman container for memory test
    podman run --runtime runc --name=podman_mem_$i $image $memory_sysbench_command > raw/podmanSys_mem_$i.txt
    # Delete the container
    podman rm podman_mem_$i
    echo "Podman Memory benchmark-$i done"

    # Create and start the Podman container for rndrw test (1 thread)
    podman run --runtime runc --name=podman_rndrw_$i $image /bin/bash -c "eval $rndrw_sysbench_command" > raw/podmanSys_rndrw_$i.txt
    # Delete the container
    podman rm podman_rndrw_$i
    echo "Podman Random read/write benchmark-$i done"

    # Create and start the Podman container for rndrd test (1 thread)
    podman run --runtime runc --name=podman_rndrd_$i $image /bin/bash -c "eval $rndrd_sysbench_command" > raw/podmanSys_rndrd_$i.txt
    # Delete the container
    podman rm podman_rndrd_$i
    echo "Podman Random read benchmark-$i done"

    # Create and start the Podman container for rndwr test (1 thread)
    podman run --runtime runc --name=podman_rndwr_$i $image /bin/bash -c "eval $rndwr_sysbench_command" > raw/podmanSys_rndwr_$i.txt
    # Delete the container
    podman rm podman_rndwr_$i
    echo "Podman Random write benchmark-$i done"

    # Create and start the Podman container for seqrd test (1 thread)
    podman run --runtime runc --name=podman_seqrd_$i $image /bin/bash -c "eval $seqrd_sysbench_command" > raw/podmanSys_seqrd_$i.txt
    # Delete the container
    podman rm podman_seqrd_$i
    echo "Podman Sequential read benchmark-$i done"

    # Create and start the Podman container for seqwr test (1 thread)
    podman run --runtime runc --name=podman_seqwr_$i $image /bin/bash -c "eval $seqwr_sysbench_command" > raw/podmanSys_seqwr_$i.txt
    # Delete the container
    podman rm podman_seqwr_$i
    echo "Podman Sequential write benchmark-$i done"

    # Create and start the Podman container for seqrewr test (1 thread)
    podman run --runtime runc --name=podman_seqrewr_$i $image /bin/bash -c "eval $seqrewr_sysbench_command" > raw/podmanSys_seqrewr_$i.txt
    # Delete the container
    podman rm podman_seqrewr_$i
    echo "Podman Sequential rewrite benchmark-$i done"

    # Create and start the Podman containers for troughput test
    podman run --runtime runc -d --network=net --name=podman_server_$i $image tail -f /dev/null > /dev/null 2>&1
    podman run --runtime runc -d --network=net --name=podman_client_$i $image tail -f /dev/null > /dev/null 2>&1
    # Get the needed IP address of the server
    serverIP=$(podman inspect -f '{{.NetworkSettings.Networks.net.IPAddress}}' podman_server_$i)
    # Start iperf3 Server
    podman exec -d podman_server_$i iperf3 -s
    # Run iperf3 Client
    podman exec podman_client_$i iperf3 -c $serverIP > raw/podmanIperf3_Troughput_$i.txt
    # Stop the containers
    podman stop podman_server_$i
    podman stop podman_client_$i
    # Delete the containers
    podman rm podman_server_$i
    podman rm podman_client_$i
    echo "Podman Network Troughput benchmark-$i done"

    # Create and start the Podman containers for RTT test
    podman run --runtime runc -d --network=net --name=podman_server_RTT_$i $image tail -f /dev/null > /dev/null 2>&1
    podman run --runtime runc -d --network=net --name=podman_client_RTT_$i $image tail -f /dev/null > /dev/null 2>&1
    # Get the needed IP address of the server
    serverIP=$(podman inspect -f '{{.NetworkSettings.Networks.net.IPAddress}}' podman_server_RTT_$i)
    # Perform RTT test
    podman exec --privileged podman_client_RTT_$i ping -c 100 $serverIP > raw/podmanIperf3_RTT_$i.txt
    # Stop the containers
    podman stop podman_client_RTT_$i
    podman stop podman_server_RTT_$i 
    # Delete the containers
    podman rm podman_client_RTT_$i
    podman rm podman_server_RTT_$i
    echo "Podman Network RTT benchmark-$i done"

    # Parse the output to extract the events/s for CPU test
    cpu_events_per_second=$(grep "events per second:" raw/podmanSys_cpu_$i.txt | awk '{print $4}')

    # Parse the output to extract the operations/s for memory test
    memory_operations_per_second=$(grep "Total operations:" raw/podmanSys_mem_$i.txt | awk -F'(' '{print $2}' | awk -F' ' '{print $1}')

    # Parse the Random read/write results
    rndrw_reads_per_second=$(grep "reads/s:" raw/podmanSys_rndrw_$i.txt | awk '{print $2}')
    rndrw_writes_per_second=$(grep "writes/s:" raw/podmanSys_rndrw_$i.txt | awk '{print $2}')
    rndrw_fsyncs_per_second=$(grep "fsyncs/s:" raw/podmanSys_rndrw_$i.txt | awk '{print $2}')
    rndrw_read_mibs=$(grep "read, MiB/s:" raw/podmanSys_rndrw_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')
    rndrw_written_mibs=$(grep "written, MiB/s:" raw/podmanSys_rndrw_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Random read result
    rndrd_reads_per_second=$(grep "reads/s:" raw/podmanSys_rndrd_$i.txt | awk '{print $2}')
    rndrd_read_mibs=$(grep "read, MiB/s:" raw/podmanSys_rndrd_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Random write result
    rndwr_writes_per_second=$(grep "writes/s:" raw/podmanSys_rndwr_$i.txt | awk '{print $2}')
    rndwr_fsyncs_per_second=$(grep "fsyncs/s:" raw/podmanSys_rndwr_$i.txt | awk '{print $2}')
    rndwr_written_mibs=$(grep "written, MiB/s:" raw/podmanSys_rndwr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')
      
    # Parse the Sequential reads results
    seqrd_reads_per_second=$(grep "reads/s:" raw/podmanSys_seqrd_$i.txt | awk '{print $2}')
    seqrd_read_mibs=$(grep "read, MiB/s:" raw/podmanSys_seqrd_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Sequential writes results
    seqwr_writes_per_second=$(grep "writes/s:" raw/podmanSys_seqwr_$i.txt | awk '{print $2}')
    seqwr_fsyncs_per_second=$(grep "fsyncs/s:" raw/podmanSys_seqwr_$i.txt | awk '{print $2}')
    seqwr_written_mibs=$(grep "written, MiB/s:" raw/podmanSys_seqwr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Sequential rewrites results
    seqrewr_writes_per_second=$(grep "writes/s:" raw/podmanSys_seqrewr_$i.txt | awk '{print $2}')
    seqrewr_fsyncs_per_second=$(grep "fsyncs/s:" raw/podmanSys_seqrewr_$i.txt | awk '{print $2}')
    seqrewr_written_mibs=$(grep "written, MiB/s:" raw/podmanSys_seqrewr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Network Throughput results
    troughput_gbit_per_second=$(grep 'sender' raw/podmanIperf3_Troughput_$i.txt | awk '{print $5}')

    # Parse the Network RTT results
    rtt_values=$(grep "rtt min/avg/max/mdev" raw/podmanIperf3_RTT_$i.txt | awk -F'= ' '{print $2}')
    read -r min_rtt avg_rtt max_rtt mdev <<<$(echo $rtt_values | awk -F'[/ ]' '{print $1" "$2" "$3" "$4}')

    # Append the index, CPU events/s, memory operations/s and fileio results to the CSV file
    echo "$i,$cpu_events_per_second,$memory_operations_per_second,$rndrw_reads_per_second,$rndrw_read_mibs,$rndrw_writes_per_second,$rndrw_written_mibs,$rndrw_fsyncs_per_second,$rndrd_reads_per_second,$rndrd_read_mibs,$rndwr_writes_per_second,$rndwr_written_mibs,$rndwr_fsyncs_per_second,$seqrd_reads_per_second,$seqrd_read_mibs,$seqwr_writes_per_second,$seqwr_written_mibs,$seqwr_fsyncs_per_second,$seqrewr_writes_per_second,$seqrewr_written_mibs,$seqrewr_fsyncs_per_second,$troughput_gbit_per_second,$min_rtt,$avg_rtt,$max_rtt,$mdev" >> $csv_file
done

