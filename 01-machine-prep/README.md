# Phase 01 — Machine Preparation

## 🎯 Goal

Prepare all nodes (control-plane and workers) for a clean, consistent Kubernetes installation on bare metal.

This phase ensures that every machine is configured identically and follows best practices before Kubespray deployment.

---

# ✅ Overview Checklist

### **System Setup**

* [ ] Update the OS packages
* [ ] Configure hostnames
* [ ] Update `/etc/hosts`
* [ ] Create Kubernetes admin user
* [ ] Install SSH keys for passwordless login
* [ ] Enable firewall rules (optional)

### **Kubernetes Requirements**

* [ ] Disable swap
* [ ] Configure kernel modules
* [ ] Configure sysctl values for networking
* [ ] Validate container runtime requirements

### **Verification**

* [ ] Check connectivity between nodes
* [ ] Confirm correct DNS resolution
* [ ] Verify time synchronization
* [ ] Confirm no swap is active

---

# 🖥️ 0. Basic System Identification

Before configuring the system, collect basic machine information.

## **Get current hostname**

```bash
hostname
```

## **Get all IP addresses**

```bash
ip a
```

## **Get default network interface**

```bash
ip route | grep default
```

## **Get hardware details**

```bash
sudo lshw -short
```

## **Check OS version**

```bash
lsb_release -a
```

## **Check disk layout**

```bash
lsblk
```

## **Check CPU & memory**

```bash
lscpu
free -h
```

---

# 🖥️ 1. OS Updates

Ensure each machine is fully up to date.

```bash
sudo apt update && sudo apt upgrade -y
sudo reboot
```

**Explanation:**

* `apt update` refreshes package lists.
* `apt upgrade` installs updated packages.
* A reboot ensures kernel updates apply.

---

# 🏷️ 2. Set Hostname

Assign unique hostnames to each node.

```bash
sudo hostnamectl set-hostname <hostname>
```

Examples:

* `cp1`
* `cp2`
* `worker1`
* `worker2`

**Explanation:**
`hostnamectl` writes hostname data to systemd-controlled files.

---

# 🧩 3. Configure /etc/hosts

Add all cluster nodes to `/etc/hosts` on every machine.

Example:

```
192.168.10.11   cp1
192.168.10.12   cp2
192.168.10.13   cp3

192.168.10.21   worker1
192.168.10.22   worker2
```

**Explanation:**
Kube components communicate by hostname—this avoids DNS dependency issues.

---

# 👤 4. Create Kubernetes Admin User + SSH Setup

Create a standard admin user to manage the cluster.

```bash
sudo useradd -m -s /bin/bash k8sadmin
sudo passwd k8sadmin
sudo usermod -aG sudo k8sadmin
```

### **Install SSH keys**

On your local machine:

```bash
ssh-keygen -t ed25519
ssh-copy-id k8sadmin@<node-ip>
```

**Explanation:**

* The admin user avoids using `root` for automation.
* Kubespray uses SSH to connect to nodes.

---

# 🔥 5. Disable Swap (Required for Kubernetes)

Check swap status:

```bash
sudo swapon --show
```

Disable swap:

```bash
sudo swapoff -a
```

Permanently disable swap:

```bash
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

**Explanation:**
Kubernetes scheduling and cgroups break when swap is enabled.

---

# 🧠 6. Kernel Modules for Kubernetes

Enable modules:

```bash
echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/k8s.conf
sudo modprobe overlay
sudo modprobe br_netfilter
```

**Explanation:**
Required for network bridging and CNI plugins.

---

# 🌐 7. sysctl Network Settings

```bash
echo -e "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\nnet.bridge.bridge-nf-call-ip6tables = 1" | sudo tee /etc/sysctl.d/k8s.conf
sudo sysctl --system
```

**Explanation:**
Enables packet forwarding and ensures iptables sees bridged traffic.

---

# 🧭 8. Time Synchronization

Install chrony:

```bash
sudo apt install chrony -y
```

Check status:

```bash
chronyc tracking
```

**Explanation:**
Consistent time is critical for certificate validation.

---

# 🔗 9. Basic Connectivity Validation

### **Ping all nodes**

```bash
ping -c3 <hostname>
```

### **Test SSH access**

```bash
ssh k8sadmin@cp1 hostname
```

### **Verify DNS resolution**

```bash
getent hosts cp1
```

---

# 🧪 10. Final Validation Checklist

Before proceeding to Phase 02, confirm:

### Host System

* [ ] Hostnames configured properly
* [ ] `/etc/hosts` identical on all nodes
* [ ] SSH key access works for `k8sadmin`
* [ ] OS fully updated

### Kernel & System Requirements

* [ ] Swap disabled (runtime + fstab)
* [ ] Required kernel modules loaded
* [ ] sysctl networking enabled
* [ ] Time is synchronized

### Network

* [ ] Nodes can ping each other
* [ ] SSH works passwordlessly
* [ ] All nodes resolve each other via hostname

---

# 📦 Scripts Folder (01-machine-prep/scripts/)

Recommended scripts:

## **init-system.sh**

* Updates OS
* Sets hostname
* Configures hosts
* Creates admin user
* Disables swap

## **kernel-tuning.sh**

* Loads kernel modules
* Applies sysctl configuration

## **verify.sh**

* Confirms all preflight checks

---

# 📄 Templates Folder (01-machine-prep/templates/)

Recommended templates:

### `hosts.template.md`

A reusable template for cluster IP plan.

### `sysctl-k8s.conf`

Predefined sysctl rules used across nodes.

---

# 🎉 Phase 01 Complete

You are now ready to begin **Phase 02 — Kubespray Setup**, where Kubernetes will be provisioned automatically using Ansible.
