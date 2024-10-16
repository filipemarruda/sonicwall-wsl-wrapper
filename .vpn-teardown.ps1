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

Write-Host "Local Gateway: $localGateway"
Write-Host "Using WSL IP: $localWSL_Ip"

# Get the network adapter name
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
$adapterName = $adapter.Name

# Restore original DNS settings
Set-DnsClientServerAddress -InterfaceAlias $adapterName -ResetServerAddresses
Write-Host "Original DNS settings restored."

# Function to remove a VPN route
function Remove-VpnRoute {
    param (
        [string]$Destination,
        [string]$Mask
    )
    route delete $Destination mask $Mask
    Write-Host "Removed route: $Destination mask $Mask"
}

# Read routes from file and remove them
$routesFile = Join-Path -Path $PSScriptRoot -ChildPath ".routes.txt"

if (Test-Path $routesFile) {
    $routes = Get-Content $routesFile | Where-Object { $_.Trim() -ne "" }
    foreach ($route in $routes) {
        $routeParts = $route.Trim() -split '/' | Where-Object { $_.Trim() -ne "" }
        if ($routeParts.Count -eq 2) {
            $destination = $routeParts[0].Trim()
            $mask = $routeParts[1].Trim()
            try {
                Remove-VpnRoute -Destination $destination -Mask $mask -ErrorAction Stop
            }
            catch {
                Write-Warning "Failed to remove route: $destination/$mask. Error: $_"
            }
        }
        else {
            Write-Warning "Invalid route format (skipping): $route"
        }
    }
} else {
    Write-Warning "Routes file not found: $routesFile"
}

Write-Host "VPN teardown in Windows complete."