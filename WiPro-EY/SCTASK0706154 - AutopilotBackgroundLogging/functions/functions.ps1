<#
    List Of Items to be Logged 
    x Computer name
    x Logged in username
    x Collect below network information
    ? Power status of computer (Plugged in vs. Battery, Power Scheme).
    ? Device state (AzureAdJoined, Domain Name)
    x Computer serial number
    
    Device details (Device Id, Thumbprint of the Device Certificate)
        •	Device Id: (The unique ID of the device in the Azure AD tenant.)
    
        Tenant details (Tenant Name, Tenant Id)
    TPM details (TPM Version, TPM Ready)
    
    Bitlocker status (Encryption Method, Protection Status, Conversion Status)
    
    Deployment profile name
    Enrollment start time
    List of items related to PC Setup Assistant Application
    Initial setup start & end time
    Critical applications start & end
    Post setup start & end time

#>

function Write-LogInfo {
    <#
        List Of Items to be Logged 
        Computer name
        Logged in username
        Collect below network information
        Power status of computer (Plugged in vs. Battery, Power Scheme).
        Device state (AzureAdJoined, Domain Name)
        Computer serial number
        Device details (Device Id, Thumbprint of the Device Certificate)
        Tenant details (Tenant Name, Tenant Id)
        TPM details (TPM Version, TPM Ready)
        Bitlocker status (Encryption Method, Protection Status, Conversion Status)
        Deployment profile name
        Enrollment start time
        List of items related to PC Setup Assistant Application
        Initial setup start & end time
        Critical applications start & end
        Post setup start & end time
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Message
    )
    Write-Host "Info: $Message" -ForegroundColor Cyan
}

function Get-ComputerName {
    <#
    .SYNOPSIS
    Returns Current ComputerName

    .DESCRIPTION
    Returns Current ComputerName from WMI Class: Win32_ComputerSystem.

    .PARAMETER  
    Mone
       
    .NOTES
        Added in Version: 1.7
        Example: IN310010XYZ  
        WMI Class: Win32_ComputerSystem
        Property: Name
        Log as: Computer Name
    

#>
    [CmdletBinding()]
    param ()
    begin {
        Write-Host "EXECUTING FUNCTION: $($MyInvocation.MyCommand)" -ForegroundColor DarkCyan
    }
    process {
        $ComputerName = $(Get-WmiObject -Class Win32_ComputerSystem).Name
        Write-LogInfo "Computer Name: $ComputerName"
        Return $ComputerName
    }
}

function Get-UserName {
    <#
    .SYNOPSIS
    Returns Current UserName

    .DESCRIPTION
    Retuens Current UserName from WMI Class: Win32_ComputerSystem.

    .PARAMETER  
    None
        
    .NOTES
    Example: US\URXXXYY
    WMI Class: Win32_ComputerSystem
    Property: Username
    Log as: Username

#>
    [CmdletBinding()]
    param ()
    begin {
        Write-Host "EXECUTING FUNCTION: $($MyInvocation.MyCommand)" -ForegroundColor DarkCyan
    }
    process {
        $Username = (Get-WmiObject -Class Win32_ComputerSystem).PrimaryOwnerName
        Write-LogInfo "PrimaryOwnerName: $Username"
    }
    end {
        Return $Username
    }
}

function Get-NetworkInformation {
    <#
    .SYNOPSIS
    Return Network Information

    .DESCRIPTION
    Collect & Return Network Adapter Information using Get-NetAdapter, specifically Name, InterfaceDescription, Status.

    .PARAMETER  
    Network Interfaces to be collected. Default: Wi-Fi, Ethernet
    $NetworkInterfaces = @('Wi-Fi', 'Ethernet')

    .NOTES
    Example: Wi-Fi, Ethernet
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [String[]]
        $NetworkInterfaces = @('Wi-Fi', 'Ethernet')
    )
    begin {
        Write-Host "EXECUTING FUNCTION: $($MyInvocation.MyCommand)" -ForegroundColor DarkCyan
    }
    process {
        $NetworkAdapters = @()
        foreach ($NetworkInterface in $NetworkInterfaces) {
            Write-LogInfo "Checking Network Interface: $NetworkInterface"

            $NetworkInterface = Get-NetAdapter -Name $NetworkInterface | Select-Object Name, InterfaceDescription, Status
            $NetAdapter = [PSCustomObject]@{
                InterfaceName        = $NetworkInterface.Name
                InterfaceDescription = $NetworkInterface.InterfaceDescription
                Status               = $NetworkInterface.Status
            }
            $NetworkAdapters += $NetAdapter
        }
    }
    end {
        Return $NetworkAdapters
    }
}
function Get-IPConfigInformartion {
    begin {
        Write-Host "EXECUTING FUNCTION: $($MyInvocation.MyCommand)" -ForegroundColor DarkCyan
    }
    process {
        $IPConfig = ipconfig /all
        $IPConfig = $IPConfig | Select-String -Pattern 'Ethernet|Wi-Fi|IPv4|IPv6|DNS|DHCP|DNS|Default Gateway|Subnet Mask|Lease Obtained|Lease Expires|DNS Servers|DHCP Server|DHCPv6 IAID|DHCPv6 Client DUID|DNS Suffix Search List|Link-local IPv6 Address|IPv4 Address|Subnet Mask|Default Gateway|DHCP Enabled|DHCP Server|DNS Servers|Lease Obtained|Lease Expires|Tunnel adapter isatap|Tunnel adapter Te'
    }
    end {
        Return $IPConfig
    }
}


function Get-ComputerPowerStatus {
    <#
    •	Battery percentage
    Example: 37
    Namespace: ROOT\CIMV2
    WMI Class: Win32_Battery
    Property: EstimatedChargeRemaining
    Log as: Battery Percentage

    •	Plugged-in

    Example: True
    Namespace: root\wmi
    WMI Class: BatteryStatus
    Property: PowerOnLine
    Log as: Plugged-In

    •	Power Scheme 

    Example: Balanced
    Namespace: ROOT\CIMV2\Power
    WMI Class: Win32_PowerPlan
    Property: ElementName  

    #>
    begin {
        Write-Host "EXECUTING FUNCTION: $($MyInvocation.MyCommand)" -ForegroundColor DarkCyan
    }
    Process {
        Get-WmiObject -Namespace ROOT\CIMV2\Power -Class Win32_PowerPlan
        #Get-CimInstance -Class win32_powerplan -Namespace ROOT\CIMV2\Power
        
        ### EstimatedChargeRemaining 
        $BatteryPercentage = $(Get-WmiObject -Namespace ROOT\CIMV2 -Class Win32_Battery).EstimatedChargeRemaining
        #$BatteryPercentage = $(Get-CimInstance -Namespace ROOT\CIMV2 -Class Win32_Battery).EstimatedChargeRemaining
        Write-LogInfo "Battery Percentage: $($BatteryPercentage)"
        
        ### Plugged-In
        $PluggedIn = $(Get-WmiObject -Namespace root\wmi -Class BatteryStatus).PowerOnLine
        Write-LogInfo "Plugged-In: $($PluggedIn)"
        
        ### Power Scheme
        $PowerScheme = $(Get-WmiObject -Namespace ROOT\CIMV2\Power Win32_PowerPlan).ElementName
        Write-LogInfo "PowerScheme: $($PowerScheme)"
    }
    end {}
}

function Get-DeviceSate {
    <#
    .SYNOPSIS
    Get Device State
    
    .DESCRIPTION
    Get Device State from WMI Class: Win32_ComputerSystem.

    .NOTES
    •	AzureAdJoined (Set the state to YES if the device is joined to Azure AD. Otherwise, set the state to NO.)

        We can run the following command in command prompt:
        dsregcmd /status to get the AzureAdJoined status.  Please check the output of this command in dsregcmd output file. Please check the screenshot as well.

        Example:
        Property: AzureAdJoined
        Log as: AzureAdJoined: Yes


    #>
    begin {
        Write-Host "EXECUTING FUNCTION: $($MyInvocation.MyCommand)" -ForegroundColor DarkCyan
    }
    process {
        $AzureAdJoined = dsregcmd /status | Select-String -Pattern 'AzureAdJoined|DomainName'
        if (-not $AzureAdJoined -ieq "YES") {
            $AzureAdJoined = 'NO'
        }
        Write-LogInfo "AzureAdJoined: $($AzureAdJoined)"
    }
    end {
        Return $AzureAdJoined
    }
}

function Get-ComputerSerialNumber {
    <#
    .SYNOPSIS
    Returns Computer Serial Number
    
    .DESCRIPTION
    Returns Computer Serial Number from WMI Class: Win32_BIOS.

    .NOTES
        Example: GTH3XYZ
        WMI Class: win32_bios
        Property: SerialNumber
        Log as:  Computer Serial Number

    #>
    begin {
        Write-Host "EXECUTING FUNCTION: $($MyInvocation.MyCommand)" -ForegroundColor DarkCyan
    }
    process {
        $ComputerSerialNumber = $(Get-WmiObject -Namespace ROOT\CIMV2 -Class Win32_BIOS).SerialNumber
        Write-LogInfo "ComputerSerialNumber: $($ComputerSerialNumber)"
    }
    end {
        Return $ComputerSerialNumber
    }
}

function Get-DeviceDetails {
    <#
        •	Device Id: (The unique ID of the device in the Azure AD tenant.)

        Get the “AadDeviceId” as Device Id from below json file. (C:\Windows\ServiceState\wmansvc\AutopilotDDSZTDFile.json)

        Attached file contains below information. Collect the AadDeviceId from this file. Please check the attached file  AutopilotDDSZTDFile.json.

        {"AutopilotServiceCorrelationId":"37c6b380-4970-44aa-a3d3-c42c3f21ac3a","ZtdRegistrationId":"a6969a7f-baa2-48f1-a338-670f04d7673d","AadDeviceId":"aab4e4ff-b23e-4e11-b852-f2d10b7fc0a6","CloudAssignedOobeConfig":286,"CloudAssignedDomainJoinMethod":0,"CloudAssignedForcedEnrollment":1,"CloudAssignedTenantDomain":"EYGS.onmicrosoft.com","CloudAssignedTenantId":"5b973f99-77df-4beb-b27d-aa0c70b8482c","CloudAssignedMdmId":"9cb77803-d937-493e-9a3b-4b49de3f5a74","CloudAssignedDeviceName":"XW%SERIAL%","DeploymentProfileName":"2100_G_StandardUserProfile","IsExplicitProfileAssignment":true,"CloudAssignedAutopilotUpdateDisabled":1,"CloudAssignedPrivacyDiagnostics":0,"HybridJoinSkipDCConnectivityCheck":0,"CloudAssignedAutopilotUpdateTimeout":1800000,"PolicyDownloadDate":"2022-09-13T15:14:02Z"}

        •	The thumbprint of the device certificate

        Get the below registry path key name as thumbprint or we can get it from dsregcmd command. I suggest using dsregcmd, because already we are using this command to get the tenant information.

        HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo
        Please check the attached registry export file here as  thumbprint reg. 
        Attached screenshot of thumbprint value from registry path.

        If we want to get it from dsregcmd command, the output looks like attached screenshot and check the attached dsregcmd output file.

        Example:
        Property: thumbprint
        Log as: The thumbprint of the device certificate.

        #>
}
function Get-TPMInfo {
    <#
    .SYNOPSIS
    Returns TPM Information
    
    .DESCRIPTION
    Returns TPM Information from WMI Class: Win32_TPM.
    
    .NOTES
    •	TPM Version:
        WMI Class: Win32_TPM
        Property: SpecVerison (Collect major version from SpecVerison value as TPM version.)
        Log as: TPM Version
        Example: Here the TPM Version is 1.2.  please check the screenshot.

    •	TPM Ready:
        Command: Get-Tpm
        Property: TPMReady
        Log as: TPM Ready
        Example:  Check the attached screenshot.
    #>
    begin {
        Write-Host "EXECUTING FUNCTION: $($MyInvocation.MyCommand)" -ForegroundColor DarkCyan
    }
    process {
        ### TPM Version
        $TPMVersion = $(Get-WmiObject -Namespace ROOT\CIMV2\Security\MicrosoftTPM -Class Win32_TPM).SpecVersion
        if ($null -eq $TPMVersion -or $TPMVersion -eq '') {
            $TPMVersion = "Not Supported" 
        }

        ### TPM Ready
        $TPMReady = $(Get-Tpm).TpmReady
    
        ### Build Object: TPMInfo
        $TPMInfo = [PSCustomObject]@{
            TPMVersion = $TPMVersion
            TPMReady   = $TPMReady
        }

        Write-LogInfo "TPM Ready: $($TPMReady)"
        Write-LogInfo "TPM Version: $($TPMVersion)"
    }
    end {
        Return $TPMInfo
    }
}
function Get-TPMVersion-delete {

    $TPMVersion = $(Get-WmiObject -Namespace ROOT\CIMV2\Security\MicrosoftTPM -Class Win32_TPM).SpecVersion
    if ($null -eq $TPMVersion -or $TPMVersion -eq '') {
        $TPMVersion = "Not Supported" 
    }
    Write-LogInfo "TPM Version: $($TPMVersion)"
}

function Get-TPMReady-delete {
    $TPMReady = $(Get-Tpm).TpmReady
    Write-LogInfo "TPM Ready: $($TPMReady)"
}

function Get-BitLockerStatus {
    <#
    .SYNOPSIS
    Get BitLocker Status
    
    
    .DESCRIPTION
    Get BitLocker Status from WMI Class: Win32_EncryptableVolume. 
    
    .NOTES
        We can use Get-BitLockerVolume to get the below Bitlocker details.

        •	Encryption Method
        Example: Xtsaes256
        Property: EncryptionMethod
        Log as:  Encryption Method

        •	Protection Status
        Example: On
        Property: ProtectionStatus
        Log as:  Protection Status

        •	Conversion Status 
        Example: Fully Encrypted
        Property: VolumeStatus
        Log as:  Conversion Status

        •	Encryption Percentage
        Example: 100
        Property: EncryptionPercentage
        Log as: Encryption Percentage

    #>
    begin {
        Write-Host "EXECUTING FUNCTION: $($MyInvocation.MyCommand)" -ForegroundColor DarkCyan
    }
    process {
        #$EncryptionMethod = Get-BitLockerVolume -MountPoint C: | Select-Object -ExpandProperty EncryptionMethod -Property EncryptionMethod, ProtectionStatus
        $BitLockerStatus = Get-BitLockerVolume -MountPoint C: | Select-Object -Property EncryptionMethod, ProtectionStatus, VolumeStatus, EncryptionPercentage 
        Write-Host "BitLockerStatus: $($BitLockerStatus)"
    }
    end {
        Write-LogInfo $BitLockerStatus.EncryptionMethod
        Write-LogInfo $BitLockerStatus.ProtectionStatus
        Write-LogInfo $BitLockerStatus.VolumeStatus
        Write-LogInfo $BitLockerStatus.EncryptionPercentage

        Return $BitLockerStatus #.EncryptionMethod
    }
}

function Get-EnrollmentStartTime {
    begin {
        Write-Host "EXECUTING FUNCTION: $($MyInvocation.MyCommand)" -ForegroundColor DarkCyan

        Function GetRegDate ($path, $key) {
            function GVl ($ar) {
                return [uint32]('0x' + (($ar | ForEach-Object ToString X2) -join ''))
            }
            $ar = Get-ItemPropertyValue $path $key
            [array]::reverse($ar)
            $time = New-Object DateTime (GVl $ar[14..15]), (GVl $ar[12..13]), (GVl $ar[8..9]), (GVl $ar[6..7]), (GVl $ar[4..5]), (GVl $ar[2..3]), (GVl $ar[0..1])
            return $time
        }
    }
    process {
        $RegKey = (@(Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" -recurse | Where-Object { $_.PSChildName -like 'DeviceEnroller' }))
        $RegPath = $($RegKey.name).TrimStart("HKEY_LOCAL_MACHINE")
        $RegDate = GetRegDate HKLM:\$RegPath "FirstScheduleTimestamp"
        $DeviceEnrolmentDate = Get-Date $RegDate
    }
    end {
        Return $DeviceEnrolmentDate
    }
}
<#
For Testing:
#>
& {
    Write-LogInfo -Message "Test"

    cls
    #Get-ComputerName
    #Get-UserName


    Get-EnrollmentStartTime
    exit
    ### Network Information:
    $NetworkAdapters = Get-NetworkInformation
    $NetworkAdapters | FL
    $IPConfigInformartion = Get-IPConfigInformartion
    foreach ($IPConfig in $IPConfigInformartion) {
        Write-LogInfo -Message $IPConfig
    }

    
    #Get-ComputerPowerStatus
    #Get-DeviceSate

    
    #Get-TPMVersion 
    #Get-TPMReady
    Get-TPMInfo
    exit
    
    $BitLockerStatus = Get-BitLockerStatus 
    Write-LogInfo $BitLockerStatus.EncryptionMethod
    Write-LogInfo $BitLockerStatus.ProtectionStatus
    Write-LogInfo $BitLockerStatus.VolumeStatus
    Write-LogInfo $BitLockerStatus.EncryptionPercentage

    #    Get-EnrollmentStartTime
}

#>