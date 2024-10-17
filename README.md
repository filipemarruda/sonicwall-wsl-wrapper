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

8. Update the .vpn.conf file with your information:
   - Set `VPN_USERNAME` to your VPN username
   - Set `VPN_DNS` to your VPN DNS server
   - Set `VPN_DOMAIN` to your VPN domain
   - Set `VPN_PASSWORD` to your VPN password
   - Set `VPN_SERVER` to your VPN server address
   - (Optional) Set `USER_HOME` to your WSL user home directory (e.g., /home/yourusername)
   - (Optional) Set `WSL_DISTRO_NAME` to your specific WSL distribution name (e.g., kali-linux)

   Example:
   ```
   VPN_USERNAME=your_username
   VPN_DNS=10.x.x.x
   VPN_DOMAIN=your_domain.com
   VPN_PASSWORD=your_password
   VPN_SERVER=vpn.your_server.com
   USER_HOME=/home/yourusername
   WSL_DISTRO_NAME=your_wsl_distro
   ```

   Note: Be cautious with sensitive information. Consider using environment variables or a secure password manager for production use.

9. (Optional) Configure DMZ routes:
   If you need to set up DMZ routes, edit the .dmz.conf file:
   ```
   nano .dmz.conf
   ```
   Add each DMZ route on a new line in the format: `IP_ADDRESS/SUBNET_MASK`

## Running the VPN

The VPN setup and connection process is divided into three steps, each executed by a separate batch file. You can run these files simply by double-clicking them in the File Explorer, or by running them from a Command Prompt or PowerShell window. Make sure to run them in sequence and with administrator privileges.

1. Navigate to the `C:\sonicwall` directory in File Explorer.

2. Double-click `Run-0.clean.bat`
   This script will clean up any existing VPN connections and prepare the system for a new connection.

3. Double-click `Run-1.start.bat`
   This script will initiate the VPN connection. 
   **Important:** You will be prompted to enter a One-Time Code (OTC). Please have your OTC ready before starting this step.

4. Double-click `Run-2.post-start.bat`
   This script will perform any necessary post-connection tasks, such as setting up routes.

Alternatively, if you prefer using the Command Prompt or PowerShell:

1. Open a Command Prompt or PowerShell window with administrator privileges.

2. Navigate to the project directory:
   ```
   cd C:\sonicwall
   ```

3. Run the scripts in sequence:
   ```
   Run-0.clean.bat
   Run-1.start.bat
   Run-2.post-start.bat
   ```

   Remember to have your One-Time Code (OTC) ready when running `Run-1.start.bat`.

Follow any on-screen prompts during each step to complete the VPN connection process.

## Notes

- Ensure that WSL is installed and properly configured on your Windows machine before running these scripts.
- The `install.sh` script must be run with sudo privileges in WSL.
- All batch files (`Run-0.clean.bat`, `Run-1.start.bat`, and `Run-2.post-start.bat`) should be run with administrator privileges.
- DMZ routes specified in .dmz.conf will be processed during VPN setup, routing traffic for these addresses through the local gateway instead of the VPN.
- Always run the batch files in the specified sequence (0, 1, 2) to ensure proper setup and connection of the VPN.
- If `USER_HOME` is not specified in the configuration, the script will use a default value (typically /root).
- If `WSL_DISTRO_NAME` is not specified, the script will use the default WSL distribution.
- When running `Run-1.start.bat`, be prepared to enter your One-Time Code (OTC) when prompted. This is a security measure required for connecting to the VPN.

For any issues or additional configuration, please refer to the individual script files or contact your system administrator.