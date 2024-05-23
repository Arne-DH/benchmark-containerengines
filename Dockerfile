# Use the latest version of Debian as the base image
FROM debian:latest

# Update the system and install sysbench
RUN apt-get update && apt-get install -y sysbench && apt-get install iperf3 -y && apt-get install -y iputils-ping
