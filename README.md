# netclab-chart

A Helm chart for deploying containerized network topologies with routers and traffic generator, using Multus CNI for multi-interface support.

---

## Chart Overview

This chart allows you to deploy lab nodes with support for advanced networking via [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni).
It renders the necessary `ConfigMap`, `Pod`, and `NetworkAttachmentDefinition` objects from structured `values.yaml`.

---

## Prerequisites

Before installing `netclab-chart`, ensure the following are present in your Kubernetes cluster:

- Helm v3.x
- Kubernetes 1.20+
- [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) installed and running

### Install Multus CNI (if not already installed)

```bash
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
```

## Installation

```bash
git clone https://github.com/mbakalarski/netclab-chart
cd netclab-chart

helm install netclab ./ --namespace netclab --create-namespace
```

## Configuration

Edit `values.yaml` to define your network.

```yaml
default_network:
  name: b0
  subnet: 10.10.0.0/24
  gateway: 10.10.0.254

topology:
  networks:
  - name: b1
  - name: b2
  - name: b3
  - name: b4
  - name: b5
  nodes:
  - name: otg
    type: ixia-c
    interfaces:
    - name: eth1
      network: b3
    - name: eth2
      network: b4
    - name: eth3
      network: b5
  - name: srl01
    type: srlinux
    memory: 2Gi
    cpu: 500m
    interfaces:
    - name: e1-1
      network: b1
    - name: e1-2
      network: b2
    - name: e1-3
      network: b3
  - name: srl02
    type: srlinux
    memory: 2Gi
    cpu: 500m
    interfaces:
    - name: e1-1
      network: b1
    - name: e1-2
      network: b2
    - name: e1-3
      network: b4
  - name: linux1
    type: linux
    interfaces:
    - name: eth1
      network: b3
  - name: linux2
    type: linux
    interfaces:
    - name: eth1
      network: b4
```

## Upgrade or Uninstall

To upgrade the release after making changes:
```bash
helm upgrade netclab ./ --namespace netclab
```

To uninstall:
```bash
helm uninstall netclab --namespace netclab
```

## Future Plans

- Replace static Helm templates with dynamic controller logic
- Define a CRD for Topology to enable programmable lab descriptions
- Add support for additional containerized router platforms

## Contributing

Feel free to open issues or submit PRs on:
https://github.com/mbakalarski/netclab-chart
