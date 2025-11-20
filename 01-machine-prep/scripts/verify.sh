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