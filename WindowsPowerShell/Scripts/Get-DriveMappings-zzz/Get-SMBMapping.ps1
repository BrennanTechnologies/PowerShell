    <#
    https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-psdrive?view=powershell-7.1

    Example 5: Compare the types of files system drives
    PowerShell

    Copy
    PS C:\> Get-PSDrive -PSProvider FileSystem
    Name           Used (GB)     Free (GB) Provider      Root
    ----           ---------     --------- --------      ----
    A                                                    A:\
    C                 202.06      23718.91 FileSystem    C:\
    D                1211.06     123642.32 FileSystem    D:\
    G                 202.06        710.91 FileSystem    \\Music\GratefulDead
    X                                      Registry      HKLM:\Network

    PS C:\> net use
    New connections will be remembered.
    Status       Local     Remote                    Network
    -------------------------------------------------------------------------------
    OK           G:        \\Server01\Public         Microsoft Windows Network

    PS C:\> [System.IO.DriveInfo]::GetDrives() | Format-Table
    Name DriveType DriveFormat IsReady AvailableFreeSpace TotalFreeSpace TotalSize     RootDirectory VolumeLabel
    ---- --------- ----------- ------- ------------------ -------------- ---------     ------------- -----------
    A:\    Network               False                                                 A:\
    C:\      Fixed NTFS          True  771920580608       771920580608   988877418496  C:\           Windows
    D:\      Fixed NTFS          True  689684144128       689684144128   1990045179904 D:\           Big Drive
    E:\      CDRom               False                                                 E:\
    G:\    Network NTFS          True      69120000           69120000       104853504 G:\           GratefulDead

    PS N:\> Get-CimInstance -Class Win32_LogicalDisk

    DeviceID DriveType ProviderName   VolumeName         Size          FreeSpace
    -------- --------- ------------   ----------         ----          ---------
    A:       4
    C:       3                        Windows            988877418496  771926069248
    D:       3                        Big!              1990045179904  689684144128
    E:       5
    G:       4         \\Music\GratefulDead              988877418496  771926069248


    PS C:\> Get-CimInstance -Class Win32_NetworkConnection
    LocalName RemoteName            ConnectionState Status
    --------- ----------            --------------- ------
    G:        \\Music\GratefulDead  Connected       OK
#>


function New-TestPSDrive {

    Write-Host $MyInvocation.MyCommand `r`n("-" * 50) -ForegroundColor DarkGray

    $parameters = @{
        Name        = "T"
        PSProvider  = "FileSystem"
        Root        = "\\XPS_15_9500\SharedTemp"
        Description = "Maps to my Shared folder."
    }
    New-PSDrive @parameters

}
function Get-SMBMappings {

    Write-Host $MyInvocation.MyCommand `r`n("-" * 50) -ForegroundColor DarkGray
    $SMBMappings = Get-SMBMapping
    Write-Host "SMBMappings:" $SMBMappings 
    
}

function Get-SMBShares {

    Write-Host $MyInvocation.MyCommand `r`n("-" * 50) -ForegroundColor DarkGray

    #$SMBMappings = 
    $SMBShares = Get-SMBShare -Special $false

    foreach($SMBShare in $SMBShares){
        Write-Host "SMBShare: " $SMBShare -ForegroundColor Cyan
        #Get-SmbShareAccess -name $SMBShare.Name
    }
}

function Get-PSDrives {

    <#
        The Get-PSDrive cmdlet gets the drives in the current session. You can get a particular drive or all drives in the session.

        This cmdlet gets the following types of drives:

        Windows logical drives on the computer, including drives mapped to network shares.
        Drives exposed by PowerShell providers (such as the Certificate:, Function:, and Alias: drives) and the HKLM: and HKCU: drives that are exposed by the Windows PowerShell Registry provider.
        Session-specified temporary drives and persistent mapped network drives that you create by using the New-PSDrive cmdlet.

    #>

    Write-Host $MyInvocation.MyCommand `r`n("-" * 50) -ForegroundColor DarkGray

    $PSDrives = Get-PSDrive -PSProvider FileSystem
    $PSDrives = $PSDrives | Select-Object -Property Name, Root

    foreach($PSDrive in $PSDrives){
        Write-Host "PSDrive: " $PSDrive -ForegroundColor Cyan
        #DriveName = $PSDrive.name
        #DriveRoot = $PSDrive.Root
    }
    Return $PSDrives
    
    #On the assumption that you do not wish to exclude drives that point to the local filesystem, I believe that will serve your need.
    #Get-PSDrive -PSProvider FileSystem | Select-Object name, @{n="Root"; e={if ($_.DisplayRoot -eq $null) {$_.Root} else {$_.DisplayRoot}}}

    # If you do wish to exclude drives that point to the local filesystem, you may find to be more to your liking.
    #Get-PSDrive -PSProvider FileSystem | Select-Object Name, DisplayRoot | Where-Object {$_.DisplayRoot -ne $null}
}

function Get-NetUseDrives {
    
    Write-Host $MyInvocation.MyCommand `r`n("-" * 50) -ForegroundColor DarkGray

    $NetUseDrives = Invoke-Expression -Command " Net Use "

    foreach($NetUseDrive in $NetUseDrives){
        Write-Host "NetUse : " $NetUseDrive -ForegroundColor Cyan
        #Write-Host "Local : " $NetUseDrive.Local -ForegroundColor Cyan
        #Write-Host "Remote: " $NetUseDrive.Remote -ForegroundColor Cyan
    }
}

function Get-SystemIODriveInfo {

    Write-Host $MyInvocation.MyCommand `r`n("-" * 50) -ForegroundColor DarkGray

    $IODrives = [System.IO.DriveInfo]::GetDrives() 
    foreach($IODrive in $IODrives){
        Write-Host "IODrive: " $IODrive -ForegroundColor Cyan
    }
    
    #$IODrives | Select-Object Name, Description, DeviceID, ProviderName

}
function Get-CIMMappedLogicalDisks {

    Write-Host $MyInvocation.MyCommand `r`n("-" * 50) -ForegroundColor DarkGray

    #Get-WmiObject -ClassName Win32_MappedLogicalDisk
    $CIMMappedLogicalDisks = Get-CimInstance -ClassName Win32_MappedLogicalDisk

    foreach($CIMMappedLogicalDisk in $CIMMappedLogicalDisks){
        Write-Host "CIMMappedLogicalDisk: " $CIMMappedLogicalDisk -ForegroundColor Cyan

    }

}

function Get-CIMLogicalDisks {
    Write-Host $MyInvocation.MyCommand `r`n("-" * 50) -ForegroundColor DarkGray

    $CIMLogicalDisks = Get-CimInstance -Class Win32_LogicalDisk
    
    foreach($CIMLogicalDisk in $CIMLogicalDisks){
        Write-Host "CIMLogicalDisk: " $CIMLogicalDisk -ForegroundColor Cyan
    }

}

function Get-CIMNetworkConnections {

    Write-Host $MyInvocation.MyCommand `r`n("-" * 50) -ForegroundColor DarkGray

    $CIMNetworkConnections = Get-CimInstance -Class Win32_NetworkConnection

    foreach($CIMNetworkConnection in $CIMNetworkConnections){

        Write-Host "CIMNetworkConnection: " $CIMNetworkConnection -ForegroundColor Cyan
    }
}

function Write-DriveLog {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $LogPath = "$PSScriptRoot\DriveLog.csv"
        ,
        [Parameter()]
        [PSCustomObject]
        $PSDrives
    )

    Write-Host $MyInvocation.MyCommand `r`n("-" * 50) -ForegroundColor DarkGray

    $DriveMappings = [PSCustomObject]@{
        ComputerName    = $env:COMPUTERNAME
        PSDriveName     = $PSDrives.Name -join ","
        PSDriveRoot     = $PSDrives.Root -join ","
        Date            = $(Get-Date -Format "MM-dd-yyy")

    }

    $DriveMappings
    $DriveMappings | Export-Csv -Path $LogPath -NoTypeInformation
}



&{

    function Import-BootStrap{
        $Modules = Get-Module -Name CB* -ListAvailable
        foreach($Module in $Modules){
            Import-Module -Name $Module
        }
    }
    Import-BootStrap

    
    #cls
    #New-TestPSDrive
    #exit

    $Commands = @(
        #"Get-SMBMappings",
        "Get-SMBShares",
        #"Get-PSDrives",
        #"Get-NetUseDrives",
        #"Get-SystemIODriveInfo",
        "Get-CIMMappedLogicalDisks",
        "Get-CIMLogicalDisks",
        "Get-CIMNetworkConnections"
    )

    foreach($Command in $Commands){
        #cls
        Invoke-Expression -Command $Command
        Pause
    }
}

