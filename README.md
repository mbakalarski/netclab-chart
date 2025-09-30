# netclab-chart

**netclab-chart**  is a Helm chart that deploys network topologies onto Kubernetes.
It leverages [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) to support multi-interface containers and renders the required Kubernetes resources (e.g., ConfigMaps, Pods, NetworkAttachmentDefinitions) from a structured YAML-based topology definition.
<br>
Use it to quickly bring up containerized network labs for testing, automation, development, and education — all within your cluster.


## Use Cases

**netclab-chart** enables rapid deployment of containerized network topologies on Kubernetes. Key use cases include:
- **Network design validation**: Validate HLD/LLD configurations and device behaviors before committing designs.
- **Test automation**: Develop and verify automation scripts for traffic/protocol generators or analyzers (e.g., APIs of IxNetwork) — effectively unit testing your test logic.
- **Image validation**: Test new versions of NOS (virtual or HW-aligned) to verify feature support and functionality.
- **Training & certification prep**: Practice CLI, protocols, and topologies in a safe, repeatable lab — ideal for students and professionals preparing for vendor certifications.

Have a use case we didn’t list? Open an issue or share your ideas — contributions are welcome!

## Prerequisites

Before installing Netclab Chart, ensure the following are present:

- [docker](https://docs.docker.com/engine/install/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [helm](https://helm.sh/docs/intro/install/)


## Installation

- Kind cluster
```bash
kind create cluster --name netclab
```

- CNI Network bridge plugin:
```bash
docker exec netclab-control-plane bash -c \
'curl -L https://github.com/containernetworking/plugins/releases/download/v1.8.0/cni-plugins-linux-amd64-v1.8.0.tgz \
| tar -xz -C /opt/cni/bin ./bridge'
```

- Multus CNI plugin:
```bash
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml
kubectl -n kube-system wait --for=jsonpath='{.status.numberReady}'=1 --timeout=5m daemonset.apps/kube-multus-ds
```

- Netclab Chart:
```bash
helm repo add netclab https://mbakalarski.github.io/netclab-chart
helm repo update
helm install netclab netclab/netclab
```

- Wait a while and check:
```bash
kubectl get pod
```

- Check resources if PODs have been in a Pending state for too long:
```bash
kubectl describe nodes
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

- Add support for additional containerized or virtualized routers
- Replace static Helm templates with dynamic controller logic
- Define a CRD for Topology to enable programmable lab descriptions


## Contributing

Feel free to open issues or submit PRs on:
https://github.com/mbakalarski/netclab-chart
