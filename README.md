# netclab-chart

**netclab** is a lightweight, Kubernetes-based framework for defining and deploying network labs and topologies.<br>
It can be used for infrastructure testing, protocol validation, and CI/CD workflows involving complex network simulations, using Multus CNI for multi-interface support.

[netclab-chart](https://github.com/mbakalarski/netclab-chart) provides a Helm chart for deploying netclab-defined labs onto Kubernetes clusters easily using Helm.<br> It renders the necessary ConfigMap, Pod, and NetworkAttachmentDefinition resources from a structured YAML file and allows the deployment of lab routers, hosts, and traffic/protocol generators.

There are related repos:
- [netcloud](https://github.com/mbakalarski/netclab): Early steps toward provisioning a Kubernetes environment for netclab and generating manifest files for different router platforms.
- [netclab-examples](https://github.com/mbakalarski/netclab-examples): Example topologies and automated network tests using `pytest`.


## Prerequisites

Before installing `netclab-chart`, ensure the following are present:

- Kubernetes with [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) installed and running
- [Helm](https://helm.sh/docs/intro/install/)

### Install Multus CNI (if not already installed)

```bash
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
```

## Installation

```bash
helm search hub netclab --list-repo-url
helm repo add netclab https://mbakalarski.github.io/netclab-chart
helm repo update
helm search repo netclab
helm install netclab netclab/netclab
```

## Configuration

Define you network, for example:
<br>

```mermaid
flowchart LR
  OTG --b3--- SR1

  subgraph SUT
    direction LR
    SR1 --b1--- SR2
    SR1 --b2--- SR2
  end

  OTG --b4--- SR2
  OTG --b5--- SR2
```

<br>

```yaml
# mytopology.yaml

topology:
  default_network:        # to access nodes
    name: b0
    subnet: 10.10.0.0/24
    gateway: 10.10.0.254
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
    interfaces:
    - name: e1-1
      network: b1
    - name: e1-2
      network: b2
    - name: e1-3
      network: b3
  - name: srl02
    type: srlinux
    memory: 2Gi           # to limit resources; chart has defaults
    cpu: 500m
    interfaces:
    - name: e1-1
      network: b1
    - name: e1-2
      network: b2
    - name: e1-3
      network: b4
    - name: e1-4
      network: b5
```


```bash
helm uninstall netclab
helm install netclab netclab/netclab --values mytopology.yaml
```


## Future Plans

- Replace static Helm templates with dynamic controller logic
- Define a CRD for Topology to enable programmable lab descriptions
- Add support for additional containerized or virtualized routers
- Add Support for multi-node cluster


## Contributing

Feel free to open issues or submit PRs on:
https://github.com/mbakalarski/netclab-chart
