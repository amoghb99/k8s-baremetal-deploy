# Phase 01 — Machine Preparation (v2)

## 🎯 Goal

Prepare all nodes (control-plane and workers) for a clean, consistent Kubernetes installation on bare metal.

This version includes senior review feedback: clearer kernel module explanations, defensive scripts, and IPv6 disabled by default for predictability.

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

> Note: command names and paths can vary between distributions. These examples are for Debian/Ubuntu-derived systems — adapt for RHEL/CentOS (yum/dnf) or others.

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

Enable modules (safe/load-if-available):

```bash
echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/k8s.conf
sudo modprobe overlay || true
sudo modprobe br_netfilter || true
```

**Explanation (module-by-module):**

* `overlay` — Provides the overlay filesystem used by many container runtimes (containerd, Docker). It enables image layering and copy-on-write semantics which are essential for containers.
* `br_netfilter` — Ensures bridged network traffic is passed to the netfilter (iptables) stack. This allows kube-proxy and CNI plugins to apply iptables rules to bridged traffic, which is required for service routing and network policies.

**Optional modules (only when needed):**

* `nf_conntrack` — Connection tracking table required by some advanced networking setups.
* `ip_vs`, `ip_vs_rr`, `ip_vs_wrr`, `ip_vs_sh` — Used for IPVS mode of kube-proxy (high-performance service proxy). Enable only if running kube-proxy in IPVS mode.

**Important:** Not every OS or kernel exposes the same module names or even modules at all (some have them built-in). The scripts provided are defensive (`|| true`) so they won't fail on systems where `modprobe` returns non-zero.

---

# 🌐 7. sysctl Network Settings

Apply recommended sysctl values and disable IPv6 for now.

```bash
echo -e "net.bridge.bridge-nf-call-iptables = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.ipv4.ip_forward = 1\nnet.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1\nnet.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee /etc/sysctl.d/k8s.conf
sudo sysctl --system
```

**Explanation:**

* Enables packet forwarding and ensures iptables sees bridged traffic.
* Disables IPv6 by default to keep networking single-stack (IPv4) during initial deployments. Dual-stack greatly increases complexity and troubleshooting overhead.

If you intentionally need IPv6 later, remove the `net.ipv6.conf.*` lines and run `sudo sysctl --system` to re-enable.

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
* [ ] Required kernel modules loaded (or present in kernel)
* [ ] sysctl networking enabled
* [ ] IPv6 disabled (or intentionally configured)
* [ ] Time is synchronized

### Network

* [ ] Nodes can ping each other
* [ ] SSH works passwordlessly
* [ ] All nodes resolve each other via hostname

---

# 📦 Scripts Folder (01-machine-prep/scripts/)

Below are production-ready scripts to place directly in the `scripts/` directory. Scripts are defensive and include IPv6 disable settings.

## **init-system.sh**

```bash
#!/bin/bash
set -e

# Update OS
apt update && apt upgrade -y

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Load kernel modules (non-fatal)
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay || true
modprobe br_netfilter || true

# Apply sysctl settings (includes IPv6 disable)
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1

# Disable IPv6 for predictable networking (remove if you need IPv6)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
sysctl --system || true

echo "System initialization complete."
```

## **kernel-tuning.sh**

```bash
#!/bin/bash
set -e

modprobe overlay || true
modprobe br_netfilter || true

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1

# Disable IPv6 for predictable networking (remove if you need IPv6)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

sysctl --system || true
```

## **verify.sh**

```bash
#!/bin/bash
set -e

echo "Checking hostname..."
hostname

echo "Checking IP addresses..."
ip a

echo "Checking swap status (should be empty)..."
swapon --show || true

echo "Checking kernel modules..."
lsmod | grep -E "overlay|br_netfilter" || true

echo "Checking sysctl values..."
sysctl net.bridge.bridge-nf-call-iptables || true
sysctl net.ipv4.ip_forward || true

echo "Checking IPv6 status (should show disabled=1)..."
sysctl net.ipv6.conf.all.disable_ipv6 || true

echo "Checking time sync..."
chronyc tracking || systemctl status chrony || true

echo "Preflight validation complete."
```

---

# 📄 Templates Folder (01-machine-prep/templates/)

Below are ready-to-use templates you can place directly into the `templates/` directory.

## **hosts.template**

A reusable IP plan & hosts file template.

```text
# ==============================
# Kubernetes Cluster Hosts File
# ==============================
# Control Plane Nodes
<CP1_IP>   cp1
<CP2_IP>   cp2
<CP3_IP>   cp3

# Worker Nodes
<WORKER1_IP>   worker1
<WORKER2_IP>   worker2
<WORKER3_IP>   worker3

# Example:
# 192.168.10.11   cp1
# 192.168.10.12   cp2
# 192.168.10.13   cp3
# 192.168.10.21   worker1
# 192.168.10.22   worker2
```

## **sysctl-k8s.conf**

This file applies Kubernetes-required sysctl settings (includes IPv6 disable).

```text
# Kubernetes sysctl settings
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1

# Disable IPv6 for predictable networking (remove if you need IPv6)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```

---

# 🎉 Phase 01 Complete

You are now ready to begin **Phase 02 — Kubespray Setup**, where Kubernetes will be provisioned automatically using Ansible.

---

# Changelog (v2)

* Added kernel module explanations and optional modules note.
* Disabled IPv6 by default (sysctl + scripts + templates).
* Made scripts defensive (`modprobe ... || true`, `sysctl --system || true`).
* Added cross-distro notes where needed.
