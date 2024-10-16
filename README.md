# SonicWall VPN Setup

This project provides scripts to set up and run a SonicWall VPN connection on a Windows machine using Windows Subsystem for Linux (WSL) and PowerShell.

## Installation

1. Open a Command Prompt or PowerShell window with administrator privileges.

2. Create a new directory for the project:
   ```
   mkdir C:\sonicwall
   cd C:\sonicwall
   ```

3. Clone this repository:
   ```
   git clone <repository-url> .
   ```

4. Open WSL (Windows Subsystem for Linux).

5. Navigate to the project directory:
   ```
   cd /mnt/c/sonicwall
   ```

6. Run the installation script:
   ```
   sudo ./install.sh
   ```

7. Edit the .vpn.conf file with your actual VPN details:
   ```
   nano .vpn.conf
   ```

8. Update the .vpn.conf file with your sensitive information:
   - Replace `your_username` with your actual VPN username
   - Replace `your_domain` with your actual VPN domain
   - Replace `your_password` with your actual VPN password
   - Replace `your_server_address` with your actual VPN server address

   Note: Be cautious with sensitive information. Consider using environment variables or a secure password manager for production use.

9. (Optional) Configure DMZ routes:
   If you need to set up DMZ routes, edit the .dmz.conf file:
   ```
   nano .dmz.conf
   ```
   Add each DMZ route on a new line in the format: `IP_ADDRESS/SUBNET_MASK`

## Running the VPN

1. Open WSL (Windows Subsystem for Linux).

2. Navigate to the project directory:
   ```
   cd /mnt/c/sonicwall
   ```

3. Run the VPN setup script:
   ```
   sudo ./vpn-setup.sh
   ```

4. Open a PowerShell window with administrator privileges.

5. Navigate to the project directory:
   ```
   cd C:\sonicwall
   ```

6. Run the VPN PowerShell script:
   ```
   .\vpn.ps1
   ```

Follow any on-screen prompts to complete the VPN connection process.

## Notes

- Ensure that WSL is installed and properly configured on your Windows machine before running these scripts.
- The `install.sh` script must be run with sudo privileges in WSL.
- The `vpn.ps1` script will automatically request administrator privileges if not run in an elevated PowerShell session.
- DMZ routes specified in .dmz.conf will be processed during VPN setup, routing traffic for these addresses through the local gateway instead of the VPN.

For any issues or additional configuration, please refer to the individual script files or contact your system administrator.
