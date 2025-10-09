# Netclab chart

Helm chart for automating the deployment of virtual network topologies on Kubernetes using Pods with multiple interfaces.
It leverages the [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) plugin and renders the required Kubernetes resources (e.g., ConfigMaps, Pods, NetworkAttachmentDefinitions) from a structured YAML-based topology definition.
<br/>
Use it to quickly bring up containerized network labs for testing, automation, development, and education — all within your cluster.


## Use Cases

This chart enables rapid deployment of containerized network topologies on Kubernetes. Key use cases include:
- **Network design validation**: Test high- and low-level design (HLD/LLD) configurations and device behavior before committing to a final design.
- **Test automation**: Develop and verify automation scripts for traffic or protocol generators/analyzers (e.g., IxNetwork APIs, OTG) — effectively unit-testing your test logic.
- **Image validation**: Validate new versions of network operating systems (NOS), whether virtual or hardware-aligned, to ensure feature support and functionality.
- **Training & certification prep**: Practice CLI, protocols, and topologies in a safe, repeatable lab — ideal for students and professionals preparing for vendor certifications.


## Prerequisites

Before installing Netclab Chart, ensure the following are present:

- [docker](https://docs.docker.com/engine/install/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [helm](https://helm.sh/docs/intro/install/)


## Installation

- Kind cluster:
```bash
kind create cluster --name netclab
```

- CNI bridge plugin:
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

- Add helm repo for netclab chart:
```bash
helm repo add netclab https://mbakalarski.github.io/netclab-chart
helm repo update
```


## Example topology
```bash
git clone https://github.com/mbakalarski/netclab-chart.git ; cd netclab-chart
```

```
+--------+
| h01    |
|        |
|    e1  |
+--------+
    |
    b2
    |
+-----------+          +-----------+
| e1-2      |          | srl02 or  |
|           |          | frr02     |
|           |          |           |
|       e1-1| -- b1 -- | e1-1      |
|           |          |           |
|           |          |           |
| srl01 or  |          |           |
| frr01     |          |     e1-2  |
+-----------+          +-----------+
                              |
                              b3
                              |
                         +--------+
                         |     e1 |
                         |        |
                         | h02    |
                         +--------+
```

### Follow the instructions for **SRLinux** or **FRRouting**

<details>
<summary>SRLinux details</summary>
<br/>

- Start nodes:
  ```bash
  helm install netclab netclab/netclab --values examples/topology-srlinux.yaml
  kubectl get pod -o wide
  ```

- Configure the nodes (repeat if they're not ready yet):
  ```bash
  kubectl cp ./examples/srl01.cfg srl01:srl01.cfg
  kubectl exec srl01 -- bash -c 'sr_cli --candidate-mode --commit-at-end < /srl01.cfg'

  kubectl cp ./examples/srl02.cfg srl02:srl02.cfg
  kubectl exec srl02 -- bash -c 'sr_cli --candidate-mode --commit-at-end < /srl02.cfg'

  kubectl exec h01 -- ip address replace 172.20.0.2/24 dev e1
  kubectl exec h01 -- ip route replace 172.30.0.0/24 via 172.20.0.1
  
  kubectl exec h02 -- ip address replace 172.30.0.2/24 dev e1
  kubectl exec h02 -- ip route replace 172.20.0.0/24 via 172.30.0.1
  ```

- Test (convergence may take time):
  ```bash
  kubectl exec h01 -- ping 172.30.0.2 -I 172.20.0.2
  ```

- Remove topology
  ```bash
  helm uninstall netclab
  ```
</details>

<details>
<summary>FRRouting details</summary>
<br/>

- Start nodes:
  ```bash
  helm install netclab netclab/netclab --values examples/topology-frrouting.yaml
  kubectl get pod -o wide
  ```

- Configure the nodes (repeat if they're not ready yet):
  ```bash
  kubectl exec frr01 -- ip addr add 10.0.0.1/32 dev lo
  kubectl exec frr01 -- ip addr add 10.0.1.1/24 dev e1-1
  kubectl exec frr01 -- ip addr add 172.20.0.1/24 dev e1-2
  kubectl exec frr01 -- touch /etc/frr/vtysh.conf
  kubectl exec frr01 -- sed -i -e 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
  kubectl exec frr01 -- /usr/lib/frr/frrinit.sh start
  kubectl cp ./examples/frr01.cfg frr01:/frr01.cfg
  kubectl exec frr01 -- vtysh -f /frr01.cfg
  
  kubectl exec frr02 -- ip addr add 10.0.0.2/32 dev lo
  kubectl exec frr02 -- ip addr add 10.0.1.2/24 dev e1-1
  kubectl exec frr02 -- ip addr add 172.30.0.1/24 dev e1-2
  kubectl exec frr02 -- touch /etc/frr/vtysh.conf
  kubectl exec frr02 -- sed -i -e 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
  kubectl exec frr02 -- /usr/lib/frr/frrinit.sh start
  kubectl cp ./examples/frr02.cfg frr02:/frr02.cfg
  kubectl exec frr02 -- vtysh -f /frr02.cfg
  
  kubectl exec h01 -- ip address replace 172.20.0.2/24 dev e1
  kubectl exec h01 -- ip route replace 172.30.0.0/24 via 172.20.0.1
  
  kubectl exec h02 -- ip address replace 172.30.0.2/24 dev e1
  kubectl exec h02 -- ip route replace 172.20.0.0/24 via 172.30.0.1
  ```

- Test (convergence may take time):
  ```bash
  kubectl exec h01 -- ping 172.30.0.2 -I 172.20.0.2
  ```

- Remove topology
  ```bash
  helm uninstall netclab
  ```
</details>

## Future Plans

- Add support for additional containerized or virtualized routers
- Replace static Helm templates with dynamic controller logic
- Define a CRD for Topology to enable programmable lab descriptions


## Contributing

Feel free to open issues or submit PRs on:
https://github.com/mbakalarski/netclab-chart
