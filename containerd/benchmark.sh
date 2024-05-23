#!/bin/bash

# Check if the directories exist, if not create them
if [ ! -d "../processing/results" ]; then
  mkdir -p "../processing/results"
fi

if [ ! -d "raw" ]; then
  mkdir "raw"
fi

# Docker image name
image="arnedh/dockerbench"

# Import commands
source ../commands.txt

# Assign and create the CSV file
csv_file="../processing/results/resultsContainerd.csv"
touch $csv_file

# Write header into results
echo "Index,CPU_Events/s,Memory_Operations/s,rndrw_Reads/s,rndrw_Read_MiB/s,rndrw_Writes/s,rndrw_Written_MiB/s,rndrw_Fsyncs/s,rndrd_Reads/s,rndrd_Read_MiB/s,rndwr_Writes/s,rndwr_Written_MiB/s,rndwr_Fsyncs/s,seqrd_Reads/s,seqrd_Read_MiB/s,seqwr_Writes/s,seqwr_Written_MiB/s,seqwr_Fsyncs/s,seqrewr_Writes/s,seqrewr_Written_MiB/s,seqrewr_Fsyncs/s,Sender_troughput_Gb/s,Minimum_rtt,Average_rtt,Max_rtt,mdev" > $csv_file

# Loop Test
for i in {0..9}
   do
      # Create and start the Docker container for CPU test
      docker run --name=dock_cpu_$i $image $cpu_sysbench_command > raw/dockerSys_cpu_$i.txt 
      echo "Docker CPU benchmark-$i done"
      # Delete the container
      docker rm dock_cpu_$i > /dev/null 2>&1

      # Create and start the Docker container for memory test
      docker run --name=dock_mem_$i $image $memory_sysbench_command > raw/dockerSys_mem_$i.txt 
      echo "Docker Memory benchmark-$i done"
      # Delete the container
      docker rm dock_mem_$i > /dev/null 2>&1

      # Create and start the Docker container for rndrw test (1 thread)
      docker run --name=dock_rndrw_$i $image /bin/bash -c "eval $rndrw_sysbench_command" > raw/dockerSys_rndrw_$i.txt 
      echo "Docker Random read/write benchmark-$i done"
      # Delete the container
      docker rm dock_rndrw_$i > /dev/null 2>&1

      # Create and start the Docker container for rndrd test (1 thread)
      docker run --name=dock_rndrd_$i $image /bin/bash -c "eval $rndrd_sysbench_command" > raw/dockerSys_rndrd_$i.txt 
      echo "Docker Random read benchmark-$i done"
      # Delete the container
      docker rm dock_rndrd_$i > /dev/null 2>&1

      # Create and start the Docker container for rndwr test (1 thread)
      docker run --name=dock_rndwr_$i $image /bin/bash -c "eval $rndwr_sysbench_command" > raw/dockerSys_rndwr_$i.txt 
      echo "Docker Random write benchmark-$i done"
      # Delete the container
      docker rm dock_rndwr_$i > /dev/null 2>&1  

      # Create and start the Docker container for seqrd test (1 thread)
      docker run --name=dock_seqrd_$i $image /bin/bash -c "eval $seqrd_sysbench_command" > raw/dockerSys_seqrd_$i.txt  # time 300s
      echo "Docker Sequential read benchmark-$i done"
      # Delete the container
      docker rm dock_seqrd_$i > /dev/null 2>&1

      # Create and start the Docker container for seqwr test (1 thread)
      docker run --name=dock_seqwr_$i $image /bin/bash -c "eval $seqwr_sysbench_command" > raw/dockerSys_seqwr_$i.txt  # time 300s
      echo "Docker Sequential write benchmark-$i done"
      # Delete the container
      docker rm dock_seqwr_$i > /dev/null 2>&1

      #Create and start the Docker container for seqrewr test (1 thread)
      docker run --name=dock_seqrewr_$i $image /bin/bash -c "eval $seqrewr_sysbench_command" > raw/dockerSys_seqrewr_$i.txt  # time 300s
      echo "Docker Sequential rewrite benchmark-$i done"
      # Delete the container
      docker rm dock_seqrewr_$i > /dev/null 2>&1

      # Create and start the Docker containers for troughput test
      docker run -d --name=dock_server_$i $image tail -f /dev/null > /dev/null 2>&1
      docker run -d --name=dock_client_$i $image tail -f /dev/null > /dev/null 2>&1

      # Get the needed IP address of the server
      serverIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dock_server_$i)

      # Start iperf3 Server
      docker exec -d dock_server_$i iperf3 -s

      # Run iperf3 Client
      docker exec dock_client_$i iperf3 -c $serverIP > raw/dockerIperf3_Troughput_$i.txt
      echo "Docker Network Troughput benchmark-$i done"

      # Stop the containers
      docker stop dock_server_$i > /dev/null 2>&1
      docker stop dock_client_$i > /dev/null 2>&1

      # Delete the containers
      docker rm dock_server_$i > /dev/null 2>&1
      docker rm dock_client_$i > /dev/null 2>&1

      # Create and start the Docker containers for RTT test
      docker run -d --name=dock_server_RTT_$i $image tail -f /dev/null > /dev/null 2>&1
      docker run -d --name=dock_client_RTT_$i $image tail -f /dev/null > /dev/null 2>&1

      # Get the needed IP address of the server
      serverIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dock_server_RTT_$i)

      # Perform RTT test
      docker exec dock_client_RTT_$i ping -c 5 $serverIP > raw/dockerIperf3_RTT_$i.txt # 300s
      echo "Docker Network RTT benchmark-$i done"

      # Stop the containers
      docker stop dock_client_RTT_$i > /dev/null 2>&1
      docker stop dock_server_RTT_$i > /dev/null 2>&1

      # Delete the containers
      docker rm dock_client_RTT_$i > /dev/null 2>&1
      docker rm dock_server_RTT_$i > /dev/null 2>&1

      # Parse the output to extract the events/s for CPU test
      cpu_events_per_second=$(grep "events per second:" raw/dockerSys_cpu_$i.txt | awk '{print $4}')

      # Parse the output to extract the operations/s for memory test
      memory_operations_per_second=$(grep "Total operations:" raw/dockerSys_mem_$i.txt | awk -F'(' '{print $2}' | awk -F' ' '{print $1}')

      # Parse the Random read/write results
      rndrw_reads_per_second=$(grep "reads/s:" raw/dockerSys_rndrw_$i.txt | awk '{print $2}')
      rndrw_writes_per_second=$(grep "writes/s:" raw/dockerSys_rndrw_$i.txt | awk '{print $2}')
      rndrw_fsyncs_per_second=$(grep "fsyncs/s:" raw/dockerSys_rndrw_$i.txt | awk '{print $2}')
      rndrw_read_mibs=$(grep "read, MiB/s:" raw/dockerSys_rndrw_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')
      rndrw_written_mibs=$(grep "written, MiB/s:" raw/dockerSys_rndrw_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

      # Parse the Random read result
      rndrd_reads_per_second=$(grep "reads/s:" raw/dockerSys_rndrd_$i.txt | awk '{print $2}')
      rndrd_read_mibs=$(grep "read, MiB/s:" raw/dockerSys_rndrd_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

      # Parse the Random write result
      rndwr_writes_per_second=$(grep "writes/s:" raw/dockerSys_rndwr_$i.txt | awk '{print $2}')
      rndwr_fsyncs_per_second=$(grep "fsyncs/s:" raw/dockerSys_rndwr_$i.txt | awk '{print $2}')
      rndwr_written_mibs=$(grep "written, MiB/s:" raw/dockerSys_rndwr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')
      
      # Parse the Sequential reads results
      seqrd_reads_per_second=$(grep "reads/s:" raw/dockerSys_seqrd_$i.txt | awk '{print $2}')
      seqrd_read_mibs=$(grep "read, MiB/s:" raw/dockerSys_seqrd_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

      # Parse the Sequential writes results
      seqwr_writes_per_second=$(grep "writes/s:" raw/dockerSys_seqwr_$i.txt | awk '{print $2}')
      seqwr_fsyncs_per_second=$(grep "fsyncs/s:" raw/dockerSys_seqwr_$i.txt | awk '{print $2}')
      seqwr_written_mibs=$(grep "written, MiB/s:" raw/dockerSys_seqwr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

      # Parse the Sequential rewrites results
      seqrewr_writes_per_second=$(grep "writes/s:" raw/dockerSys_seqrewr_$i.txt | awk '{print $2}')
      seqrewr_fsyncs_per_second=$(grep "fsyncs/s:" raw/dockerSys_seqrewr_$i.txt | awk '{print $2}')
      seqrewr_written_mibs=$(grep "written, MiB/s:" raw/dockerSys_seqrewr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

      # Parse the Network Throughput results
      troughput_gbit_per_second=$(grep 'sender' raw/dockerIperf3_Troughput_$i.txt | awk '{print $5}')

      # Parse the Network RTT results
      rtt_values=$(grep "rtt min/avg/max/mdev" raw/dockerIperf3_RTT_$i.txt | awk -F'= ' '{print $2}')
      read -r min_rtt avg_rtt max_rtt mdev <<<$(echo $rtt_values | awk -F'[/ ]' '{print $1" "$2" "$3" "$4}')

      # Append results to the CSV file
      echo "$i,$cpu_events_per_second,$memory_operations_per_second,$rndrw_reads_per_second,$rndrw_read_mibs,$rndrw_writes_per_second,$rndrw_written_mibs,$rndrw_fsyncs_per_second,$rndrd_reads_per_second,$rndrd_read_mibs,$rndwr_writes_per_second,$rndwr_written_mibs,$rndwr_fsyncs_per_second,$seqrd_reads_per_second,$seqrd_read_mibs,$seqwr_writes_per_second,$seqwr_written_mibs,$seqwr_fsyncs_per_second,$seqrewr_writes_per_second,$seqrewr_written_mibs,$seqrewr_fsyncs_per_second,$troughput_gbit_per_second,$min_rtt,$avg_rtt,$max_rtt,$mdev" >> $csv_file
   done