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


function promql_metrics() {

    echo v_1
    v_avg_requests=$(curl 'http://localhost:8080/api/v1/query?query=rate(nginx_ingress_controller_nginx_process_requests_total[1m])' -g -s | jq '.data.result[0].value[1]')
    echo v_2
    v_avg_memory=$(curl 'http://localhost:8080/api/v1/query?query=avg_over_time(container_memory_usage_bytes{namespace="nginx-ingress",container="controller"}[1m])' -g -s | jq '.data.result[0].value[1]')
    echo v_3
    v_avg_cpu=$(curl 'http://localhost:8080/api/v1/query' --get --data-urlencode 'query=1-rate(container_cpu_usage_seconds_total{namespace="nginx-ingress",container="controller"}[1m])' -s | jq '.data.result[0].value[1]')

    printf "%s,%s,%s\n" ${v_avg_requests} ${v_avg_memory} ${v_avg_cpu} > metrics.csv
}

function main() {
    echo going to port forward
    port_forward_pid=$(start_k8s_port_forward ingress-nginx-controller 8080 80 nginx-ingress)

    echo starting
    ab -n 100 -c 10 http://localhost:8080/foo
    ab -n 100 -c 10 http://localhost:8080/bar

    promql_metrics


    stop_k8s_port_forward $port_forward_pid
}


main