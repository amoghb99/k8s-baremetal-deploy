# Phase 02 — Kubespray Setup

## 🎯 Goal

Deploy a full Kubernetes cluster using **Kubespray + Ansible** with a reproducible, automated, and configurable workflow.

This phase covers downloading Kubespray, preparing the inventory, installing dependencies, and running the cluster deployment.

---

# ✅ Overview Checklist

### Environment Preparation

* [ ] Install Python3 & pip
* [ ] Install Ansible & dependencies
* [ ] Clone Kubespray
* [ ] Install Kubespray Python requirements

### Inventory Setup

* [ ] Create your cluster inventory directory
* [ ] Copy sample inventory
* [ ] Update `hosts.yaml` with your nodes
* [ ] Customize group_vars (optional)

### Deployment

* [ ] Run ansible-playbook for cluster installation
* [ ] Retrieve and configure kubeconfig

### Verification

* [ ] `kubectl get nodes`
* [ ] `kubectl get pods -A`
* [ ] Cluster networking validation

---

# 🧰 1. Install Required Packages

Ensure the deployment workstation (usually your admin node or local machine) has required tools.

```bash
sudo apt update
sudo apt install -y python3 python3-pip git sshpass
```

Install Ansible:

```bash
pip3 install ansible
```

Check versions:

```bash
ansible --version
python3 --version
```

---

# 📦 2. Clone Kubespray Repository

```bash
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
```

Install Python dependencies:

```bash
pip3 install -r requirements.txt
```

---

# 🏗️ 3. Create a Custom Inventory

Kubespray provides a `sample` inventory. Copy it:

```bash
cp -rfp inventory/sample inventory/mycluster
```

Your structure now looks like:

```
inventory/
  mycluster/
    group_vars/
    host.yaml
```

---

# ✍️ 4. Edit hosts.yaml

This file defines:

* Which nodes belong to the control-plane
* Which nodes are workers
* Their SSH access configuration
* The API VIP (optional)

Example minimal `hosts.yaml`:

```yaml
all:
  hosts:
    cp1:
      ansible_host: 192.168.10.11
      ip: 192.168.10.11
      access_ip: 192.168.10.11
    cp2:
      ansible_host: 192.168.10.12
      ip: 192.168.10.12
      access_ip: 192.168.10.12
    worker1:
      ansible_host: 192.168.10.21
      ip: 192.168.10.21
      access_ip: 192.168.10.21

  children:
    kube_control_plane:
      hosts:
        cp1:
        cp2:
    kube_node:
      hosts:
        cp1:
        cp2:
        worker1:
    etcd:
      hosts:
        cp1:
        cp2:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
```

---

# ⚙️ 5. Configure group_vars (Optional but Recommended)

These settings customize your cluster.

Common files:

```
inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
inventory/mycluster/group_vars/all/all.yml
```

Recommended tweaks:

* Set container runtime to containerd
* Enable nginx-ingress addon (optional)
* Configure load balancer (HAProxy/MetalLB)

Example (container runtime selection):

```yaml
container_manager: containerd
```

---

# ▶️ 6. Run the Kubespray Deployment

From within the Kubespray root directory:

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml --become --become-user=root cluster.yml
```

Add verbose output if you want:

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml --become -vvv cluster.yml
```

Deployment duration: **10–20 minutes** depending on nodes.

---

# 📄 7. Retrieve kubeconfig

Once deployment succeeds:

```bash
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

Verify connectivity:

```bash
kubectl cluster-info
kubectl get nodes -o wide
```

Expected output:

```
NAME      STATUS   ROLES           AGE   VERSION
cp1       Ready    control-plane   1m    v1.29.x
worker1   Ready    <none>          1m    v1.29.x
```

---

# 🔍 8. Post-Deployment Validation

### Check all namespaces:

```bash
kubectl get pods -A
```

### Check CoreDNS:

```bash
kubectl rollout status deployment/coredns -n kube-system
```

### Validate networking:

```bash
kubectl run tmp --rm -i --tty --image=busybox -- sh
ping google.com
```

### Optional: Check cluster info

```bash
kubectl get cs
```

---

# 📦 Scripts Folder (02-kubespray/scripts/) — Recommended

### **deploy.sh**

Automates update, install, and run.

```bash
#!/bin/bash
set -e

cd kubespray
pip3 install -r requirements.txt
ansible-playbook -i inventory/mycluster/hosts.yaml --become cluster.yml
```

### **reset.sh**

Reset a broken cluster.

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml --become reset.yml
```

---

# 📄 Templates Folder (02-kubespray/inventory/) — Ready-to-Use

## **hosts.yaml.template**

```yaml
all:
  hosts:
    <NAME>:
      ansible_host: <IP>
      ip: <IP>
      access_ip: <IP>

  children:
    kube_control_plane:
      hosts:
        <CP_NODES>
    kube_node:
      hosts:
        <ALL_NODES>
    etcd:
      hosts:
        <ETCD_NODES>
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
```

---

# 🎉 Phase 02 Complete

Your cluster is now fully deployed using Kubespray.

You can now continue to **Phase 03 — Longhorn Storage** to enable distributed block storage for workloads.
