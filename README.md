[![GitHub Repo stars](https://img.shields.io/github/stars/mbakalarski/netclab-chart?style=for-the-badge&color=CFB002)](https://github.com/mbakalarski/netclab-chart)
[![GitHub Downloads](https://img.shields.io/github/downloads/mbakalarski/netclab-chart/total?style=for-the-badge&label=HELM%20CHART%20DOWNLOADS&color=f200ff)](https://github.com/mbakalarski/netclab-chart/releases)
[![GitHub Release](https://img.shields.io/github/v/release/mbakalarski/netclab-chart?style=for-the-badge&color=007EC6)](https://github.com/mbakalarski/netclab-chart/releases/latest)
[![GitHub Issues](https://img.shields.io/github/issues/mbakalarski/netclab-chart?style=for-the-badge&color=FF6F00)](https://github.com/mbakalarski/netclab-chart/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/mbakalarski/netclab-chart?style=for-the-badge&color=44CC11)](https://github.com/mbakalarski/netclab-chart/pulls)

<br>

## ❓ What is this?
Helm chart for automating the deployment of virtual network topologies on Kubernetes using Pods with multiple interfaces.
It leverages the [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) plugin and renders the required Kubernetes resources (e.g., ConfigMaps, Pods, NetworkAttachmentDefinitions) from a structured YAML-based topology definition.
<br/>
Use it to quickly bring up containerized network labs for testing, automation, development, and education — all within your cluster.


## ⚙️ Use cases
This chart enables rapid deployment of containerized network topologies on Kubernetes. Key use cases include:
- **Network design validation**: Test high- and low-level design (HLD/LLD) configurations and device behavior before committing to a final design.
- **Test automation**: Develop and verify automation scripts for traffic or protocol generators/analyzers (e.g., IxNetwork APIs, OTG) — effectively unit-testing your test logic.
- **Image validation**: Validate new versions of network operating systems (NOS), whether virtual or hardware-aligned, to ensure feature support and functionality.
- **Training & certification prep**: Practice CLI, protocols, and topologies in a safe, repeatable lab — ideal for students and professionals preparing for vendor certifications.


## 📦 Prerequisites
Before installing Netclab Chart, ensure the following are present:

- [docker](https://docs.docker.com/engine/install/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [helm](https://helm.sh/docs/intro/install/)


## 🚀 Installation

- Kind cluster:
```bash
kind create cluster --name netclab
```

- CNI plugins:
```bash
docker exec netclab-control-plane bash -c \
'curl -L https://github.com/containernetworking/plugins/releases/download/v1.8.0/cni-plugins-linux-amd64-v1.8.0.tgz \
| tar -xz -C /opt/cni/bin ./bridge ./host-device'
```

- Multus plugin:
```bash
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml
kubectl -n kube-system wait --for=jsonpath='{.status.numberReady}'=1 --timeout=5m daemonset.apps/kube-multus-ds
```

- Add helm repo for netclab chart:
```bash
helm repo add netclab https://mbakalarski.github.io/netclab-chart
helm repo update
```


## 🧩 Usage

After installation, you can manage your topology using the YAML file.
Pods will be created according to the topology definition.

> **Note:**<br>
> Node and network names must be valid Kubernetes resource names and also acceptable as Linux interface names.<br>
> Avoid uppercase letters, underscores, or special characters.<br>
> For SR Linux nodes, interface names in the YAML configuration must follow the format e1-x (for example, e1-1, e1-2, etc.).

Configuration options are documented in the table below.
You can override these values in your own file.

| Parameter                | Description                                                  | Defaults                           |
| ------------------------ | -------------------------------------------------------------| -----------------------------------|
| `topology.networks.type` | Type of connection between nodes. Can be `bridge` or `veth`. | `veth`                             |
| `topology.nodes.type`    | Type of node. Can be: `srlinux`, `frrouting`, `linux`        |                                    |
| `topology.nodes.image`   | Container images used for topology nodes.                    | `ghcr.io/nokia/srlinux:latest`<br>`quay.io/frrouting/frr:8.4.7`<br>`bash:latest` |
| `topology.nodes.memory`  | Memory allocation per node type.                             | srlinux: `4Gi`<br>frr: `512Mi`<br>linux: `200Mi` |
| `topology.nodes.cpu`     | CPU allocation per node type.                                | srlinux: `2000m`<br>frr: `500m`<br>linux: `200m` |


## 🧱 Example topology
```bash
git clone https://github.com/mbakalarski/netclab-chart.git && cd netclab-chart
```

```console
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

### Follow instructions for **SRLinux** or/and **FRRouting**

> **Note:** The topologies are independent and can run in separate Kubernetes namespaces.


<details>
<summary>SRLinux details</summary>

- Start nodes:
  ```bash
  helm install dc1 netclab/netclab --values ./examples/topology-srlinux.yaml --namespace dc1-ns --create-namespace
  kubectl config set-context --current --namespace dc1-ns
  ```
  
  ```bash
  kubectl get pod
  ```

  ```bash
  NAME                 READY   STATUS    RESTARTS   AGE
  h01                  1/1     Running   0          12s
  h02                  1/1     Running   0          12s
  srl01                1/1     Running   0          12s
  srl02                1/1     Running   0          12s
  ```

- Configure nodes (repeat if they're not ready yet):
  ```bash
  kubectl exec h01 -- ip address replace 172.20.0.2/24 dev e1
  kubectl exec h01 -- ip route replace 172.30.0.0/24 via 172.20.0.1

  kubectl exec h02 -- ip address replace 172.30.0.2/24 dev e1
  kubectl exec h02 -- ip route replace 172.20.0.0/24 via 172.30.0.1

  kubectl cp ./examples/srl01.cfg srl01:/srl01.cfg
  kubectl exec srl01 -- bash -c 'sr_cli --candidate-mode --commit-at-end < /srl01.cfg'

  kubectl cp ./examples/srl02.cfg srl02:/srl02.cfg
  kubectl exec srl02 -- bash -c 'sr_cli --candidate-mode --commit-at-end < /srl02.cfg'
  ```

  ```bash
  All changes have been committed. Leaving candidate mode.
  All changes have been committed. Leaving candidate mode.
  ```

- Test (convergence may take time):
  ```bash
  kubectl exec h01 -- ping 172.30.0.2 -I 172.20.0.2
  ```

- LLDP neighbor information:
  ```bash
  kubectl exec srl01 -- sr_cli show system lldp neighbor
  ```

  ```bash
  +--------------+-------------------+----------------------+---------------------+------------------------+----------------------+---------------+
  |     Name     |     Neighbor      | Neighbor System Name | Neighbor Chassis ID | Neighbor First Message | Neighbor Last Update | Neighbor Port |
  +==============+===================+======================+=====================+========================+======================+===============+
  | ethernet-1/1 | 00:01:03:FF:00:00 | srl02                | 00:01:03:FF:00:00   | 47 seconds ago         | 24 seconds ago       | ethernet-1/1  |
  +--------------+-------------------+----------------------+---------------------+------------------------+----------------------+---------------+
  ```
</details>


<details>
<summary>FRRouting details</summary>

- Start nodes:
  ```bash
  kubectl config set-context --current --namespace default
  helm install dc2 netclab/netclab --values examples/topology-frrouting.yaml
  ```

  ```bash
  kubectl get pod
  ```

  ```bash
  NAME               READY   STATUS    RESTARTS   AGE
  frr01              1/1     Running   0          6s
  frr02              1/1     Running   0          6s
  h01                1/1     Running   0          6s
  h02                1/1     Running   0          6s
  ```

- Configure nodes (repeat if they're not ready yet):
  ```bash
  kubectl exec h01 -- ip address replace 172.20.0.2/24 dev e1
  kubectl exec h01 -- ip route replace 172.30.0.0/24 via 172.20.0.1
  
  kubectl exec h02 -- ip address replace 172.30.0.2/24 dev e1
  kubectl exec h02 -- ip route replace 172.20.0.0/24 via 172.30.0.1
  
  kubectl exec frr01 -- ip address add 10.0.0.1/32 dev lo
  kubectl exec frr01 -- ip address replace 10.0.1.1/24 dev e1-1
  kubectl exec frr01 -- ip address replace 172.20.0.1/24 dev e1-2
  kubectl exec frr01 -- touch /etc/frr/vtysh.conf
  kubectl exec frr01 -- sed -i -e 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
  kubectl exec frr01 -- /usr/lib/frr/frrinit.sh start
  kubectl cp ./examples/frr01.cfg frr01:/frr01.cfg
  kubectl exec frr01 -- vtysh -f /frr01.cfg
  
  kubectl exec frr02 -- ip address add 10.0.0.2/32 dev lo
  kubectl exec frr02 -- ip address replace 10.0.1.2/24 dev e1-1
  kubectl exec frr02 -- ip address replace 172.30.0.1/24 dev e1-2
  kubectl exec frr02 -- touch /etc/frr/vtysh.conf
  kubectl exec frr02 -- sed -i -e 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
  kubectl exec frr02 -- /usr/lib/frr/frrinit.sh start
  kubectl cp ./examples/frr02.cfg frr02:/frr02.cfg
  kubectl exec frr02 -- vtysh -f /frr02.cfg
  ```

  ```bash
  Starting watchfrr with command: '  /usr/lib/frr/watchfrr  -d  -F traditional   zebra bgpd staticd'
  Started watchfrr
  Starting watchfrr with command: '  /usr/lib/frr/watchfrr  -d  -F traditional   zebra bgpd staticd'
  Started watchfrr
  ```

- Test (convergence may take time):
  ```bash
  kubectl exec h01 -- ping 172.30.0.2 -I 172.20.0.2
  ```
</details>

<details>
<summary>Uninstall topologies</summary>

- dc1:
  ```bash
  helm uninstall dc1 --namespace dc1-ns
  kubectl delete ns dc1-ns
  ```
- dc2:
  ```bash
  helm uninstall dc2 --namespace default
  ```
- reset default context:
  ```
  kubectl config set-context --current --namespace default
  ```
</details>


## 🧭 Future Plans

- Add support for additional containerized or virtualized routers
- Replace static Helm templates with dynamic controller logic
- Define a CRD for Topology to enable programmable lab descriptions


## 🤝 Contributing

Found an issue or have an idea?
Open an issue or submit a PR at: <br>
👉 [https://github.com/mbakalarski/netclab-chart](https://github.com/mbakalarski/netclab-chart)
