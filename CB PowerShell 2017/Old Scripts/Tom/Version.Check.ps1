#************************************************************************************
# Script Information:
#
# Script Name:  Version.Check.ps1 
# Version:  v0.1
# Author:  Tom Skawinski (tskawinski@webmd.net)
# Date Created:  04/09/12
# Date Modified: 04/09/12
# Purpose:  Perform version.txt checks on applications.  Script takes 2 inputs
#
# v0.1:		Script created
#
#************************************************************************************
#************************************************************************************

<#
.SYNOPSIS
	Script takes Application Name & Environment inputs and performs a version check on all the instances running under the application.
.DESCRIPTION
	Valid Environment Names:
	QA00
	QA01
	QA02
	PERF
	PROD_IAD1
	PROD_SEA1

	Valid Application Names:
	"RT" = WebMD Runtime
	"member" - Registration member/regapp
	"regapi" - Registration api
	"regsvc" - Registration SVC
.EXAMPLE
	./Version.Check.ps1 -app "RT" -env "PERF"
#>

Param(
	[Parameter(Mandatory=$true)]
	[string]$app,
	[string]$env
)

If((-not($app)) -or (-not($env))) {
	Throw "You must supply two parameters while running this script.  Use get-help .\Version.Check -examples"
}

$erroractionpreference = "SilentlyContinue"
$errorResolving = @()
$resultsArray = @()

$mappings = 	@{	
					"RT" = (@{	"PROD_IAD1"="www01-web.con.iad1.webmd.com;www02-web.con.iad1.webmd.com;www03-web.con.iad1.webmd.com;www04-web.con.iad1.webmd.com;www05-web.con.iad1.webmd.com;www06-web.con.iad1.webmd.com;www07-web.con.iad1.webmd.com;www08-web.con.iad1.webmd.com;www09-web.con.iad1.webmd.com;www10-web.con.iad1.webmd.com;www01-web.bts.iad1.webmd.com;www02-web.bts.iad1.webmd.com;www03-web.bts.iad1.webmd.com;stg01-web.con.iad1.webmd.com;prev01-app.con.iad1.webmd.com;prev02-app.con.iad1.webmd.com";
								"PROD_SEA1"="www01-web.con.sea1.webmd.com;www02-web.con.sea1.webmd.com;www03-web.con.sea1.webmd.com;www04-web.con.sea1.webmd.com;www05-web.con.sea1.webmd.com;www06-web.con.sea1.webmd.com;www07-web.con.sea1.webmd.com;www08-web.con.sea1.webmd.com;www09-web.con.sea1.webmd.com;www10-web.con.sea1.webmd.com;www01-web.bts.sea1.webmd.com;www02-web.bts.sea1.webmd.com;www03-web.bts.sea1.webmd.com;stg01-web.con.sea1.webmd.com;prev01-app.con.sea1.webmd.com;prev02-app.con.sea1.webmd.com";
								"PERF"="wfaws06p-con-08;wfaws06p-con-08;www.staging.perf.webmd.com;www.preview.perf.webmd.com";
								"QA01"="wfaws11q-con-08;wfaws12q-con-08;wfaws07q-con-08;172.25.82.21";
								"QA00"="wfaws09q-con-08;wfaws10q-con-08;www.staging.qa00.webmd.com;www.preview.qa00.webmd.com";
							});
							
					"member" = (@{	"PROD_IAD1"="member01-web.shr.iad1.webmd.com;member02-web.shr.iad1.webmd.com;member03-web.shr.iad1.webmd.com;member04-web.shr.iad1.webmd.com";
									"PROD_SEA1"="member01-web.shr.sea1.webmd.com;member02-web.shr.sea1.webmd.com;member03-web.shr.sea1.webmd.com;member04-web.shr.sea1.webmd.com";
									"PERF"="member03-web-perf.shr.iad1.webmd.com;member04-web-perf.shr.iad1.webmd.com";
									"QA01"="member02-web-qa01.shr.iad1.webmd.com;member03-web-qa01.shr.iad1.webmd.com";
									"QA00"="member01-web-qa00.shr.iad1.webmd.com";
							});
							
					"regapi" = (@{	"PROD_IAD1"="regapi01-web.shr.iad1.webmd.com;regapi02-web.shr.iad1.webmd.com;regapi03-web.shr.iad1.webmd.com;regapi04-web.shr.iad1.webmd.com";
									"PROD_SEA1"="regapi01-web.shr.sea1.webmd.com;regapi02-web.shr.sea1.webmd.com;regapi03-web.shr.sea1.webmd.com;regapi04-web.shr.sea1.webmd.com";
									"PERF"="regapi03-web-perf.shr.iad1.webmd.com;regapi04-web-perf.shr.iad1.webmd.com";
									"QA01"="regapi02-web-qa01.shr.iad1.webmd.com;regapi03-web-qa01.shr.iad1.webmd.com";
									"QA00"="regapi01-web-qa00.shr.iad1.webmd.com";
							});
							
					"regsvc" = (@{	"PROD_IAD1"="regsvc01-app.shr.iad1.webmd.com;regsvc02-app.shr.iad1.webmd.com;regsvc03-app.shr.iad1.webmd.com;regsvc04-app.shr.iad1.webmd.com";
									"PROD_SEA1"="regsvc01-app.shr.sea1.webmd.com;regsvc02-app.shr.sea1.webmd.com;regsvc03-app.shr.sea1.webmd.com;regsvc04-app.shr.sea1.webmd.com";
									"PERF"="regsvc03-app-perf.shr.iad1.webmd.com;regsvc04-app-perf.shr.iad1.webmd.com";
									"QA01"="regsvc02-app-qa01.shr.iad1.webmd.com;regsvc03-app-qa01.shr.iad1.webmd.com";
									"QA00"="regsvc01-app-qa00.shr.iad1.webmd.com";
							});
							
					"myaccount" = (@{	"PROD_IAD1"="api01-web.con.iad1.webmd.com/api/reg;api02-web.con.iad1.webmd.com/api/reg;api03-web.con.iad1.webmd.com/api/reg;api04-web.con.iad1.webmd.com/api/reg;api05-web.con.iad1.webmd.com/api/reg;api06-web.con.iad1.webmd.com/api/reg";
										"PROD_SEA1"="api01-web.con.sea1.webmd.com/api/reg;api02-web.con.sea1.webmd.com/api/reg;api03-web.con.sea1.webmd.com/api/reg;api04-web.con.sea1.webmd.com/api/reg;api05-web.con.sea1.webmd.com/api/reg;api06-web.con.sea1.webmd.com/api/reg";
										"PERF"="apib01-web-perf.con.iad1.webmd.com/api/reg;apib02-web-perf.con.iad1.webmd.com/api/reg";
										"QA01"="apib01-web-qa01.con.iad1.webmd.com/api/reg;apib02-web-qa01.con.iad1.webmd.com/api/reg";
										"QA00"="api01-web-qa00.con.iad1.webmd.com/api/reg"
							});
							
					"TEST" = (@{	"PROD_IAD1"="testinstance.webmd.com";
									"PROD_SEA1"="testinstance2.webmd.com";
									"PERF"="testinstance3.webmd.com";
									"QA00"="testinstance4.webmd.com";
									"QA01"="testinstance5.webmd.com";
									"QA02"="testinstance6.webmd.com";
							});
							
				} #End Mappings Array

if($mappings[$app][$env] -ne $null) {
	[array]$instances = ($mappings[$app][$env]).Split(";")
	
	foreach ($instanceName in $instances) {
		# Check here first if able to resolve hostname
		
		try {
			# Check for API instance names
			if($instanceName -like "*/*") {
				$dnsResolve = [System.Net.Dns]::GetHostByName($instanceName.Split("/")[0])
			}
			else {
				$dnsResolve = [System.Net.Dns]::GetHostByName($instanceName)
			}
		}
		catch {
			$errorResolving += $instanceName
			continue
		}
	
		# Set URLpath variable
		$URLpath = "http://$instanceName/version.txt"
		
		$result = (New-Object Net.WebClient).DownloadString($URLpath)
		$resultsArray += $result
		Write-Host "$instanceName : `t$result"
	}
	
	#Check to make sure all versions match
	[array]$elements = $resultsArray | Get-Unique
	
	if($elements.Count -gt 1) {
		Write-Host "`r`nVersion mismatch.  Please analyze version.txt output"
	}
	else {
		Write-Host "`r`nAll version.txt match"
	}
}
if($errorResolving.Count -gt 0) {
	Write-Host "`r`nFollowing hostnames could not be resolved: "
	foreach ($errorResolvingItem in $errorResolving) {
		$errorResolvingItem	
	}
}