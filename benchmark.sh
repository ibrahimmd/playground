#!/bin/bash


source ./lib.sh

function init() {
    log "INFO" "doing init"
}

function preflight_checks() {

    log "INFO" "preflight checks"

    # FIXME: not following DRY principle
    ok=$(cmd_exists kubectl)    ; [ $ok -eq 0 ] || log "ERROR" "kubectl command does not exist"
    ok=$(cmd_exists nc)         ; [ $ok -eq 0 ] || log "ERROR" "nc command does not exist"    
    ok=$(cmd_exists ab)         ; [ $ok -eq 0 ] || log "ERROR" "ab command does not exist"        
    ok=$(cmd_exists jq)         ; [ $ok -eq 0 ] || log "ERROR" "jq command does not exist"            
}    

function start_k8s_port_forward() {
    local svc_name=$1
    local local_port=$2
    local remote_port=$3
    local namespace=$4

    # log "INFO" "going to port forward nginx ingress port"

    # FIXME: we are assuming that the local port is not currently in use by another process

    # Start port forwarding in the background
    # without "> /dev/null 2>&1", function will hang as kubectl will keep sending output
    kubectl port-forward svc/${svc_name} ${local_port}:${remote_port} -n ${namespace} > /dev/null 2>&1 &

    # Capture the process ID of the port forwarding
    local port_forward_pid=$!

    # wait till forwarded port is reachable
    # log "INFO" "waiting for port to be up"
    while ! nc -vz localhost $local_port  > /dev/null 2>&1 ; do
	    sleep 1
	done

    # Output the process ID for potential future use
    echo "$port_forward_pid"
}

# Function to stop port forwarding
function stop_k8s_port_forward() {
    local port_forward_pid=$1

    log "INFO" "killing port forward background process"

    # kill the port forwarding process
    kill $port_forward_pid
}


function promql_metrics() {

    log "INFO" "pulling nginx metrics"

    # FIXME: we are not validating if we are getting any data
    v_avg_requests=$(curl 'http://localhost:8080/api/v1/query?query=rate(nginx_ingress_controller_nginx_process_requests_total[1m])' -g -s | jq -r '.data.result[0].value[1]')
    v_avg_memory=$(curl 'http://localhost:8080/api/v1/query?query=avg_over_time(container_memory_usage_bytes{namespace="nginx-ingress",container="controller"}[1m])' -g -s | jq -r '.data.result[0].value[1]')
    v_avg_cpu=$(curl 'http://localhost:8080/api/v1/query' --get --data-urlencode 'query=1-rate(container_cpu_usage_seconds_total{namespace="nginx-ingress",container="controller"}[1m])' -s | jq -r '.data.result[0].value[1]')

    log "INFO" "writing metrics to metrics.csv"
    printf "%s,%s,%s\n" ${v_avg_requests} ${v_avg_memory} ${v_avg_cpu} > metrics.csv
}

function main() {    
    
    init
    preflight_checks
    
    log "INFO" "going to port forward nginx ingress port"
    port_forward_pid=$(start_k8s_port_forward ingress-nginx-controller 8080 80 nginx-ingress)

    log "INFO" "starting benchmark for /foo"
    ab -n 100 -c 10 http://localhost:8080/foo

    log "INFO" "starting benchmark for /bar"
    ab -n 100 -c 10 http://localhost:8080/bar

    sleep 5

    promql_metrics

    stop_k8s_port_forward $port_forward_pid
}


main