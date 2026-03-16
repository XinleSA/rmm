#!/bin/bash
#############################################################################
# Author: James Barrett | Company: Xinle, LLC
# Version: 8.1.0
# Created: March 11, 2025
# Last Modified: March 16, 2026
#############################################################################
#
#  Xinle 欣乐 — IPsec Site-to-Site VPN Setup Script
#
#  Called by 01_master_setup.sh as part of the main install flow.
#  All fixes are built in — no manual post-install steps required.
#
#  What this script configures:
#  1. Installs strongSwan
#  2. Enables kernel IP forwarding (net.ipv4.ip_forward=1), persistent
#  3. Generates a random 32-char PSK and writes /etc/ipsec.secrets
#  4. Writes /etc/ipsec.conf with:
#       - auto=add  (UDM Pro initiates; VPS listens)
#       - if_id_in/out=42 bound to xfrm0 interface
#       - IKEv2, AES-256, SHA-256, DH Group 14
#       - DPD restart on dead peer
#  5. Creates /etc/ipsec.d/xinle-updown.sh to add/remove the route to
#     10.1.0.0/24 whenever the tunnel comes up or goes down
#  6. Applies iptables rules directly — NO UFW, NO iptables-persistent.
#     Rules are persisted via a dedicated systemd service (xinle-firewall.service)
#     that re-applies them on every boot. This avoids all package conflicts.
#  7. Creates and enables xfrm0-interface.service (systemd) which:
#       - Creates the xfrm0 virtual interface bound to if_id 42
#       - Assigns tunnel IP 172.20.10.1/32
#       - Adds static route to 10.1.0.0/24 via xfrm0
#  8. Starts and enables the ipsec service
#  9. Saves the PSK to /etc/ipsec.d/psk.txt for the master script summary
#############################################################################

set -euo pipefail

# --- Configuration ---
readonly AI_SITE_SUBNET="10.1.0.0/24"
readonly DOCKER_SUBNET="172.20.0.0/16"
readonly TUNNEL_IP="172.20.10.1"
readonly XFRM_IF_ID="42"
readonly PSK_FILE="/etc/ipsec.d/psk.txt"

# --- Helper Functions ---
print_header() { echo -e "\n\e[1;35m--- $1 ---\e[0m"; }
print_info()   { echo -e "\e[1;36m  $1\e[0m"; }

# --- 1. Install strongSwan ---
print_header "Installing strongSwan IPsec VPN"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y strongswan strongswan-starter

# --- 2. Enable IP Forwarding ---
print_header "Enabling Kernel IP Forwarding"
sysctl -w net.ipv4.ip_forward=1
grep -q "^net.ipv4.ip_forward" /etc/sysctl.conf \
    && sed -i 's/^net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf \
    || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
print_info "IP forwarding enabled and persisted in /etc/sysctl.conf."

# Disable rp_filter — strict mode breaks Docker NAT on some VPS kernels
sysctl -w net.ipv4.conf.all.rp_filter=0    >/dev/null
sysctl -w net.ipv4.conf.eth0.rp_filter=0   >/dev/null 2>/dev/null || true
grep -q "rp_filter" /etc/sysctl.conf || \
    printf "\nnet.ipv4.conf.all.rp_filter=0\nnet.ipv4.conf.default.rp_filter=0\n" >> /etc/sysctl.conf

# --- 3. Generate Pre-Shared Key ---
print_header "Generating Pre-Shared Key"
_psk_raw=$(openssl rand -hex 48)
PSK="${_psk_raw:0:32}"
unset _psk_raw
print_info "PSK generated."

# --- 4. Write IPsec Secrets ---
mkdir -p /etc/ipsec.d
cat > /etc/ipsec.secrets << EOF
: PSK "${PSK}"
EOF
chmod 600 /etc/ipsec.secrets

# --- 5. Write IPsec Configuration ---
print_header "Writing IPsec Configuration"
cat > /etc/ipsec.conf << EOF
config setup
    charondebug="ike 1, knl 1, cfg 1"
    uniqueids=yes
    strictcrlpolicy=no

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=%forever
    keyexchange=ikev2
    authby=secret
    dpdaction=restart
    dpddelay=30s
    dpdtimeout=120s

conn xinle-s2s
    left=%defaultroute
    leftid=@rmmx.xinle.biz
    leftsubnet=${DOCKER_SUBNET}
    leftupdown=/etc/ipsec.d/xinle-updown.sh
    right=%any
    rightsubnet=${AI_SITE_SUBNET}
    ike=aes256-sha256-modp2048!
    esp=aes256-sha256!
    if_id_in=${XFRM_IF_ID}
    if_id_out=${XFRM_IF_ID}
    auto=add
EOF
print_info "ipsec.conf written."

# --- 6. Create Updown Script (manages route on tunnel up/down) ---
print_header "Creating IPsec Updown Script"
cat > /etc/ipsec.d/xinle-updown.sh << 'UPDOWN'
#!/bin/bash
case "$PLUTO_VERB" in
    up-client)
        ip route replace 10.1.0.0/24 dev xfrm0 2>/dev/null || true
        ;;
    down-client)
        ip route del 10.1.0.0/24 dev xfrm0 2>/dev/null || true
        ;;
esac
UPDOWN
chmod +x /etc/ipsec.d/xinle-updown.sh
print_info "Updown script created at /etc/ipsec.d/xinle-updown.sh."

# --- 7. Apply iptables Rules (NO package install — pure systemd persistence) ---
print_header "Configuring Firewall (direct iptables — no UFW, no iptables-persistent)"

# Disable UFW if present — its reject chains block Docker traffic
if command -v ufw &>/dev/null; then
    print_info "Disabling UFW to prevent iptables conflicts..."
    ufw --force disable 2>/dev/null || true
fi

# Set FORWARD policy to ACCEPT (required for Docker + IPsec routing)
iptables  -P FORWARD ACCEPT
ip6tables -P FORWARD ACCEPT 2>/dev/null || true

# Apply xfrm0 FORWARD rules immediately
iptables -C FORWARD -i xfrm0 -j ACCEPT 2>/dev/null || iptables -I FORWARD -i xfrm0 -j ACCEPT
iptables -C FORWARD -o xfrm0 -j ACCEPT 2>/dev/null || iptables -I FORWARD -o xfrm0 -j ACCEPT

# Open required inbound ports (INPUT chain)
# SSH
iptables -C INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 22 -j ACCEPT
# HTTP (NPM)
iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 80 -j ACCEPT
# NPM Admin UI
iptables -C INPUT -p tcp --dport 81 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 81 -j ACCEPT
# HTTPS (NPM)
iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 443 -j ACCEPT
# NetLock RMM Agent Backend
iptables -C INPUT -p tcp --dport 7080 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 7080 -j ACCEPT
# Grafana Alloy UI
iptables -C INPUT -p tcp --dport 12345 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 12345 -j ACCEPT
# IPsec IKE
iptables -C INPUT -p udp --dport 500 -j ACCEPT 2>/dev/null || iptables -A INPUT -p udp --dport 500 -j ACCEPT
# IPsec NAT-T
iptables -C INPUT -p udp --dport 4500 -j ACCEPT 2>/dev/null || iptables -A INPUT -p udp --dport 4500 -j ACCEPT
# Allow established/related traffic
iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Allow loopback
iptables -C INPUT -i lo -j ACCEPT 2>/dev/null || iptables -A INPUT -i lo -j ACCEPT

print_info "iptables rules applied immediately."

# Write a systemd service to re-apply all iptables rules on every boot
# This replaces iptables-persistent with zero package dependencies
cat > /etc/systemd/system/xinle-firewall.service << 'FWUNIT'
[Unit]
Description=Xinle Firewall Rules (iptables — no UFW/iptables-persistent)
After=network.target
Before=docker.service ipsec.service

[Service]
Type=oneshot
RemainAfterExit=yes

# FORWARD policy
ExecStart=/sbin/iptables -P FORWARD ACCEPT

# xfrm0 FORWARD rules
ExecStart=/bin/sh -c 'iptables -C FORWARD -i xfrm0 -j ACCEPT 2>/dev/null || iptables -I FORWARD -i xfrm0 -j ACCEPT'
ExecStart=/bin/sh -c 'iptables -C FORWARD -o xfrm0 -j ACCEPT 2>/dev/null || iptables -I FORWARD -o xfrm0 -j ACCEPT'

# INPUT: allow established/related
ExecStart=/bin/sh -c 'iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT'
# INPUT: loopback
ExecStart=/bin/sh -c 'iptables -C INPUT -i lo -j ACCEPT 2>/dev/null || iptables -A INPUT -i lo -j ACCEPT'
# INPUT: SSH
ExecStart=/bin/sh -c 'iptables -C INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 22 -j ACCEPT'
# INPUT: HTTP
ExecStart=/bin/sh -c 'iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 80 -j ACCEPT'
# INPUT: NPM Admin
ExecStart=/bin/sh -c 'iptables -C INPUT -p tcp --dport 81 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 81 -j ACCEPT'
# INPUT: HTTPS
ExecStart=/bin/sh -c 'iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 443 -j ACCEPT'
# INPUT: NetLock RMM Agent Backend
ExecStart=/bin/sh -c 'iptables -C INPUT -p tcp --dport 7080 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 7080 -j ACCEPT'
# INPUT: Grafana Alloy UI
ExecStart=/bin/sh -c 'iptables -C INPUT -p tcp --dport 12345 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 12345 -j ACCEPT'
# INPUT: IPsec IKE
ExecStart=/bin/sh -c 'iptables -C INPUT -p udp --dport 500 -j ACCEPT 2>/dev/null || iptables -A INPUT -p udp --dport 500 -j ACCEPT'
# INPUT: IPsec NAT-T
ExecStart=/bin/sh -c 'iptables -C INPUT -p udp --dport 4500 -j ACCEPT 2>/dev/null || iptables -A INPUT -p udp --dport 4500 -j ACCEPT'

[Install]
WantedBy=multi-user.target
FWUNIT

systemctl daemon-reload
systemctl enable xinle-firewall.service
print_info "xinle-firewall.service created and enabled (rules will re-apply on every boot)."

# --- 8. Create xfrm0 Systemd Service ---
print_header "Creating Virtual Tunnel Interface (xfrm0)"
cat > /etc/systemd/system/xfrm0-interface.service << EOF
[Unit]
Description=Xinle xfrm0 Tunnel Interface (IPsec Site-to-Site VPN)
After=network.target ipsec.service xinle-firewall.service
Wants=ipsec.service

[Service]
Type=oneshot
RemainAfterExit=yes

# Create the virtual XFRM interface bound to if_id ${XFRM_IF_ID}
ExecStart=/sbin/ip link add xfrm0 type xfrm dev eth0 if_id ${XFRM_IF_ID}
ExecStart=/sbin/ip addr add ${TUNNEL_IP}/32 dev xfrm0
ExecStart=/sbin/ip link set xfrm0 up

# Static route: send traffic for the UDM Pro LAN through the tunnel
ExecStart=/sbin/ip route replace ${AI_SITE_SUBNET} dev xfrm0

ExecStop=/sbin/ip route del ${AI_SITE_SUBNET} dev xfrm0 2>/dev/null || true
ExecStop=/sbin/ip link del xfrm0 2>/dev/null || true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xfrm0-interface.service
systemctl start xfrm0-interface.service
print_info "xfrm0 interface created (if_id=${XFRM_IF_ID}), address ${TUNNEL_IP}, route to ${AI_SITE_SUBNET} added."

# --- 9. Start IPsec Service ---
print_header "Starting strongSwan (ipsec) Service"
systemctl restart ipsec
systemctl enable ipsec
print_info "strongSwan started and enabled."

# --- 10. Save PSK for Master Script Summary ---
echo "${PSK}" > "${PSK_FILE}"
chmod 600 "${PSK_FILE}"
print_info "PSK saved to ${PSK_FILE} for inclusion in deployment summary."
