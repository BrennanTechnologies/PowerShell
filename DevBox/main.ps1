param (
	[Parameter()]
	[string]$ConfigurationFile,
	[Parameter()]
	[string]$DownloadUrl,
	[Parameter()]
	[string]$RunAsUser,
	[Parameter()]
	[string]$Package
)

$CustomizationScriptsDir = "C:\DevBoxCustomizations"
$LockFile = "lockfile"
$RunAsUserScript = "runAsUser.ps1"
$CleanupScript = "cleanup.ps1"
$RunAsUserTask = "DevBoxCustomizations"
$CleanupTask = "DevBoxCustomizationsCleanup"
$ConfigurationFile = "configuration.dsc.yaml"


function SetupScheduledTasks {
	Write-Host "Setting up scheduled tasks"
	if (!(Test-Path -PathType Container $CustomizationScriptsDir)) {
		New-Item -Path $CustomizationScriptsDir -ItemType Directory
		New-Item -Path "$($CustomizationScriptsDir)\$($LockFile)" -ItemType File
		Copy-Item "./$($RunAsUserScript)" -Destination $CustomizationScriptsDir
		Copy-Item "./$($CleanupScript)" -Destination $CustomizationScriptsDir
		Copy-Item "./$($ConfigurationFile)" -Destination $CustomizationScriptsDir    
	}

	# Reference: https://learn.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-objects
	$ShedService = New-Object -comobject "Schedule.Service"
	$ShedService.Connect()

	# Schedule the cleanup script to run every minute as SYSTEM
	$Task = $ShedService.NewTask(0)
	$Task.RegistrationInfo.Description = "Dev Box Customizations Cleanup"
	$Task.Settings.Enabled = $true
	$Task.Settings.AllowDemandStart = $false
	
	$Trigger = $Task.Triggers.Create(9)
	$Trigger.Enabled = $true
	$Trigger.Repetition.Interval = "PT1M"

	$Action = $Task.Actions.Create(0)
	$Action.Path = "PowerShell.exe"
	$Action.Arguments = "Set-ExecutionPolicy Bypass -Scope Process -Force; $($CustomizationScriptsDir)\$($CleanupScript)"
	$Action.WorkingDirectory = $CustomizationScriptsDir

	$TaskFolder = $ShedService.GetFolder("\")
	$TaskFolder.RegisterTaskDefinition("$($CleanupTask)", $Task , 6, "NT AUTHORITY\SYSTEM", $null, 5)

	# Schedule the script to be run in the user context on login

	$Task = $ShedService.NewTask(0)

	$Task.RegistrationInfo.Description = "Dev Box Customizations"

	$Task.Settings.Enabled = $true

	$Task.Settings.AllowDemandStart = $false

	$Task.Principal.RunLevel = 1

 

	$Trigger = $Task.Triggers.Create(9)

	$Trigger.Enabled = $true

 

	$Action = $Task.Actions.Create(0)

	$Action.Path = "C:\Program Files\PowerShell\7\pwsh.exe"

	$Action.Arguments = "-MTA -Command $($CustomizationScriptsDir)\$($RunAsUserScript)"

	$Action.WorkingDirectory = $CustomizationScriptsDir

 

	$TaskFolder = $ShedService.GetFolder("\")

	$TaskFolder.RegisterTaskDefinition("$($RunAsUserTask)", $Task , 6, "Users", $null, 4)

	Write-Host "Done setting up scheduled tasks"

}

 

function InstallPS7 {

	if (!(Get-Command pwsh -ErrorAction SilentlyContinue)) {

		Write-Host "Installing PowerShell 7"

		$code = Invoke-RestMethod -Uri https://aka.ms/install-powershell.ps1

		$null = New-Item -Path function:Install-PowerShell -Value $code

		WithRetry -ScriptBlock {

			Install-PowerShell -UseMSI -Quiet

		} -Maximum 5 -Delay 100

		# Need to update the path post install

		$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

		Write-Host "Done Installing PowerShell 7"

	}

	else {

		Write-Host "PowerShell 7 is already installed"

	}

}

 

function InstallWinGet {

	### CB TODO: if winget client...? Microsoft.WinGet.Configuration

	# # https://www.powershellgallery.com/packages/Microsoft.WinGet.Configuration/0.1.1-alpha

	# $module = "C:\Repo\azure-devcenter-customizations-tests\Modules\microsoft.winget.configuration.0.1.1-alpha\Microsoft.WinGet.Configuration.psd1"

	# if (!$(Get-Module $module -ListAvailable)) {

	#   Write-Host "Installing Module: " $module

	#   Import-Module -Name $module -Force

	# }

 

	# check if the Microsoft.Winget.Configuration module is installed

   

	if (!(Get-Module -ListAvailable -Name Microsoft.Winget.Client)) {

		Write-Host "Installing WinGet"

		Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers

		Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

 

		Install-Module Microsoft.WinGet.Client -Scope AllUsers

 

		pwsh.exe -MTA -Command "Install-Module Microsoft.WinGet.Configuration -AllowPrerelease -Scope AllUsers"

		pwsh.exe -MTA -Command "Install-Module winget -Scope AllUsers"

 

		Write-Host "Done Installing WinGet"

		return $true

	}

	else {

		Write-Host "WinGet is already installed"

		return $false

	}

}

 

InstallPS7

$installed_winget = InstallWinGet

 

# TODO only need to setup scheduled tasks if running as user

if (!(Test-Path -PathType Leaf "$($CustomizationScriptsDir)\$($LockFile)")) {

	SetupScheduledTasks

}




function AppendToUserScript {

	Param(

		[Parameter(Position = 0, Mandatory = $true)]

		[string]$Content

	)

	Add-Content -Path "$($CustomizationScriptsDir)\$($RunAsUserScript)" -Value "`r`n" ### Add a new line before the content

	Add-Content -Path "$($CustomizationScriptsDir)\$($RunAsUserScript)" -Value $Content

}

 

Write-Host "Writing commands to user script"

if ($installed_winget) {

	AppendToUserScript "try { "

	AppendToUserScript "    Repair-WinGetPackageManager -Latest"

	AppendToUserScript "} catch { "

	AppendToUserScript '    Write-Error $_'

	AppendToUserScript "}"

}

 

if ($Package) {

	if ($RunAsUser -eq "true") {

		AppendToUserScript "Install-WinGetPackage -Id $($Package)"

	}

	else {

		Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine = "C:\Program Files\PowerShell\7\pwsh.exe -MTA -Command `"Install-WinGetPackage -Id $($Package)`"" }

	}

}

 

if ($ConfigurationFile) {

	if ($DownloadUrl) {

		$ConfigurationFileDir = Split-Path -Path $ConfigurationFile

		if (-Not (Test-Path -Path $ConfigurationFileDir)) {

			New-Item -ItemType Directory -Path $ConfigurationFileDir

		}

		Invoke-WebRequest -Uri $DownloadUrl -OutFile $ConfigurationFile

	}

 

	if ($RunAsUser -eq "true") {

		#$str = "Get-WinGetConfiguration -File '" + $PSScriptRoot + " \" + $($ConfigurationFile) + "' | Invoke-WinGetConfiguration -AcceptConfigurationAgreements"

		#AppendToUserScript $str

		Write-Host "Get ConfigFile: $ConfigurationFile" $(Test-Path -Path $ConfigurationFile)

		$str = "Get-WinGetConfiguration -File '" + $($ConfigurationFile) + "' | Invoke-WinGetConfiguration -AcceptConfigurationAgreements"

		AppendToUserScript $str

 

		#$str = "Get-WinGetConfiguration -File '" + $PSScriptRoot + " \" + $($ConfigurationFile) + "' | Invoke-WinGetConfiguration -AcceptConfigurationAgreements"

		#AppendToUserScript $str

       

		#AppendToUserScript "Get-WinGetConfiguration -File $($ConfigurationFile) | Invoke-WinGetConfiguration -AcceptConfigurationAgreements"

		AppendToUserScript '$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + "; " + [System.Environment]::GetEnvironmentVariable("Path","User")'

		AppendToUserScript 'Read-Host "End of main.ps1 (Ctrl-C to exit. Press Enter to continue.)"'

	}

	else {

		Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine = "C:\Program Files\PowerShell\7\pwsh.exe -MTA -Command `"Get-WinGetConfiguration -File $($ConfigurationFile) | Invoke-WinGetConfiguration -AcceptConfigurationAgreements`""

		}

	}

}