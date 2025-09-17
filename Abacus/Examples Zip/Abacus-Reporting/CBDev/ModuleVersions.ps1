Get-Module -Name Abacus-Reporting

Import-Module -Name Abacus-Reporting -Force -RequiredVersion 1.2.0 -PassThru

$Module = Get-Module -Name "Abacus-Reporting"
#$Module.Name 
#$Module.Version.ToString()
Write-Host "Importing Module: " $Module.Name  $Module.Version.ToString() -ForegroundColor yellow


# Import-Module -Name Abacus-Reporting -Force -MaximumVersion 

Get-Command -Module Abacus-Reporting
# Requires -Module @{ModuleName = 'PSScriptAnalyzer'; RequiredVersion = '1.5.0'}

$Module = Get-Module -Name Abacus-Reporting
$Module.Name 
$Module.Version.ToString()