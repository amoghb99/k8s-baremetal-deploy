# k8s-baremetal-deploy

A complete, production-ready **bare-metal Kubernetes deployment framework**, structured into clear phases, with scripts, templates, and documentation for building a cluster from scratch using **Kubespray**, **Longhorn**, **MetalLB**, **Ingress**, **HAProxy**, and post-install hardening.

This repository is designed to be **modular, repeatable, and fully automated**, while remaining transparent and customizable.

---

# 📁 Repository Structure

```
k8s-baremetal-deploy/
├── docs/
│   └── ip-plan.md
├── 01-machine-prep/
│   ├── scripts/
│   └── templates/
├── 02-kubespray/
│   ├── inventory/
│   └── cluster-config/
├── 03-longhorn/
├── 04-metallb/
├── 05-ingress/
├── 06-proxy/
│   └── haproxy-config/
├── 07-post-install/
└── Makefile
```

Each phase contains:

* A **README document** (Canvas-generated)
* **Scripts** to automate tasks
* **Templates** for configuration files
* **Step-by-step procedures** and explanation of commands
* **Validation checklists**

---

# 🚀 Deployment Phases

### **Phase 01 — Machine Preparation**

Prepare all nodes for Kubernetes.

* System updates
* SSH setup
* Swap disable
* Kernel modules
* sysctl tuning
* Connectivity validation

### **Phase 02 — Kubespray Setup**

Deploy Kubernetes using Kubespray.

* Clone kubespray
* Install dependencies
* Configure inventory
* Run Ansible playbook
* Retrieve kubeconfig

### **Phase 03 — Longhorn Storage**

Install Longhorn distributed block storage.

* Helm install
* StorageClass setup
* Node disk configuration

### **Phase 04 — MetalLB**

Enable LoadBalancer services in bare-metal.

* Install MetalLB
* Configure IPAddressPool
* Create L2Advertisement

### **Phase 05 — Ingress Controller**

Install NGINX or Traefik ingress.

* Helm deployment
* Assign MetalLB IP
* Example ingress resources

### **Phase 06 — External Proxy / HA Load Balancer**

HAProxy-based TCP load balancer for port 6443 and ingress.

* HAProxy configuration
* (Optional) Keepalived VIP floating IP

### **Phase 07 — Post-Install Hardening & Monitoring**

Secure and observe your cluster.

* cert-manager + issuers
* Prometheus + Alertmanager
* Fluent Bit (optional)
* RBAC examples
* NetworkPolicies
* ETCD backup strategy

---

# 🧭 How to Use This Repository

## 1️⃣ Start With the IP Plan

Edit:

```
docs/ip-plan.md
```

Define:

* Node hostnames
* Node IP addresses
* MetalLB address pools
* VIPs (if HAProxy/Keepalived)

## 2️⃣ Follow the Phases in Order

Run each phase sequentially:

```
cd 01-machine-prep
# run scripts and follow README
```

Each phase produces a ready-to-apply Kubernetes component.

## 3️⃣ Use the Makefile (Optional)

Useful shortcuts (customizable):

* `make prep`
* `make deploy`
* `make reset`

---

# 🛠️ Requirements

* Ubuntu Server 20.04+ or Debian-based OS
* SSH access between nodes
* Minimum 3 nodes (2 control-plane recommended)
* Python3 + Ansible for control machine
* At least 8GB RAM per node for full feature deployment

---

# 📌 Design Goals

* **Bare-metal optimized**: Works without cloud providers
* **Modular**: Each phase is independent and reusable
* **Auditable**: Every command documented and explained
* **Automated**: Scripts available for repeat deployments
* **Extensible**: Add-on services included (cert-manager, monitoring, etc.)

---

# 🧪 Validation

After completing all phases, validate:

```
kubectl get nodes -o wide
kubectl get pods -A
kubectl get svc -A
```

Ingress → test example app
Longhorn → test volume
MetalLB → verify LoadBalancer IP assignment
HAProxy → test VIP high availability

---

# 🙌 Contributing

This project is fully modular—feel free to improve documents, scripts, and Helm configs.

---

# 📄 License

MIT License — free to use, modify, and distribute.
