#!/bin/bash

function start_k8s_port_forward() {
    local svc_name=$1
    local local_port=$2
    local remote_port=$3
    local namespace=$4

    # Start port forwarding in the background
    # without "> /dev/null 2>&1", function will hang as kubectl will keep sending output
    kubectl port-forward svc/${svc_name} ${local_port}:${remote_port} -n ${namespace} > /dev/null 2>&1 &

    # Capture the process ID of the port forwarding
    local port_forward_pid=$!

    # Sleep for a short duration to allow port forwarding to start
    sleep 2

    # Output the process ID for potential future use
    echo "$port_forward_pid"
}

# Function to stop port forwarding
function stop_k8s_port_forward() {
    local port_forward_pid=$1

    # Kill the port forwarding process
    kill $port_forward_pid

    echo "Port forwarding stopped"
}

function main() {
    echo going to port forward
    port_forward_pid=$(start_k8s_port_forward ingress-nginx-controller 8080 80 nginx-ingress)

    echo starting
    ab -n 500 -c 10 http://localhost:8080/foo
    ab -n 500 -c 10 http://localhost:8080/bar

    # stop_k8s_port_forward $port_forward_pid
}

main