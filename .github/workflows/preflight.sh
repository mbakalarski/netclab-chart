#!/bin/bash


set -e

declare cluster_name="netclab"
declare cluster_node="${cluster_name}-control-plane"


log(){ echo; echo "$(date -Is -u) $*"; }


wait_dir_has_file(){
    local dirpath="$1"
    local filename="$2"
    local -i timeout=30
    if [[ -n ${3} ]]; then timeout=${3}; fi
    local -i c=0

    log "Test ${filename} in ${dirpath}; timeout ${timeout}"

    while [[ ${timeout} -ge 0 ]]
    do
        echo -n "."
        c=$(docker exec $cluster_node bash -c "ls -lt ${dirpath}" | grep ${filename} | wc -l)
        if [[ $c -eq 1 ]]; then break ;fi
        sleep 1
        timeout=$(($timeout-1))
    done
    echo
    docker exec $cluster_node bash -c "ls -lt ${dirpath}${filename}"
}


log "Install kubectl"
[ $(uname -m) = x86_64 ] && export os="linux/amd64"
[ $(uname -m) = aarch64 ] && export os="darwin/arm64"
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/$os/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl


log "Kind cluster ${cluster_name}"
kind delete cluster -n ${cluster_name}
kind create cluster -n ${cluster_name}
wait_dir_has_file "/etc/cni/net.d/" "10-kindnet.conflist"


log "Install Helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


unset version
version=$(basename $(curl -s -w %{redirect_url} "https://github.com/k8snetworkplumbingwg/multus-cni/releases/latest"))
log "Multus ${version}"
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml

unset timeout; timeout=5m
log "Deploying, give me ${timeout}"
kubectl -n kube-system wait --for=jsonpath='{.status.numberReady}'=1 --timeout=${timeout} daemonset.apps/kube-multus-ds

wait_dir_has_file "/etc/cni/net.d/" "00-multus.conf" 120

log "Done"
