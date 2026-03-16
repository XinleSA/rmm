# Xinle 欣乐 RMMX — Self-Hosted Infrastructure

**Version 10.1.0** | **Author:** James Barrett | **Company:** Xinle, LLC
**Target OS:** Ubuntu 24.04 LTS | **Last Modified:** March 2026

---

## One-Line Deployment

```bash
curl -fsSL https://raw.githubusercontent.com/XinleSA/rmmx/main/scripts/bootstrap.sh | sudo bash
```

---

## What You Get

| Service | URL | Notes |
|---------|-----|-------|
| **Landing Dashboard** | `https://rmmx.xinle.biz` | Central hub with links to all services |
| **NetLock RMM** | `https://rmm.xinle.biz` | Remote monitoring & management |
| **n8n** | `https://rmmx.xinle.biz/n8n/` | Workflow automation |
| **Forgejo** | `https://rmmx.xinle.biz/git/` | Self-hosted Git |
| **Nginx Proxy Manager** | `http://<vps>:81` | Reverse proxy & SSL |
| **pgAdmin** | `https://rmmx.xinle.biz/pgadmin/` | PostgreSQL admin |
| **phpMyAdmin** | `https://rmmx.xinle.biz/pma/` | MySQL admin |
| **Grafana Alloy** | `http://<vps>:12345` | Metrics agent |

---

## Network Architecture

```
Internet
    │
    ▼
Cloudflare DNS (rmmx.xinle.biz + rmm.xinle.biz → 184.105.7.78)
    │
    ▼
VPS 184.105.7.78
    ├── :80/:443  → Nginx Proxy Manager → rmmx.xinle.biz subfolders
    ├── :81       → NPM Admin UI
    ├── :7080     → NetLock RMM Agent Backend (direct — not through NPM)
    ├── :7081     → NetLock RMM Relay Server
    ├── :12345    → Grafana Alloy UI
    └── :500/:4500 → IPsec IKEv2 VPN
                         │
                    Encrypted tunnel
                         │
                    UDM Pro (10.1.0.1)
                         │
                    Home LAN 10.1.0.0/24
                    (Proxmox, SAR server, AI stack)

Docker Network: xinle_network (172.20.0.0/16)
```

---

## Required Firewall Ports (ServerOptima Portal)

| Port | Protocol | Service |
|------|----------|---------|
| 80 | TCP | HTTP |
| 81 | TCP | NPM Admin |
| 443 | TCP | HTTPS |
| **7080** | **TCP** | **NetLock Agent Backend** |
| **7081** | **TCP** | **NetLock Relay** |
| 12345 | TCP | Alloy UI |
| 500 | UDP | IPsec IKE |
| 4500 | UDP | IPsec NAT-T |

---

## Post-Deployment Steps

- **[ ]** Cloudflare DNS — add `rmmx` and `rmm` A records → `184.105.7.78` (DNS Only)
- **[ ]** ServerOptima firewall — open ports 7080, 7081, 443, 80, 81, 12345, 500/udp, 4500/udp
- **[ ]** NPM — request SSL certs for `rmmx.xinle.biz` and `rmm.xinle.biz`
- **[ ]** NPM — attach SSL certs to proxy hosts, enable Force SSL
- **[ ]** Switch Cloudflare to Proxied (Orange) after SSL verified
- **[ ]** UDM Pro — configure IPsec VPN with PSK from `sudo cat /etc/ipsec.d/psk.txt`
- **[ ]** NetLock RMM — complete setup, enter Members Portal API key
- **[ ]** NetLock RMM — download and install agents on endpoints
- **[ ]** n8n, Forgejo — complete first-run wizard

Full guide: **[`docs/POST_INSTALL_RUNBOOK.md`](docs/POST_INSTALL_RUNBOOK.md)**

---

## Container Stack

```
xinle_network (172.20.0.0/16)
│
├── INGRESS
│   └── npm (jc21/nginx-proxy-manager) :80/:443/:81
│
├── DASHBOARD
│   └── landing (nginx:alpine) — serves ./dash/
│
├── APPLICATIONS
│   ├── n8n (n8nio/n8n) :5678
│   ├── forgejo (forgejo/forgejo:14) :3000
│   ├── netlockrmm-web (nicomak101/netlock-rmm-web-console) :5000
│   └── netlockrmm-server (nicomak101/netlock-rmm-server) :7080/:7081
│
├── DATABASES
│   ├── postgres:16 :5432
│   ├── pgadmin (dpage/pgadmin4) :80
│   ├── mysql:8.0 :3306
│   └── phpmyadmin :80
│
└── MONITORING
    └── alloy (grafana/alloy) :12345
```

---

## Repository Structure

```
rmmx/
├── scripts/
│   ├── bootstrap.sh                    # Entry point — curl this (v1.3.0)
│   ├── 01_master_setup.sh              # Main installer (v14.2.0)
│   ├── 02_update_images.sh             # Update Docker images
│   ├── 04_reinstall_os.sh              # Full OS reinstall (v7.3.0)
│   ├── 05_setup_ipsec_vpn.sh           # IPsec VPN (v8.1.0)
│   ├── netlock-web-appsettings.json    # NetLock web console config
│   ├── netlock-server-appsettings.json # NetLock server config
│   └── postgres-init/                  # DB init SQL
├── dash/
│   └── index.html                      # Landing dashboard
├── docker-compose.yml                  # Full stack (v9.1.0)
├── monitoring/
│   └── alloy-config.alloy              # Grafana Alloy config
├── npm_configs/                        # NPM proxy config reference
├── docs/
│   ├── POST_INSTALL_RUNBOOK.md         # ← Start here after install
│   ├── 04_vps_reset_guide.md
│   ├── 05_cloudflare_dns_guide.md
│   ├── 06_site_to_site_vpn_guide.md
│   └── 07_ipsec_vpn_next_steps.md
└── error_logs/                         # Auto-pushed install logs
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [`docs/POST_INSTALL_RUNBOOK.md`](docs/POST_INSTALL_RUNBOOK.md) | Complete post-install checklist with credentials |
| [`docs/05_cloudflare_dns_guide.md`](docs/05_cloudflare_dns_guide.md) | DNS setup |
| [`docs/06_site_to_site_vpn_guide.md`](docs/06_site_to_site_vpn_guide.md) | IPsec VPN guide |
| [`docs/07_ipsec_vpn_next_steps.md`](docs/07_ipsec_vpn_next_steps.md) | VPN verification |
| [`docs/04_vps_reset_guide.md`](docs/04_vps_reset_guide.md) | VPS reset / OS reinstall |
