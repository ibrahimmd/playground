#!/bin/bash
KIND_K8S_VERSION=1.29.2
#INGRESS_NGINX_BRANCH=release-1.10   # don't use main/master branch as it may not be compatibe with k8s version
NGINX_INGRESS_NAMESPACE="nginx-ingress"
NGINX_INGRESS_HELM_REPO="https://kubernetes.github.io/ingress-nginx"
NGINX_INGRESS_HELM_REPO_NAME="ingress-nginx"
NGINX_INGRESS_HELM_CHART_NAME="ingress-nginx"
NGINX_INGRESS_HELM_VERSION=4.10.0
PROMETHEUS_NAMESPACE="monitoring"
PROMETHEUS_HELM_VERSION=58.2.1
LOG_LEVEL="INFO"

alias k=kubectl

function log() {
    local log_level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    local log_levels=("DEBUG" "INFO" "WARNING" "ERROR" "FATAL")

    # if [[ " ${log_levels[@]} " =~ " ${log_level} " ]]; then
    #     # Determine if the message should be printed based on log level
    #     if [[ "${log_levels[@]/$log_level/}" == "${log_levels[@]/#*/}" ]]; then
    #         # If the log level is greater than or equal to the threshold log level, print the message
    #         if [[ "${log_levels[@]/$log_level/}" == "${log_levels[@]/$LOG_LEVEL/}" ]]; then
    #             printf "[%s] [%s] %s\n" "${timestamp}" "${log_level}" "${message}"
    #         fi
    #     fi
    # else
    #     # If an invalid log level is provided, print a warning
    #     echo "[$timestamp] [WARNING] Invalid log level: $log_level"
    #     printf "[%s] [%s] %s\n" "${timestamp}" "WARNING" "Invalid log level: ${log_level}"
    # fi

    printf "[%s] %-10s %s\n" "${timestamp}" "[${log_level}]" "${message}"
}

function init() {
    log "INFO" "doing init"
}


function create_kind_cluster() {
    log "INFO" "installing kind cluster"
    # spin up kind cluster
    kind create cluster --config config/kind.yaml
}

function deploy_nginx_ingress() {
    # install nginx ingress in ingress-nginx namespace
    # k apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_NGINX_BRANCH}/deploy/static/provider/kind/deploy.yaml

    log "INFO" "deploying nginx ingress"

    kubectl create ns ${NGINX_INGRESS_NAMESPACE}
    helm repo add ${NGINX_INGRESS_HELM_REPO_NAME} ${NGINX_INGRESS_HELM_REPO}
    helm upgrade -i ${NGINX_INGRESS_HELM_CHART_NAME} ${NGINX_INGRESS_HELM_REPO_NAME}/${NGINX_INGRESS_HELM_CHART_NAME} \
        --version ${NGINX_INGRESS_HELM_VERSION} \
        -n ${NGINX_INGRESS_NAMESPACE} \
        -f config/ingress-nginx.yaml

    # wait till nginx controller is up
    kubectl rollout status deploy ingress-nginx-controller -n ${NGINX_INGRESS_NAMESPACE} -w
}

function deploy_prometheus() {
    log "INFO" "deploying prometheus"

    kubectl create ns ${PROMETHEUS_NAMESPACE}
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    # helm upgrade -i prometheus-operator-crds prometheus-community/prometheus-operator-crds -n monitoring
    # helm upgrade -i prometheus prometheus-community/prometheus \
    #     --version ${PROMETHEUS_HELM_VERSION} \
    #     -n ${PROMETHEUS_NAMESPACE} \
    #     -f config/prometheus.yaml

    helm upgrade -i prometheus prometheus-community/kube-prometheus-stack \
        --version ${PROMETHEUS_HELM_VERSION} \
        -n ${PROMETHEUS_NAMESPACE} \
        -f config/kube-prometheus-stack.yaml

}

function deploy_app(){
    log "INFO" "deploying app"
    kubectl apply -f config/app.yaml
}

function deploy_servicemonitors(){
    log "INFO" "deploying servicemonitors"
    kubectl apply -f config/prometheus-nginx-servicemonitor.yaml
}


init
create_kind_cluster
deploy_nginx_ingress
deploy_prometheus
deploy_app
deploy_servicemonitors