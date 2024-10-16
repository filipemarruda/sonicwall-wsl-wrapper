#!/bin/bash

# SonicWall NetExtender Client for Linux Installation Script

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Set the download URL
DOWNLOAD_URL="https://software.sonicwall.com/NetExtender/NetExtender.Linux-10.2.850.x86_64.tgz"

# Set the filename
FILENAME="NetExtender.Linux-10.2.850.x86_64.tgz"

# Download the file
echo "Downloading SonicWall NetExtender..."
wget "$DOWNLOAD_URL" -O "$FILENAME"

# Check if download was successful
if [ $? -ne 0 ]; then
    echo "Download failed. Please check your internet connection and try again."
    exit 1
fi

# Extract the tarball
echo "Extracting files..."
tar zxvf "$FILENAME" -C ./netExtenderClient

# Change to the extracted directory
cd ./netExtenderClient

# Run the install script
echo "Running installation script..."
./install

# Check if installation was successful
if [ $? -ne 0 ]; then
    echo "Installation failed. Please check the error messages above."
    exit 1
fi

# Clean up
echo "Cleaning up..."
cd ..
rm -f "$FILENAME"
rm -R netExtenderClient

# Create default .vpn.conf file
echo "Creating default .vpn.conf file..."
cat > .vpn.conf << EOL
# SonicWall VPN Configuration File

# VPN Username (replace with your actual username)
VPN_USERNAME="your_username"

# VPN Domain (replace with your actual domain)
VPN_DOMAIN="your_domain"

# VPN Password (replace with your actual password)
# Note: Storing passwords in plain text is not recommended for production use.
# Consider using a more secure method in a production environment.
VPN_PASSWORD="your_password"

# VPN Server address (replace with your actual server address)
VPN_SERVER="your_server_address"

# Additional configuration options can be added here as needed
EOL

echo "Installation completed successfully."
echo "To run NetExtender, type 'netExtender' or '/usr/sbin/netExtender' if /usr/sbin is not in your PATH."
echo "For more details, consult the man page by typing 'man netExtender'."
echo "A default .vpn.conf file has been created. Please edit it with your actual VPN details before running vpn-setup.sh."
