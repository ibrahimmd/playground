# playground

## Getting started

- Clone repo
- Run `deploy.sh`. This will install the kind cluster, nginx, prometheus and 2 apps
  - [kind](https://kind.sigs.k8s.io/) cluster with 1 control node and 3 worker nodes, k8s version: `v1.29.2`
  - [nginx ingress](https://github.com/kubernetes/ingress-nginx) on node with label `role=ingress`
  - [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) on node with label `role=prometheus`
  - `foo` and `bar` app using [http-echo](https://github.com/hashicorp/http-echo) on node with label `role=app`
  - Only uses `nodeSelector` and does not use `taints` / `tolerations`
- Run `benchmark.sh` to run benchmarks, pull prometheus metrics and write to file `metrics.csv` before and after running benchmarks.
  - script will expose nginx on `localhost` port `8080`
  - `foo` app url: http://localhost:8080/foo
  - `bar` app url: http://localhost:8080/bar
  - prometheus url: http://localhost:8080/graph

## Prerequisites

Binaries:
- kubectl
- kind
- docker
- helm
- nc
- ab
- curl
- jq

No process should be running on `localhost` port `8080` for benchmark to run.

This installation has been tested on:
- Mac M2
- Raspberry Pi 4 running Ubuntu 22.04


## Cleanup
- Run `cleanup.sh` to delete the kind cluster
