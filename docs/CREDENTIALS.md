# Xinle RMMX — Initial Credentials & Access

This document contains the initial default credentials for all services deployed as part of the Xinle RMMX stack. Many of these services will prompt you to change the password and/or create a new administrative user on first login.

**Server IP:** `184.105.7.78`
**Dashboard:** [https://rmmx.xinle.biz/dash/](https://rmmx.xinle.biz/dash/)

---

## Web Application Credentials

| Service | URL | Username | Password | Notes |
|---|---|---|---|---|
| **NetLock RMM** | `https://rmmx.xinle.biz/` | *(First-run setup)* | *(First-run setup)* | Create your admin account on first visit. |
| **n8n** | `https://rmmx.xinle.biz/n8n/` | *(First-run setup)* | *(First-run setup)* | Create your owner account on first visit. |
| **Forgejo** | `https://rmmx.xinle.biz/git/` | *(First-run setup)* | *(First-run setup)* | Create your admin account on first visit. |
| **pgAdmin** | `https://rmmx.xinle.biz/pgadmin/` | `admin@xinle.biz` | `tb,Xinle2026!` | This is the initial admin user. |
| **phpMyAdmin** | `https://rmmx.xinle.biz/pma/` | `root` | `tb,Xinle2026!` | Connects to the MariaDB/MySQL server. |
| **NPM Admin** | `http://rmmx.xinle.biz:81` | `ai@xinle.biz` | `tb,Xinle2026!` | Nginx Proxy Manager admin UI. |

---

## Database Credentials

These credentials are for connecting to the databases directly, either from another container within the Docker network or via a tool like DBeaver through the IPsec VPN.

| Database | Hostname | Port | Username | Password | Default DB |
|---|---|---|---|---|---|
| **PostgreSQL** | `postgres` | `5432` | `sar` | `tb,Xinle2026!` | `xinle_db` |
| **MariaDB/MySQL** | `mysql` | `3306` | `root` | `tb,Xinle2026!` | `netlockrmm` |

---

## IPsec Site-to-Site VPN

These details are for configuring the IPsec tunnel on your local router (e.g., a UDM Pro).

| Parameter | Value |
|---|---|
| **Server IP / Endpoint** | `184.105.7.78` |
| **Pre-Shared Key (PSK)** | `ffa233dee472e12a421f5cc64027687a` |
| **IKE Version** | `IKEv2` |
| **Encryption** | `AES-256` |
| **Hashing** | `SHA-256` |
| **Diffie-Hellman Group** | `14` (or `ECP384` / `19`) |
| **Local Subnet (UDM)** | `10.1.0.0/24` *(or your local LAN)* |
| **Remote Subnet (VPS)** | `172.20.0.0/16` |

### VPN User Authentication (EAP-MSCHAPv2)

To connect a client device (like a laptop or phone) through the tunnel, you need to create a user with an EAP password. SSH into the server and run:

```bash
# Replace vpnuser and YourPassword with your desired credentials
echo 'vpnuser : EAP "YourPassword"' | sudo tee -a /etc/ipsec.d/passwd

# Reload the IPsec configuration to apply the new user
sudo ipsec reload
```

Once the user is created, you can configure your device's built-in VPN client using the server IP, your new username/password, and the PSK.
