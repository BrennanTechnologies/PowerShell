cls

function Get-MachineSID
{
  param(
  [string]$HostName,
  [switch]$DomainSID
  )

  ### SOURCE: https://gist.github.com/IISResetMe/36ef331484a770e23a81
  
  # Retrieve the Win32_ComputerSystem class and determine if machine is a Domain Controller  
  $WmiComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
  $IsDomainController = $WmiComputerSystem.DomainRole -ge 4

  if($IsDomainController -or $DomainSID)
  {
    # We grab the Domain SID from the DomainDNS object (root object in the default NC)
    $Domain    = $WmiComputerSystem.Domain
    $SIDBytes = ([ADSI]"LDAP://$Domain").objectSid |%{$_}
    $SID = New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ([Byte[]]$SIDBytes),0
    Return $SID.Value
  }
  else
  {
    # Going for the local SID by finding a local account and removing its Relative ID (RID)
    $LocalAccountSID = Get-WmiObject -ComputerName $HostName -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" | Select-Object -First 1 -ExpandProperty SID
    $MachineSID      = ($p = $LocalAccountSID -split "-")[0..($p.Length-2)]-join"-"
    $SID = New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $MachineSID
    Return $SID.Value
  }
}

$HostName = "."

### Check SID
###------------------------
$VMTemplateSID = "S-1-5-21-1341700647-1908522465-1290903906-501"
Write-Host "VMTemplateSID: " $VMTemplateSID -ForegroundColor DarkCyan

$NewSID = (Get-MachineSID -HostName $HostName)
Write-Host "NewSID: " $NewSid -ForegroundColor Magenta
if($VMTemplateSID -ne $NewSID)
{
    $IsSIDChanged = $True
    Write-Error "ECI.ERROR: SID wasnt Changed." -ErrorAction Continue -ErrorVariable +ECIError
}
else
{
    $IsSIDChanged = $False
}
Write-Host "IsSIDChanged: " $IsSIDChanged


<#

if($usernameDisting.count -eq 1 -and $usernameDisting -isnot [system.array])

if($VMName.count -eq 1 -and $VMName -isnot [system.array])
{

}
else
{
    Write-Error -Message "ECI.Error: VMName is not Unique." -ErrorAction Continue -ErrorVariable +ECIError
}​#>