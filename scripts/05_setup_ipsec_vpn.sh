#!/bin/bash
# =============================================================================
#  Xinle 欣乐 — IPsec Site-to-Site VPN Setup Script
# =============================================================================
#  Version: 6.0
#
#  This script installs and configures strongSwan to create a secure, policy-based
#  IPsec site-to-site VPN tunnel, designed to connect to a UniFi Dream Machine Pro.
# =============================================================================

set -e

# --- Configuration ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly AI_SITE_SUBNET="10.1.0.0/24"
readonly DOCKER_SUBNET="172.20.0.0/16"
readonly TUNNEL_IP="172.20.10.1"

# --- Helper Functions ---
print_header() { echo -e "\n\e[1;35m--- $1 ---\e[0m"; }
print_info()   { echo -e "\e[1;36m  $1\e[0m"; }

# --- 1. Install strongSwan ---
print_header "Installing strongSwan IPsec VPN"
apt-get update -qq
apt-get install -y strongswan

# --- 2. Generate Pre-Shared Key (PSK) ---
print_header "Generating Pre-Shared Key"
PSK=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)
print_info "PSK generated successfully."

# --- 3. Configure IPsec ---
print_header "Configuring IPsec (ipsec.conf & ipsec.secrets)"

# Write ipsec.secrets
cat > /etc/ipsec.secrets << EOF
: PSK "${PSK}"
EOF

# Write ipsec.conf
cat > /etc/ipsec.conf << EOF
config setup
    charondebug="all"
    uniqueids=yes
    strictcrlpolicy=no

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1
    keyexchange=ikev2
    authby=secret

conn xinle-s2s
    left=%defaultroute
    leftid=@rmmx.xinle.biz
    leftsubnet=${DOCKER_SUBNET}
    right=%any
    rightsubnet=${AI_SITE_SUBNET}
    ike=aes256-sha256-modp2048!
    esp=aes256-sha256!
    auto=start
EOF

print_info "strongSwan configuration files created."

# --- 4. Configure Firewall (UFW) ---
print_header "Configuring Firewall (UFW)"
ufw allow 500/udp
ufw allow 4500/udp
print_info "UFW ports 500/udp and 4500/udp opened for IPsec."

# --- 5. Create Virtual Tunnel Interface ---
print_header "Creating Virtual Tunnel Interface (xfrm0)"
cat > /etc/systemd/system/xfrm0-interface.service << EOF
[Unit]
Description=Persistent xfrm0 Tunnel Interface
After=network.target strongswan.service

[Service]
Type=oneshot
ExecStart=/sbin/ip link add xfrm0 type xfrm dev eth0 if_id 100
ExecStart=/sbin/ip addr add ${TUNNEL_IP}/32 dev xfrm0
ExecStart=/sbin/ip link set xfrm0 up
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable xfrm0-interface.service
systemctl start xfrm0-interface.service
print_info "xfrm0 interface created at ${TUNNEL_IP} and will persist on reboot."

# --- 6. Start & Enable Service ---
print_header "Starting and Enabling strongSwan Service"
systemctl restart strongswan
systemctl enable strongswan
print_info "strongSwan service started and enabled."

# --- 7. Display UDM Pro Configuration ---
print_header "ACTION REQUIRED: UDM Pro Configuration"
echo ""
echo "  Use the following values to configure the Site-to-Site VPN in your UniFi controller:"
echo "  ───────────────────────────────────────────────────────────────────────────"
echo "    Pre-Shared Key : ${PSK}"
echo "    Remote Host    : $(curl -s ifconfig.me)"
echo "    Remote Network : ${DOCKER_SUBNET}"
echo "    Tunnel IP      : ${TUNNEL_IP}"
echo "    IKE Version    : IKEv2"
    echo "    Encryption     : AES-256"
    echo "    Hash           : SHA-256"
    echo "    DH Group       : 14 (2048-bit MODP)"
echo "  ───────────────────────────────────────────────────────────────────────────"
echo ""
