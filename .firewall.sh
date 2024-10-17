#!/bin/bash

# Read VPN configuration from vpn.conf file in the same directory as the script
CONFIG_FILE=".vpn.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file $CONFIG_FILE not found!"
    exit 1
fi
source "$CONFIG_FILE"

# Set MTU for eth0
ifconfig eth0 mtu 1480

# Use USER_HOME if set, otherwise use ~
USER_HOME_DIR="${USER_HOME:-~}"

# Rest of your script continues here...

setup_routing() {
    echo "Setting up routing rules..."
    sysctl -w net.ipv4.ip_forward=1

    echo "Flush existing rules..."
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F

    echo "Set default policies to ACCEPT..."
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT

    echo "Allow all traffic on ppp0 interface..."
    iptables -A INPUT -i ppp0 -j ACCEPT
    iptables -A OUTPUT -o ppp0 -j ACCEPT

    echo "NAT configuration..."
    iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE

    echo "Display the rules..."
    iptables -L -v
    iptables -t nat -L -v
}

setup_routing

echo "The route fowarding are fully setted!!!! Enjoy!"