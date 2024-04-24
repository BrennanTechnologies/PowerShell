# Get Name of current network adapter
write-host "Finding Current Network Interface"
$ExistingInterface     = Get-NetAdapter –Physical | where status -eq 'up'
$ExistingInterfaceName = $ExistingInterface.Name


# Check IPv6 Status 
$IPv6Status = Get-NetAdapterBinding -Name $ExistingInterfaceName -DisplayName "Internet Protocol Version 6 (TCP/IPv6)"
$IPv6Status = $IPv6Status.Enabled
    Write-Host "IPv6 Status: $IPv6Status"            

# Disable IPv6
Write-Host "Disabling IPv6 on Interface $ExistingInterfaceName"
Disable-NetAdapterBinding -InterfaceAlias $ExistingInterfaceName -ComponentID ms_tcpip6

# Show the Status of IPv6
$IPv6Status = Get-NetAdapterBinding -Name $ExistingInterfaceName -DisplayName "Internet Protocol Version 6 (TCP/IPv6)"
$IPv6Status = $IPv6Status.Enabled
Write-Host "IPv6 Status: $IPv6Status"