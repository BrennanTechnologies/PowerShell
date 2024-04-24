cls
$String = "PowerShell"
#Write-Host $String


<#
"PowerShell" -match 'shell'        # Output: True
"PowerShell" -like  '*shell'        # Output: False
#>


$string = 'The last logged on user was CONTOSO\jsmith'
$string -match 'was (?<domain>.+)\\(?<user>.+)'

$Matches

Write-Output "`nDomain name:"
$Matches.domain

Write-Output "`nUser name:"
$Matches.user