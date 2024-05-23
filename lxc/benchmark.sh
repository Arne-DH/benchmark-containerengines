#!/usr/bin/env bash

# Check if the directories exist, if not create them
if [ ! -d "../processing/results" ]; then
  mkdir -p "../processing/results"
fi

if [ ! -d "raw" ]; then
  mkdir "raw"
fi

# Debian version
debian_version="bookworm"

# Assign and create the CSV file
csv_file="../processing/results/resultsLXC.csv"
touch $csv_file

# Import commands
source ../commands.txt

# Write header into results
echo "Index,CPU_Events/s,Memory_Operations/s,rndrw_Reads/s,rndrw_Read_MiB/s,rndrw_Writes/s,rndrw_Written_MiB/s,rndrw_Fsyncs/s,rndrd_Reads/s,rndrd_Read_MiB/s,rndwr_Writes/s,rndwr_Written_MiB/s,rndwr_Fsyncs/s,seqrd_Reads/s,seqrd_Read_MiB/s,seqwr_Writes/s,seqwr_Written_MiB/s,seqwr_Fsyncs/s,seqrewr_Writes/s,seqrewr_Written_MiB/s,seqrewr_Fsyncs/s,Sender_troughput_Gb/s,Minimum_rtt,Average_rtt,Max_rtt,stddev" > $csv_file

# Base image
lxc-create --template download --name base -- -d debian -r bookworm -a amd64 # arm64
lxc-start --name base
lxc-attach -n base -- bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y -q iperf3 sysbench inetutils-ping"    
sleep 15
lxc-stop --name base
lxc-snapshot --name base

sleep 5

echo "Beginning LXC benchmark"

# Loop Test
for i in {0..9}
do
    #Create a new LXC container and run CPU test
    lxc-copy --name base --snapshot --newname lxc_cpu_$i
    lxc-start --name lxc_cpu_$i
    lxc-attach -n lxc_cpu_$i -- bash -c "$cpu_sysbench_command" > raw/lxcSys_cpu_$i.txt   
    echo "LXC CPU benchmark-$i done"

    # Remove the container
    lxc-destroy -f -n lxc_cpu_$i

    # Create a new LXC container and run memory test
    lxc-copy --name base --snapshot --newname lxc_mem_$i
    lxc-start --name lxc_mem_$i
    lxc-attach -n lxc_mem_$i -- bash -c "$memory_sysbench_command" > raw/lxcSys_mem_$i.txt   
    echo "LXC Memory benchmark-$i done"

    # Remove the container
    lxc-destroy -f -n lxc_mem_$i

    # Create a new LXC container and run rndrw test
    lxc-copy --name base --snapshot --newname lxc_rndrw_$i
    lxc-start --name lxc_rndrw_$i
    lxc-attach -n lxc_rndrw_$i -- bash -c "eval $rndrw_sysbench_command" > raw/lxcSys_rndrw_$i.txt
    echo "LXC Random read/write benchmark-$i done"

    # Remove the container
    lxc-destroy -f -n lxc_rndrw_$i

    # Create a new LXC container and run rndrd test
    lxc-copy --name base --snapshot --newname lxc_rndrd_$i
    lxc-start --name lxc_rndrd_$i
    lxc-attach -n lxc_rndrd_$i -- bash -c "eval $rndrd_sysbench_command" > raw/lxcSys_rndrd_$i.txt
    echo "LXC Random read benchmark-$i done"

     # Remove the container
    lxc-destroy -f -n lxc_rnrd_$i

    # Create a new LXC container and run rndwr test
    lxc-copy --name base --snapshot --newname lxc_rndwr_$i
    lxc-start --name lxc_rndwr_$i
    lxc-attach -n lxc_rndwr_$i -- bash -c "eval $rndwr_sysbench_command" > raw/lxcSys_rndwr_$i.txt
    echo "LXC Random write benchmark-$i done"

     # Remove the container
    lxc-destroy -f -n lxc_rndwr_$i

    # Create a new LXC container and run seqrd test
    lxc-copy --name base --snapshot --newname lxc_seqrd_$i
    lxc-start --name lxc_seqrd_$i
    lxc-attach -n lxc_seqrd_$i -- bash -c "eval $seqrd_sysbench_command" > raw/lxcSys_seqrd_$i.txt
    echo "LXC Sequential read benchmark-$i done"

     # Remove the container
    lxc-destroy -f -n lxc_seqrd_$i

    # Create a new LXC container and run seqwr test
    lxc-copy --name base --snapshot --newname lxc_seqwr_$i
    lxc-start --name lxc_seqwr_$i
    lxc-attach -n lxc_seqwr_$i -- bash -c "eval $seqwr_sysbench_command" > raw/lxcSys_seqwr_$i.txt
    echo "LXC Sequential write benchmark-$i done"

     # Remove the container
    lxc-destroy -f -n lxc_seqwr_$i

    # Create a new LXC container and run seqrewr test
    lxc-copy --name base --snapshot --newname lxc_seqrewr_$i
    lxc-start --name lxc_seqrewr_$i
    lxc-attach -n lxc_seqrewr_$i -- bash -c "eval $seqrewr_sysbench_command" > raw/lxcSys_seqrewr_$i.txt
    echo "LXC Sequential rewrite benchmark-$i done"
    
    # Remove the container
    lxc-destroy -f -n lxc_seqrewr_$i

    # Create a new LXC container and run network troughput test
    lxc-copy --name base --snapshot --newname lxc_client_$i
    lxc-copy --name base --snapshot --newname lxc_server
    
    # Start the containers
    lxc-start --name lxc_client_$i
    lxc-start --name lxc_server

    # Run helper script
    sleep 5
    bash helper.sh &
    sleep 5

    # Get the server IP addres
    lxc_server_ip=$(lxc-info -n lxc_server -H -i)

    lxc-attach -n lxc_client_$i -- bash -c "iperf3 -c $lxc_server_ip" > raw/lxcIperf3_Troughput_$i.txt
    echo "LXC iperf3 benchmark-$i done"

    #Remove the containers
    lxc-destroy -f -n lxc_server
    lxc-destroy -f -n lxc_client_$i

    # Create a new LXC container and run network RTT test
    lxc-copy --name base --snapshot --newname lxc_client_RTT_$i
    lxc-copy --name base --snapshot --newname lxc_server_RTT_$i
    
    # Start the containers
    lxc-start --name lxc_client_RTT_$i
    lxc-start --name lxc_server_RTT_$i

    # Sleep for 10 seconds
    sleep 10

    # Get the server IP addres
    lxc_server_ip=$(lxc-info -n lxc_server_RTT_$i -H -i)

    # Perform RTT test
    lxc-attach -n lxc_client_RTT_$i -- bash -c "ping -c 100 $lxc_server_ip" > raw/lxcIperf3_RTT_$i.txt # 300s
    echo "LXC RTT benchmark-$i done"

    #Remove the containers
    lxc-destroy -f -n lxc_server_RTT_$i
    lxc-destroy -f -n lxc_client_RTT_$i

    # Parse the output to extract the events/s for CPU test
    cpu_events_per_second=$(grep "events per second:" raw/lxcSys_cpu_$i.txt | awk '{print $4}')

    # Parse the output to extract the operations/s for memory test
    memory_operations_per_second=$(grep "Total operations:" raw/lxcSys_mem_$i.txt | awk -F'(' '{print $2}' | awk -F' ' '{print $1}')

    # Parse the Random read/write results
    rndrw_reads_per_second=$(grep "reads/s:" raw/lxcSys_rndrw_$i.txt | awk '{print $2}')
    rndrw_writes_per_second=$(grep "writes/s:" raw/lxcSys_rndrw_$i.txt | awk '{print $2}')
    rndrw_fsyncs_per_second=$(grep "fsyncs/s:" raw/lxcSys_rndrw_$i.txt | awk '{print $2}')
    rndrw_read_mibs=$(grep "read, MiB/s:" raw/lxcSys_rndrw_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')
    rndrw_written_mibs=$(grep "written, MiB/s:" raw/lxcSys_rndrw_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Random read result
    rndrd_reads_per_second=$(grep "reads/s:" raw/lxcSys_rndrd_$i.txt | awk '{print $2}')
    rndrd_read_mibs=$(grep "read, MiB/s:" raw/lxcSys_rndrd_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Random write result
    rndwr_writes_per_second=$(grep "writes/s:" raw/lxcSys_rndwr_$i.txt | awk '{print $2}')
    rndwr_fsyncs_per_second=$(grep "fsyncs/s:" raw/lxcSys_rndwr_$i.txt | awk '{print $2}')
    rndwr_written_mibs=$(grep "written, MiB/s:" raw/lxcSys_rndwr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')
        
    # Parse the Sequential reads results
    seqrd_reads_per_second=$(grep "reads/s:" raw/lxcSys_seqrd_$i.txt | awk '{print $2}')
    seqrd_read_mibs=$(grep "read, MiB/s:" raw/lxcSys_seqrd_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Sequential writes results
    seqwr_writes_per_second=$(grep "writes/s:" raw/lxcSys_seqwr_$i.txt | awk '{print $2}')
    seqwr_fsyncs_per_second=$(grep "fsyncs/s:" raw/lxcSys_seqwr_$i.txt | awk '{print $2}')
    seqwr_written_mibs=$(grep "written, MiB/s:" raw/lxcSys_seqwr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Sequential rewrites results
    seqrewr_writes_per_second=$(grep "writes/s:" raw/lxcSys_seqrewr_$i.txt | awk '{print $2}')
    seqrewr_fsyncs_per_second=$(grep "fsyncs/s:" raw/lxcSys_seqrewr_$i.txt | awk '{print $2}')
    seqrewr_written_mibs=$(grep "written, MiB/s:" raw/lxcSys_seqrewr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Network Throughput results
    troughput_gbit_per_second=$(grep 'sender' raw/lxcIperf3_Troughput_$i.txt | awk '{print $5}')

    # Parse the Network RTT results
    rtt_values=$(grep "round-trip min/avg/max/stddev" raw/lxcIperf3_RTT_$i.txt | awk -F'= ' '{print $2}')
    read -r min_rtt avg_rtt max_rtt stddev <<<$(echo $rtt_values | awk -F'[/ ]' '{print $1" "$2" "$3" "$4}')

    echo $min_rtt $avg_rtt $max_rtt $stddev

    # Append the index, CPU events/s, memory operations/s and fileio results to the CSV file
    echo "$i,$cpu_events_per_second,$memory_operations_per_second,$rndrw_reads_per_second,$rndrw_read_mibs,$rndrw_writes_per_second,$rndrw_written_mibs,$rndrw_fsyncs_per_second,$rndrd_reads_per_second,$rndrd_read_mibs,$rndwr_writes_per_second,$rndwr_written_mibs,$rndwr_fsyncs_per_second,$seqrd_reads_per_second,$seqrd_read_mibs,$seqwr_writes_per_second,$seqwr_written_mibs,$seqwr_fsyncs_per_second,$seqrewr_writes_per_second,$seqrewr_written_mibs,$seqrewr_fsyncs_per_second,$troughput_gbit_per_second,$min_rtt,$avg_rtt,$max_rtt,$stddev" >> $csv_file
done

# Remove the base container
lxc-snapshot --name base -d snap0
lxc-destroy --name base