<#
.SYNOPSIS
This script is used for data center moves / application flips

.DESCRIPTION
This script has three functions. 

createsn - copies all machine.config to two different files called machine.config_SNAPSHOT.config and machine.config_PRODUCTION.config. 
Then the servers.txt file is read

production - copies the machine.config_PRODUCTION.config to machine.config

snapshot - copies the machine.config_SNAPSHOT.config to machine.config

.EXAMPLE
WebOpsDBSnapshot.ps1 createsn

.NOTES
Notes here

.LINK

#>
$Script:Version = ".1"
$Script:FileName = "WebOps_DBSnapShot.ps1"
$Script:Author = "Matthew J Wilson (mwilson@webmd.net)"
$Script:LastUpdated = "4/5/2012"



mkdir tmp

Function Convert-ToProperties ($p) {
    $p.Split(';') | % {
      $key, $value = $_.split('=')
      $p = $p |
       Add-Member -PassThru Noteproperty ($key -Replace " ", "") $value
    }
    $p
}     

Function Copy-MachineConfigs($serverName)
{
	
	if (Test-Path "\\$serverName\c`$\windows\Microsoft.Net\Framework64\v4.0.30319\config\machine.config")
	{
		Copy-Item "\\$serverName\c`$\windows\Microsoft.Net\Framework64\v4.0.30319\config\machine.config" -Destination "tmp\v4_x64_machine.config"
		Write-Output "Found x64 .NET 4.0 machine.config for $serverName"
	}
	
	if (Test-Path "\\$serverName\c`$\windows\Microsoft.Net\Framework\v4.0.30319\config\machine.config")
	{
		Copy-Item "\\$serverName\c`$\windows\Microsoft.Net\Framework\v4.0.30319\config\machine.config" -Destination "tmp\v4_x86_machine.config"
		Write-Output "Found 32bit .NET 4.0 machine.config for $serverName"
	}
	
	if (Test-Path "\\$serverName\c`$\windows\Microsoft.Net\Framework64\v2.0.50727\config\machine.config")
	{
		Copy-Item "\\$serverName\c`$\windows\Microsoft.Net\Framework64\v2.0.50727\config\machine.config" -Destination "tmp\v2_x64_machine.config"
		Write-Output "Found x64 .NET 2.0 machine.config for $serverName"
	}
	
	if (Test-Path "\\$serverName\c`$\windows\Microsoft.Net\Framework\v2.0.50727\config\machine.config")
	{
		Copy-Item "\\$serverName\c`$\windows\Microsoft.Net\Framework\v2.0.50727\config\machine.config" -Destination "tmp\v2_x86_machine.config"
		Write-Output "Found 32bit .NET 2.0 machine.config for $serverName"
	}

}

Function Create-SnapshotMachineConfig
{
	$arrDBNames = @("Accuweather","ConsRatings","List","Physician_Finder","RegAdmin","sdcat","sdcat_pub","UserScoringService","SymptomsUsage","Live_RT","poll_live","poll_preview","poll_staging","Preview_RT","RSS_Premium","Staging_RT","VaccinationManager","BabyData","Preview_Starling","Starling","HealthTracker","FoodActivity")
$hDBSnapshots = @{"Accuweather" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "ConsRatings" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "List" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "Physician_Finder" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "RegAdmin" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "sdcat" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "sdcat_pub" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "UserScoringService" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "SymptomsUsage" = "sqlvp-prof-07.portal.webmd.com\PROF,1433"; "Live_RT" = "sqlvp-prof-07.portal.webmd.com\PROF,1433"; "poll_live" = "sqlvp-prof-07.portal.webmd.com\PROF,1433"; "poll_preview" = "sqlvp-prof-07.portal.webmd.com\PROF,1433"; "poll_staging" = "sqlvp-prof-07.portal.webmd.com\PROF,1433"; "Preview_RT" = "sqlvp-prof-07.portal.webmd.com\PROF,1433"; "RSS_Premium" = "sqlvp-prof-07.portal.webmd.com\PROF,1433"; "Staging_RT" = "sqlvp-prof-07.portal.webmd.com\PROF,1433"; "VaccinationManager" = "sqlvp-prof-07.portal.webmd.com\PROF,1433"; "BabyData" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "FoodActivity" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "HealthTracker" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "Preview_Starling" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433"; "Starling" = "sqlvp-mste-07.portal.webmd.com\MSTE,1433";}
	$configFiles = Get-ChildItem -Path "tmp\*.config"
	foreach ($configFile in $configFiles)
	{
		$xml = [xml](Get-Content $configFile)
		$appSettingsTarget = $xml.selectSingleNode("//appSettings")
		$connStringTarget = $xml.SelectSingleNode("//connectionStrings")
		$xmlAppSettingsvalue = $xml.configuration.appSettings.add
		$xmlConnectionStringsvalue = $xml.configuration.connectionStrings.add
		$saveFile = $false
		foreach ($val in $xmlAppSettingsvalue)
		{	
			Write-Output $val.Value
			$sb = New-Object System.Data.Common.DbConnectionStringBuilder
			$sb.set_ConnectionString($val.Value)
			foreach ($dbname in $arrDBNames)
			{
				
				if ($sb["database"] -eq $dbname)
				{
					$sb["server"] = $hDBSnapshots.Get_Item($dbname)
					$val.Value = [string]$sb
					$saveFile = $true
				}
			}
			
			
			
		}
		
		foreach($val in $xmlConnectionStringsvalue)
		{
			Write-Output $val.connectionString
			$sb = New-Object System.Data.Common.DbConnectionStringBuilder
			$sb.set_ConnectionString($val.connectionString)
			foreach ($dbname in $arrDBNames)
			{
				if ($sb["database"] -eq $dbname)
				{
					$sb["server"] = $hDBSnapshots.Get_Item($dbname)
					$val.connectionString = [string]$sb
					$saveFile = $true
				}
			}
			
		}
		
		if ($saveFile) { $xml.save("$configFile" + "_SNAPSHOT.config") }
	}
	

}

Function Copy-SnapshotFileToServer($serverName)
{
	if (Test-Path "tmp\v4_x64_machine.config_SNAPSHOT.config")
	{
		Copy-Item "tmp\v4_x64_machine.config_SNAPSHOT.config" -Destination "\\$serverName\c`$\windows\Microsoft.Net\Framework64\v4.0.30319\config\machine.config_SNAPSHOT.config"
	}
	
	if (Test-Path "tmp\v4_x86_machine.config_SNAPSHOT.config")
	{
		Copy-Item "tmp\v4_x64_machine.config_SNAPSHOT.config" -Destination "\\$serverName\c`$\windows\Microsoft.Net\Framework\v4.0.30319\config\machine.config_SNAPSHOT.config"
	}
	
	if (Test-Path "tmp\v2_x64_machine.config_SNAPSHOT.config")
	{
		Copy-Item "tmp\v2_x64_machine.config_SNAPSHOT.config" -Destination "\\$serverName\c`$\windows\Microsoft.Net\Framework64\v2.0.50727\config\machine.config_SNAPSHOT.config"
	}
	
	if (Test-Path "tmp\v2_x86_machine.config_SNAPSHOT.config")
	{
		Copy-Item "tmp\v2_x86_machine.config_SNAPSHOT.config" -Destination "\\$serverName\c`$\windows\Microsoft.Net\Framework\v2.0.50727\config\machine.config_SNAPSHOT.config"
	}
	
	del tmp\*.config
}

$usage = "WebOps_DBSnapShot.ps1 createsn | production | snapshot For more complete help: Get-Help WebOps_DBSnapShot.ps1 "

Function createSnapshot
{
	$serverList = Get-Content "servers.txt"
	foreach ($server in $serverList) 
	{ 	
		Copy-MachineConfigs($server) 
		Create-SnapshotMachineConfig
		Copy-SnapshotFileToServer($server)
	}
	
	


}

Function UseProductionConfig
{



}

Function UseSnapshotConfig
{



}

switch ($args[0])
{
	"createsn" { createSnapshot }
	"production" { Write-Output "Using Production" }
	"snapshot" { Write-Output "Using Snapshot" }
	$null { Write-Output $usage }
}