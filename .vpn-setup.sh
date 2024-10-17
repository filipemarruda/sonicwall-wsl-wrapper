#!/bin/bash

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Read VPN configuration from vpn.conf file in the same directory as the script
CONFIG_FILE=".vpn.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file $CONFIG_FILE not found!"
    exit 1
fi

source "$CONFIG_FILE"

# Use USER_HOME if set, otherwise use ~
USER_HOME_DIR="${USER_HOME:-~}"

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

# Remove .netExtender.log file
rm -f "$USER_HOME_DIR/.netExtender.log"

netExtender -M 1480 -u "$VPN_USERNAME" -d "$VPN_DOMAIN" -p "$VPN_PASSWORD" $VPN_SERVER 
