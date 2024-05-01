# Squid Cache Access Logging Workaround on Kubernetes

# Introduction

[squid-cache](https://www.squid-cache.org/)

Squid is started as the `root` user and it will switch to a safe user (usually `nobody` or `squid`) and group after startup.

Therefore writing access logs to a file or `stdout` as the non-root user will not work due to insufficient privileges.

For Kubernetes deployments, it's normal practice to let containers print logs to `stdout` but [we are not able to do that with Squid](https://github.com/scbunn/docker-squid/issues/5).


# Workaround

Squid [access_log](https://www.squid-cache.org/Doc/config/access_log/) configuration directive has an option to send logs to a `UDP` receiver. So we can add `socat` as an additional container that will listen on a port and print the access logs on the screen.



# Getting Started

Create a Kind Cluster

```
kind create cluster --config kind.yaml
```

Create `app` namespace

```
k create ns app
```

Deploy `squid` with `socat`

```
k apply -n app squid-cache.yaml
k rollout status deploy squid-cache -n app
```

Shell into `tmp-shell` container and run some `curl` commands
```
k exec -it -n app $(k get po -l app=tmp-shell --no-headers=true | cut -d " " -f 1) -- /bin/bash
for i in {1..10}; do curl https://ifconfig.me -x squid-cache:3128; done
```

Check the `access-log` container of the squid cache pod.
```
k logs -l app=squid-cache -c access-log -n app -f
```






