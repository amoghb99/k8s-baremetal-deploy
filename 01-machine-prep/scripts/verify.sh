#!/bin/bash
set -e

 echo "Checking hostname..."
hostname

 echo "Checking IP addresses..."
ip a

 echo "Checking swap status (should be empty)..."
swapon --show

 echo "Checking kernel modules..."
lsmod | grep -E "overlay|br_netfilter"

 echo "Checking sysctl values..."
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward

 echo "Checking time sync..."
chronyc tracking || systemctl status chrony

 echo "Preflight validation complete."
``` (01-machine-prep/templates/)
Recommended templates:

### `hosts.template`
A reusable template for cluster IP plan.

### `sysctl-k8s.conf`
Predefined sysctl rules used across nodes.