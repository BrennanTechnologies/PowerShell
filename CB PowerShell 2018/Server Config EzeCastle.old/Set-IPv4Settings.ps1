cls

Get-Variable -* | Remove-Variable | OUT-NULL

<#

Set the ip and dns servers 
Ip 10.0.0.1 255.255.255.0  

Gateway 10.0.0.250 
Dns 10.0.0.220 10.0.0.221 

Join to a domain (your choice on the name)

#>


### Rename Network Adapter using PowerShell 3.0 Commandlet 
function Rename-Interface
{

    $script:InterfaceName    = "Ethernet"
    $script:NewInterfaceName    = "LAN"

    # Check if Interface Name Exists before Renaming
    if (Get-NetAdapter | Where-Object {$_.Name -like $InterfaceName})
    {
        try
        {
            Rename-NetAdapter (Get-NetAdapter -Name $InterfaceName).Name -NewName $NewInterfaceName
            write-host "Interface $InterfaceName renamed to $NewInterfaceName"
        }
        catch

        {
            Write-Host "Error Renaming Adapter " $InterfaceName 
        }
    }

    else
    {
        write-host "Not Renaming interface. No adaper present named " $InterfaceName
    }

    }
    
    Rename-Interface

function Set-NewIPv4Address
{
     ### Set the New IP Address & Default Gateway

    [IPAddress]$NewIPv4Address   = “10.0.0.1”
    [IPAddress]$NewDefultGateway = "10.0.0.250"

    ### Get the Current IP Address
    $CurrentIPAddress = (Get-NetIPAddress -InterfaceAlias $NewInterfaceName -AddressFamily IPv4).IPv4Address

    ### Checking if the current IP Address is already the same if the New IP Address
    if($CurrentIPAddress -ne $NewIPv4Address) 
    {
        write-host "The New IP Address is Different"
        write-host "CurrentIP: " $CurrentIPAddress 
        write-host "NewIP: "     $NewIPv4Address  
        
        ### Change the Settings using 2012 R2 PowerShell 3.0 Commandlets
        New-NetIPAddress $NewIPv4Address –InterfaceAlias $NewInterfaceName -AddressFamily IPV4 –PrefixLength 24 -DefaultGateway $NewDefultGateway

        ### Verify Settings
        write-host "IP Address set to this new value: " (Get-NetIPAddress -InterfaceAlias $NewInterfaceName -AddressFamily IPv4).IPv4Address
    }
    else
    {
        ### Do nothing if the New iP Address is the same as the Existing IP Address 
        write-host "The IP Address is the Same"
        write-host "CurrentIP: " $CurrentIPAddress
        write-host "NewIP: "     $NewIPv4Address  
        write-host "IP Addresses are the same. Not Resetting."
    }
}

Set-NewIPv4Address

### Configure DNS Settings
function Set-DNS
{
    $PrimaryDNS   = "10.0.0.220"
    $SecondaryDNS = "10.0.0.221"
    
    try
    {
        ### Change the Settings using 2012 R2 PowerShell 3.0 Commandlets
        Write-Host "Setting Primary & Secondary DNS Servers: " $PrimaryDNS,$SecondaryDNS
        Set-DNSClientServerAddress –interfaceIndex 12 –ServerAddresses ($PrimaryDNS,$SecondaryDNS)

        ### Verify Settings
        write-host "Gettting New DNS Server Address"
        $DNSClientServerAddress = Get-DNSClientServerAddress
        write-host $DNSClientServerAddress.ServerAddresses
    }
    catch
    {
    

    }
}

Set-DNS


### Set IPv4 Configuration Settings
<#
Set the ip and dns servers 
Ip 10.0.0.1 255.255.255.0  

Gateway 10.0.0.250 
Dns 10.0.0.220 10.0.0.221 
#>


#New-NetIPAddress –InterfaceAlias “Wired Ethernet Connection” –IPv4Address “192.168.0.1” –PrefixLength 24 -DefaultGateway 192.168.0.254

#Set-DnsClientServerAddress -InterfaceAlias “Wired Ethernet Connection” -ServerAddresses 192.168.0.1, 192.168.0.2

