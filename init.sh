#!/bin/sh

set -e  # Exit on error

echo "Warming up..."

# Define paths
CONFIG_DIR="/etc/amnezia/amneziawg"
AMNEZIA_CONF="$CONFIG_DIR/amnezia.conf"
WIREGUARD_CONF="$CONFIG_DIR/wireguard.conf"

# clear existing configurations
find /etc/amnezia/amneziawg -mindepth 1 -delete

# Check if source files exist
if [ ! -f "/config/amnezia.conf" ]; then
    echo "ERROR: amnezia.conf is missing in /config/"
    exit 1
fi
if [ ! -f "/config/wireguard.conf" ]; then
    echo "ERROR: wireguard.conf is missing in /config/"
    exit 1
fi

# Copy files
echo "Copying amnezia.conf to $CONFIG_DIR/"
cp "/config/amnezia.conf" "$AMNEZIA_CONF"
echo "Copying wireguard.conf to $CONFIG_DIR/"
cp "/config/wireguard.conf" "$WIREGUARD_CONF"

# Fix amnezia.conf
echo "Fixing amnezia config file"
grep -q "^Table =" "$AMNEZIA_CONF" || sed -i '/^\[Interface\]/a Table = off' "$AMNEZIA_CONF"

# Set permissions
chmod 600 "$AMNEZIA_CONF" "$WIREGUARD_CONF"
echo "Permissions set to 600 for both config files"

# Bring up interfaces
echo "Starting amnezia interface..."
awg-quick up amnezia || { echo "ERROR: Failed to start amnezia interface"; exit 1; }

echo "Starting wireguard interface..."
awg-quick up wireguard || { echo "ERROR: Failed to start wireguard interface"; exit 1; }

echo "Both interfaces started successfully"

# Set up routes
echo "Setting up routes..."

ip route add default dev amnezia table 200
ip rule add iif wireguard lookup 200 priority 1000

echo "routes applied successfully"

# Set up iptables rules
echo "Setting up forwarding and NAT rules..."

# 1. Allow forwarding between the two WireGuard interfaces
iptables -A FORWARD -i wireguard -o amnezia -j ACCEPT
iptables -A FORWARD -i amnezia -o wireguard -j ACCEPT

# 2. (Recommended) Accept already-established/related connections (stateful)
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 3. Masquerade (NAT) traffic leaving via the amnezia tunnel
iptables -t nat -A POSTROUTING -o amnezia -j MASQUERADE

echo "iptables rules applied successfully"

exec /bin/sh