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

source ./lib.sh

function init() {
    log "INFO" "doing init"
}

function preflight_checks() {

    log "INFO" "preflight checks"

    # FIXME: not following DRY principle
    ok=$(cmd_exists kind)    ; [ $ok -eq 0 ] || log "ERROR" "kind command does not exist"
    ok=$(cmd_exists docker)  ; [ $ok -eq 0 ] || log "ERROR" "docker command does not exist"
    ok=$(cmd_exists helm)    ; [ $ok -eq 0 ] || log "ERROR" "helm command does not exist"
    ok=$(cmd_exists kubectl) ; [ $ok -eq 0 ] || log "ERROR" "kubectl command does not exist"

}

function create_kind_cluster() {
    log "INFO" "installing kind cluster"
    # spin up kind cluster
    kind create cluster --config config/kind.yaml
}

function deploy_nginx_ingress() {
    log "INFO" "deploying nginx ingress"

    kubectl create ns ${NGINX_INGRESS_NAMESPACE}
    helm repo add ${NGINX_INGRESS_HELM_REPO_NAME} ${NGINX_INGRESS_HELM_REPO}
    helm repo update ${NGINX_INGRESS_HELM_REPO_NAME}
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
    helm repo update prometheus-community

    helm upgrade -i prometheus prometheus-community/kube-prometheus-stack \
        --version ${PROMETHEUS_HELM_VERSION} \
        -n ${PROMETHEUS_NAMESPACE} \
        -f config/kube-prometheus-stack.yaml

}

function deploy_app(){
    log "INFO" "deploying app"

    # FIXME: should be moved to helm chart
    kubectl apply -f config/app.yaml
}

function deploy_servicemonitors(){
    log "INFO" "deploying servicemonitors"
    kubectl apply -f config/prometheus-nginx-servicemonitor.yaml
}


init
preflight_checks
create_kind_cluster
deploy_nginx_ingress
deploy_prometheus
deploy_app
deploy_servicemonitors