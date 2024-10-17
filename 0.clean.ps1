# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessStartInfo.FileName = "PowerShell.exe"
        $ProcessStartInfo.Arguments = $CommandLine
        $ProcessStartInfo.Verb = "runas"
        $ProcessStartInfo.WorkingDirectory = Get-Location
        [System.Diagnostics.Process]::Start($ProcessStartInfo)
        Exit
    }
}

# Rest of your script starts here
Write-Host "Running with administrator privileges"

# Get the current script's directory
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Run VPN teardown script
$vpnTeardownScript = Join-Path -Path $scriptPath -ChildPath ".vpn-teardown.ps1"

if (Test-Path $vpnTeardownScript) {
    Write-Host "Executing VPN teardown script..."
    & $vpnTeardownScript
} else {
    Write-Host "Error: VPN teardown script not found at $vpnTeardownScript" -ForegroundColor Red
}

# Pause at the end of the script
Write-Host "Press Enter to close this window..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")