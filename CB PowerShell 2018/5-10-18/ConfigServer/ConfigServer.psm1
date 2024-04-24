<# TODO
----------------------------------------------------------------------------------------------------
1. Install VMWare Tools.
2. Set the Screen Resolution to 1024 x 768

- Install all Windows Updates available
4. Set Network Information 
    - CHECK “Internet Protocol Version 6 (TCP/IPv6)”
    - Enter the IP address, Subnet mask, Default gateway, and DNS server information. 

- Set up NIC teaming on network infrastructures that can support fault-tolerant LAN switching. This can only be done with the server has two NICs and software that can support It. 

- FOR VIRTUAL SERVERS: Create additional disk partitions based on the server function (refer to the appropriate standard for that function) 

5. Activate Windows

6. Install all Windows Updates available
    - ‘Update & Security’
    - Verify that the Windows Updates Settings says DownloadOnly 
    - After the updates are installed the server will reboot.

7. Check Device Manager for any missing drivers and install them accordingly

8. Configure Disks 
    - DCDROM -- R:
    - Create PrimaryDisk Partion D: Label "SWAP"

     Right-click the CD-ROM drive and choose “Change Drive Letter and Paths”  Click “Change” and choose “R” from the drop-down list. Click OK twice 

    - Create a primary disk partition (D:) for the Swap & Kits drive from Disk Management 
        - Label the Swap drive “Swap” or “Swap and Kits”.
        Copy the contents of the Server 2016 DVD to the D:\Kits folder 
        - Disable Files/Folder Compression
        - In the Registry Editor, locate the following key:HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem If the NtfsDisableCompression DWORD Does Not Exist, create it, if it does then skip the following bullet points: 

9. Configure Paging (Swap) File

10a. - Create a folder called “Scripts” in the root of the C: drive to store all non-logon scripts 
10b. - Create a folder called “Kits” in the root of the D: drive to store all installation files
10c. Copy the contents of the Server 2016 DVD to the D:\Kits folder

11. Configure Remote Desktop
    - Choose “Allow Remote connections to this computer” Make sure that the “Allow Connections only from Computers running Desktop with Network Level Authentication (Recommended)” is not checked. 

12. Disable “Restrict each user to a single session”
     - Type “GPEDIT.MSC” and on the Local Group Policy Editor navigate to “Computer Configuration\ Administrative Templates\ Windows Components\ Remote Desktop Services\ Remote Desktop Session Host\ Connections” 
        Double click “Restrict Remote Desktop user to a single Remote Desktop session” 
        Check “Not configured” or “Disable” and click “OK” 
        FOR VIRTUAL CITRIX SERVERS: Check the “Restrict each user to a single session” and click “OK”. Check with your CTM 

13. Disable Automatic Reboot 



14. Disable IE IE Enhance Security Configuration

15. Rename Administrator to ECIAdmin
    - Open the “eciadmin” user properties and make sure the password is set to never expire 

16. Rename Server and Join to Domain 

17?  - Install-WindowsFeature RSAT 
     - Install-WindowsFeature Telnet-Client



----------------------------------------------------------------------------------------------------
#>




function Import-Modules 
{
    ### Set the Module Location
    if($env:USERDNSDOMAIN -eq "ECILAB.NET")   {$Module = "\\tsclient\P\CBrennanScripts\Modules\"}
    if($env:USERDNSDOMAIN -eq "ECICLOUD.COM") {$Module = "\\tsclient\P\CBrennanScripts\Modules\"}
    if($env:USERDNSDOMAIN -eq "ECI.CORP")     {$Module = "\\eci.corp\dfs\nyusers\cbrennan\CBrennanScripts\Modules\"}
    if($env:COMPUTERNAME  -eq "W2K16V2")      {$Module = "\\tsclient\Z\CBrennanScripts\Modules\"}
    
    $Modules = @()
    #$Modules += "CommonFunctions"
    $Modules += "ConfigServer"

    foreach ($Module in $Modules)
    {
        ### Reload Module at RunTime
        if(Get-Module -Name $Module){Remove-Module -Name $Module}

        ### Import the Module
        $ModulePath = $ModulePath + $Module + "\" + $Module + ".psm1"
        Import-Module -Name $ModulePath -DisableNameChecking #-Verbose

        ### Test the Module - Exit Script on Failure
        if( (Get-Module -Name $Module)){Write-Host "Loading Custom Module: $Module" -ForegroundColor Green}
        if(!(Get-Module -Name $Module)){Write-Host "The Custom Module $Module WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
    }
}

function Import-Parameters
{
    $ScriptBlock = 
    {
        ### Hard Code the Parameter File
        $ParameterFile = "Parameters.csv"

        ### Set Parameter File Path 
        $ParametersFilePath =  $ScriptPath + "\" + $ParameterFile

        ### Check if Parameter File Exits
        write-log "Checking for Parameter File: $ParameterFile"

        if(-not (Test-Path $ParametersFilePath))
        {
            write-log "Parameter File Missing: $ParameterFile" -Foregroundcolor Red
            write-log "Exiting Script!" -Foregroundcolor Red
            Exit
        }
        else
        {
            write-log "Parameter File Exists. Importing: $ParameterFile" -Foregroundcolor Green
        }

        ###########################
        ### Initialize Parameters
        ###########################

        ### Import from CSV file
        $script:Parameters = Import-CSV -path $ParametersFilePath 

        foreach ($Parameter in $Parameters)
        {
            # Set Variable Scope to "Script" for Functions
            Set-Variable -Name $Parameter.NewParameter -Value $Parameter.NewValue -scope global
                
            # Verify Variables
            $Verify = Get-Variable -Name $Parameter.NewParameter
            #$Parameter.NewParameter
            #$Parameter.NewValue
        }            
    }

    Try-Catch $ScriptBlock
}

function Write-Config
{
    Param(
    [Parameter(Mandatory = $True, Position = 0)] [string]$Msg,
    [Parameter(Mandatory = $False, Position = 1)] [string]$String,
    [Parameter(Mandatory = $False, Position = 2)] [string]$String2,
    [Parameter(Mandatory = $False, Position = 3)] [string]$String3,
    [Parameter(Mandatory = $False, Position = 4)] [string]$String4
    )

    $script:ConfigReportFile = $ReportPath + "\ConfigReport_" + $ScriptName + "_" + $TimeStamp + ".log"

    ### Write the Message to the Config Report.
    $Msg = $Msg + $String + $String2 + $String3 + $String4
    Write-Host $Msg -ForegroundColor White
    $Msg | Out-File -filepath $ConfigReportFile -append   # Write the Log File Emtry
}

function Start-ConfigReport
{
    $script:ConfigReportFile = $ReportPath + "\ConfigReport_" + $ScriptName + "_" + $TimeStamp + ".log"

    ### Write Config Report Header
    Write-Config "Server Configuration Report:"
    Write-Config  ('-' * 50) 
    $ConfigReport = @()
    $ReportHeader = @{
        New_Server_Name = $NewServerName
        Build_Date = (Get-Date)
        New_Domain = $NewDomain
        Target_Server = $env:COMPUTERNAME
        Target_Domain = $env:USERDNSDOMAIN
    }

    $PSObject      = New-Object PSObject -Property $ReportHeader
    $ConfigReport += $PSObject 
    $ConfigReport | Format-List
    $ConfigReport | Format-List | Out-File  -filepath $ConfigReportFile -append 
    
    ### Write Input Parameters
    Write-Config "Input Parameters:"
    Write-Config  ('-' * 50) 

    $Params = @()
    foreach ($Parameter in $Parameters)
    {
        $NewParams = [ordered]@{
        NewParameter = $Parameter.NewParameter
        NewValue     = $Parameter.NewValue
        }

        ### Build Parameter Report Header
        $PSObject      = New-Object PSObject -Property $NewParams
        $Params       += $PSObject 
    }  
    $Params | Format-Table -AutoSize
    $Params | Format-Table -AutoSize | Out-File  -filepath $ConfigReportFile -append 
}


workflow Reboot-Computer
{
    ### Rename Computer
    #write-host "Renaming Local Computer"
    #Rename-Computer –ComputerName  $CurrentComputerName –NewName $NewComputerName # -LocalCredential $AdministratorAccount -PassThru
            
    ### Reboot Computer
    Restart-Computer -Wait -PSComputerName $CurrentComputerName

        ### Verify the New Computer Name
        $NewComputerName = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Name
        #Write-Host "New Computer Name: $NewComputerName" 
        $NewComputerName | Out-File -FilePath -Path "$ReportPath \Test.txt"
}

function Rename-LocalComputer
{

    $ScriptBlock = 
    {
        Write-Config "Executing Function: " $((Get-PSCallStack)[2].Command) `n('-' * 50)

        #$CurrentComputerName = $env:COMPUTERNAME
        $CurrentComputerName = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Name

        ### CheckCurrent Computer Name1
        if($CurrentComputerName -ne $NewComputerName)
        {
            ### Rename Computer
            write-host "Renaming Local Computer"
            Rename-Computer –ComputerName  $CurrentComputerName –NewName $NewComputerName # -LocalCredential $AdministratorAccount -PassThru
            
            ### Reboot Computer
            #Restart-Computer -Wait -PSComputerName CurrentComputerName

            ### Verify Computer Name
            write-Host "The computer is now named: $CurrentComputerName"
        }

        elseif(CurrentComputerName -eq $NewComputerName)
        {
            ### Names are the Same
            write-host "Computer Names are the same"
        }

    }

    Try-Catch $ScriptBlock
}
function Rename-Interface
{
        Write-Config "Executing Function: " $((Get-PSCallStack)[0].Command) `n('-' * 50)

        $ScriptBlock = 
        {
            ### Get NIC that is currently in use.
            $ExistingInterfaceName = (Get-NetAdapter –Physical | Where-Object Status -eq 'Up').Name

            #### Check if Interface Name Exists before Renaming
            if ($ExistingInterfaceName -ne $NewInterfacename )
             {
                Rename-NetAdapter (Get-NetAdapter -Name $ExistingInterfaceName).Name -NewName $NewInterfaceName
                                    
                ### Verify
                $VerifyInterfaceName = (Get-NetAdapter –Physical | Where-Object Status -eq 'Up').Name
                if($VerifyInterfaceName -eq $NewInterfacename)
                {
                    Write-Config "VERIFIED: Interface $ExistingInterfaceName renamed to $VerifyInterfaceName"
                }
            }

            elseif($ExistingInterfaceName -eq $NewInterfacename)
            {
                Write-Config "Not Renaming interface. Adapter is already named $ExistingInterfaceName"
            }
            elseif($ExistingInterfaceName -ne $NewInterfacename)
            {
                Write-Config "Interface Not Renamed -  ExistingInterfaceName: $ExistingInterfaceName NewInterfacename: $NewInterfacename"
            }
        }

    Try-Catch $ScriptBlock
}

function Set-IPv4
{
    $ScriptBlock = 
    {
        ### Cast the variables as IP address
        [IPAddress]$NewIPv4Address     = $NewIPv4Address.Trim()
        [IPAddress]$NewDefaultGateway  = $NewDefaultGateway.Trim()

        ### Get the Current NIC
        $CurrentInterface  = (Get-NetAdapter –Physical | where Status -eq 'Up').Name
        $CurrentInterface 
        exit

        ### Determine if IPv4 Address is Static
        $DhcpStatus = (Get-NetIPInterface -AddressFamily IPv4 -InterfaceAlias $CurrentInterface).DHCP
            
        ### If DHCP is Enabled, Create New IPv4 Address, Else Set IPv4 Addres
        if ($DhcpStatus -eq "Enabled")
        {
            ### Set the IPv4 Settings
            write-log "`n`nSetting Adapter IP Address and Default Gateway"  -ForegroundColor Yellow
            New-NetIPAddress $NewIPv4Address –InterfaceAlias $CurrentInterface -AddressFamily IPV4 –PrefixLength $NewPrefixLength -DefaultGateway $NewDefaultGateway | Out-Null
        }
        elseif ($DhcpStatus -eq "Disabled")
        {
            Set-NetIPAddress
        }


        ### Get the Current IP Address
        $CurrentIPAddress = (Get-NetIPAddress -InterfaceAlias $CurrentInterface -AddressFamily IPv4).IPv4Address

        ### Checking if the current IP Address is already the same if the New IP Address
        if($CurrentIPAddress -ne $NewIPv4Address) 
        {
            write-log "The New IP Address is Different - CurrentIP: $CurrentIPAddress NewIP: $NewIPv4Address" -ForegroundColor Yellow

            #$ISDHCPEnabled = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration  -Filter "IPEnabled=TRUE").DHCPEnabled

            # Remove the static ip
            #Remove-NetIPAddress -InterfaceAlias $CurrentInterface

            # Remove the default gateway
            #Remove-NetRoute -InterfaceAlias $CurrentInterface

            ### Change the IPv4 Settings
            write-log "`n`nSetting Adapter IP Address and Default Gateway"  -ForegroundColor Yellow
            New-NetIPAddress $NewIPv4Address –InterfaceAlias $CurrentInterface -AddressFamily IPV4 –PrefixLength $NewPrefixLength -DefaultGateway $NewDefaultGateway | Out-Null

            ### Verify Settings
            $VerifyIP = (Get-NetIPAddress -InterfaceAlias $NewInterfaceName -AddressFamily IPv4).IPv4Address

            if($VerifyIP -eq $NewIPv4Address){Write-Log "IP Address set to this new value: " $VerifyIP}
            else {Write-Log "Mismatch - VerifyIP: $VerifyIP NewIPv4Address: $NewIPv4Address"}
        }
        elseif($CurrentIPAddress -eq $NewIPv4Address) 
        {
            ### Do nothing if the New iP Address is the same as the Existing IP Address 
            write-log "The IP Address is the Same - CurrentIP: $CurrentIPAddress NewIP: $NewIPv4Address" -ForegroundColor Yellow
        }
    }

    Try-Catch $ScriptBlock
}

function Set-IPv6
{

    $ScriptBlock = 
    {
        
        Write-Config "Executing Function: " $((Get-PSCallStack)[0].Command) `n('-' * 50)

        ### Set IPv6
        ###---------------------------------------------------------------------------
        
        ### Get Current Interface
        $CurrentInterface     = Get-NetAdapter –Physical | where status -eq 'up'
        $CurrentInterfaceName = $CurrentInterface.Name
    
        ### Get IPv6 State
        $IPv6State   = Get-NetAdapterBinding -Name $CurrentInterfaceName -DisplayName "Internet Protocol Version 6 (TCP/IPv6)"
        $IPv6Enabled = $IPv6State.Enabled

        ### Comapre IPv6 State with IPv6 Preference
        if (($Ipv6Preference -eq "Enable") -OR ($Ipv6Preference -eq "Disable"))
        {
            write-log "Configuring IPv6: -InterfaceAlias: $CurrentInterfaceName -Ipv6Enabled: $IPv6Enabled -IPv6Preference: $Ipv6Preference"

            if ((-not($IPv6Enabled)) -AND ($Ipv6Preference -eq "Enable"))
            {
                ### Enable IPv6
                Enable-NetAdapterBinding -InterfaceAlias $CurrentInterfaceName -ComponentID ms_tcpip6
            }
            elseif (($IPv6Enabled) -AND ($Ipv6Preference -eq "Disable"))
            {
                ### Disbale IPv6
                Disable-NetAdapterBinding -InterfaceAlias $CurrentInterfaceName -ComponentID ms_tcpip6
            }
            elseif ((($IPv6Enabled) -AND ($Ipv6Preference -eq "Enable")) -OR (-not($IPv6Enabled) -AND ($Ipv6Preference -eq "Disable")))
            {
                ### Do nothing
                write-log "IPV6 Setting are correct. Continuing."
            }
        }
        elseif ((-not($Ipv6Preference -eq "Enable")) -OR (-not($Ipv6Preference -eq "Disable")))
        {
            write-log "Ipv6Preference specified in parameters was: $Ipv6Preference. Must be set to Enable or Disable." 

        }
        
        ### Verify IPv6 Preference was set
        ###-----------------------------------------------
        $VerifyIPv6Enabled = (Get-NetAdapterBinding -Name $CurrentInterfaceName -DisplayName "Internet Protocol Version 6 (TCP/IPv6)").Enabled

        if ((($VerifyIPv6Enabled) -AND ($Ipv6Preference -eq "Enable")) -OR  (-NOT($VerifyIPv6Enabled) -AND ($Ipv6Preference -eq "Disable")))
        {
            ### Verified
            write-config "VERIFIED IPv6: -InterfaceAlias: $CurrentInterfaceName -Ipv6Enabled: $VerifyIPv6Enabled -IPv6Preference: $Ipv6Preference"
        }
        elseif ((-not($VerifyIPv6Enabled) -AND ($Ipv6Preference -eq "Enable")) -OR  (($VerifyIPv6Enabled) -AND ($Ipv6Preference -eq "Disable")))
        {
            ### Not Verified
            write-config "NOT VERIFIED IPv6: -InterfaceAlias: $CurrentInterfaceName -Ipv6Enabled: $VerifyIPv6Enabled -IPv6Preference: $Ipv6Preference"
        }
    }

    Try-Catch $ScriptBlock
}

function Set-CDRom
{
    Write-Config "Executing Function: " $((Get-PSCallStack)[0].Command) `n('-' * 50)

    $ScriptBlock = 
    {
        Write-Config "Executing Function: " $((Get-PSCallStack)[2].Command) `n('-' * 50)
        
        ### Drive Letter Must End with Colon ":"
        $LastChar = $NewCDLetter.substring($NewCDLetter.length-1) 
        if ($LastChar -ne ":"){$NewCDLetter = $NewCDLetter + ":"}

        ### Get the Current CD-ROM Letter & Volume
        $CurrentCDLetter = (Get-WMIObject -Class Win32_CDROMDrive -ComputerName $env:ComputerName).Drive

        if ($CurrentCDLetter -ne $NewCDLetter)
        {
            ### Get the CD Volume Object
            $CDVolume = Get-WmiObject -Class Win32_Volume -ComputerName $env:computername -Filter "DriveLetter='$CurrentCDLetter'" -ErrorAction Stop            
 
            ### Change the CD-ROM Letter of the CD Volume Object
            Set-WmiInstance -InputObject $CDVolume -Arguments @{DriveLetter=$NewCDLetter} | Out-Null

            ### Verify New CD-ROM Letter
            $VerifiedCDLetter = (Get-WMIObject -Class Win32_CDROMDrive -ComputerName $env:computername).Drive
            if ($VerifiedCDLetter -eq $NewCDLetter)
            {
                Write-Config "VERIFIED:`t CD-ROM Renamed - CurrentCDLetter: $VerifiedCDLetter renamed to VerifiedCDLetter: $VerifiedCDLetter"
            }
            elseif($VerifiedCDLetter -ne $NewCDLetter)
            {
                Write-Config "Mismatch - CurrentCDLetter: $VerifiedCDLetter doesnt match NewCDLetter: $NewCDLetter"
            }
        }
        else
        {
            Write-Config "Not Renaming CD-Rom. Drive Letters are the same: CurrentCDLetter: $CurrentCDLetter"
        }
    }

    Try-Catch $ScriptBlock
}

function Set-SwapFile
{
    $ScriptBlock = 
    {
        function Set-SwapFile-Physical
        {
            $NewSwapFileLocation = "D:"
            $PageFileInitialSize = "1024"
            $PageFileMaximumSize = "1024"

            ### Turn Off Automatic PageFile Management
            $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
            if ($ComputerSystem.AutomaticManagedPagefile)
            {
                $ComputerSystem.AutomaticManagedPagefile = $false
                $ComputerSystem.Put()
            }

            ### Delete the Current PageFile
            $CurrentPageFile = Get-WmiObject -Query "select * from Win32_PageFileSetting where name = $CurrentPageFileLocation"
            $CurrentPageFile.delete()

            ### Create New Page File
            $NewPageFileLocation = $NewSwapFileLocation + "\pagefile.sys" 
            Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name=$NewPageFileLocation; InitialSize = $PageFileInitialSize; MaximumSize = $PageFileMaximumSize}
        }

        function Set-SwapFile-HyperV
        {
            ### This code is not complete

            $ComputerName = "2012_R2_Base"
            $SmartPagingFilePath = "D:\SmartPaging"

            if((Get-Module Hyper-v) -ne $Null)
            {
                Get-VM | where-object {$_.Name -like $ComputerName  } 
                Set-VM -ComputerName $ComputerName -SmartPagingFilePath $SmartPagingFilePath
            }
            elseif((Get-Module Hyper-v) -eq $Null)
            {
            write-host "This host is a Hyper-V VM."
            write-host "These commands require the Hyper-V Module & Services to be loaded"
            Pause-Script "This host is a Hyper-V VM. `n`n These commands require the Hyper-V Module & Services to be loaded. `n`n Hit any key to Continue."
            }
        }

        function Set-SwapFile-VMWare
        {
            write-host "This host is a VMWare VM."
            write-host "These commands require the PowerCLI Module & Services to be loaded"
            Pause-Script "This host is a Hyper-V VM. `n`n These commands require the PowerCLI V Module & Services to be loaded. `n`n Hit any key to Continue."

            ### This code is not complete
            <#
            Get-VM  | %{
            $ds = $_.ExtensionData.Layout.Swapfile.Split(']')[0].TrimStart('[')
            $_ | Select Name,@{N="Swap DS";E={$ds}},@{N="Free GB";E={[math]::Round($dsTab[$ds],1)}}
            #>
        }

        function Get-MachineType
        {
            $Computer = $env:COMPUTERNAME
            $ComputerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $env:COMPUTERNAME #-ErrorAction Stop -Credential $Credential 

            switch ($ComputerSystemInfo.Model) 
            { 
                # Check for Hyper-V Machine Type 
                "Virtual Machine" 
                { 
                    $MachineType="Hyper-V" 
                    $Machine = "VM"
                } 
 
                # Check for VMware Machine Type 
                "VMware Virtual Platform"
                { 
                    $MachineType="VMware"
                    $Machine = "VM" 
                } 
 
                # Check for Oracle VM Machine Type 
                "VirtualBox" 
                { 
                    $MachineType="VirtualBox" 
                    $Machine = "VM"
                }
                default 
                { 
                    $MachineType="Physical"
                    $Machine = "Physical" 
                } 
                }          
  
            $script:Machine              = $Machine
            $script:MachineType          = $MachineType 
            $script:MachineModel         = $ComputerSystemInfo.Model 
            $script:MachineManufacturer  = $ComputerSystemInfo.Manufacturer 

            write-host "This host is a VM. Thee are the properties:"
            write-host "Machine: "             $Machine
            write-host "MachineType: "         $MachineType
            write-host "MachineModel: "        $MachineModel
            write-host "MachineManufacturer: " $MachineManufacturer
        }

        ### Detect Machine Type ###

        # Call the Function
        Get-MachineType

        if($MachineType -eq "Physical")
        {
            write-host "Machine is Physical"
            # Call the Function
            Set-SwapFile-Physical
        }
        elseif($MachineType -eq "Hyper-V")
        {
            write-host "Hyper-V"
            Set-SwapFile-HyperV
        }
        elseif($MachineType -eq "VNWare")
        {
            write-host "Hyper-V PowerCLI"
            Set-SwapFile-VMWare
        }
    }

    Try-Catch $ScriptBlock

}
function Add-WindowsFeatures
{
    $ScriptBlock = 
    {
        <#
        $WindowsFeatures  = @()
        $WindowsFeatures += "NET-Framework-Features"
        $WindowsFeatures += "NET-Framework-Core"
        $WindowsFeatures += "GPMC"
        $WindowsFeatures += "RSAT"
        $WindowsFeatures += "Telnet-Client"
        #>

        ### List Features to Install
        Write-Log "The following Features will be installed" -foregroundcolor Cyan
        foreach ($Feature in $WindowsFeatures)
        {
            Write-Log $Feature -foregroundcolor Gray
        }

        foreach ($Feature in $WindowsFeatures)
        {
            ### Install Feature
            Install-WindowsFeature -name $Feature

            ### Verify Feature
            Write-log "Verifying Installaton of $Feature"
            $Feature = Get-WindowsFeature -name $Feature 
            if($Feature.Installed -eq "True")
            {
                Write-config "Windows Feature Installed: -Name: $Feature.Name -Installed: $Feature.Installed "
            }
            if($Feature.Installed -ne "True")
            {
                Write-Config "Windows Feature NOT Installed: -Name: $Feature.Name -Installed: $Feature.Installed "
            }
        } 
    }
    
    Try-Catch $ScriptBlock
}

function Update-Windows
{
    $ScriptBlock = 
    {
        ## Set the Path too the Modules
        #$script:ScriptPath  = split-path -parent $MyInvocation.MyCommand.Definition # Required method for PS 2.0
        $script:PSWindowsUpdateScriptPath = $ScriptPath + "\PSWindowsUpdate\"

        function Install-Updates
        {
            ### Install Updates
            Get-WUInstall  -IgnoreReboot 
        }

        function Ask-YesNo($Prompt, $YesMsg, $NoMsg)
        {
            ### Advanced Function using cmdletbinding Methods
            [cmdletbinding()]

            [Parameter(Mandatory=$True, Position=0)]
            [String]$Prompt,

            [Parameter(Mandatory=$True, Position=1)]
            [String]$YesMsg

            [Parameter(Mandatory=$True, Position=1)]
            [String]$NoMsg

            $ReadHost = Read-Host "$Prompt [Y/N]"
            $ReadHost = $ReadHost.ToUpper()

            if ($ReadHost -eq "Y" )
            {
                write-host $YesMsg
                Install-Updates
            }
            elseif($ReadHost -eq "N")
            {
                write-host $NoMsg
            }
            elseif (($ReadHost -ne "Y") -or ($ReadHost -ne "N"))
            {
                write-host "You did not enter Y or N!" -foregroundcolor white
                Ask-YesNo
            }
        }

        function Install-PSWindowsUpdateModule
        {
            # This function uses the Windows Update Module for PowerShell
  
            ### Check for Module
            if( -not (Test-Path $PSWindowsUpdateScriptPath))
            {
                write-log "The PSWindowsUpdate module is not avalable in $PSWindowsUpdateScriptPath."
            }
            elseif( -not (Test-Path $PSWindowsUpdateScriptPath))
            {
                write-log "Module exists. Importing." 
            }

            ### Unbloack the Files
            Unblock-File -Path "$PSWindowsUpdateScriptPath\*"

            ### Import the Module
            Import-Module $PSWindowsUpdateScriptPath\PSWindowsUpdate

            ### Show PSWindowsUpdate Commandlets
            #Get-Command –module PSWindowsUpdate
        }

        function List-AvailableUpdates
        {
            ### List Avaialable Updatesi
            Write-Host "Getting List of Udates: This requires Internet Access"
            Write-Host "Getting List of the Updates Avalable for this Computer. `n This may take a minute . . ." -ForegroundColor Cyan
            Get-WUInstall -ListOnly | FT Title, KB #, ComputerName, Size   
        }

        function Run-Updates
        {
            Install-PSWindowsUpdateModule
            List-AvailableUpdates
            Ask-YesNo "Do You want to install these updates?" "Installing Updates" "Canceling Update Installs"
        }

        function Check-InternetConnection
        {

            $TargetURL = "google-public-dns-a.google.com"
            $TargetIP  = "8.8.8.8"
                 
            write-host "Testing Internet Connection."
            $TestInternetConnection = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}')).IsConnectedToInternet 
            $PingInternet = Test-Connection $TargetIP -count 1 -quiet


            If ($PingInternet -eq "True")
            {
                write-host "Internet Connection is Good."
                Run-Updates
            }
            elseif($PingInternet -eq "False")
            {
                write-host "Internet Connection is not Available."
            }
        }
    
    Write-Host "Windows Updates requires a connection to the Internet. `n Testing internet connection."
    Check-InternetConnection

        
    }
    Try-Catch $ScriptBlock

}

function Set-FirewallRules
{
    $ScriptBlock = 
    {
        $Parameters = @{
            DisplayName = "Allow RDP from 10.0.0.0/24"
            LocalPort = 3390
            Direction="Inbound"
            Protocol ="TCP" 
            Action = "Allow"
                
            # Get the Remote Address from the $ParamaterFile
            RemoteAddress = $AllowRDPSubnet
        }

        ## Checking if the Rule Exists
        write-host "Checking if rule exists: " $Parameters.DisplayName
        $Rules = Get-NetFirewallRule -DisplayName *
            
        if (-not $Rules.DisplayName.Contains($Parameters.DisplayName)) 
        {
            ### Create New Firewall Rule
            Write-Log "This rule Does not exist. Creating New Firewall Rule"
            New-NetFirewallRule -DisplayName $Parameters.DisplayName -Action $Parameters.Action -Direction $Parameters.Direction `
            –LocalPort $Parameters.LocalPort -Protocol $Parameters.Protocol -RemoteAddress $Parameters.RemoteAddress| Out-Null
        }
        else
        {
            write-host "This rule already exists. Not Creating"
        }

        ### Show the Firewall Settings
        write-log "Checking the Firewall Settings"
        $FirewallRule = Get-NetFirewallRule -DisplayName $Parameters.DisplayName
        write-host "DisplayName: " $FirewallRule.DisplayName "Action: " $FirewallRule.Action "Enabled: " $FirewallRule.Enabled
    }
    Try-Catch $ScriptBlock
}

function Rename-LocalAdministrator
{

    $ScriptBlock = 
    {

        function Get-CurrentAdmin
        {
            ### Find the Current Local Administrator Account
            Add-Type -AssemblyName System.DirectoryServices.AccountManagement
            $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $env:ComputerName)
            $UserPrincipal = New-Object System.DirectoryServices.AccountManagement.UserPrincipal($PrincipalContext)
            $Searcher = New-Object System.DirectoryServices.AccountManagement.PrincipalSearcher
            $Searcher.QueryFilter = $UserPrincipal

            ### The Administrator account is the only account that has a SID that ends with “-500”
            $Account = $Searcher.FindAll() | Where-Object {$_.Sid -Like "*-500"}
            $script:CurrentAdminName = $Account.Name
            Write-Log "The current Local Administrator Account is: $CurrentAdminName"
        }

        function Rename-Admin
        {
            ### Get the Current Local Admin Account
            $User= Get-WmiObject -Class Win32_UserAccount -Filter  "LocalAccount='True'" | Where {$_.Name -eq $CurrentAdminName}

            ### Rename the Current Local Admin Account
            write-host "Renaming $CurrentAdminName to $NewAdminName "
            $user.Rename($NewAdminName) | Out-Null
        }

        function Check-CurrentAdmin
        {
            ### Check if Local Admin is already renamed

            if($CurrentAdminName -eq $NewAdminName)
            {
                write-host "CurrentAdminName is the same as NewAdminName"
                write-host "Current Admin: $CurrentAdminName New Admin: $NewAdminName"
            }
            elseif($CurrentAdminName -ne $NewAdminName)
            {
                write-host "Renaming Local Admin Account"
                write-host "Current Admin: $CurrentAdminName New Admin: $NewAdminName"
                Rename-Admin
            }
        }

        function Verify-NewAdmin
        {
            write-host "Verifying new Admin Account Name"
            Get-CurrentAdmin
        }

        Get-CurrentAdmin
        Check-CurrentAdmin
        Verify-NewAdmin

    }

    Try-Catch $ScriptBlock
}

function Join-ComputerToDomain
{
    $ScriptBlock = 
    {
        Param([String]$User = "Administrator")

        function Join-Domain
        {
            write-host "Addding computer to domain $ADDomain"
            $Password = Read-Host -Prompt "Enter password for $ADDomain\$User" -AsSecureString 
            $UserName = "$ADDomain\$user" 
            $credential = New-Object System.Management.Automation.PSCredential($UserName,$Password) 

            try
            {
                Add-Computer -DomainName $ADDomain -Credential $Credential #-restart –force
            }

            catch
            {
                write-log "Unable to join Domain $ADDomain"
                $error[0]
            }
        }

        ### Check if Domain is reachable
        if (Test-Connection $ADDomain)
        {
            write-host "Adding computer to Domain $ADDomain"
            Join-Domain
        }
        elseif(-not (Test-Connection $ADDomain))
        {
            write-host-"The Domain $ADDomain is not reachable"
        }
    }

    Try-Catch $ScriptBlock
}

function Set-ServerBuildType($ServerBuildType)
{
    Write-Log "BuildType: $ServerBuildType" -ForegroundColor Cyan
    Write-Log "Server Name: $NewComputerName "
    ### Set Parameters for ALL Server Build Types
    $BuildDate = Get-Date -Format g


    ### Set Parameters for Server Build Types

    Switch ($ServerBuildType)
    {
         ### Windows Server 2012 R2 Builds
         2012R2_Std {}
         2012R2_DC{}
         2012R2_Citrix{}
     
         ### Windows Server 2016 Builds
         2016_Std 
         {
            ### Server Build Standards
            $global:NewInterfacename = "Ethernet01"
            $global:Ipv6Preference =  "Enable"
            $global:NewCDLetter = "R:"
         
            ### Windows Features
            $global:WindowsFeatures  = @()
            $WindowsFeatures += "NET-Framework-Features"
            $WindowsFeatures += "NET-Framework-Core"
            $WindowsFeatures += "GPMC"
            $WindowsFeatures += "RSAT"
            $WindowsFeatures += "Telnet-Client"



         }

         2016_DC{}
         2016_Citrix{}


    }

    
}


function Create-KitsFolder
{
    $Path = "D:\Kits"
    New-Item -ItemType directory -Path $Path -Force | Out-Null

    ### Verify
    if(Test-Path $Path)
    {
        Write-Config "VERIFIED: Folder Created - $Path"
    }
}

function Create-ScriptsFolder
{
    $Path = "C:\Scripts"
    New-Item -ItemType directory -Path $Path -Force | Out-Null

    ### Verify
    if(Test-Path $Path)
    {
        Write-Config "VERIFIED: Folder Created - $Path"
    }
}

function Enable-RemoteDesktop
{
    ### Enable Remote Desktop
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
}

function Build-Server
{

    Write-Log "Building Server:" -foregroundcolor Cyan

    # Run Functions
    #--------------------------
    #Import-Parameters
    #Start-ConfigReport
        #Screen Resolution to 1024 x 768    
    #Rename-LocalComputer
    #Rename-Interface
    #Set-TimeZone
    #Set-IPv4
    #Set-IPv6
    #Set-CDRom
    #Set-SwapFile
    #Add-WindowsFeatures
    #Update-Windows
    #Set-WindowsFirewall
    #Add-WindowsFeatures
    #Rename-LocalAdministrator
    #Join-ComputerToDomain

    #Configure-RemoteDesktop
    #Create-ScriptsFolder
    #Create-KitssFolder
    #Disable-AutomaticReboot
    #Diable-IE-ESC
    #Create-KitsFolder
    #Create-ScriptsFolder
    Enable-RemoteDesktop


}
