# Get the directory of the current script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Read VPN configuration
$vpnConfigPath = Join-Path -Path $scriptPath -ChildPath ".vpn.conf"
$vpnConfig = Get-Content -Path $vpnConfigPath | ConvertFrom-StringData

# Function to get the appropriate WSL command
function Get-WSLCommand {
    if ($vpnConfig.ContainsKey('WSL_DISTRO_NAME') -and $vpnConfig.WSL_DISTRO_NAME) {
        return "wsl -d $($vpnConfig.WSL_DISTRO_NAME) -u root"
    } else {
        return "wsl -u root"
    }
}

# Function to execute WSL command and return the output
function Invoke-WSLCommand {
    param (
        [string]$Command
    )
    $wslCommand = "$(Get-WSLCommand) bash -c `"$Command`""
    return Invoke-Expression $wslCommand
}

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessStartInfo.FileName = "PowerShell.exe"
        $ProcessStartInfo.Arguments = $CommandLine
        $ProcessStartInfo.Verb = "runas"
        $ProcessStartInfo.WorkingDirectory = $scriptPath
        [System.Diagnostics.Process]::Start($ProcessStartInfo)
        Exit
    }
}

# Change to the script's directory
Set-Location -Path $scriptPath

# Rest of your script starts here
Write-Host "Running with administrator privileges"

# Get the current Windows path (now it should be the script's directory)
$windowsPath = Get-Location
Write-Host "Current Windows path: $windowsPath"

# Convert Windows path to WSL path
$wslPath = Invoke-WSLCommand "wslpath -u '$windowsPath'"
Write-Host "Converted WSL path: $wslPath"

# Run the script interactively
Write-Host "Running .vpn-setup.sh interactively. Please follow the prompts to enter your OTP." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to exit if needed." -ForegroundColor Yellow

Invoke-WSLCommand "cd '$wslPath' && chmod +x .vpn-setup.sh && ./.vpn-setup.sh"

# Pause at the end of the script
Write-Host "VPN setup process completed. Press Enter to close this window..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")