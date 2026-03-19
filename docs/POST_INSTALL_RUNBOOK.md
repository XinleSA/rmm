# Xinle RMMX — Post-Installation Runbook

This document outlines the required steps to complete the Xinle RMMX stack configuration after the main installer has finished.

**Dashboard:** [https://rmmx.xinle.biz/dash/](https://rmmx.xinle.biz/dash/)
**Credentials:** [CREDENTIALS.md](./CREDENTIALS.md)

---

## Step 1: First-Time Logins & Setup

Before configuring the network, log in to each primary service to complete its first-run setup process. This typically involves creating an administrative user and setting a password.

1.  **NetLock RMM:** [https://rmmx.xinle.biz/](https://rmmx.xinle.biz/)
2.  **n8n:** [https://rmmx.xinle.biz/n8n/](https://rmmx.xinle.biz/n8n/)
3.  **Forgejo:** [https://rmmx.xinle.biz/git/](https://rmmx.xinle.biz/git/)

Refer to the [CREDENTIALS.md](./CREDENTIALS.md) document for the initial default passwords for pgAdmin, phpMyAdmin, and the Nginx Proxy Manager admin UI.

---

## Step 2: IPsec Site-to-Site VPN Configuration

To enable direct, secure communication between your local network and the services running on the VPS, you must configure a site-to-site IPsec VPN tunnel.

### A. UDM Pro / EdgeRouter Configuration

Use the following parameters to create a new **Site-to-Site VPN** on your UniFi or EdgeMax device.

| Parameter | Value |
|---|---|
| **VPN Type** | IPsec Site-to-Site |
| **Remote Subnets** | `172.20.0.0/16` |
| **Peer IP / Endpoint** | `184.105.7.78` |
| **Local WAN IP** | *(Your router's public IP)* |
| **IKE Version** | `IKEv2` |
| **Pre-Shared Key (PSK)** | `ffa233dee472e12a421f5cc64027687a` |
| **Key Exchange Version** | `IKEv2` |
| **Encryption** | `AES-256` |
| **Hashing** | `SHA256` |
| **DH Group** | `14` |
| **Perfect Forward Secrecy** | Enabled |

### B. Device Communication Across the Tunnel

Once the tunnel is **up and active**, devices on your local network (e.g., `10.1.0.0/24`) can communicate directly with the Docker containers on the VPS as if they were on the same network.

-   **Accessing Services:** You can connect to services using their container hostname and port. For example, you can connect a database client like DBeaver directly to `postgres:5432` or `mysql:3306` from your laptop.
-   **DNS Resolution:** The Docker DNS server will resolve container hostnames (`postgres`, `n8n`, `forgejo`, etc.) for any device connected through the VPN.
-   **Firewall:** The IPsec tunnel bypasses the public firewall rules. All traffic between the trusted subnets is allowed.

### C. Client-to-Site VPN (Road Warrior)

For individual devices (laptops, phones) to connect from anywhere, you can create EAP-MSCHAPv2 users. SSH into the server (`184.105.7.78`) and run:

```bash
# Replace vpnuser and YourPassword with your desired credentials
echo 'vpnuser : EAP "YourPassword"' | sudo tee -a /etc/ipsec.d/passwd

# Reload the IPsec configuration to apply the new user
sudo ipsec reload
```

Configure your device's native VPN client with the server IP, your new username/password, and the same PSK.

---

## Step 3: Cloudflare DNS & SSL

After verifying all services are working correctly, you can enable Cloudflare's proxy (orange cloud) for the `rmmx.xinle.biz` DNS record. This will provide DDoS protection, caching, and a global CDN for your services.

1.  **Log in to Cloudflare.**
2.  Navigate to the DNS settings for `xinle.biz`.
3.  Find the `A` record for `rmmx`.
4.  Click the **Proxy status** toggle from **DNS only** to **Proxied**.
5.  In the NPM UI for the `rmmx.xinle.biz` proxy host, go to the **SSL** tab and change the SSL Certificate from the Let's Encrypt cert to **"Cloudflare Origin Certificate"** if you have one configured, or ensure your Cloudflare SSL/TLS encryption mode is set to **Full (Strict)**.
