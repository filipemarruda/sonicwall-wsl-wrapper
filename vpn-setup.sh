#!/bin/bash

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Dynamically get the logged-in user's home directory
SUDO_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)

# Read VPN configuration from vpn.conf file in the same directory as the script
CONFIG_FILE=".vpn.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file $CONFIG_FILE not found!"
    exit 1
fi

source "$CONFIG_FILE"

# Function to validate configuration
validate_config() {
    local missing_vars=()
    
    [ -z "$VPN_USERNAME" ] && missing_vars+=("VPN_USERNAME")
    [ -z "$VPN_DOMAIN" ] && missing_vars+=("VPN_DOMAIN")
    [ -z "$VPN_PASSWORD" ] && missing_vars+=("VPN_PASSWORD")
    [ -z "$VPN_SERVER" ] && missing_vars+=("VPN_SERVER")
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo "Error: The following required variables are not set in $CONFIG_FILE:"
        for var in "${missing_vars[@]}"; do
            echo "- $var"
        done
        echo "Please update $CONFIG_FILE with the correct information."
        exit 1
    fi
    
    echo "Configuration validated successfully."
}

# Validate the configuration
validate_config

ifconfig eth0 mtu 1480
rm $USER_HOME/.netExtender.log

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



echo "Starting netExtender. You will be prompted for the OTP if required."
echo "VPN_USERNAME: $VPN_USERNAME"
echo "VPN_DOMAIN: $VPN_DOMAIN"
echo "VPN_PASSWORD: $VPN_PASSWORD"
echo "VPN_SERVER: $VPN_SERVER"
echo "VPN_DNS: $VPN_DNS"

netExtender -M 1480 -u "$VPN_USERNAME" -d "$VPN_DOMAIN" -p "$VPN_PASSWORD" $VPN_SERVER 
