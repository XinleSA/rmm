# Guide: Nginx Proxy Manager Setup

**Version 7.0.0** | **Author:** James Barrett | **Company:** Xinle, LLC | **Last Modified:** March 2026

---

## Architecture Note

NPM handles **two separate domains**:

| Domain | Purpose | Backend |
|--------|---------|---------|
| `rmmx.xinle.biz` | All services via subfolders | Various containers |
| `rmm.xinle.biz` | NetLock RMM web console | `netlockrmm-web:5000` |

> **NetLock agents do NOT go through NPM.** They connect directly to `rmm.xinle.biz:7080` (port 7080 must be open in ServerOptima firewall).

---

## Step 1: Log In

1. Open `http://184.105.7.78:81`
2. Log in: `admin@example.com` / `changeme`
3. **Change credentials immediately** when prompted

---

## Step 2: Request SSL Certificates

Go to **SSL Certificates → Add SSL Certificate → Let's Encrypt**

Request certs for both domains:
- `rmmx.xinle.biz` — email: `jbarrett@xinle.biz`
- `rmm.xinle.biz` — email: `jbarrett@xinle.biz`

> Cloudflare DNS must be **DNS Only (grey cloud)** for both records during cert issuance.

---

## Step 3: Proxy Host — rmmx.xinle.biz

The install script auto-creates this host. If missing, create manually:

**Details tab:**
- Domain: `rmmx.xinle.biz`
- Scheme: `http`, Forward: `landing:80`
- Enable: Block Exploits, Websockets

**SSL tab:** Select `rmmx.xinle.biz` cert, Force SSL, HTTP/2

**Advanced tab** (full nginx config):
```nginx
location = / { return 301 /dash/index.html; }

location ^~ /dash/ {
    proxy_pass http://landing:80/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}
location ^~ /n8n/ {
    proxy_pass http://n8n:5678/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
location ^~ /git/ {
    proxy_pass http://forgejo:3000/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Prefix /git;
    client_max_body_size 512m;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
}
location ^~ /pgadmin/ {
    proxy_pass http://pgadmin:80/pgadmin/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Script-Name /pgadmin;
}
location ^~ /pma/ {
    proxy_pass http://phpmyadmin:80/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}
location ^~ /admin/files/download {
    proxy_pass http://netlockrmm-server:7080;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}
location ^~ /private/downloads/ {
    proxy_pass http://netlockrmm-server:7080;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

---

## Step 4: Proxy Host — rmm.xinle.biz

**Details tab:**
- Domain: `rmm.xinle.biz`
- Scheme: `http`, Forward: `netlockrmm-web:5000`
- Enable: Websockets

**SSL tab:** Select `rmm.xinle.biz` cert, Force SSL, HTTP/2

> No advanced config needed — the web console handles its own routing.

---

## Step 5: Enable Cloudflare Proxy

After both SSL certs are confirmed working, switch both `rmmx` and `rmm` Cloudflare records to **Proxied (Orange Cloud)**.

---

## NetLock RMM Agent Connection

Agents do **not** go through NPM. They connect directly:

| Role | Address |
|------|---------|
| Communication | `rmm.xinle.biz:7080` |
| Remote | `rmm.xinle.biz:7080` |
| Update | `rmm.xinle.biz:7080` |
| Trust | `rmm.xinle.biz:7080` |
| File | `rmm.xinle.biz:7080` |
| Relay | `rmm.xinle.biz:7081` |

Port 7080 and 7081 must be open in the **ServerOptima firewall portal**.
