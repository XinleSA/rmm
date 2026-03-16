# Xinle RMMX — Post-Install Runbook & Credentials

**Version 5.0.0** | **Author:** James Barrett | **Company:** Xinle, LLC | **Last Modified:** March 2026

---

## Quick Reference: Deploy Command

```bash
curl -fsSL https://raw.githubusercontent.com/XinleSA/rmmx/main/scripts/bootstrap.sh | sudo bash
```

> **v14.2.0:** Automatically detects pre-existing installs and offers full purge + fresh start.

---

## Architecture Overview

```
Internet → Cloudflare DNS → VPS (184.105.7.78)
                              ├── :80/:443 → Nginx Proxy Manager → All web services
                              ├── :81      → NPM Admin UI
                              ├── :7080    → NetLock RMM Agent Backend (direct)
                              ├── :7081    → NetLock RMM Relay Server (direct)
                              ├── :12345   → Grafana Alloy UI
                              └── :500/:4500 → IPsec VPN
                                    ↕
                              UDM Pro → Home LAN (10.1.0.0/24)
```

**Key design:** NetLock RMM agents connect **directly** to port 7080 (not through NPM). The web console at `https://rmm.xinle.biz` goes through NPM on 443. All other services go through NPM subfolder routing.

---

## Default Credentials

> ⚠ **Change all defaults immediately after first login.**

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| **Nginx Proxy Manager** | `http://184.105.7.78:81` | `admin@example.com` | `changeme` |
| **NetLock RMM** | `https://rmm.xinle.biz` | `admin` | Set via MySQL (see below) |
| **n8n** | `https://rmmx.xinle.biz/n8n/` | First-run wizard | — |
| **Forgejo** | `https://rmmx.xinle.biz/git/` | First-run wizard | — |
| **pgAdmin** | `https://rmmx.xinle.biz/pgadmin/` | `admin@xinle.biz` | *(PGADMIN_PASSWORD from .env)* |
| **phpMyAdmin** | `https://rmmx.xinle.biz/pma/` | `sar` | *(MYSQL_PASSWORD from .env)* |
| **Grafana Alloy** | `http://184.105.7.78:12345` | No auth | — |

---

## Service URLs

| Service | Public URL | Internal | Port |
|---------|-----------|----------|------|
| Landing Dashboard | `https://rmmx.xinle.biz` | `landing:80` | via NPM |
| NPM Admin | `http://184.105.7.78:81` | `npm:81` | 81 |
| **NetLock RMM Web** | `https://rmm.xinle.biz` | `netlockrmm-web:5000` | via NPM |
| **NetLock Agent Backend** | `rmm.xinle.biz:7080` | `netlockrmm-server:7080` | **7080 direct** |
| n8n | `https://rmmx.xinle.biz/n8n/` | `n8n:5678` | via NPM |
| Forgejo | `https://rmmx.xinle.biz/git/` | `forgejo:3000` | via NPM |
| pgAdmin | `https://rmmx.xinle.biz/pgadmin/` | `pgadmin:80` | via NPM |
| phpMyAdmin | `https://rmmx.xinle.biz/pma/` | `phpmyadmin:80` | via NPM |
| Grafana Alloy | `http://184.105.7.78:12345` | `alloy:12345` | 12345 direct |

---

## ✅ Post-Deployment Checklist

### Step 1 — Cloudflare DNS

Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/) → `xinle.biz` → DNS → Records

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | `rmmx` | `184.105.7.78` | **DNS Only (Grey)** |
| A | `rmm` | `184.105.7.78` | **DNS Only (Grey)** |
| A | `@` | `184.105.7.78` | Proxied (Orange) |
| CNAME | `www` | `rmmx.xinle.biz` | Proxied (Orange) |

> **Both `rmmx` and `rmm` must be DNS Only** until SSL certs are issued.

---

### Step 2 — ServerOptima Firewall

Log into [ServerOptima Portal](https://useast-cloud.serveroptima.com/) → **rmmx** → **Network → Firewall → Add new rule**

| Protocol | Port | Purpose |
|----------|------|---------|
| TCP | 80 | HTTP / NPM |
| TCP | 81 | NPM Admin |
| TCP | 443 | HTTPS |
| TCP | **7080** | **NetLock RMM Agent Backend** |
| TCP | **7081** | **NetLock RMM Relay Server** |
| TCP | 12345 | Grafana Alloy UI |
| UDP | 500 | IPsec IKEv2 |
| UDP | 4500 | IPsec NAT-T |

---

### Step 3 — Verify All Containers Are Running

```bash
cd /home/ubuntu/xinle-infra
docker compose ps
```

---

### Step 4 — Nginx Proxy Manager Setup

1. Open: `http://184.105.7.78:81` → Log in → Change default credentials
2. **SSL Certificates → Add → Let's Encrypt:**
   - Request cert for `rmmx.xinle.biz`
   - Request cert for `rmm.xinle.biz`
3. **Hosts → Proxy Hosts** — two hosts should exist (auto-created by install):
   - `rmmx.xinle.biz` → `landing:80` (with all subpaths in advanced config)
   - `rmm.xinle.biz` → `netlockrmm-web:5000`
4. Edit each host → SSL tab → attach respective cert → Force SSL → Save
5. Switch Cloudflare `rmmx` and `rmm` to Proxied (Orange) after SSL verified

**NPM Subfolder Routing for `rmmx.xinle.biz`:**

| Path | Container | Port |
|------|-----------|------|
| `/` | redirect → `/dash/index.html` | — |
| `/dash/` | `landing` | 80 |
| `/n8n/` | `n8n` | 5678 |
| `/git/` | `forgejo` | 3000 |
| `/pgadmin/` | `pgadmin` | 80 |
| `/pma/` | `phpmyadmin` | 80 |

---

### Step 5 — IPsec VPN — UDM Pro

```bash
sudo cat /etc/ipsec.d/psk.txt   # Get PSK
```

In [UniFi Network Controller](https://ai.xinle.biz/) → Settings → VPN → Site-to-Site:

| Field | Value |
|-------|-------|
| Pre-Shared Key | *(from psk.txt)* |
| Remote Host | `184.105.7.78` |
| Remote Network | `172.20.0.0/16` |
| Local Network | `10.1.0.0/24` |
| IKE | IKEv2, AES-256, SHA-256, DH Group 14 |

Verify: `sudo ipsec status` → should show `ESTABLISHED`

---

### Step 6 — NetLock RMM First Login

The install script creates a default admin account. If login fails, reset via MySQL:

```bash
MYSQL_PASS=$(sudo grep MYSQL_ROOT_PASSWORD /home/ubuntu/xinle-infra/.env | cut -d= -f2)
HASH=$(python3 -c "import bcrypt; print(bcrypt.hashpw(b'YourPassword', bcrypt.gensalt(11)).decode())")
sudo docker exec mysql mysql -u root -p"${MYSQL_PASS}" netlockrmm \
  -e "UPDATE accounts SET password='${HASH}', reset_password=0 WHERE username='admin';" 2>/dev/null
```

Login at `https://rmm.xinle.biz` → username: `admin`

**After login:**
1. Go to **Settings → Members Portal** → enter your API key
2. Go to **Settings → System** → verify Public Override URL is `https://rmm.xinle.biz`
3. **Download Installer** — all server fields should show `rmm.xinle.biz:7080`
4. Run installer on endpoints → devices appear under **Unauthorized Devices** → Authorize

---

### Step 7 — Application First-Run

**n8n** — `https://rmmx.xinle.biz/n8n/`
- Create owner account
- Verify webhook URL: `https://rmmx.xinle.biz/n8n/`

**Forgejo** — `https://rmmx.xinle.biz/git/`
- Set Application URL: `https://rmmx.xinle.biz/git`
- Create admin account → Install Forgejo

**pgAdmin** — `https://rmmx.xinle.biz/pgadmin/`
- Add server: host `postgres`, port `5432`, credentials from `.env`

---

### Step 8 — Verification Checklist

| Check | Command / URL | Expected |
|-------|--------------|---------|
| All containers | `docker compose ps` | All `Up` |
| Landing page | `https://rmmx.xinle.biz` | Dashboard loads |
| NetLock web | `https://rmm.xinle.biz` | Login page |
| NetLock agent port | `nc -zv 184.105.7.78 7080` | Connection OK |
| n8n | `https://rmmx.xinle.biz/n8n/` | Login/setup |
| Forgejo | `https://rmmx.xinle.biz/git/` | Git homepage |
| IPsec tunnel | `sudo ipsec status` | `ESTABLISHED` |
| Ping home LAN | `ping -c 3 10.1.0.1` | 0% loss |

---

## Useful Commands

```bash
# Container management
cd /home/ubuntu/xinle-infra
docker compose ps
docker compose logs -f <service>
docker compose restart <service>
docker compose pull && docker compose up -d

# Re-run installer
curl -fsSL https://raw.githubusercontent.com/XinleSA/rmmx/main/scripts/bootstrap.sh | sudo bash

# NetLock RMM
sudo docker logs --tail 30 netlockrmm-server
sudo docker logs --tail 30 netlockrmm-web
MYSQL_PASS=$(sudo grep MYSQL_ROOT_PASSWORD /home/ubuntu/xinle-infra/.env | cut -d= -f2)
sudo docker exec mysql mysql -u root -p"${MYSQL_PASS}" netlockrmm -e "SELECT public_override_url FROM settings;" 2>/dev/null

# IPsec VPN
sudo ipsec status
sudo ipsec restart
sudo cat /etc/ipsec.d/psk.txt

# Firewall
sudo iptables -L INPUT -n -v | grep -E "22|80|81|443|7080|7081|12345|500|4500"
sudo systemctl status xinle-firewall.service
```

---

## Key File Locations

| File | Path |
|------|------|
| Docker Compose | `/home/ubuntu/xinle-infra/docker-compose.yml` |
| Environment vars | `/home/ubuntu/xinle-infra/.env` |
| Container data | `/docker_apps/` |
| NetLock web config | `/docker_apps/netlockrmm/web/appsettings.json` |
| NetLock server config | `/docker_apps/netlockrmm/server/appsettings.json` |
| IPsec PSK | `/etc/ipsec.d/psk.txt` |
| Firewall service | `/etc/systemd/system/xinle-firewall.service` |
| Install logs | `/tmp/xinle-install-*.log` + `error_logs/` in repo |
