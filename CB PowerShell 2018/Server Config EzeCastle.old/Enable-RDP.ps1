$Parameters = @{
    DisplayName = "Allow RDP from 10.0.0.0/24"
    LocalPort = 3390
    Direction="Inbound"
    Protocol ="TCP" 
    Action = "Allow"
    RemoteAddress = "10.0.0.0/24"
}


## Checking if the Rule Exists
write-host "Checking if rule exists: " $Parameters.DisplayName
$Rules = Get-NetFirewallRule -DisplayName *
if (-not $Rules.DisplayName.Contains($Parameters.DisplayName)) 
{
    ### Create New Firewall Rule
    write-host "Creating New Firewall Rule"
    New-NetFirewallRule -DisplayName $Parameters.DisplayName -Action $Parameters.Action -Direction $Parameters.Direction `
    –LocalPort $Parameters.LocalPort -Protocol $Parameters.Protocol -RemoteAddress $Parameters.RemoteAddress| Out-Null
}
else
{
    write-host "This rule already exists."
}

### Show the Firewall Settings
write-host "Checking the Firewall Settings"
$FirewallRule = Get-NetFirewallRule -DisplayName $Parameters.DisplayName
write-host "DisplayName: " $FirewallRule.DisplayName "Action: " $FirewallRule.Action "Enabled: " $FirewallRule.Enabled

