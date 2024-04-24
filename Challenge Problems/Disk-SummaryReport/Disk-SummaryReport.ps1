<#
Get all files in a given folder including subfolders and display a result that shows the total number of files, 
the total size of all files, the average file size, the computer name, and the date when you ran the command.

Lines per file

Total Space
Used Space
Free Space
Biggest File
Smallest File
Biggest Folder
Smallest Folder

#>
[CmdletBinding()]
param (
	[Parameter(Mandatory = $false)]
	[ValidateNotNullOrEmpty()]
	[string]
	$ComputerName = $env:computername
)

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Drive
Parameter description

.EXAMPLE
An example

.NOTES
General notes


#Drive = $Drive.Replace(":", "")
	#$Drive = $ParameterName
	#$Drive = $Drive.Replace("\\", "")
	#$Drive = $Drive.Replace("/", "")

#>
function Get-TotalDiskSpace {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$DefaultDrive = "c"`
	)
	Begin {}
	Process{

		if(-not $DefaultDrive) {
			Write-Host "Using default drive: $DefaultDrive"
			#$physicalDisk = Get-PhysicalDisk
			#$systemDevice = (Get-WmiObject Win32_OperatingSystem).SystemDevice
			
			#$diskPartition = Get-WmiObject Win32_DiskPartition |Where-Object {$_.BootPartition -eq "true"} |Select-Object DeviceID
			#$diskPartition 

			#Get-WmiObject Win32_logicaldisk
			#Get-Volume -DriveLetter C
			
			
			#$psDrive = Get-PSDrive  -Name c #$Drive
			#$volume = Get-Volume
		}
		else {
			Write-Host "Getting Drive Summary" -ForegroundColor Magenta
			#$drive = Get-PSDrive  -Name c #$Drive
			#$drive | gm ; exit

			$drive = Get-Volume -DriveLetter C #$drive
			#$drive | gm

			$driveSummary = [PSCustomObject][ordered]@{
				FileSystemLabel	= $drive.FileSystemLabel
				Size 			= $drive.Size/(1024*1024*1024)
				SizeRemaining 	= $drive.SizeRemaining/(1024*1024*1024)
				UsedDiskSpace	= ($drive.Size-$drive.SizeRemaining)/(1024*1024*1024)
				DriveLetter		= $drive.DriveLetter
				FileSystem		= $drive.FileSystem
				FileSystemType	= $drive.FileSystemType
				DriveType		= $drive.DriveType
				HealthStatus	= $drive.HealthStatus
			}
			$driveSummary
		}

		}
	}
	End { 
		Write-Log "END: " $PSCommandPath
	}


& {
	Begin {
		Clear-Host
		Get-TotalDiskSpace

		exit 

		Write-Host "Total Disk Space"
		### Check Drive for colon ':'
		if ($Drive -notcontains ":") {
			$Drive = $Drive + ":"
		}
		Write-Host "Drive: $Drive"
	
	}
	
	Process {
		$getFiles = Get-ChildItem -Path $Folder -File 
		
		$files = @()
		$TotalSize = 0
		$TotalFiles = 0
		foreach ($file in $getFiles) {
			#Write-Host "File: " $file.Name $file.Length
			#$file | gm
	
			#Get-ChildItem -Path $file.FullName | Select-Object Extension
			#(Split-Path -Path $file -Leaf).Split(".")[1];
			#$file -split(".")[1]
			#$file.split(".")[0] 
	
			#$ext = (Split-Path -Path $file -Leaf).Split(".")[1]
			if ( (Split-Path -Path $file -Leaf).Split(".")[1] -eq "txt" ) {
				$lines =  $file | Measure-Object -Line 
				Write-Host "Lines: " $file.Name `t $lines.Lines
			}
			$file = [PSCustomObject]@{
				Name = $file.Name
				FileSize = $file.Length
				Ext = (Split-Path -Path $file -Leaf).Split(".")[1]
			}
			$TotalFiles += 1
			$TotalSize += $FileSize
			$files += $file
		}
		Write-Host "TotalFiles: " $TotalFiles
		Write-Host "TotalSize: "$TotalSize 
		$files | ft
	}
	
	
	End {
		Write-Host "End"
	}
}
