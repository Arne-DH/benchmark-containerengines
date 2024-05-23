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
csv_file="../processing/results/resultsCRI-O.csv"
touch $csv_file

# Write header into results
echo "Index,CPU_Events/s,Memory_Operations/s,rndrw_Reads/s,rndrw_Read_MiB/s,rndrw_Writes/s,rndrw_Written_MiB/s,rndrw_Fsyncs/s,rndrd_Reads/s,rndrd_Read_MiB/s,rndwr_Writes/s,rndwr_Written_MiB/s,rndwr_Fsyncs/s,seqrd_Reads/s,seqrd_Read_MiB/s,seqwr_Writes/s,seqwr_Written_MiB/s,seqwr_Fsyncs/s,seqrewr_Writes/s,seqrewr_Written_MiB/s,seqrewr_Fsyncs/s,Sender_troughput_Gb/s,Minimum_rtt,Average_rtt,Max_rtt,mdev" > $csv_file

for i in {0..9}
do
    # Create and start the Kubernetes pod for CPU test
    kubectl run kube-cpu-$i --image=$image_name --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-cpu-'$i'", "image": "'$image_name'", "command": ["/bin/sh", "-c", "sleep infinity"]}]}}'
    # Wait for the pod to be ready
    kubectl wait --for=condition=ready pod/kube-cpu-$i --timeout=300s
    # Run the CPU benchmark
    kubectl exec kube-cpu-$i -- bash -c "$cpu_sysbench_command" > raw/kubeSys_cpu_$i.txt
    echo "Kubernetes CPU benchmark-$i done"
    # Remove the pod
    kubectl delete pod kube-cpu-$i

    # Create and start the Kubernetes pod for memory test
    kubectl run kube-mem-$i --image=$image_name --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-mem-'$i'", "image": "'$image_name'", "command": ["/bin/sh", "-c", "sleep infinity"]}]}}'
    # Wait for the pod to be ready
    kubectl wait --for=condition=ready pod/kube-mem-$i --timeout=300s
    # Run the memory benchmark
    kubectl exec kube-mem-$i -- bash -c "$memory_sysbench_command" > raw/kubeSys_mem_$i.txt
    echo "Kubernetes Memory benchmark-$i done"
    # Remove the pod
    kubectl delete pod kube-mem-$i

    # Create and start the Kubernetes pod for rndrw test
    kubectl run kube-rndrw-$i --image=$image_name --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-rndrw-'$i'", "image": "'$image_name'", "command": ["/bin/sh", "-c", "sleep infinity"]}]}}'
    # Wait for the pod to be ready
    kubectl wait --for=condition=ready pod/kube-rndrw-$i --timeout=300s
    # Run the rndrw benchmark
    kubectl exec kube-rndrw-$i -- bash -c "eval $rndrw_sysbench_command" > raw/kubeSys_rndrw_$i.txt
    echo "Kubernetes Random read/write benchmark-$i done"
    # Remove the pod
    kubectl delete pod kube-rndrw-$i

    # Create and start the Kubernetes pod for rndrd test
    kubectl run kube-rndrd-$i --image=$image_name --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-rndrd-'$i'", "image": "'$image_name'", "command": ["/bin/sh", "-c", "sleep infinity"]}]}}'
    # Wait for the pod to be ready
    kubectl wait --for=condition=ready pod/kube-rndrd-$i --timeout=300s
    # Run the rndrd benchmark
    kubectl exec kube-rndrd-$i -- bash -c "eval $rndrd_sysbench_command" > raw/kubeSys_rndrd_$i.txt
    echo "Kubernetes Random read benchmark-$i done"
    # Remove the pod
    kubectl delete pod kube-rndrd-$i

    # Create and start the Kubernetes pod for rndwr test
    kubectl run kube-rndwr-$i --image=$image_name --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-rndwr-'$i'", "image": "'$image_name'", "command": ["/bin/sh", "-c", "sleep infinity"]}]}}'
    # Wait for the pod to be ready
    kubectl wait --for=condition=ready pod/kube-rndwr-$i --timeout=300s
    # Run the rndwr benchmark
    kubectl exec kube-rndwr-$i -- bash -c "eval $rndwr_sysbench_command" > raw/kubeSys_rndwr_$i.txt
    echo "Kubernetes Random write benchmark-$i done"
    # Remove the pod
    kubectl delete pod kube-rndwr-$i

    # Create and start the Kubernetes pod for seqrd test
    kubectl run kube-seqrd-$i --image=$image_name --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-seqrd-'$i'", "image": "'$image_name'", "command": ["/bin/sh", "-c", "sleep infinity"]}]}}'
    # Wait for the pod to be ready
    kubectl wait --for=condition=ready pod/kube-seqrd-$i --timeout=300s
    # Run the seqrd benchmark
    kubectl exec kube-seqrd-$i -- bash -c "eval $seqrd_sysbench_command" > raw/kubeSys_seqrd_$i.txt
    echo "Kubernetes Sequential read benchmark-$i done"
    # Remove the pod
    kubectl delete pod kube-seqrd-$i

    # Create and start the Kubernetes pod for seqwr test
    kubectl run kube-seqwr-$i --image=$image_name --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-seqwr-'$i'", "image": "'$image_name'", "command": ["/bin/sh", "-c", "sleep infinity"]}]}}'
    # Wait for the pod to be ready
    kubectl wait --for=condition=ready pod/kube-seqwr-$i --timeout=300s
    # Run the seqwr benchmark
    kubectl exec kube-seqwr-$i -- bash -c "eval $seqwr_sysbench_command" > raw/kubeSys_seqwr_$i.txt
    echo "Kubernetes Sequential write benchmark-$i done"
    # Remove the pod
    kubectl delete pod kube-seqwr-$i

    # Create and start the Kubernetes pod for seqrewr test
    kubectl run kube-seqrewr-$i --image=$image_name --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-seqrewr-'$i'", "image": "'$image_name'", "command": ["/bin/sh", "-c", "sleep infinity"]}]}}'
    # Wait for the pod to be ready
    kubectl wait --for=condition=ready pod/kube-seqrewr-$i --timeout=300s
    # Run the seqrewr benchmark
    kubectl exec kube-seqrewr-$i -- bash -c "eval $seqrewr_sysbench_command" > raw/kubeSys_seqrewr_$i.txt
    echo "Kubernetes Sequential rewrite benchmark-$i done"
    # Remove the pod
    kubectl delete pod kube-seqrewr-$i

    # Create and start the Kubernetes pods for network troughput test
    kubectl run kube-server-$i --image=$image_name --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-server-'$i'", "image": "'$image_name'", "command": ["/bin/sh", "-c", "sleep infinity"]}]}}'
    kubectl run kube-client-$i --image=$image_name --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-client-'$i'", "image": "'$image_name'", "command": ["/bin/sh", "-c", "sleep infinity"]}]}}'

    # Wait for the pods to be ready
    kubectl wait --for=condition=ready pod/kube-server-$i --timeout=60s
    kubectl wait --for=condition=ready pod/kube-client-$i --timeout=60s

    # Get the needed IP address of the server
    serverIP=$(kubectl get pod kube-server-$i -o=jsonpath='{.status.podIP}')

    # Start iperf3 Server
    kubectl exec kube-server-$i -- iperf3 -s > /dev/null 2>&1

    # Run iperf3 Client
    kubectl exec kube-client-$i -- iperf3 -c $serverIP > kubeIperf3_Troughput_$i.txt
    echo "Kubernetes iperf3 benchmark-$i done"

    # Remove the pods
    kubectl delete pod kube-server-$i
    kubectl delete pod kube-client-$i

    # Create and start the Kubernetes pods for rtt test
    kubectl run kube-server-rtt-$i --image=$image --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-server-rtt-'$i'", "image": "'$image'", "command": ["/bin/sh", "-c", "sleep infinity"], "securityContext": {"capabilities": {"add": ["NET_RAW"]}}}]}}'
    kubectl run kube-client-rtt-$i --image=$image --restart=Never --overrides='{"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}], "containers": [{"name": "kube-client-rtt-'$i'", "image": "'$image'", "command": ["/bin/sh", "-c", "sleep infinity"], "securityContext": {"capabilities": {"add": ["NET_RAW"]}}}]}}'


    # Wait for the pods to be ready
    kubectl wait --for=condition=ready pod/kube-server-rtt-$i --timeout=60s
    kubectl wait --for=condition=ready pod/kube-client-rtt-$i --timeout=60s

    # Get the needed IP address of the server
    serverIP=$(kubectl get pod kube-server-rtt-$i -o=jsonpath='{.status.podIP}')

    # Perform rtt test
    kubectl exec kube-client-rtt-$i -- ping -c 5 $serverIP > kubeIperf3_rtt_$i.txt
    echo "Kubernetes rtt benchmark-$i done"

    # Remove the pods
    kubectl delete pod kube-server-rtt-$i
    kubectl delete pod kube-client-rtt-$i

    # Parse the output to extract the events/s for CPU test
    cpu_events_per_second=$(grep "events per second:" raw/kubeSys_cpu_$i.txt | awk '{print $4}')

    # Parse the output to extract the operations/s for memory test
    memory_operations_per_second=$(grep "Total operations:" raw/kubeSys_mem_$i.txt | awk -F'(' '{print $2}' | awk -F' ' '{print $1}')

    # Parse the Random read/write results
    rndrw_reads_per_second=$(grep "reads/s:" raw/kubeSys_rndrw_$i.txt | awk '{print $2}')
    rndrw_writes_per_second=$(grep "writes/s:" raw/kubeSys_rndrw_$i.txt | awk '{print $2}')
    rndrw_fsyncs_per_second=$(grep "fsyncs/s:" raw/kubeSys_rndrw_$i.txt | awk '{print $2}')
    rndrw_read_mibs=$(grep "read, MiB/s:" raw/kubeSys_rndrw_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')
    rndrw_written_mibs=$(grep "written, MiB/s:" raw/kubeSys_rndrw_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Random read result
    rndrd_reads_per_second=$(grep "reads/s:" raw/kubeSys_rndrd_$i.txt | awk '{print $2}')
    rndrd_read_mibs=$(grep "read, MiB/s:" raw/kubeSys_rndrd_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Random write result
    rndwr_writes_per_second=$(grep "writes/s:" raw/kubeSys_rndwr_$i.txt | awk '{print $2}')
    rndwr_fsyncs_per_second=$(grep "fsyncs/s:" raw/kubeSys_rndwr_$i.txt | awk '{print $2}')
    rndwr_written_mibs=$(grep "written, MiB/s:" raw/kubeSys_rndwr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')
        
    # Parse the Sequential reads results
    seqrd_reads_per_second=$(grep "reads/s:" raw/kubeSys_seqrd_$i.txt | awk '{print $2}')
    seqrd_read_mibs=$(grep "read, MiB/s:" raw/kubeSys_seqrd_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Sequential writes results
    seqwr_writes_per_second=$(grep "writes/s:" raw/kubeSys_seqwr_$i.txt | awk '{print $2}')
    seqwr_fsyncs_per_second=$(grep "fsyncs/s:" raw/kubeSys_seqwr_$i.txt | awk '{print $2}')
    seqwr_written_mibs=$(grep "written, MiB/s:" raw/kubeSys_seqwr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Sequential rewrites results
    seqrewr_writes_per_second=$(grep "writes/s:" raw/kubeSys_seqrewr_$i.txt | awk '{print $2}')
    seqrewr_fsyncs_per_second=$(grep "fsyncs/s:" raw/kubeSys_seqrewr_$i.txt | awk '{print $2}')
    seqrewr_written_mibs=$(grep "written, MiB/s:" raw/kubeSys_seqrewr_$i.txt | awk -F':' '{print $2}' | awk '{print $1}')

    # Parse the Network Throughput results
    troughput_gbit_per_second=$(grep 'sender' raw/kubeIperf3_Troughput_$i.txt | awk '{print $5}')

    # Parse the Network RTT results
    rtt_values=$(grep "round-trip min/avg/max/stddev" raw/kubeIperf3_RTT_$i.txt | awk -F'= ' '{print $2}')
    read -r min_rtt avg_rtt max_rtt stddev <<<$(echo $rtt_values | awk -F'[/ ]' '{print $1" "$2" "$3" "$4}')

    echo $min_rtt $avg_rtt $max_rtt $stddev

    # Append the index, CPU events/s, memory operations/s and fileio results to the CSV file
    echo "$i,$cpu_events_per_second,$memory_operations_per_second,$rndrw_reads_per_second,$rndrw_read_mibs,$rndrw_writes_per_second,$rndrw_written_mibs,$rndrw_fsyncs_per_second,$rndrd_reads_per_second,$rndrd_read_mibs,$rndwr_writes_per_second,$rndwr_written_mibs,$rndwr_fsyncs_per_second,$seqrd_reads_per_second,$seqrd_read_mibs,$seqwr_writes_per_second,$seqwr_written_mibs,$seqwr_fsyncs_per_second,$seqrewr_writes_per_second,$seqrewr_written_mibs,$seqrewr_fsyncs_per_second,$troughput_gbit_per_second,$min_rtt,$avg_rtt,$max_rtt,$stddev" >> $csv_file

done