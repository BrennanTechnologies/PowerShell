#########################################
### VM Provisioning Module
### ECI.EMI.Automation.VM.Prod.psm1
#########################################

function Get-ECI.EMI.Automation.VM.VMTemplate
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Getting VMWare Template : $VMTemplateName"  -ForegroundColor DarkCyan
    
    #$ECIVMTemplate = $VMTemplateName
    $ECIVMTemplate = Get-Template -Name $VMTemplateName -Server $vCenter -ErrorAction SilentlyContinue

    if(($ECIVMTemplate.count) -gt 1)
    {
        $ECIVMTemplate = $ECIVMTemplate[0]
    }
    if(-NOT $ECIVMTemplate)
    {
        $ErrorMsg = "ECI.ERROR: Template Not Found"
        Write-Error -Message $ErrorMsg -ErrorAction Continue -ErrorVariable +ECIError
        Send-ECI.Alert -ErrorMsg $ErrorMsg
    }
    
    $global:ECIVMTemplate = $ECIVMTemplate
    Write-Host "Template Selected       : $ECIVMTemplate" -ForegroundColor Cyan
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray

    Return $ECIVMTemplate
}

function Set-ECI.EMI.Automation.VM.ServerUUID
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    
    ### Set VM Name fromn HostName Parameters
    ###----------------------------------------------------------------
   
    $VMID = (Get-VM -Name $VMName).ID
    $VMID = $VMID.Split("-")
    
    #$VMID = $VMID[-2].ToUpper() + "-" + $VMID[-1]
    $VMID = $VMID[-2] + "-" + $VMID[-1]

    $VMUUID = Get-VM $VMName | %{(Get-View $_.Id).config.uuid}

    #$ServerUUID = "VI" + "." + $VMUUID + "." + ($VMID[-2]).ToUpper() + "-" + $VMID[-1]
    $ServerUUID = "VI" + "." + $VMUUID + "." + $VMID[-2] + "-" + $VMID[-1]
    
    $global:VMUUID       = $VMUUID
    $global:VMID         = $VMID
    $global:ServerUUID   = $ServerUUID

    Write-Host "vCenterUUID   : " $vCenterUUID -ForegroundColor DarkCyan
    Write-Host "VMID          : " $VMID        -ForegroundColor DarkCyan
    Write-Host "ServerUUID    : " $ServerUUID  -ForegroundColor Cyan
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $ServerUUID
   
    #Example:
    #---------
    #VI-d8c273b7-6f4e-4ce7-8986-72dfbd3f0376-VM-38002
}

###############################################
### Create New VM  - ECI Cmdlet
###############################################

function New-ECI.EMI.Automation.VM
{
    Param(
    [Parameter(Mandatory = $True)][string]$ConfigurationMode,
    [Parameter(Mandatory = $True)][string]$VMName,
    [Parameter(Mandatory = $True)][string]$ECIVMTemplate,
    [Parameter(Mandatory = $True)][string]$OSCustomizationSpecName,
    [Parameter(Mandatory = $True)][string]$ResourcePool,
    [Parameter(Mandatory = $True)][string]$OSDataStore,
    [Parameter(Mandatory = $True)][string]$PortGroup,
    [Parameter(Mandatory = $True)][string]$IPv4Address,
    [Parameter(Mandatory = $True)][string]$SubnetMask,
    [Parameter(Mandatory = $True)][string]$DefaultGateway,
    [Parameter(Mandatory = $True)][string]$PrimaryDNS,
    [Parameter(Mandatory = $True)][string]$SecondaryDNS
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    function New-ECI.EMI.Automation.VM.OSCustomizationSpec
    {
        $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

        ###----------------------------------------------------------
        ### Create New OSCustomizationSpec
        ###----------------------------------------------------------
        ### Remove OSCustomizationSpec
        if(Get-OSCustomizationSpec $OSCustomizationSpecName -ErrorAction SilentlyContinue)
        {
            Write-Host "Removing OSCustomizationSpec   :" $OSCustomizationSpecName
            Remove-OSCustomizationSpec $OSCustomizationSpecName -Confirm:$false
        
            ### Remove OSCustomizationNicMapping
            #Get-OSCustomizationSpec $OSCustomizationSpecName | Get-OSCustomizationNicMapping | Remove-OSCustomizationNicMapping -Confirm:$false
        }
        else
        {
            Write-Host "No OSCustomizationSpec Found: "
        }    
    
        ### New OSCustomizationSpec
        ###------------------------
        $OSCustomizationSpec = @{
            Name             = $OSCustomizationSpecName 
            Type             = $Type 
            OSType           = $OSType 
            NamingScheme     = $NamingScheme.trim()
            FullName         = $FullName 
            OrgName          = $OrgName 
            AdminPassword    = $AdminPassword
            ChangeSid        = $True
            DeleteAccounts   = $False 
            TimeZone         = $TimeZone 
            ProductKey       = $ProductKey 
            LicenseMode      = $LicenseMode 
            Workgroup        = $Workgroup
        }
    
        Write-Host "Creating - OSCustomizationSpec : $OSCustomizationSpecName" -ForegroundColor Cyan
        New-OSCustomizationSpec @OSCustomizationSpec
        Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    }

    function New-ECI.EMI.Automation.VM.OSCustomizationNicMapping
    {
        $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
        ###----------------------------------------------------------
        ### Create New OSCustomizationSpec NIC Mapping
        ###----------------------------------------------------------    
        $OSCustomizationNicMapping = {
            IpMode          = "UseStaticIp"
            IpAddress       = $IPv4Address 
            SubnetMask      = $SubnetMask 
            DefaultGateway  = $DefaultGateway 
            Dns             = $PrimaryDNS + "," + $SecondaryDNS
        }
        Write-Host "Creating - OSCustomizationNicMapping  : $OSCustomizationSpecName" -ForegroundColor Cyan
        #Get-OSCustomizationSpec $OSCustomizationSpecName | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping @OSCustomizationNicMapping
        $NicMapping = @{

         IPMode         = "UseStaticIp "
         IpAddress      = $IPv4Address 
         SubnetMask     = $SubnetMask 
         DefaultGateway = $DefaultGateway 
         Dns            = $PrimaryDNS,$SecondaryDNS
        }

        Get-OSCustomizationSpec $OSCustomizationSpecName | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IPMode UseStaticIp -IpAddress $IPv4Address -SubnetMask $SubnetMask -DefaultGateway $DefaultGateway -Dns $PrimaryDNS,$SecondaryDNS

        Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    }

    function New-ECI.EMI.Automation.VM.VM
    {
        $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

        ###----------------------------------------------------------
        ### Create New VM
        ###----------------------------------------------------------  

        ### Check if VM exists
        ###--------------------------
        try
        {
            $VMExists = Get-VM -Name $VMName -ErrorAction SilentlyContinue ###<---- NOTE: This gerenerats a false error if the VM does not exist.
            Write-Host "ExceptionType: " $global:Error[0].Exception.GetType().fullname -ForegroundColor Magenta
        }
        catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]
        {
            Write-Host "This VM Does Not Exists" -ForegroundColor Magenta
        }
        catch
        {
            Write-ECI.ErrorStack
        }
        
        if($VMExists)
        {
            ### Do we want to Abort or run in Report mode ????????
            
            ### Run in Report Mode
            ###--------------------------
            #Write-Host "This VM Exists. Running Report Mode" -ForegroundColor Red
            #$global:ConfigurationMode = "Report"                                    ### <---------- ConfigurationMode  

            ### Throw Abort
            ###--------------------------
            $global:Abort = $True
            
            Write-Host "Invoking Abort Error!!!" -ForegroundColor red
            Invoke-ECI.Abort
        }
        
        ### VM does not exist
        ###--------------------------
        else
        {
            ### Create New VM
            ###----------------------------------------------------------
            Write-Host "Creating New VM       : " $VMName -ForegroundColor Cyan
            Write-Host "Please wait. The VM Provisioning process may take a while . . .  " -ForegroundColor Yellow
            try
            {
                $VMParameters = @{
                    VMName                    = $VMName
                    Template                  = $ECIVMTemplate
                    vCenterFolder             = $vCenterFolder
                    OSCustomizationSpec       = $OSCustomizationSpecName
                    ResourcePool              = $ResourcePool
                    OSDataStore               = $OSDataStore
                } 

                $ScriptBlock = 
                {
                    ### Without Folder
                    #New-VM @VMParameters
                    #New-VM -Name $VMName -Template $ECIVMTemplate -ResourcePool $ResourcePool -Datastore $OSDataStore -OSCustomizationSpec $OSCustomizationSpecName

                    ### With Folder
                    
                    ### New VM
                    $NewVMParams = {
                        Name                = $VMName 
                        Template            = $ECIVMTemplate 
                        Location            = $vCenterFolder 
                        ResourcePool        = $ResourcePool 
                        Datastore           = $OSDataStore 
                        OSCustomizationSpec = $OSCustomizationSpecName
                    }
                    #New-VM @NewVMParams

                    if($VMName.count -eq 1 -and $VMName -isnot [system.array])
                    {
                        New-VM -Name $VMName -Template $ECIVMTemplate -Location $vCenterFolder -ResourcePool $ResourcePool -Datastore $OSDataStore -OSCustomizationSpec $OSCustomizationSpecName
                    }
                    else
                    {
                        Write-Error -Message "ECI.Error: VMName is not Unique." -ErrorAction Continue -ErrorVariable +ECIError
                    }
				}
                
                if($ConfigurationMode -eq "Configure")                              ### <---------- ConfigurationMode  
                {
                    try
                    {
                        Invoke-Command -ScriptBlock $ScriptBlock -ErrorVariable +ECIError
                    }
                    catch
                    {
                        Write-ECI.ErrorStack
                    }
                }
                if($ConfigurationMode -eq "Report")                                 ### <---------- ConfigurationMode  
                {
                    Write-Host "ECI-WHATIF-COMMAND: " $ScriptBlock
                    Write-ECI.EMI.Report -Report $ScriptBlock
                }

            }

            catch
            {
                Write-ECI.ErrorStack
            }
        }

        Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

   &{
        BEGIN {}

        PROCESS 
        {
            New-ECI.EMI.Automation.VM.OSCustomizationSpec
            New-ECI.EMI.Automation.VM.OSCustomizationNicMapping
            New-ECI.EMI.Automation.VM.VM
        }

        END {}

    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Set-ECI.EMI.Automation.VM.VMCPU
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    
    ##########################################
    ### Modify Parameter Values
    ##########################################
    ### Cast the Variable
    [int]$vCPUCount = $vCPUCount
    
    ##########################################
    ### DESIRED STATE PARAMETERS
    ##########################################
    $PropertyName      = "vCPUCount"
    $DesiredState      = $vCPUCount
    #ConfigurationMode = "Configure" ### Report - Configure
    $AbortTrigger      = $False  ### $True - $False
    
    ##########################################
    ### GET CURRENT CONFIGURATION STATE: 
    ##########################################
    [scriptblock]$script:GetCurrentState =
    {
        $global:CurrentState = (Get-VM $VMName | Select NumCpu).NumCpu
    }

    ##########################################
    ### SET DESIRED-STATE:
    ##########################################
    [scriptblock]$script:SetDesiredState =
    {
        ### Set VM CPU Count
        ###-----------------------------------------
        Write-Host "Setting VM CPU Count: " $vCPUCount -ForegroundColor Cyan
        $VMName = Get-VM -Name $VMName
        
        if($vCPUCount -ge $vCPUCountMin -AND $vCPUCount -le $vCPUCountMax)
        {
            if($VMName.count -eq 1 -and $VMName -isnot [system.array])
            {
                Set-VM -VM $VMName -Confirm:$False -NumCpu $vCPUCount
            }
            else
            {
                Write-Error -Message "ECI.Error: VMName is not Unique." -ErrorAction Continue -ErrorVariable +ECIError
            }
        }
        else
        {
            Write-Error -Message "ECI.Error: vCPU Count is Out of Range" -ErrorAction Continue -ErrorVariable +ECIError
        }
    }
    
    ##########################################
    ### CALL CONFIGURE DESIRED STATE:
    ##########################################
    $Params = @{
        ServerID            = $ServerID 
        HostName            = $HostName 
        FunctionName        = $FunctionName 
        PropertyName        = $PropertyName 
        DesiredState        = $DesiredState 
        GetCurrentState     = $GetCurrentState 
        SetDesiredState     = $SetDesiredState 
        ConfigurationMode   = $ConfigurationMode 
        AbortTrigger        = $AbortTrigger
    }
    Configure-DesiredState @Params

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Set-ECI.EMI.Automation.VM.VMMemory
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
       
    ##########################################
    ### DESIRED STATE PARAMETERS
    ##########################################
    $PropertyName      = "vMemoryGB"
    $DesiredState      = $vMemoryGB
    #ConfigurationMode = "Configure" ### Report - Configure
    $AbortTrigger      = $False  ### $True - $False
    
    
    ##########################################
    ### GET CURRENT CONFIGURATION STATE: 
    ##########################################
    [scriptblock]$script:GetCurrentState =
    {
        $global:CurrentState = (Get-VM $VMName | Select MemoryGB).MemoryGB
    }

    ##########################################
    ### SET DESIRED-STATE:
    ##########################################
    [scriptblock]$script:SetDesiredState =
    {
        ### Set VM Memory
        ###-----------------------------------------
        Write-Host "Setting VM vMemorySizeGB: " $vMemoryGB -ForegroundColor Cyan
        $VMName = Get-VM -Name $VMName
        if($vMemoryGB -ge $vMemoryGBMin -AND $vMemoryGB -le $vMemoryGBMax)
        {
            if($VMName.count -eq 1 -and $VMName -isnot [system.array])
            {
                Set-VM -VM $VMName -Confirm:$False -MemoryGB $vMemoryGB
            }
            else
            {
                Write-Error -Message "ECI.Error: VMName is not Unique." -ErrorAction Continue -ErrorVariable +ECIError
            }
        }
        else
        {
            Write-Error -Message "ECI.Error: vMemory is Out of Range" -ErrorAction Continue -ErrorVariable +ECIError
        }


    }
    
    ##########################################
    ### CALL CONFIGURE DESIRED STATE:
    ##########################################
    $Params = @{
        ServerID            = $ServerID 
        HostName            = $HostName 
        FunctionName        = $FunctionName 
        PropertyName        = $PropertyName 
        DesiredState        = $DesiredState 
        GetCurrentState     = $GetCurrentState 
        SetDesiredState     = $SetDesiredState 
        ConfigurationMode   = $ConfigurationMode 
        AbortTrigger        = $AbortTrigger
    }
    Configure-DesiredState @Params

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function New-ECI.EMI.Automation.VM.HardDisk
{
    Param(
        [Parameter(Mandatory = $true)][string]$VMName,
        [Parameter(Mandatory = $true)][string]$Datastore,
        [Parameter(Mandatory = $true)][string]$CapacityGB
    )
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
        
    $Params = @{
        VM             = $VMName
        Datastore      = $Datastore
        CapacityGB     = $CapacityGB
        StorageFormat  = "Thin"
        Persistence    = "Persistent"
        Confirm        = $false
    }
    #New-HardDisk @Params
    
    try
    {
        New-HardDisk -VM $VMName -Datastore $DataStore -CapacityGB $CapacityGB -StorageFormat Thin -Persistence persistent -Confirm:$false
    }
    catch
    {
        Write-ECI.ErrorStack
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Get-ECI.EMI.Automation.VM.DataStore
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Get-ECI.EMI.Automation.VM.Resources.DataStore -Environment $Environment -ServerRole $ServerRole
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Configure-ECI.EMI.Automation.VM.HardDisks
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "ServerHardDisks"
    $ConnectionString =  $DevOps_DBConnectionString
    $Query = “SELECT * FROM definitionVMParameters WHERE ServerRole = '$ServerRole'”
	Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query


    $Volumes = @{
        OSVolumeCapacity   = $ServerHardDisks.OSVolumeCapacityGB
        SwapVolumeCapacity = $ServerHardDisks.SwapVolumeCapacityGB
        DataVolumeCapacity = $ServerHardDisks.DataVolumeCapacityGB
        LogVolumeCapacity  = $ServerHardDisks.LogVolumeCapacityGB
        SysVolumeCapacity  = $ServerHardDisks.SysVolumeCapacityGB
    }
       
    foreach($Volume in $Volumes.GetEnumerator())
    {
        if(([string]::IsNullOrEmpty($Volume.Value)) -ne $true)
        {
            Write-Host "Volume: " $Volume.Name `t "VolumeSize: " $Volume.Value
            #New-ECI.EMI.Automation.VM.HardDisk -VMName $VMName -Datastore $Datastore -CapacityGB $CapacityGB
        }
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function New-ECI.EMI.Automation.VM.HardDisks
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $Disk = @()
    $OS   = @( $OSDataStore,   $OSVolumeCapacity   )
    $Swap = @( $SwapDataStore, $SwapVolumeCapacity )
    $Data = @( $DataDataStore, $DataVolumeCapacity )
    $Log  = @( $LogDataStore,  $LogVolumeCapacity  )
    $Sys  = @( $SysDataStore,  $SysVolumeCapacity  )


    #New-ECI.EMI.Automation.VM.HardDisk -VMName $VMName -Datastore $Datastore -CapacityGB $CapacityGB

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


function New-ECI.EMI.Automation.VM.HardDisk.PageFile
{
    Param(
        [Parameter(Mandatory = $true)][string]$VMName
    )
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
   
    $Datastore = $SwapDataStore
    $CapacityGB = $SwapVolumeCapacityGB
    
    #$Datastore =  "LD5_EMS_Client_DC_OS_401"

    try
    {
        ### Create New Disk
        ### --------------------------
        New-ECI.EMI.Automation.VM.HardDisk -VMName $VMName -Datastore $Datastore -CapacityGB $CapacityGB #-StorageFormat Thin -Persistence Persistent -Confirm:$false
     }
    catch
    {
        Write-ECI.ErrorStack
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Start-ECI.EMI.Automation.VM
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    Write-Host "Starting VM: $VMName" -ForegroundColor Cyan
    Start-VM $VMName
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


function Wait-ECI.EMI.Automation.VM.VMTools
{
    Param(
    [Parameter(Mandatory = $true)][string]$VMName
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Waiting for VMTools: " $VMName -ForegroundColor Yellow
    
    ###----------------------
    ### Setup Retry Loop
    ###----------------------
    $Retries            = 4
    $RetryCounter       = 0
    $Success            = $False
    $RetryTime          = 5
    $RetryTimeIncrement = $RetryTime
    $ECIErrorMsg        = "VM Tools Failed."

    while($Success -ne $True)
    {
        try
        {
            Wait-Tools -VM $VMName -TimeoutSeconds $VMToolsTimeout
            $Success = $True
            Write-Host "TEST: VM Tools Responded." -ForegroundColor Green
    
        }
        catch
        {
            if($RetryCounter -eq $Retries)
            {
                Throw "ECI.Throw.Terminating.Error: $ECIErrorMsg"
            }
            else
            {
                ### Retry x Times
                ###----------------------------------
                $RetryCounter++

                ### Write ECI Error Log
                ###---------------------------------
                Write-Error -Message ("ECI.ERROR.Exception.Message: " + $global:Error[0].Exception.Message) -ErrorAction Continue -ErrorVariable +ECIError 
                if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
                $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force
                
                ### Error Handling Action
                ###----------------------------------               
                Start-ECI.EMI.Automation.Sleep -Message "Retry CopyFiletoGuest." -t $RetryTime
                
                ### Set Bailout Value: Restart VM Tools
                ###----------------------------------
                if($RetryCounter -eq ($Retries - 1))
                {
                    Write-Host "Bailout Reached: Retry Counter..." $RetryCounter -ForegroundColor Magenta
                    Restart-ECI.EMI.VM.VMTools -VMName $VMName
                }
                $RetryTime = $RetryTime + $RetryTimeIncrement
            }
        }
    }
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Wait-ECI.EMI.Automation.VM.VMTools-original
{
    Param(
    [Parameter(Mandatory = $true)][string]$VMName,
    [Parameter(Mandatory = $false)][int16]$t,
    [Parameter(Mandatory = $false)][int16]$RetryCount
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Waiting for VMTools: " $VMName -ForegroundColor Yellow

    if(!$t)          { $t = $WaitTime_VMTools }
    if(!$RetryCount) { $RetryCount = 5 }

    $VMTools = Wait-Tools -VM $VMName -TimeoutSeconds $t -ErrorAction SilentlyContinue
    
    if(!$VMTools)
    {
        for ($i=1; $i -le $RetryCount; $i++)
        {
            Write-Warning  "VMTools Not Responding. Retrying...." -WarningAction Continue
            Wait-ECI.EMI.Automation.VM.VMTools -VMName $VMName #-t 60
        }
    }
    if($VMTools)
    {
        Write-Host "The Server is Up - VMNAME: $VMName" -ForegroundColor Green
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


function Wait-ECI.EMI.Automation.VM.OSCusomizationSpec
{
    Param([Parameter(Mandatory = $true)][string]$VMName)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $GuestState = [ordered]@{
        VMName                            = $VM
        VMHost                            = $VMHost
        State                             = $VM.Guest.State                                              ### <---- RETURN: Running/NotRunning
        ToolsRunningStatus                = $VM.ExtensionData.Guest.ToolsRunningStatus                   ### <---- RETURN: guestToolsRunning/guestToolsNotRunning
        guestOperationsReady              = $VM.ExtensionData.guest.guestOperationsReady                 ### <---- RETURN: True/False
        interactiveGuestOperationsReady   = $VM.ExtensionData.guest.interactiveGuestOperationsReady      ### <---- RETURN: True/False
        guestStateChangeSupported         = $VM.ExtensionData.guest.guestStateChangeSupported            ### <---- RETURN: True/False
    }

    [int]$t = $WaitTime_OSCustomization

### TESTING     # <-----------------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#[int]$t = 180   # <-----------------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    Start-ECI.EMI.Automation.Sleep -t $t -Message "Waiting for ECI OS CusomizationSpec to Complete."
    Wait-ECI.EMI.Automation.VM.VMTools -VMName $VMName
    

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray

}

function Wait-ECI.EMI.Automation.VM.OSCusomizationSpec-original
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $GuestState = [ordered]@{
        VMName                            = $VM
        VMHost                            = $VMHost
        State                             = $VM.Guest.State                                              ### <---- RETURN: Running/NotRunning
        ToolsRunningStatus                = $VM.ExtensionData.Guest.ToolsRunningStatus                   ### <---- RETURN: guestToolsRunning/guestToolsNotRunning
        ToolsVersionStatus                = $VM.ExtensionData.Summary.Guest.ToolsVersionStatus           ### <---- RETURN: guestToolsCurrent/???
        VirtualMachineToolsStatus         = $VM.ExtensionData.Guest.ToolsStatus                          ### <---- RETURN: toolsNotInstalled/toolsNotRunning/toolsOk/toolsOld
        ConfigToolsToolsVersion           = ($VM | Get-View).Config.Tools.ToolsVersion                   ### <---- RETURN: 10309
        Configversion                     = ($VM | Get-View).Config.version                              ### <---- RETURN: vmx-11
        guestState                        = $VM.ExtensionData.guest.guestState                           ### <---- RETURN: running/notRunning
        guestOperationsReady              = $VM.ExtensionData.guest.guestOperationsReady                 ### <---- RETURN: True/False
        interactiveGuestOperationsReady   = $VM.ExtensionData.guest.interactiveGuestOperationsReady      ### <---- RETURN: True/False
        guestStateChangeSupported         = $VM.ExtensionData.guest.guestStateChangeSupported            ### <---- RETURN: True/False
    }

    
    $t = 240

    Write-Host "START-SLEEP - for $t seconds: Waiting for OS CusomizationSpec to Complete." -ForegroundColor Yellow

    For ($i=$t; $i -gt 1; $i--) 
    {  
        #$a = [math]::Round((($i/$t)/1)*100)  ### Amount Remaining
        
        $a = [math]::Round( (($t-$i)/$t)*100) ### Amount Completed

        Write-Progress -Activity "START-SLEEP - for $t seconds: Waiting for OS CusomizationSpec to Complete." -SecondsRemaining $i -CurrentOperation "Completed: $a%" -Status "Waiting"
        Start-Sleep 1
        #Write-Host "Still Waiting ..." -ForegroundColor DarkGray
    }

    Write-Host "Done Waiting." -ForegroundColor Cyan
    Write-Progress -Activity 'OS Cusomization' -Completed
}


function Test-ECI.EMI.Automation.VM.InvokeVMScript
{
    Param([Parameter(Mandatory = $true)][string]$VMName)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $ScriptText =  { 
    
        ### Test VM Tools Service
        #$VMTools = Get-Service -Name VMTools  
        #Write-Host "VMTools Status: " $VMTools.Status

        ### Test New File
        $TestPath = "C:\Temp"
        if(-NOT(Test-Path -Path $TestPath)) {(New-Item -ItemType directory -Path $TestPath -Force | Out-Null)}

        $TestFile = $TestPath + "\" + "deleteme.txt"
        New-Item $TestFile -ItemType file -Force

        if([System.IO.File]::Exists($TestFile))
        {
            Write-Host "TEST FILE: Exists."
        }
        elseif(-NOT([System.IO.File]::Exists($TestFile)))
        {
            Write-Host "TEST FILE: Failed!!!"
            $Abort = $True
            Write-ECI.ErrorStack
        }
    }
    Write-Host "Test-ECI.EMI.Automation.VM.InvokeVMScript..." -ForegroundColor Cyan
    $TestInvoke = Invoke-VMScript -VM $VMName -ScriptText $ScriptText -ScriptType Powershell -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword
    Write-Host "TestInvoke.ExitCode:" $TestInvoke.ExitCode -ForegroundColor Gray
    Write-Host "TestInvoke.ScriptOutput:" $TestInvoke.ScriptOutput -ForegroundColor DarkGray

    if($TestInvoke.ExitCode -eq 0)
    {
        Write-Host "INVOKE TEST: Succeded." -ForegroundColor Green
    }
    elseif($TestInvoke.ExitCode -ne 0)
    {
        Write-Host "INVOKE TEST: Failed. Retrying ..." -ForegroundColor Red
        Start-ECI.EMI.Automation.Sleep -t 60
        Test-ECI.EMI.Automation.VM.InvokeVMScript
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Test.ECI.EMI.VM.GuestReady-notneeded???
{
    Param([Parameter(Mandatory = $true)][string]$VMName)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $VMguestOperationsReady  = (Get-VM -Name $VMName).ExtensionData.guest.guestOperationsReady   ### <---- RETURN: True/False

<#
    $RetryCount = 5
    for ($i=1; $i -le $RetryCount; $i++)
    {

    }
#>

    if($VMguestOperationsReady -eq $False)
    {
        Write-Host "Guest OS Not Ready." -ForegroundColor Yellow
        Start-ECI.EMI.Automation.Sleep -t $WaitTime_StartSleep
        Test.ECI.EMI.VM.GuestReady
    }
    elseif($VMguestOperationsReady -eq $True)
    {
        Continue
    }
    else
    {
        Write-Host "Server not responding. `n Exiting!" -ForegroundColor Red
        #Exit
    }
}

function Stop-ECI.EMI.Automation.VM
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    Write-Warning "Stopping VM: $VMName" -WarningAction Continue
    #Write-Host "Stopping VM: $VMName" -ForegroundColor Yellow
    Stop-VM $VMName -Confirm:$false
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Restart-ECI.EMI.Automation.VM-delete #<--deleteme???
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $t = $WaitTime_VMTools
    Write-Host "Restarting VM: $VMName in $t seconds."
    Start-Sleep -seconds $t

    Restart-VM -VM $VMName -Confirm:$false
    Wait-ECI.VMTools -VM $VMName -t $t


}


function Mount-ECI.EMI.Automation.VM.ISO
{
    param(
    [Parameter(Mandatory = $True,Position=0)][string]$ISOName,
    [Parameter(Mandatory = $True,Position=1)][string]$VMName
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Getting ISO from SQL: " $ISOName -ForegroundColor Cyan

    #$isoDataSore = "cloud_staging_pub_lhc"
    #$isoDataSoreFolderPath = "ISO/Current/Microsoft"
    #$isoDataSoreFileName = "SW_DVD9_Win_Svr_STD_Core_and_DataCtr_Core_2016_64Bit_English_-3_MLF_X21-30350.ISO"
    
    ### Get ISO Parameters from DB
    ###---------------------------------
    $DataSetName = "ISOParameters"
    $ConnectionString = $DevOps_DBConnectionString
    $Query = “SELECT * FROM definitionISOs WHERE ISOName = '$ISOName'"
    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query

    try
    {
        ### Get ISO from Datastore
        $ISODataStoreFile = $((Get-Datastore $isoDataStore).DatastoreBrowserPath + $isoDataStoreFolderPath) + "/" + $isoDataStoreFileName 
        $DatastoreFullPath = (Get-Item $ISODataStoreFile).DatastoreFullPath

        ### Mount ISO
        ###---------------------------------        
        #Get-CDDrive -VM $VMName | Set-CDDrive -IsoPath $DatastoreFullPath -StartConnected:$true -Connected:$true -Confirm:$false
        Get-CDDrive -VM $VMName | Set-CDDrive -IsoPath $DatastoreFullPath -Confirm:$false | select *
        Start-ECI.EMI.Automation.Sleep -t 30 -Message "Waiting to Mount ISO Image."
        (Get-CDDrive -VM $VMName | Set-CDDrive -connected $true -Confirm:$false).ISOPath
    }
    catch
    {
        Write-ECI.ErrorStack
    }

    function Check-ECI.VM.State
    {
        ### Check VM State
        ###-------------------------------
        $Message = (Get-VMQuestion -VM $VMName).Text
        if($Message)
        {
            if( $Message.Conains("The operation on file") -AND $Message.Conains("failed") )
            {
                if( ((Get-VMQuestion -VM $VMName).Options.Summary).Contains("Retry") | Out-Null)
                {
                    Get-VM -Name $VMName | Get-VMQuestion | Set-VMQuestion –Option button.retry -Confirm:$false
                }
            }
        }
    }
    #Check-ECI.VM.State

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $ISODataStoreFile
}

function DisMount-ECI.EMI.Automation.VM.ISO
{
    param([Parameter(Mandatory = $True,Position=1)][string]$VMName)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    try
    {
        Get-VM -Name $VMName | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$False
        #Get-VM -Name $VMName | Get-CDDrive | where {$_.IsoPath -ne $null} | Set-CDDrive -NoMedia -Confirm:$False
    }
    catch
    {
        Write-ECI.ErrorStack
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Restart-ECI.VMGuest-deleteme #<--deleteme???
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    
    $t = $WaitTime_GuestOSRestart
    Write-Host "Restarting VM: $VMName in $t seconds."
    Start-Sleep -seconds $t

    Restart-VMGuest -VM $VMName -Confirm:$false
    #Restart-VMGuest -VM $VMName -Server $VIServer | Wait-Tools | Out-Null
    
    #Wait-ECI.VMTools -VM $VMName -t $t
}

function Decommission-ECI.VM
{

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Stop VM if Started
    $PowerState = (Get-VM $VMName | Select PowerState).PowerState
 
    if($PowerState -eq "PoweredOn")     #PoweredOff
    {
        Write-Host "WARNING! STOPPING VM: $VMName" -ForegroundColor Red
        Stop-VM $VMName -Confirm:$false    
    }

    ### Record VM to SQL
    Get-DecommissionData -ServerID $ServerID
    
    #### Write-DecomtoSQL

    ### Delete VM
    Write-Host "WARNING! DELETING VM: $VMName" -ForegroundColor Red
    Remove-VM $VMName -DeletePermanently -Confirm:$false

}

function Delete-ECI.VMs
{
    #### need to add CmdletBinding ShouldProcess
    
    
    ######################################################################################################
    ### *** DANGER: *** Set $Filter carefully!!! This function could potentially delete the wrong VM's.
    ######################################################################################################

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $FilTer = "ETEST040_Test-LD5*"

    Write-Host "Cleaning Up Test VM's." -ForegroundColor Yellow

    #$VMs = Get-VM | Where-Object {$_.Name -like "*_GEEMO001*"} # LAB
    
    $VMs = Get-VM | Where-Object {$_.Name -like $Filter} # LD5

    foreach($VM in $VMs)
    {
        if($VM.PowerState -eq "PoweredOn")
        {
            Write-Host "Stopping VM: " $VM -ForegroundColor DarkGray
            Stop-VM $VM -Confirm:$false -ErrorAction Continue
        }
        Write-Host "Deleting VM: " $VM -ForegroundColor Red
        
        ### Set Confirm = True
        Remove-VM $VM -DeletePermanently -Confirm:$true -ErrorAction Continue 
    }
}

function Add-ISOtoDatastore
{
    ### Add ISO
    $Datastore = "nfs_emsadmin_sas1"
    $ISODataStore = "vmstore:\Boston\nfs_iso\Microsoft\Windows\"
    #DIR $ISODataStore

    ### Get Datastore Items
    (Get-ChildItem $ISODataStore).Name
    
    $ItemFolder = "C:\Scripts\New_ISO\"
    #$ItemFile = "Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh-CUSTOM2.ISO"
    $ItemFile = "Windows_Server_2016_Auto.ISO"
    $ItemFile = "Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
    $ItemFile = "VMware-tools-windows-10.1.0-4449150.iso"

    $Item = $ItemFolder + $ItemFile

    Copy-DatastoreItem -Item $Item -Destination $ISODataStore 


    #Get-VM -Name SDGRP008 | Get-CDDrive | `
    #Set-CDDrive -IsoPath "[$Datastore] ISOfiles\0.iso" -Confirm:$false


    ### Remove ISO
    $ISODataStore = "vmstore:\Boston\nfs_iso\Microsoft\Windows\"
    $ItemFile = "Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh-CUSTOM.ISO"
    $ItemFile = "Windows_Server_2016_Auto.ISO"
    $ItemFile = "Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
    $Item = $ISODataStore + $ItemFile
    
    Remove-Item $Item 
}

function Get-Vix.Version
{
    $propertiesVix =[System.Diagnostics.FileVersionInfo]::GetVersionInfo($env:programfiles + '\VMware\VMware VIX\VixCOM.dll')
    $majorVix = $propertiesVix.FileMajorPart
    $minorVix = $propertiesVix.FileMinorPart
    $buildVix = $propertiesVix.FileBuildPart
    $versionVix = ([string]$majorVix + '.' + [string]$minorVix + '.' + [string]$buildVix)
    if(($pCLIMajor -eq 5 -and $versionVix -eq '1.10.0') -or ($pCLIMajor -eq 4 -and $versionVix -eq '1.6.2'))
    {
        $condVix = $true
    }
}

function Get-VMTools.Version
{
    Param([Parameter(Mandatory = $True)][string]$VMName)

    <#	
        Operation mode of guest operating system:
        "running" - Guest is running normally.
        "shuttingdown" - Guest has a pending shutdown command.
        "resetting" - Guest has a pending reset command.
        "standby" - Guest has a pending standby command.
        "notrunning" - Guest is not running.
        "unknown" - Guest information is not available.
    #>




<#
Get-VM -Name $VMName | % { get-view $_.id } | select name, @{Name=“ToolsVersion”; Expression={$_.config.tools.toolsversion}}, @{ Name=“ToolStatus”; Expression={$_.Guest.ToolsVersionStatus}}|Sort-Object Name
Result:
Name         : ETEST040_Test-LD5-06jEi
ToolsVersion : 10309
ToolStatus   : guestToolsCurrent
#>


    $VMGuestToolsVersion = Get-VM -Name $VMName | Get-VMGuest | Select ToolsVersion
    Write-Host "VMGuestToolsVersion : " $VMGuestToolsVersion -ForegroundColor Magenta

    $GuestExtensionData = Get-VM -Name $VMName | Select -expandproperty ExtensionData | Select -expandproperty Guest 
    Write-Host "GuestExtensionData  : " $GuestExtensionData -ForegroundColor Magenta

    #Start-Sleep -Seconds 60

}

function Get-PowerCLI.Version
{
    Get-PowerCLIVersion 
}



