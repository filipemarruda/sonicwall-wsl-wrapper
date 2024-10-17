# Function to get the local gateway
function Get-LocalGateway {
    $gateway = Get-NetRoute -DestinationPrefix 0.0.0.0/0 | 
            Where-Object { $_.NextHop -ne "::" } | 
            Select-Object -ExpandProperty NextHop
    return $gateway
}

# Function to get the correct WSL IP
function Get-CorrectWSLIP {
    $wslIPs = (wsl hostname -I).Trim() -split '\s+'
    Write-Host "All WSL IPs: $($wslIPs -join ', ')"

    $windowsWSLAdapters = Get-NetAdapter -IncludeHidden | Where-Object { $_.Name -like "*WSL*" }
    Write-Host "Windows WSL Adapters:"
    $windowsWSLAdapters | ForEach-Object { Write-Host "  $($_.Name): $($_.InterfaceDescription)" }

    foreach ($adapter in $windowsWSLAdapters) {
        $windowsIP = $null
        try {
            $windowsIP = (Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction Stop).IPAddress
        } catch {
            Write-Host "Error getting IP for adapter $($adapter.Name): $_"
            continue
        }
        Write-Host "Windows IP for $($adapter.Name): $windowsIP"

        foreach ($ip in $wslIPs) {
            $ipParts = $ip -split '\.'
            $windowsIPParts = $windowsIP -split '\.'
            
            # For 172.x.x.x range, compare only first two octets
            if ($ipParts[0] -eq '172' -and $windowsIPParts[0] -eq '172') {
                $network = "$($ipParts[0]).$($ipParts[1])"
                $windowsNetwork = "$($windowsIPParts[0]).$($windowsIPParts[1])"
            } else {
                # For other ranges, compare first three octets
                $network = "$($ipParts[0]).$($ipParts[1]).$($ipParts[2])"
                $windowsNetwork = "$($windowsIPParts[0]).$($windowsIPParts[1]).$($windowsIPParts[2])"
            }
            
            Write-Host "  Comparing WSL IP network $network with Windows IP network $windowsNetwork"
            if ($network -eq $windowsNetwork) {
                Write-Host "Found matching WSL IP: $ip"
                return $ip
            }
        }
    }

    # If no match found, try to find an IP in the 172.x.x.x range
    $fallbackIP = $wslIPs | Where-Object { $_ -like "172.*" } | Select-Object -First 1
    if ($fallbackIP) {
        Write-Host "No exact match found. Using fallback IP in 172.x.x.x range: $fallbackIP"
        return $fallbackIP
    }

    Write-Warning "Could not find a matching WSL IP. Using the first available WSL IP."
    return $wslIPs[0]
}

# LOCAL INFRA
$localGateway = Get-LocalGateway
$localWSL_Ip = Get-CorrectWSLIP

# Read VPN configuration
$vpnConfigPath = Join-Path -Path $PSScriptRoot -ChildPath ".vpn.conf"
$vpnConfig = Get-Content -Path $vpnConfigPath | ConvertFrom-StringData

$vpnDNS = $vpnConfig.VPN_DNS

# Check if USER_HOME is set in the config file
if ($vpnConfig.ContainsKey('USER_HOME') -and $vpnConfig.USER_HOME) {
    $userHomeDir = $vpnConfig.USER_HOME
} else {
    # If USER_HOME is not set, use /root as fallback
    $userHomeDir = "/root"
}

# Check if WSL_DISTRO_NAME is set in the config file
if ($vpnConfig.ContainsKey('WSL_DISTRO_NAME') -and $vpnConfig.WSL_DISTRO_NAME) {
    $wslCommand = "wsl -d $($vpnConfig.WSL_DISTRO_NAME) -u root"
} else {
    $wslCommand = "wsl -u root"
}

# Diagnostic information
$logFileContent = Invoke-Expression  "$wslCommand cat $userHomeDir/.netExtender.log"
if ($logFileContent) {
    Write-Host "Successfully fetched log file content from WSL."

    # Extract routes from log content
    $routes = $logFileContent | Select-String -Pattern "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" | ForEach-Object { $_.Matches.Value }
    if ($routes) {
        # Save the routes to routes.txt
        $routesTxtPath = Join-Path -Path $PSScriptRoot -ChildPath ".routes.txt"
        $routes | Out-File -FilePath $routesTxtPath
        Write-Host "Routes extracted and saved to .routes.txt"
    } else {
        Write-Warning "No routes found in the log file."
    }
} else {
    Write-Warning "Log file appears to be empty or inaccessible."
}

# Get the network adapter name
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
$adapterName = $adapter.Name

# Save current DNS settings
$currentDNS = (Get-DnsClientServerAddress -InterfaceAlias $adapterName -AddressFamily IPv4).ServerAddresses

# Set new DNS servers (VPN DNS as primary, current DNS as fallback)
$newDNSServers = @($vpnDNS) + $currentDNS
Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses $newDNSServers
Write-Host "DNS servers set to: $($newDNSServers -join ', ')"

# Function to add a VPN route
function Add-VpnRoute {
    param (
        [string]$Destination,
        [string]$Mask
    )
    route add $Destination mask $Mask $localWSL_Ip
    Write-Host "Added route: $Destination mask $Mask"
}

# Add the extracted routes
if (Test-Path $routesTxtPath) {
    $routes = Get-Content $routesTxtPath | Where-Object { $_.Trim() -ne "" }
    foreach ($route in $routes) {
        $destination, $mask = $route.Trim() -split '/' | ForEach-Object { $_.Trim() }
        if ($destination -and $mask) {
            Add-VpnRoute -Destination $destination -Mask $mask
        }
        else {
            Write-Warning "Invalid route format: $route"
        }
    }
} else {
    Write-Warning "Routes file not found: $routesTxtPath"
}

# Function to process DMZ routes
function Process-DmzRoutes {
    $dmzConfigPath = Join-Path -Path $PSScriptRoot -ChildPath ".dmz.conf"
    if (Test-Path $dmzConfigPath) {
        $dmzRoutes = Get-Content $dmzConfigPath | Where-Object { $_.Trim() -ne "" }
        foreach ($route in $dmzRoutes) {
            $destination, $mask = $route.Trim() -split '/' | ForEach-Object { $_.Trim() }
            if ($destination -and $mask) {
                Write-Host "Processing DMZ route: $destination mask $mask"
                route delete $destination mask $mask $localWSL_Ip
                route add $destination mask $mask $localGateway
            }
            else {
                Write-Warning "Invalid DMZ route format: $route"
            }
        }
    } else {
        Write-Warning "DMZ configuration file not found: $dmzConfigPath"
    }
}

# Process DMZ routes
Process-DmzRoutes

Write-Host "VPN setup in Windows complete."
