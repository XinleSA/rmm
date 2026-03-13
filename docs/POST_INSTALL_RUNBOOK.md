# Xinle RMMX: Post-Installation Runbook

**Version 2.0.0** | **Author:** James Barrett | **Company:** Xinle, LLC | **Last Modified:** March 2026

---

## Quick Reference: Installation Command

Run this single command on a **fresh Ubuntu 24.04.4 LTS** server as `root` or a user with `sudo` privileges. It is fully automated and idempotent — safe to re-run after a failed attempt.

```bash
curl -fsSL https://raw.githubusercontent.com/XinleSA/rmmx/main/scripts/bootstrap.sh | sudo bash
```

> **Before running:** Ensure the `rmmx` DNS `A` record in Cloudflare is set to **DNS Only (Grey Cloud)** pointing to `184.105.7.78`. See [Step 1](#step-1-cloudflare-dns-configuration) below.

---

## Introduction

This document provides the complete manual steps required to fully configure your Xinle RMMX instance **after** the `01_master_setup.sh` script has completed successfully. Following these steps in order will enable DNS resolution, activate the secure VPN tunnel, configure public-facing HTTPS access to all applications, and guide you through the initial setup of each service.

## Prerequisites

Before running the installation script, ensure the following are in place:

- You have a fresh **Ubuntu 24.04.4 LTS** server with a public IP of `184.105.7.78`.
- You have SSH access to the server as `root` or a `sudo`-capable user.
- You have access to the **Cloudflare DNS dashboard** for `xinle.biz`.
- You have access to the **UniFi Network Controller** for the UDM Pro at the AI site.

---

## Step 1: Cloudflare DNS Configuration

DNS must be configured **before** running the install script. Nginx Proxy Manager uses Let's Encrypt to issue SSL certificates via the HTTP-01 challenge, which requires direct access to the server on port 80. The Cloudflare proxy must be **disabled** during initial setup.

> For full details and diagrams, see [`docs/05_cloudflare_dns_guide.md`](./05_cloudflare_dns_guide.md).

### 1a. Create the Required DNS Records

1. Log in to the [Cloudflare Dashboard](https://dash.cloudflare.com/).
2. Select the `xinle.biz` zone.
3. Navigate to **DNS** > **Records**.
4. Click **Add record** and create the following entries:

| Type | Name | Content | TTL | Proxy Status | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `A` | `rmmx` | `184.105.7.78` | Auto | **DNS Only (Grey Cloud)** | Primary endpoint — **must be grey for initial setup** |
| `A` | `@` | `184.105.7.78` | Auto | Proxied (Orange Cloud) | Root domain |
| `CNAME` | `www` | `rmmx.xinle.biz` | Auto | Proxied (Orange Cloud) | www redirect |

> **CRITICAL:** The `rmmx` record **must** be set to **DNS Only (Grey Cloud)** before running the install script and before requesting the SSL certificate in NPM. If the Cloudflare proxy is active (orange cloud), Let's Encrypt's HTTP-01 challenge will fail and no certificate will be issued.

### 1b. After SSL is Issued

Once the install script has completed and you have successfully obtained an SSL certificate in Nginx Proxy Manager (Step 3), return to Cloudflare and change the `rmmx` record proxy status to **Proxied (Orange Cloud)** to enable DDoS protection and IP masking.

---

## Step 2: Run the Installation Script

With DNS configured, run the install command from the [Quick Reference](#quick-reference-installation-command) section at the top of this document. The script will perform the following stages automatically:

1. Install Docker CE and Docker Compose plugin
2. Install and configure Grafana Alloy (metrics collection, runs as a Docker container)
3. Install strongSwan and configure the IPsec VPN tunnel with all routing rules
4. Create all Docker application directories and seed configuration files
5. Pull all Docker images and start the full application stack
6. Configure UFW firewall rules

At the end of a successful run, the terminal will print a **"DEPLOYMENT COMPLETE — ACTION REQUIRED"** summary block containing:

- The auto-generated **Pre-Shared Key (PSK)** for the VPN — **copy this immediately**
- The exact UDM Pro configuration values
- Next-step instructions

---

## Step 3: UDM Pro IPsec VPN Activation

The VPS-side VPN is configured automatically by the install script. You must now configure the UDM Pro to initiate the tunnel.

> **Architecture:** The **UDM Pro is the initiator**. The VPS listens with `auto=add` and `right=%any`. This design accommodates a dynamic UDM Pro WAN IP while the VPS maintains a static IP (`184.105.7.78`).

> For full details, diagrams, and advanced troubleshooting, see [`docs/06_site_to_site_vpn_guide.md`](./06_site_to_site_vpn_guide.md).

### 3a. Configure the UDM Pro

1. Log in to your [UniFi Network Controller](https://ai.xinle.biz/).
2. Navigate to **Settings** > **VPN** > **Site-to-Site VPN**.
3. Click **Create New**.
4. Fill in the fields using the values from the script's deployment summary output:

| UniFi Field | Value |
| :--- | :--- |
| **Name** | `Xinle RMMX VPS` |
| **VPN Type** | IPsec |
| **IKE Version** | IKEv2 |
| **Pre-Shared Key** | `<PSK printed by the install script>` |
| **Remote Host / Peer IP** | `184.105.7.78` |
| **Remote Network** | `172.20.0.0/16` (VPS Docker subnet) |
| **Local Network** | `10.1.0.0/24` (AI site LAN) |
| **Encryption** | AES-256 |
| **Hash** | SHA-256 |
| **DH Group** | 14 (2048-bit MODP) |
| **PFS** | Enabled (Group 14) |

5. Click **Save**. The UDM Pro will initiate the tunnel immediately.

### 3b. Verify the Tunnel on the VPS

SSH into the VPS and run the following commands to confirm the tunnel is established:

```bash
# Check IPsec SA (Security Association) status — should show ESTABLISHED
sudo ipsec status

# Confirm the xfrm0 interface is up and has the tunnel IP
ip addr show xfrm0

# Confirm the route to the AI site LAN is present
ip route show | grep 10.1.0.0

# Ping the UDM Pro gateway
ping -c 3 10.1.0.1

# Ping a device on the AI site LAN (replace with a real device IP)
ping -c 3 10.1.0.100
```

### 3c. Troubleshooting

If the tunnel does not establish, check the strongSwan log:

```bash
sudo journalctl -u ipsec -f --no-pager
```

| Symptom | Likely Cause | Fix |
| :--- | :--- | :--- |
| `NO_PROPOSAL_CHOSEN` | IKE/ESP cipher mismatch | Verify AES-256 / SHA-256 / Group-14 on both sides |
| `AUTHENTICATION_FAILED` | PSK mismatch | Re-check the PSK value on the UDM Pro |
| `TS_UNACCEPTABLE` | Subnet mismatch | Verify Local/Remote subnets match exactly |
| Tunnel up but no ping | Missing route or firewall rule | Run `ip route show` and `iptables -L FORWARD -n` on VPS |

---

## Step 4: Nginx Proxy Manager (NPM) Setup

NPM routes traffic from `rmmx.xinle.biz` to the correct Docker containers and manages the SSL certificate.

### 4a. Initial Login

1. Open `http://rmmx.xinle.biz:81` in your browser.
2. Log in with the default credentials:
   - **Email:** `admin@example.com`
   - **Password:** `changeme`
3. You will be immediately prompted to change the email and password. Set these to secure values before proceeding.

### 4b. Create the Proxy Host

1. Go to **Hosts** > **Proxy Hosts** and click **Add Proxy Host**.
2. On the **Details** tab, configure the primary host:
   - **Domain Names:** `rmmx.xinle.biz`
   - **Scheme:** `http`
   - **Forward Hostname / IP:** `landing-page`
   - **Forward Port:** `80`
   - Enable **Block Common Exploits**

### 4c. Configure Application Locations (Subpaths)

3. Go to the **Locations** tab and click **Add Location** for each entry in the table below. The **Forward Hostname / IP** is the Docker service name (resolvable within the `xinle_network`):

| Location Path | Forward Hostname / IP | Forward Port | Application |
| :--- | :--- | :--- | :--- |
| `/home` | `landing-page` | `80` | Branded landing page |
| `/npm` | `npm-app` | `81` | NPM admin panel |
| `/n8n` | `n8n` | `5678` | Workflow automation |
| `/git` | `forgejo` | `3000` | Git server |
| `/rmm` | `netlock-rmm-web` | `80` | NetLock RMM web console |
| `/pgdba` | `pgadmin` | `80` | PostgreSQL admin |
| `/dba` | `phpmyadmin` | `80` | MariaDB admin |

### 4d. Request SSL Certificate

4. Go to the **SSL** tab:
   - **SSL Certificate:** Select **Request a new SSL Certificate**
   - Enable **Force SSL**
   - Enable **HTTP/2 Support**
   - Tick **I Agree to the Let's Encrypt Terms of Service**
5. Click **Save**. NPM will contact Let's Encrypt and issue the certificate. This takes approximately 30–60 seconds.

> If certificate issuance fails, verify that the `rmmx` Cloudflare DNS record is set to **DNS Only (Grey Cloud)** and that port 80 is open (`sudo ufw status` should show `80/tcp ALLOW`).

### 4e. Enable Cloudflare Proxy

Once `https://rmmx.xinle.biz` loads correctly with a valid SSL certificate, return to Cloudflare and change the `rmmx` `A` record proxy status to **Proxied (Orange Cloud)**.

---

## Step 5: Application First-Run Configuration

### NetLock RMM (`https://rmmx.xinle.biz/rmm`)

NetLock RMM is the primary endpoint management platform for the Xinle infrastructure.

1. Navigate to `https://rmmx.xinle.biz/rmm`.
2. You will be presented with the initial setup wizard. Create the **first administrator account** with a secure password.
3. Once logged in, navigate to **Settings** > **Server Settings**.
4. Set the **Server Address** (used by agents to connect back) to:
   ```
   https://rmmx.xinle.biz
   ```
5. Save the settings.
6. **Deploy an Agent:**
   - Go to **Agents** > **Install Agent**.
   - Select the target platform (Windows, Linux, or macOS).
   - Copy the installer command or download the installer package.
   - Run the installer on the target device. The agent will appear in the Agents panel within a few minutes.
7. **Recommended post-setup tasks:**
   - Create device groups under **Groups**
   - Configure alert policies under **Alerts**
   - Set up remote access credentials under **Settings** > **Remote Access**

### n8n (`https://rmmx.xinle.biz/n8n`)

1. Navigate to `https://rmmx.xinle.biz/n8n`.
2. Create the **owner account** by filling in your name, email, and password.
3. You will be taken to the workflow editor. You can now create automated workflows.

### Forgejo (`https://rmmx.xinle.biz/git`)

1. Navigate to `https://rmmx.xinle.biz/git`.
2. The initial configuration page will appear.
3. **Database Settings** are pre-configured via Docker Compose environment variables — do not change them.
4. Under **General Settings**, set:
   - **Server Domain:** `rmmx.xinle.biz`
   - **Application URL:** `https://rmmx.xinle.biz/git`
5. Under **Administrator Account Settings**, create your admin user.
6. Click **Install Forgejo**.

### pgAdmin (`https://rmmx.xinle.biz/pgdba`)

1. Navigate to `https://rmmx.xinle.biz/pgdba`.
2. Log in with the pgAdmin admin credentials set in your `.env` file.
3. Right-click **Servers** > **Register** > **Server**.
4. On the **Connection** tab, enter:

| Field | Value |
| :--- | :--- |
| **Host** | `postgres` |
| **Port** | `5432` |
| **Username** | `sar` |
| **Password** | *(value of `POSTGRES_PASSWORD` in `.env`)* |

### phpMyAdmin (`https://rmmx.xinle.biz/dba`)

1. Navigate to `https://rmmx.xinle.biz/dba`.
2. Log in with:
   - **Server:** `mariadb`
   - **Username:** `sar`
   - **Password:** *(value of `MARIADB_PASSWORD` in `.env`)*

> **Security Note:** The hostnames `postgres` and `mariadb` are Docker service names resolvable only within the `xinle_network` Docker bridge. They are not exposed to the public internet.

---

## Step 6: Post-Deployment Verification Checklist

Use this checklist to confirm the deployment is fully operational before handing off to production use.

| Check | Command / URL | Expected Result |
| :--- | :--- | :--- |
| All containers running | `docker ps --format "table {{.Names}}\t{{.Status}}"` | All containers show `Up` |
| Landing page accessible | `https://rmmx.xinle.biz` | Branded landing page loads |
| SSL certificate valid | Browser padlock on `https://rmmx.xinle.biz` | Valid Let's Encrypt cert |
| IPsec tunnel established | `sudo ipsec status` | `ESTABLISHED` |
| Route to AI site LAN | `ip route show \| grep 10.1.0.0` | Route via `xfrm0` present |
| Ping AI site gateway | `ping -c 3 10.1.0.1` | 0% packet loss |
| NetLock RMM accessible | `https://rmmx.xinle.biz/rmm` | Login page loads |
| n8n accessible | `https://rmmx.xinle.biz/n8n` | Setup or login page loads |
| Forgejo accessible | `https://rmmx.xinle.biz/git` | Git homepage loads |

---

## Additional Documentation

| Document | Description |
| :--- | :--- |
| [`docs/05_cloudflare_dns_guide.md`](./05_cloudflare_dns_guide.md) | Detailed Cloudflare DNS setup with diagrams |
| [`docs/06_site_to_site_vpn_guide.md`](./06_site_to_site_vpn_guide.md) | Full IPsec VPN setup, verification, and troubleshooting |
| [`docs/07_ipsec_vpn_next_steps.md`](./07_ipsec_vpn_next_steps.md) | Post-VPN activation steps and advanced routing |
| [`docs/04_vps_reset_guide.md`](./04_vps_reset_guide.md) | How to fully reset and re-deploy the VPS |
