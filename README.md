k8s-baremetal-deploy/
├─ README.md                          # high-level overview + quickstart
├─ .gitignore
├─ docs/                              # design notes, architecture diagrams, IP plan
│  └─ ip-plan.md
├─ 01-machine-prep/
│  ├─ README.md
│  ├─ scripts/
│  │  ├─ 01-update-and-packages.sh
│  │  ├─ 02-setup-sshkeys.sh
│  │  ├─ 03-disable-swap-and-sysctl.sh
│  │  └─ 04-set-hosts.sh
│  └─ templates/
│     └─ hosts-example.txt
├─ 02-kubespray/
│  ├─ README.md
│  ├─ inventory/                       # inventory managed here (hosts.yaml)
│  │  └─ hosts.yaml.example
│  ├─ cluster-config/                  # any custom kubespray vars
│  │  └─ mycluster.yml
│  └─ run-kubespray.sh
├─ 03-longhorn/
│  ├─ README.md
│  ├─ helm-values.yaml
│  └─ install-longhorn.sh
├─ 04-metallb/
│  ├─ README.md
│  ├─ ip-address-pool.yaml
│  └─ install-metallb.sh
├─ 05-ingress/
│  ├─ README.md
│  ├─ nginx-ingress-values.yaml
│  └─ install-ingress.sh
├─ 06-proxy/                           # external/edge proxy (HAProxy/MetalLB+VIP etc)
│  ├─ README.md
│  └─ haproxy-config/
├─ 07-post-install/                    # security, monitoring, backup, cert-manager
│  ├─ README.md
│  ├─ install-cert-manager.sh
│  ├─ install-monitoring.sh
│  └─ backup-strategy.md
└─ Makefile
