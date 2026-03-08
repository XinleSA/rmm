# Xinle 欣乐 — Self-Hosted Infrastructure

**Version: 8.2** | **Target OS: Ubuntu 24.04.4 LTS (Noble Numbat)**

> **[🌐 View Landing Page →](https://xinlesa.github.io/rmmx/)**
> **[📖 Full Documentation →](docs/README.md)**

---

## Quick Start (Fresh Server)

SSH into your VPS as `root` and run this single command:

```bash
curl -fsSL https://raw.githubusercontent.com/XinleSA/rmmx/main/scripts/01_master_setup.sh | sudo bash
```

This will clone this repository, create the `sar` system user, install all dependencies (Docker, IPsec, Grafana Alloy, CIFS/NFS), and start all services automatically.

---

## Services

| Service | URL | Description |
| :--- | :--- | :--- |
| Landing Page | `https://rmmx.xinle.biz/home` | Central hub for all services |
| NetLock RMM | `https://rmmx.xinle.biz/rmm` | Remote monitoring & management |
| Nginx Proxy Manager | `https://rmmx.xinle.biz/npm` | Reverse proxy & SSL |
| n8n | `https://rmmx.xinle.biz/n8n` | Workflow automation |
| Forgejo | `https://rmmx.xinle.biz/git` | Self-hosted Git |
| pgAdmin 4 | `https://rmmx.xinle.biz/pgdba` | PostgreSQL admin |
| phpMyAdmin | `https://rmmx.xinle.biz/dba` | MySQL admin (NetLock RMM) |

---

## Scripts

| Script | Version | Description |
| :--- | :--- | :--- |
| `scripts/01_master_setup.sh` | 8.0 | **Start here** — deploys the full stack |
| `scripts/02_update_images.sh` | 8.2 | Update Docker images, Alloy, and optionally schedule daily cron |
| `scripts/03_migrate_github_to_forgejo.sh` | 6.0 | Migrate all GitHub repos to Forgejo |
| `scripts/04_reinstall_os.sh` | 6.0 | Factory reset the VPS to Ubuntu 24.04.4 via SSH |
| `scripts/05_setup_ipsec_vpn.sh` | 6.0 | Configure IPsec site-to-site VPN to UDM Pro |

### Update Script Usage

```bash
sudo ./scripts/02_update_images.sh --help        # Show all options
sudo ./scripts/02_update_images.sh               # Interactive (prompts each step)
sudo ./scripts/02_update_images.sh -y            # Unattended (auto-yes all steps)
sudo ./scripts/02_update_images.sh --install-cron  # Schedule daily 2:00 AM auto-update
```

---

## Monitoring

**Grafana Alloy** is installed as a host service and pushes metrics to `https://fenix.xinle.biz/grafana`.
Import the dashboards from `monitoring/` into Grafana:

- `node-exporter-full-dashboard.json` — Host CPU, memory, disk, network (ID: 1860)
- `cadvisor-dashboard.json` — Docker container metrics (ID: 13946)

---

## Repository Structure

| Path | Description |
| :--- | :--- |
| `docker-compose.yml` | All Docker service definitions |
| `monitoring/` | Grafana Alloy config and dashboard JSON files |
| `landing/index.html` | Landing page served at `/home` |
| `docs/` | Full documentation (all guides) |
| `npm_configs/` | Nginx Proxy Manager config snippets |

---

*Infrastructure managed by [Xinle 欣乐](https://xinle.biz)*
