# Xinle RMMx — Post-Installation Runbook

**Version: 1.0** | **Last Updated: March 13, 2026**

---

This runbook provides the step-by-step procedures required to fully configure the Xinle RMMx stack after the initial deployment is complete. Follow these sections in order.

## 1. Nginx Proxy Manager (NPM) Initial Setup

The first step is to log in to the NPM admin UI and set up the proxy hosts that will expose your internal services to the internet via `rmmx.xinle.biz`.

### 1.1. Log in to NPM

1.  **Navigate to the NPM Admin UI:**
    > [http://rmmx.xinle.biz:81](http://rmmx.xinle.biz:81)

2.  **Log in with default credentials:**
    -   **Email:** `admin@example.com`
    -   **Password:** `changeme`

3.  **Change your credentials immediately** when prompted. You will be asked to provide a new admin username/email and password.

### 1.2. Create Proxy Hosts

You will now create a proxy host for each service you want to expose. The key services are:

-   **NetLock RMM Web Console** (`netlockrmm-web`)
-   **n8n** (Workflow Automation)
-   **Forgejo** (Git Server)
-   **pgAdmin** (PostgreSQL Admin)
-   **phpMyAdmin** (MySQL Admin)

**For each service, follow these steps:**

1.  In the NPM dashboard, click **Hosts** > **Proxy Hosts**.
2.  Click **Add Proxy Host**.
3.  Fill out the form as follows (example for NetLock RMM):

| Field | Value |
|---|---|
| **Domain Names** | `rmm.xinle.biz` |
| **Scheme** | `http` |
| **Forward Hostname / IP** | `netlockrmm-web` (the Docker container name) |
| **Forward Port** | `5000` |
| **Cache Assets** | `Enabled` |
| **Block Common Exploits** | `Enabled` |

4.  Click the **SSL** tab.
5.  In the **SSL Certificate** dropdown, select **Request a new SSL Certificate**.
6.  Enable **Force SSL** and **HTTP/2 Support**.
7.  Agree to the Let's Encrypt Terms of Service.
8.  Click **Save**.

NPM will now obtain a Let's Encrypt SSL certificate for `rmm.xinle.biz` and configure the reverse proxy. Repeat this process for the other services using the table below:

| Service | Subdomain | Forward Hostname | Forward Port |
|---|---|---|---|
| n8n | `n8n.xinle.biz` | `n8n` | `5678` |
| Forgejo | `git.xinle.biz` | `forgejo` | `3000` |
| pgAdmin | `pgadmin.xinle.biz` | `pgadmin` | `80` |
| phpMyAdmin | `pma.xinle.biz` | `phpmyadmin` | `80` |

After completing these steps, all services will be accessible via their respective `https://*.xinle.biz` subdomains with valid SSL certificates.

---

## 2. IPsec VPN Tunnel Configuration

The installer has set up the IPsec/IKEv2 server, but you must configure your UDM Pro (or other VPN client) to connect to it. The server is configured to use a pre-shared key (PSK) for authentication.

### 2.1. VPN Server Details

-   **Server IP:** `184.105.7.78`
-   **IPsec Identifier:** `rmmx.xinle.biz`
-   **Pre-Shared Key (PSK):** `8e2c3e3fcbbc0d7d8161827f4789119c`  *(This should be replaced with the actual PSK from the server's `/etc/ipsec.secrets` file)*
-   **Username:** `vpnuser`
-   **Password:** `(to be set by you)` *(This should be replaced with the actual password from `/etc/ipsec.d/passwd`)*

### 2.2. UDM Pro Configuration

1.  In your UniFi Network Application, go to **Settings** > **Teleport & VPN**.
2.  Under **VPN Server**, click **Create New**.
3.  Configure the VPN server with the following settings:
    -   **VPN Type:** `IPsec`
    -   **Name:** `Xinle RMMx Server`
    -   **Pre-Shared Key:** *(Enter the PSK from section 2.1)*
    -   **Gateway IP:** `184.105.7.78`
    -   **Local Network:** *(Enter the local network you want to access from the VPN, e.g., `192.168.1.0/24`)*

4.  Save the configuration.

### 2.3. Client Configuration

The installer does not create VPN users by default for security reasons. You must add a user to `/etc/ipsec.d/passwd` on the server. Example format:

```
vpnuser : EAP "YourStrongPasswordHere"
```

After adding the user, run `sudo ipsec reload`.

### 2.3. Client Configuration

Configure your client device (Windows, macOS, iOS, Android) to connect to the VPN using the server details from section 2.1.

---

## 3. Service-Specific Configuration

### 3.1. NetLock RMM

-   **Initial Login:** Access `https://rmm.xinle.biz` and create your administrator account.
-   **Agent Deployment:** Download the agent from the RMM console and deploy it to your target machines.

### 3.2. n8n

-   **Initial Login:** Access `https://n8n.xinle.biz` and create your owner account.
-   **Workflow Setup:** Start building your automation workflows.

### 3.3. Forgejo

-   **Initial Login:** Access `https://git.xinle.biz` and register your administrator account.
-   **Repository Creation:** Create your first Git repository.

---

## 4. System Maintenance

### 4.1. Daily Updates

The installer has set up a daily cron job to run the update script at 2:00 AM Central Time. This will keep the system and all services up to date.

### 4.2. Log Rotation

Log rotation is handled automatically by Docker and the host system.

---

## 5. References

-   [1] Nginx Proxy Manager Documentation: [https://nginxproxymanager.com/](https://nginxproxymanager.com/)
-   [2] strongSwan IPsec Documentation: [https://www.strongswan.org/](https://www.strongswan.org/)
