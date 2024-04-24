##################################
### EMI Automation Module
### ECI.EMI.Automation.Prod.psm1
##################################

function Get-LocalAdminAccount
{
    Param([Parameter(Mandatory = $True)][string]$State)    

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Getting Local Admin Account: " $State

    if($State = "Template")
    {
        $global:LocalAdminAccount = "Administrator"
        $global:LocalAdminAccountPassword = "cH3r0k33"

    }
    elseif($State = "Configured")
    {
        $global:LocalAdminAccount = "Administrator"
        $global:LocalAdminAccountPassword = "cH3r0k33"
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### Function: Set HostName & VMName ++$GPID
### --------------------------------------------------
function Create-ECI.EMI.Automation.VMName
{
    Param (
    [Parameter(Mandatory = $True)][string]$GPID,
    [Parameter(Mandatory = $True)][string]$HostName
    )
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray
    
    ### GPID + HostName
    ###-------------------
    $global:VMName = $GPID + "_" + $HostName

    ### HostName + GPID
    ###-------------------    
    #$global:VMName = $HostName + "_" + $GPID

    Write-Host "Setting VMName: " $VMName -ForegroundColor Cyan
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


### Function: Set VMGuest Execution Policy
### --------------------------------------------------
function Configure-ECI.EMI.Automation.ExecutionPolicyonVMGuest
{
    Param([Parameter(Mandatory = $True)][string]$VMName)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $ExecutionPolicyonVMGuest =
    { 
        if ($(Get-ExecutionPolicy) -ne "Bypass")
        {
            Write-Host "`nSetting Execution Policy on VM Guest to Bypass:"
            Set-ExecutionPolicy ByPass -Scope LocalMachine

            #REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f
            #Start-Process powershell -ArgumentList '-noprofile -Command Set-ExecutionPolicy ByPass -Scope LocalMachine' -verb RunAs
            #REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f
        }
        else
        {
            Write-Host "`nExecution Policy on VM Guest already set to Bypass"     
        }
    }

    #Write-Host "vCenter_Account          : " $vCenter_Account     -ForegroundColor Gray
    #Write-Host "vCenter_Password         : " $vCenter_Password    -ForegroundColor Gray
    #Write-Host "Creds.LocalAdminName     : " $Creds.LocalAdminName   -ForegroundColor Gray
    #Write-Host "Creds.LocalAdminPassword : " $Creds.LocalAdminPassword  -ForegroundColor Gray

    Write-Host "INVOKING: $((Get-PSCallStack)[0].Command) on $VMName" -ForegroundColor Cyan

    $Invoke = Invoke-VMScript -VM $VMName -ScriptText $ExecutionPolicyonVMGuest -ScriptType Powershell -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword
    #$Invoke = Invoke-VMScript -VM $VMName -ScriptText $ExecutionPolicyonVMGuest -ScriptType Powershell -HostUser $vCenter_Account -HostPassword $vCenter_Password 
    #$Invoke = Invoke-VMScript -VM $VMName -ScriptText $ExecutionPolicyonVMGuest -ScriptType Powershell -HostUser $vCenter_Account -HostPassword $vCenter_Password -GuestUser Administrator -GuestPassword cH3r0k33
    
    #if($Invoke.ExitCode -ne 0)
    #{
    #    $Abort = $True
    #    Write-Host "ABORT ERROR: Aborting Script Execution" -ForegroundColor Red
    #    #Send-Alert
    #    Exit
    #}

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Install-ECI.EMI.Automation.ECIModulesonVMGuest
{
    Param(
        [Parameter(Mandatory = $True)][string]$Env,
        [Parameter(Mandatory = $True)][string]$Environment
    )
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $Source = "\\eciscripts.file.core.windows.net\clientimplementation\" + $Environment +"\ECI.Modules." + $Env
    $Destination = "C:\Program Files\WindowsPowerShell\Modules\"

    Write-Host "Source      : " (Get-Item $Source)        -ForegroundColor Cyan
    Write-Host "Destination : " $Destination              -ForegroundColor Cyan

    #(Get-Item $Source) | Copy-ECI.EMI.VM.GuestFile -LocalToGuest -VMName $VMName  -Destination $Destination

    $Modules = Get-ChildItem $Source
    foreach($Module in $Modules)
    {
        Write-Host "Installing Module: " $Module -ForegroundColor White
        #Copy-ECI.EMI.VM.GuestFile -LocalToGuest -Source $Module.FullName -VMName $VMName  -Destination $Destination
    }
    Write-Host "Please Wait... This may take a minute." -ForegroundColor DarkGray

   ###----------------------
    ### Guest state Retry Loop
    ###----------------------
    $Retries            = 4
    $RetryCounter       = 0
    $RetryTime          = 15
    $RetryTimeIncrement = $RetryTime
    $Success            = $False

    while($Success -ne $True)
    {
        try
        {
            ### Copy all files at once to avoid multiple logins.
            Get-Item $Source | Copy-VMGuestFile -LocalToGuest -Destination $Destination -VM $VMName -Force -Confirm:$false -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword
            #Copy-ECI.EMI.VM.GuestFile -LocalToGuest -Source $Module.FullName -VMName $VMName  -Destination $Destination
            
            $Success = $True
            Write-Host "$FunctionName - Succeded: " $Success -ForegroundColor Green 
        }
        catch
        {
            if($RetryCounter -ge $Retries)
            {
                Throw "ECI.THROW.TERMINATING.ERROR: ERROR Copying VMGuest Files:! "
            }
            else
            {
                ### Retry x Times
                ###--------------------
                $RetryCounter++
                
                ### Write ECI Error Log
                ###---------------------------------
                Write-Error -Message ("ECI.ERROR.Exception.Message: " + $global:Error[0].Exception.Message) -ErrorAction Continue -ErrorVariable ECIError
                if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
                $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force

                ### Error Handling Action
                ###----------------------------------                  
                Start-ECI.EMI.Automation.Sleep -Message "Retry Invoke-VMScript." -t $RetryTime

                ### Restart VM Tools
                ###--------------------                
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


function Install-ECI.EMI.Automation.ECIModulesonVMGuest-ORIGINAL
{
    Param(
        [Parameter(Mandatory = $True)][string]$Env,
        [Parameter(Mandatory = $True)][string]$Environment
    )
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $Source = "\\eciscripts.file.core.windows.net\clientimplementation\" + $Environment +"\ECI.Modules." + $Env
    $Destination = "C:\Program Files\WindowsPowerShell\Modules\"

    Write-Host "Source      : " (Get-Item $Source)        -ForegroundColor Cyan
    Write-Host "Destination : " $Destination              -ForegroundColor Cyan

    #(Get-Item $Source) | Copy-ECI.EMI.VM.GuestFile -LocalToGuest -VMName $VMName  -Destination $Destination

    $Modules = Get-ChildItem $Source
    foreach($Module in $Modules)
    {
        Write-Host "Installing Module: " $Module -ForegroundColor White
        #Copy-ECI.EMI.VM.GuestFile -LocalToGuest -Source $Module.FullName -VMName $VMName  -Destination $Destination
    }
    Write-Host "Please Wait... This may take a minute." -ForegroundColor DarkGray


    ### Copy ECI ModuleFolders
    ###------------------------
    $RetryCount = 3
    try
    {
        ### Copy all files at once to avoid multiple logins.
        Get-Item $Source | Copy-VMGuestFile -LocalToGuest -Destination $Destination -VM $VMName -Force -Confirm:$false -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword
        #Copy-ECI.EMI.VM.GuestFile -LocalToGuest -Source $Module.FullName -VMName $VMName  -Destination $Destination
    }
    catch
    {
        Write-Host "ERROR Copying VMGuest Files: " $Error[0] -ForegroundColor Red
          
        for ($i=1; $i -le $RetryCount; $i++)
        {
            Start-ECI.EMI.Automation.Sleep -t 30
            Write-Warning  "VMTools Not Responding. Retrying...." -WarningAction Continue
            Install-ECI.EMI.Automation.ECIModulesonVMGuest -Env $Env -Environment $Environment
        }

        Write-ECI.ErrorStack
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Delete-ECI.EMI.Automation.ECIModulesonVMGuest
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $ScriptText =
    { 
        $ECIModulePath = "C:\Program Files\WindowsPowerShell\Modules\ECI.Modules*"

        try
        {
            Remove-Item -Path $ECIModulePath -Recurse -Force -Confirm:$false
        }
        catch
        {
            Write-ECI.ErrorStack
        }
    }

    Write-Host "INVOKING: $((Get-PSCallStack)[0].Command) on $VMName" -ForegroundColor Cyan

#Write-Host "Creds.LocalAdminName     : " $Creds.LocalAdminName -ForegroundColor Magenta
#Write-Host "Creds.LocalAdminPassword : " $Creds.LocalAdminPassword -ForegroundColor Magenta
#Write-Host "vCenter_Account          : " $vCenter_Account -ForegroundColor Magenta
#Write-Host "vCenter_Password         : " $vCenter_Password -ForegroundColor Magenta

    $Invoke = Invoke-VMScript    -ScriptText $ScriptText -VM $VMName  -ScriptType Powershell -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword -HostUser $vCenter_Account -HostPassword $vCenter_Password

    #if($Invoke.ExitCode -ne 0)
    #{
    #    $Abort = $True
    #    Write-Host "ABORT ERROR: Aborting Script Execution" -ForegroundColor Red
    #    #Send-Alert
    #    Exit
    #}
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Set-ECI.EMI.Automation.LocalAdminAccount
{
    Param(
    [Parameter(Mandatory = $False)][switch]$Template,
    [Parameter(Mandatory = $False)][switch]$ECI
    )
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
       
    [hashtable]$global:Creds = @{}
    
    if($Template -eq $True)
    {
        $DataSetName = "TemplateLocalAdmin"
        $ConnectionString =  $DevOps_DBConnectionString
        $Query = "SELECT AdminPassword FROM definitionVMOSCustomizationSpec WHERE ServerRole = '$ServerRole' AND BuildVersion = '$BuildVersion'"
        Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query  
        
        $Creds.CredentialState    = "Template-Creds"
        $Creds.LocalAdminName     = "Administrator"
        $Creds.LocalAdminPassword =  $AdminPassword
    }
    elseif($ECI -eq $True)
    {

        $DataSetName = "ECILocalAdmin"
        $ConnectionString =  $DevOps_DBConnectionString
        $Query = "SELECT ECILocalAdminName,ECILocalAdminPassword FROM definitionOSParameters WHERE ServerRole = '$ServerRole' AND BuildVersion = '$BuildVersion'"
        Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query  
        
        $Creds.CredentialState    = "ECI-Creds"
        $Creds.LocalAdminName     = $ECILocalAdminName
        $Creds.LocalAdminPassword = $ECILocalAdminPassword
    }
    
    Write-Host "Creds State    : " $Creds.CredentialState -ForegroundColor Cyan
    Write-Host "LocalAdminName : " $Creds.LocalAdminName -ForegroundColor Cyan
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $Creds
}

### ===================================================================================================
### Configure Desired State        <<<----- CMDLET
### ===================================================================================================
###
function Configure-DesiredState
{
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory = $True)][int]$ServerID,
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$FunctionName,
    [Parameter(Mandatory = $True)][string]$PropertyName,
    [Parameter(Mandatory = $True)][string]$DesiredState,
    [Parameter(Mandatory = $True)][scriptblock]$GetCurrentState,
    [Parameter(Mandatory = $True)][scriptblock]$SetDesiredState,
    [Parameter(Mandatory = $True)][ValidateSet("Report","Configure")][string]$ConfigurationMode,
    [Parameter(Mandatory = $True)][ValidateSet($True, $False)][string]$AbortTrigger
    )

    ###===============================================
    ### GET CURRENT CONFIGURATION-STATE: 
    ###===============================================
    function Get-CurrentState
    {
        try
        {
            Invoke-Command $GetCurrentState 
        }
        catch
        {
            Write-ECI.ErrorStack
        }
    }

    ###===============================================
    ### COMPARE CURRENT/DESIRED-STATE:
    ###===============================================
    function Compare-DesiredState
    {
        $global:Compare = ($CurrentState -eq $DesiredState)
        #Write-ConfigReport `n('- ' * 10)`n "COMPARE: $Compare" `n('- ' * 10)`n "FUNCTION: $FunctionName" `n "CURRENTSTATE: $CurrentState" `n "DESIREDSTATE: $DesiredState"
        Write-ConfigReport `r`n('- ' * 20)`r`n"COMPARE          : $Compare"`r`n('- ' * 20)`r`n"FUNCTION         : $FunctionName"`r`n"CURRENTSTATE     : $CurrentState"`r`n"DESIREDSTATE     : $DesiredState"`r`n ('- ' * 20)`r`n

        if($Compare -eq $True)
        {
            ### CURRENT STATE = DESIRED STATE: True
            ### --------------------------------------
            Write-ConfigReport `r`n"The Current-State Matches the Desired-State."
        }
        elseif($Compare -eq $False)
        {
            ### CURRENT STATE = DESIRED STATE: False
            ### --------------------------------------
            Write-ConfigReport `r`n"The Current-State Does Not Match the Desired-State."
        }
    }

    ###===============================================
    ### SET DESIRED-STATE:
    ###===============================================
    function Set-DesiredState
    {
        Write-ConfigReport `r`n('- ' * 20)`r`n"SET DESIRED STATE: $DesiredState"`r`n('- ' * 20)`r`n"FUNCTION         : $FunctionName"`r`n"DESIREDSTATE     : $DesiredState"`r`n('- ' * 20)`r`n

        foreach ($State in $DesiredState)
        {
            if($ConfigurationMode -eq "Configure")
            {
                Write-ConfigReport `r`n "CONFIG MODE: Setting Desired State."`r`n
                [ScriptBlock]$DesiredStateConfiguration = {Invoke-Command $SetDesiredState}

                try
                {
                    Invoke-Command $DesiredStateConfiguration
                }
                catch
                {
                    Write-ECI.ErrorStack
                }
            }
            elseif($ConfigurationMode -eq "Report")
            {
                Write-ConfigReport `r`n "REPORT MODE: Reporting Data Only!" `r`n
            }
        }
    }
        
    ###===============================================
    ### VERIFY DESIRED-STATE:
    ###===============================================
    function Verify-DesiredState
    {
        foreach ($State in $DesiredState)
        {
            ### VERIFY: Current State
            ### -----------------------------------------------------
            Get-CurrentState
            $global:VerifyState = $CurrentState

            ### COMPARE: Verify State - Desired State
            ### ----------------------------------------------------- 
            $global:Verify = ($VerifyState -eq $DesiredState) ### <-- True/False
            Write-ConfigReport `r`n('- ' * 20)`r`n"VERIFY           : $Verify"  `r`n('- ' * 20)`r`n"VERIFYSTATE      : $VerifyState"`r`n"DESIREDSTATE     : $DesiredState"`r`n('- ' * 20)`r`n

            ### VERIFY = TRUE
            ### -----------------------------------------------------        
            if($Verify -eq $True)
            {
                Write-Host `r`n"The Current-State Matches the Desired-State."
                
                ### ABORT = FALSE
                ### --------------------
                $global:Abort = $False
            }
        
            ###  VERIFY = FALSE
            ### -----------------------------------------------------
            elseif($Verify -eq $False)
            {
                ### Increment Verify Error Counter
                $global:VerifyErrorCount ++
                $global:VerifyErrorFunction = $FunctionName
                $global:VerifyErrorDesiredState = $DesiredState
                
                Write-Host `r`n("-" * 50)`r`n"The Current-State Does Not Match the Desired-State."`r`n("-" * 50)`r`n  -ForegroundColor Yellow


                if ($AbortTrigger -eq $True)
                {
                    ### ABORT TRIGGER = TRUE
                    ### --------------------
                    $global:Abort = $True
                    $VerifyColor = "Red"
                   
                    #Throw-AbortError
                }
                elseif($AbortTrigger -eq $False)
                {
                    ### ABORT TRIGGER = FALSE
                    ### --------------------
                    $global:Abort = $False
                    $VerifyColor = "Yellow"
                }
            
                Write-Host "VerifyErrorCount        : " $VerifyErrorCount        -ForegroundColor $VerifyColor
                Write-Host "VerifyErrorFunction     : " $VerifyErrorFunction     -ForegroundColor $VerifyColor
                Write-Host "VerifyErrorDesiredState : " $VerifyErrorDesiredState -ForegroundColor $VerifyColor
                Write-Host "VerifyErrorVerifyState  : " $VerifyErrorVerifyState  -ForegroundColor $VerifyColor

                if ($Abort -eq $True)
                {
                    Write-Host "ServerID      : " $ServerID     -ForegroundColor Red
                    Write-Host "HostName      : " $HostName     -ForegroundColor Red
                    Write-Host "VMName        : " $VMName       -ForegroundColor Red
                    Write-Host "FunctionName  : " $FunctionName -ForegroundColor Red
                    Write-Host "Verify        : " $Verify       -ForegroundColor Red
                    Write-Host "AbortTrigger  : " $AbortTrigger -ForegroundColor Red
                    Write-Host "Abort         : " $Abort        -ForegroundColor Red
                    Write-Host "Error: " $Error[0]
                }
            }
        }
    }

    ###===============================================
    ### REPORT DESIRED-STATE:
    ###===============================================
    function Report-DesiredState
    {    
         ### Update Config Log
        ###-------------------------------------
        Write-Host `r`n"UPDATING SERVER CONFIGLOG RECORD: " -ForegroundColor DarkCyan
        Write-Host "ServerID      : " $ServerID      -ForegroundColor DarkCyan
        Write-Host "HostName      : " $HostName      -ForegroundColor DarkCyan
        Write-Host "FunctionName  : " $FunctionName  -ForegroundColor DarkCyan
        Write-Host "Verify        : " $Verify        -ForegroundColor DarkCyan
        Write-Host "Abort         : " $Abort         -ForegroundColor DarkCyan
        
        $Params = @{
            ServerID      = $ServerID 
            HostName      = $HostName 
            FunctionName  = $FunctionName 
            PropertyName  = $PropertyName 
            CurrentState  = $CurrentState 
            Verify        = $Verify 
            Abort         = $Abort
        }
        Write-ECI.ConfigLog @Params

        ### Update Desired State
        ###-------------------------------------
        Write-Host `r`n"UPDATING SERVER DESIRED STATE RECORD:" -ForegroundColor DarkCyan
        Write-Host "ServerID      : " $ServerID       -ForegroundColor DarkCyan
        Write-Host "HostName      : " $HostName       -ForegroundColor DarkCyan
        Write-Host "PropertyName  : " $PropertyName   -ForegroundColor DarkCyan
        Write-Host "CurrentState  : " $CurrentState   -ForegroundColor DarkCyan
        Write-Host "DesiredState  : " $DesiredState   -ForegroundColor DarkCyan
        Write-Host "Verify        : " $Verify         -ForegroundColor DarkCyan
        Write-Host "Abort         : " $Abort          -ForegroundColor DarkCyan

        $Params = @{
            ServerID      = $ServerID 
            HostName      = $HostName 
            PropertyName  = $PropertyName 
            CurrentState  = $CurrentState 
            DesiredState  = $DesiredState 
            Verify        = $Verify 
            Abort         = $Abort
        }
        Write-ECI.DesiredState @Params
        
        ### Update Current State
        ###-------------------------------------
        Write-Host `r`n"UPDATING SERVER CURRENT STATE RECORD:" -ForegroundColor DarkCyan
        Write-Host "ServerID      : " $ServerID       -ForegroundColor DarkCyan
        Write-Host "HostName      : " $HostName       -ForegroundColor DarkCyan
        Write-Host "PropertyName  : " $PropertyName   -ForegroundColor DarkCyan
        Write-Host "CurrentState  : " $CurrentState   -ForegroundColor DarkCyan
        
        $Params = @{
            ServerID      = $ServerID 
            HostName      = $HostName 
            PropertyName  = $PropertyName 
            CurrentState  = $CurrentState                
        }
        Write-ECI.CurrentState @Params


### DOES THIS PART EVER EXECUTE???????????????????????????????????????????
        ### IF ABORT = TRUE
        ### --------------------
        if($Abort -eq $True)
        {
            ### ABORT = TRUE: Throw Abort Error
            ### -------------------------------------------------------------------------------------
            Write-ConfigReport "ABORTTRIGGER: " $AbortTrigger "`t`tABORT: " $Abort 
            
            Write-Host "ABORT ERROR:  " "ServerID: " $ServerID "HostName: " $HostName "VMName: " $VMName "FunctionName: " $FunctionName "Verify: " $Verify "AbortTrigger: " $AbortTrigger "Abort: " $Abort
            #Throw-AbortError -ServerID $ServerID -HostName $HostName -VMName $VMName -FunctionName $FunctionName -Verify $Verify  -PropertyName $PropertyName -AbortTrigger $AbortTrigger -Abort $Abort
        }
    }

    ###===============================================
    ###-----------------------------------------------
    ### CONFIGURE DESIRED-STATE
    ###-----------------------------------------------
    ###===============================================
    &{
        BEGIN
        {   
        }

        PROCESS
        {
            Get-CurrentState
            Compare-DesiredState
            if($Compare -eq $False){Set-DesiredState}
            Verify-DesiredState
            Report-DesiredState
        }

        END
        {   
            $CurrentState = $Null
            $DesiredState = $Null
            $VerifyState  = $Null
            $Verify       = $Null
            $Abort        = $Null
        }   
    }
}

###
### ===================================================================================================

function List-AllParameters-deleteme #<-- deleteme?????
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Server  Parameters
    ###----------------------------------------------------------------
    Write-Host `r`n('-' * 50)`n "Server Parameters  : "                        -ForegroundColor Gray
    Write-Host "ServerID                   : " $ServerID                     -ForegroundColor Gray

    ### Server Request Parameters
    ###----------------------------------------------------------------
    Write-Host `r`n('-' * 50)`n "ServerRequest Parameters  : "                  -ForegroundColor Gray
    Write-Host "RequestID                  : " $RequestID                     -ForegroundColor Gray
    Write-Host "RequestDateTime            : " $RequestDateTime               -ForegroundColor Gray
    Write-Host "HostName                   : " $HostName                      -ForegroundColor Gray
    Write-Host "ServerRole                 : " $ServerRole                    -ForegroundColor Gray
    Write-Host "IPv4Address                : " $IPv4Address                   -ForegroundColor Gray
    Write-Host "SubnetMask                 : " $SubnetMask                    -ForegroundColor Gray
    Write-Host "DefaultGateway             : " $DefaultGateway                -ForegroundColor Gray
    Write-Host "InstanceLocation           : " $InstanceLocation              -ForegroundColor Gray
    Write-Host "BackupRecovery             : " $BackupRecovery                -ForegroundColor Gray
    Write-Host "DisasterRecovery           : " $DisasterRecovery              -ForegroundColor Gray 

    ### VM Parameters
    ###----------------------------------------------------------------
    Write-Host `r`n('-' * 50)`n "VM Parameters             : " -ForegroundColor Gray
    Write-Host "VMParameterID              : " $VMParameterID -ForegroundColor Gray
    Write-Host "vCPUCount                  : " $vCPUCount -ForegroundColor Gray
    Write-Host "vMemorySizeGB              : " $vMemorySizeGB -ForegroundColor Gray
    Write-Host "OSVolumeGB                 : " $OSVolumeGB -ForegroundColor Gray
    Write-Host "SwapVolumeGB               : " $SwapVolumeGB -ForegroundColor Gray
    Write-Host "DataVolumeGB               : " $DataVolumeGB -ForegroundColor Gray
    Write-Host "LogVolumeGB                : " $LogVolumeGB -ForegroundColor Gray
    Write-Host "SysVolumeGB                : " $SysVolumeGB -ForegroundColor Gray

    ### OS Parameters
    ###----------------------------------------------------------------
    Write-Host `r`n('-' * 50)`n "OS Parameters              : "  -ForegroundColor Gray
    Write-Host "NetworkInterfacename       : " $NetworkInterfacename -ForegroundColor Gray
    Write-Host "LocalAdministrator         : " $LocalAdministrator -ForegroundColor Gray
    Write-Host "CDROMLetter                : " $CDROMLetter -ForegroundColor Gray
    Write-Host "IPv6Preference             : " $IPv6Preference -ForegroundColor Gray
    Write-Host "WindowsFirewallPreference  : " $WindowsFirewallPreference -ForegroundColor Gray
    Write-Host "IEESCPreference            : " $InternetExplorerESCPreference -ForegroundColor Gray
    Write-Host "RemoteDesktopPreference    : " $RemoteDesktopPreference -ForegroundColor Gray
    Write-Host "RDPResetrictionsPreference : " $RDPResetrictionsPreference -ForegroundColor Gray
    Write-Host "SwapFileBufferSizeMB       : " $SwapFileBufferSizeMB -ForegroundColor Gray
    Write-Host "SwapFileLocation           : " $SwapFileLocation -ForegroundColor Gray
    Write-Host "SwapFileMemoryThreshholdGB : " $SwapFileMemoryThreshholdGB -ForegroundColor Gray
    Write-Host "SwapFileMultiplier         : " $SwapFileMultiplier -ForegroundColor Gray
    Write-Host  `r`n('-' * 50)`r`n -ForegroundColor Gray
}

### Import VMWare Modules
### --------------------------------------------------
function Import-ECI.EMI.Automation.VMWareModules
{
    Param(
        [Parameter(Mandatory = $True)][string]$Env,
        [Parameter(Mandatory = $True)][string]$Environment,
        [Parameter(Mandatory = $True)][string]$ModuleName,
        [Parameter(Mandatory = $True)][version]$ModuleVersion
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Modify PSModulePath
    ###---------------------------
    $global:VMModulesPath = "\\eciscripts.file.core.windows.net\clientimplementation\" + $Environment + "\Vendor.Modules." + $Env + "\VMWare\PowerCLI.10.1.0\"
    $env:PSModulePath = $env:PSModulePath + ";" +  $VMModulesPath
    #$ModuleName = $VMModulesPath + $VMModulesName
    
    
    
    if((Get-Module -ListAvailable -Name $ModuleName) -ne $Null)
    {
        Write-Host "Importing VNWare Modules: " $ModuleName  $ModuleVersion -ForegroundColor Gray

        try
        {
            ### Uninstall Existing Modules
            ###---------------------------
            $VMModules = Get-Module -Name $ModuleName ; if($VMModules) {$VMModules | Remove-Module}
            
            ### Import Modules
            ###---------------------------
            Get-Module -ListAvailable -Name $ModuleName | Import-Module -Force # -MinimumVersion $ModuleVersion
            import-module -Name vmware.vimautomation.vds -Force
        }
        catch
        {
            Write-ECI.ErrorStack
        }
    }
    else
    {
         Write-Host "Modules not available! Check the env:PSModulePath." (Get-Module -ListAvailable $VMModules) -ForegroundColor Red
    }
    
    Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -InvalidCertificateAction ignore -Confirm:$false
    
    Get-Module -Name $ModuleName
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### --------------------------------------------------
function Get-ECI.EMI.Automation.vCenter
{
    Param([Parameter(Mandatory = $True)][string]$InstanceLocation)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    switch ( $InstanceLocation )
    {
        "Lab" { $vCenter = "ecilab-bosvcsa01.ecilab.corp" }
        "BOS" { $vCenter = "bosvc.eci.cloud"      }
        "QTS" { $vCenter = "cloud-qtsvc.eci.corp" }
        "SAC" { $vCenter = "sacvc.eci.cloud"      }
        "LHC" { $vCenter = "lhcvc.eci.cloud"      }
        "LD5" { $vCenter = "ld5vc.eci.cloud"      }
        "HK"  { $vCenter = "hkvc.eci.cloud"       }
        "SG"  { $vCenter = "sgvc.eci.cloud"       }
    }

    
    Write-Host "Instance Location  : " $InstanceLocation -ForegroundColor Cyan
    Write-Host "vCenter            : " $vCenter -ForegroundColor Cyan
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    $global:vCenter = $vCenter
    Return $vCenter
}

### --------------------------------------------------
function Connect-ECI.EMI.Automation.VIServer
{
    Param(
        [Parameter(Mandatory = $False)][string]$InstanceLocation,
        [Parameter(Mandatory = $False)][string]$vCenter,
        [Parameter(Mandatory = $False)][string]$User,
        [Parameter(Mandatory = $False)][string]$Password
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    if($User){$vCenter_Account = $User}
    if($Password){$vCenter_Password = $Password}

    ### Show/Hide VMWare Module Progress Bar
    $global:ProgressPreference = "Continue" ### Continue/SilentlyContinue
    
    ### Hide Certificate Warning Message
    Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -InvalidCertificateAction ignore -Confirm:$false | Out-Null  

    if($InstanceLocation)
    {
        ### Connect to vCenter
        ###---------------------------------
        if($global:DefaultVIServers.Name -eq (Get-ECI.EMI.Automation.vCenter -InstanceLocation $InstanceLocation))
        {
            Write-Host "Using Current VI Server Session : " $global:DefaultVIServers -ForegroundColor Cyan
            #Disconnect-VIServer -Server $global:DefaultVIServers -confirm:$false
        }
        elseif($global:DefaultVIServers.Name -ne (Get-ECI.EMI.Automation.vCenter -InstanceLocation $InstanceLocation))
        {
            write-host "Connecting to InstanceLocation : " $InstanceLocation -ForegroundColor Cyan
            $vCenter = Get-ECI.EMI.Automation.vCenter -InstanceLocation $InstanceLocation
            $global:VISession = Connect-VIServer -Server $vCenter -User $vCenter_Account -Password $vCenter_Password        
        }
    }

    if($vCenter)
    {
        ### Connect to vCenter
        ###---------------------------------
        if($global:DefaultVIServers.Name -eq $vCenter)
        {
            Write-Host "Using Current VI Server Session : " $global:DefaultVIServers -ForegroundColor Cyan
            #Disconnect-VIServer -Server $global:DefaultVIServers -confirm:$false
        }
        elseif($global:DefaultVIServers.Name -ne $vCenter)
        {
            write-host "Connecting to vCenterName : " $vCenter -ForegroundColor Cyan
            $global:VISession = Connect-VIServer -Server $vCenter -User $vCenter_Account -Password $vCenter_Password
        }

    }
       
    ### Get  InstanceUUID
    ###---------------------------------
    $global:vCenterUUID = $VISession.InstanceUuid
    Write-Host "vCenterUUID                          : " $vCenterUUID -ForegroundColor DarkCyan

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $VISession
}

### Delete Server Logs
### --------------------------------------------------
function Delete-ECI.EMI.Automation.ServerLogs
{
    Param([Parameter(Mandatory = $True)][string]$HostName)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Delete Log Path
    #$VMLogPath = $AutomationLogPath + "\" + $HostName + "\"
    $VMLogPath = $AutomationLogPath + "\" + $HostName + "\temp\"
    Write-Host "Deleting Server Logs:" $VMLogPath -ForegroundColor DarkCyan

    if(Test-Path -Path $VMLogPath)
    {
        Remove-Item -Path $VMLogPath -Include * -Recurse -Force -Confirm:$false 
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Copy-ECI.EMI.Automation.VMLogsfromGuest    #<--- Consolidatec
{
    Param(
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$VMName
    )
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    #VMLogs to Local
    $VMLogDestination = ($AutomationLogPath + "\" + $HostName)
    $GuestLogs = ($AutomationLogPath + "\" + $HostName)
    
    #if(-NOT(Test-Path -Path $VMLogDestination)) {(New-Item -ItemType directory -Path $VMLogDestination -Force | Out-Null)}
    Copy-ECI.EMI.VM.GuestFile -GuestToLocal -VM $VMName -Source $GuestLogs -Destination $VMLogDestination
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Copy-ECI.EMI.Automation.VMLogsfromGuest-original
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Set Folders

#working
#{

    $VMLogDestination = $AutomationLogPath + "\" + $HostName + "\" 
    $GuestLogSource = $AutomationLogPath + "\" + $HostName #+ "\*.*" 

    #foreach($Log in $GuestLogSource)
    #{
        
    #}

    if(-NOT(Test-Path -Path $VMLogDestination)) {(New-Item -ItemType directory -Path $VMLogDestination -Force | Out-Null)}
    write-host "Copying Log Files from Guest..."        -ForegroundColor Cyan
    write-host "GUEST LOG SOURCE :" $GuestLogSource     -ForegroundColor DarkCyan
    write-host "LOG DESTINATION  :" $VMLogDestination   -ForegroundColor DarkCyan

    #Copy-VMGuestFile -Source $GuestLogSource -Destination $VMLogDestination -VM $VMName -GuestToLocal -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword 

###<--- Use Cmdlet!!!!!!!!!!!!!!
Write-Host "USE Cmdlet" -ForegroundColor Magenta
    #Copy-VMGuestFile -Source $GuestLogSource -Destination $VMLogDestination -VM $VMName -GuestToLocal -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword 
    $GuestLogSource | Copy-VMGuestFile -Destination $VMLogDestination -VM $VMName -GuestToLocal -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword 
#Copy-ECI.EMI.VM.GuestFile -GuestToLocal -VM $VMName -Source $GuestLogSource -Destination $VMLogDestination
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### Write Server Logs to SQL
function Write-ECI.EMI.Automation.VMLogstoSQL
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Writing All Logs to SQL . . . " -ForegroundColor Cyan
    Write-ConfigLog-SQL
    Write-DesiredState-SQL
    Write-CurrentState-SQL
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


### Write Server Config Log
### --------------------------------------------------
function Write-ECI.ConfigLog
{
    Param(
    [Parameter(Mandatory = $True)][string]$ServerID,
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$FunctionName,
    [Parameter(Mandatory = $True)][string]$PropertyName,
    [Parameter(Mandatory = $True)][string]$CurrentState,
    [Parameter(Mandatory = $True)][string]$Verify,
    [Parameter(Mandatory = $True)][string]$Abort
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Create Log File
    ###---------------------------
    $VMLogName = "ConfigLog"
    #$VMLogFile = $AutomationLogPath + "\" + $HostName + "\" + $VMLogName + "_" + $HostName  + ".txt"
    $VMLogFile = $AutomationLogPath + "\" + $HostName + "\temp\" + $VMLogName + "_" + $HostName  + ".txt"
    if(-NOT(Test-Path -Path $VMLogFile)) {(New-Item -ItemType file -Path $VMLogFile -Force | Out-Null)}

    Set-Variable -Name $VMLogName -Value $VMLogFile -Option AllScope -Scope global -Force

    ## Write Log to Guest
    ###---------------------------
    $VMLogEntry = "ServerID=" + $ServerID + "," + "HostName=" + $HostName + "," +  "FunctionName=" + $FunctionName + "," +  "PropertyName=" + $PropertyName + "," +  "CurrentState=" + $CurrentState + "," +  "Verify=" + $Verify + "," +  "Abort=" + $Abort
    
    Write-Host "LOG: $VMLogName LOGFILE : $VMLogFile" -ForegroundColor DarkGray
    Write-Host "LOG: $VMLogName ENTRY   : $VMLogEntry" -ForegroundColor DarkGray
    $VMLogEntry | Out-File -FilePath $VMLogFile -Force -Append

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}
function Write-ConfigLog-Old
{
    Param(
    [Parameter(Mandatory = $True)][string]$ServerID,
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$FunctionName,
    [Parameter(Mandatory = $True)][string]$PropertyName,
    [Parameter(Mandatory = $True)][string]$CurrentState,
    [Parameter(Mandatory = $True)][string]$Verify,
    [Parameter(Mandatory = $True)][string]$Abort
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Create Log File
    ###---------------------------
    $LogName = "ConfigLog"
    $LogFile = $AutomationLogPath + "\" + $HostName + "\" + $VMLogName + "_" + $HostName  + ".txt"
    #if(-NOT(Test-Path -Path $VMLogFile)) {(New-Item -ItemType file -Path $VMLogFile -Force | Out-Null)}

    Set-Variable -Name $VMLogName -Value $VMLogFile -Option AllScope -Scope global -Force

    ## Write Log to Guest
    ###---------------------------
    $LogEntry = "ServerID=" + $ServerID + "," + "HostName=" + $HostName + "," +  "FunctionName=" + $FunctionName + "," +  "PropertyName=" + $PropertyName + "," +  "CurrentState=" + $CurrentState + "," +  "Verify=" + $Verify + "," +  "Abort=" + $Abort
    
    Write-Host "LOG LOGFILE : $LogFile" -ForegroundColor DarkGray
    Write-Host "LOG ENTRY   : $LogEntry" -ForegroundColor DarkGray
    $LogEntry | Out-File -FilePath $LogFile -Force -Append

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### Write Server Config Logs to SQL
### --------------------------------------------------
function Write-ConfigLog-SQL
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Set Log Name
    ###---------------------------
    $VMLogName = "ConfigLog"
    #$VMLogPath = $AutomationLogPath + "\" + $HostName + "\" 
    $VMLogPath = $AutomationLogPath + "\" + $HostName + "\temp\" 
    $ConnectionString  = $DevOps_DBConnectionString 

    ### Open Database Connection
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open()   
    ### Insert Row
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $Connection    

    ### Import Log File
    ###----------------------
    $VMLastLog = Get-ChildItem -Path ($VMLogPath) | Where-Object {($_ -like $VMLogName + "*")} | Sort-Object LastAccessTime -Descending | Select-Object -First 1
    $VMLastLogFile = $VMLogPath + "\" + $VMLastLog
    $VMLastLogFile = Get-Content -Path $VMLastLogFile
    
    foreach ($Record in $VMLastLogFile)
    {
        $Keys = $Null
        $Values = $Null

        foreach($Column in ($Record.split(",")))
        {
          $Key = $Column.split("=")[0]
          $Value =  "'" + $Column.split("=")[1] + "'"
          $Keys = $Keys + $Key + ","
          $Values = $Values + $Value + ","
        }
        $Keys = $Keys.Substring(0,$Keys.Length-1)
        $Values = $Values.Substring(0,$Values.Length-1)

        $Query = "INSERT INTO ServerConfigLog($Keys) VALUES ($Values)"
        
        ### Show Results
        ###------------------------
        Write-Host "SQLQuery: " $Query -ForegroundColor DarkCyan

        $cmd.CommandText = $Query
        $cmd.ExecuteNonQuery() #| Out-Null
    }
    ### Close
    $connection.Close()

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### Write Server Desired State
### --------------------------------------------------
function Write-ECI.DesiredState
{
    Param(
    [Parameter(Mandatory = $True)][string]$ServerID,
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$PropertyName,
    [Parameter(Mandatory = $True)][string]$CurrentState,
    [Parameter(Mandatory = $True)][string]$DesiredState,
    [Parameter(Mandatory = $True)][string]$Verify,
    [Parameter(Mandatory = $True)][string]$Abort
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Set Log Name
    ###---------------------------
    $VMLogName = "DesiredStateLog"
    #$VMLogFile = $AutomationLogPath + "\" + $HostName + "\" + $VMLogName + "_" + $HostName  + ".txt"
    $VMLogFile = $AutomationLogPath + "\" + $HostName + "\temp\" + $VMLogName + "_" + $HostName  + ".txt"
    if(-NOT(Test-Path -Path $VMLogFile)) {(New-Item -ItemType file -Path $VMLogFile -Force | Out-Null)}

    Set-Variable -Name $VMLogName -Value $VMLogFile -Option AllScope -Scope global -Force

    ## Write Log to Guest
    ###---------------------------
    $VMLogEntry =   "ServerID=" + $ServerID + "," + "HostName=" + $HostName + "," +  "PropertyName=" + $PropertyName + "," +  "CurrentState=" + $CurrentState + "," +  "DesiredState=" + $DesiredState + "," +  "Verify=" + $Verify + "," +  "Abort=" + $Abort
    
    Write-Host "LOG: $VMLogName LOGFILE : $VMLogFile" -ForegroundColor DarkGray
    Write-Host "LOG: $VMLogName ENTRY   : $VMLogEntry" -ForegroundColor DarkGray
    $VMLogEntry | Out-File -FilePath $VMLogFile -Force -Append

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}
function Write-DesiredState-old
{
    Param(
    [Parameter(Mandatory = $True)][string]$ServerID,
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$PropertyName,
    [Parameter(Mandatory = $True)][string]$CurrentState,
    [Parameter(Mandatory = $True)][string]$DesiredState,
    [Parameter(Mandatory = $True)][string]$Verify,
    [Parameter(Mandatory = $True)][string]$Abort,
    [Parameter(Mandatory = $False)][switch]$RuninGuest
    )

    ### Set Log Name
    ###---------------------------
    $VMLogName = "DesiredStateLog"
    $VMLogPath = $AutomationLogPath + "\" + $HostName + "\" 

    ### Set Log File Name
    ###---------------------------
    $VMLogFile = $VMLogPath + $VMLogName + "_" + $HostName  + ".txt" #+ "_" + (Get-Date -format "MM-dd-yyyy_hh_mm_ss") + ".txt"
    if(-NOT(Test-Path -Path $VMLogFile)) {(New-Item -ItemType file -Path $VMLogFile -Force | Out-Null)}

    Set-Variable -Name $VMLogName -Value $VMLogFile -Option AllScope -Scope global -Force

    $VMLogEntry =   "ServerID=" + $ServerID + "," + "HostName=" + $HostName + "," +  "PropertyName=" + $PropertyName + "," +  "CurrentState=" + $CurrentState + "," +  "DesiredState=" + $DesiredState + "," +  "Verify=" + $Verify + "," +  "Abort=" + $Abort
    $VMLogEntry | Out-File -FilePath $VMLogFile -Force -Append
}

### Write Server Desired State to SQL
### --------------------------------------------------
function Write-DesiredState-SQL
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Set Log Name
    ###---------------------------
    $VMLogName = "DesiredState"
    #$VMLogPath = $AutomationLogPath + "\" + $HostName + "\" 
    $VMLogPath = $AutomationLogPath + "\" + $HostName + "\temp\" 
    $ConnectionString  = $DevOps_DBConnectionString 

    ### Open Database Connection
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open()   
    ### Insert Row
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $Connection    

    ### Import Log File
    ###----------------------
    $VMLastLog = Get-ChildItem -Path ($VMLogPath) | Where-Object {($_ -like $VMLogName + "*")} | Sort-Object LastAccessTime -Descending | Select-Object -First 1
    $VMLastLogFile = $VMLogPath + "\" + $VMLastLog
    
    $VMLastLogFile = Get-Content -Path $VMLastLogFile
    
    foreach ($Record in $VMLastLogFile)
    {
        $Keys = $Null
        $Values = $Null

        foreach($Column in ($Record.split(",")))
        {
          $Key = $Column.split("=")[0]
          $Value =  "'" + $Column.split("=")[1] + "'"
          $Keys = $Keys + $Key + ","
          $Values = $Values + $Value + ","
        }
        $Keys = $Keys.Substring(0,$Keys.Length-1)
        $Values = $Values.Substring(0,$Values.Length-1)

        $Query = "INSERT INTO ServerDesiredState($Keys) VALUES ($Values)"
        
        ### Show Results
        ###------------------------        
        write-host "SQLQuery: " $Query -ForegroundColor DarkCyan

        $cmd.CommandText = $Query
        $cmd.ExecuteNonQuery() #| Out-Null
    }
    ### Close
    $connection.Close()
}

### Write Server Curren State
### --------------------------------------------------
function Write-ECI.CurrentState
{
    Param(
    [Parameter(Mandatory = $True)][string]$ServerID,
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$PropertyName,
    [Parameter(Mandatory = $True)][string]$CurrentState
    )

    ### Set Log Name
    ###---------------------------
    $VMLogName = "CurrentStateLog"
    #$VMLogFile = $AutomationLogPath + "\" + $HostName + "\" + $VMLogName + "_" + $HostName  + ".txt"
    $VMLogFile = $AutomationLogPath + "\" + $HostName + "\temp\" + $VMLogName + "_" + $HostName  + ".txt"
    if(-NOT(Test-Path -Path $VMLogFile)) {(New-Item -ItemType file -Path $VMLogFile -Force | Out-Null)}

    Set-Variable -Name $VMLogName -Value $VMLogFile -Option AllScope -Scope global -Force

    ## Write Log to Guest
    ###---------------------------
    $VMLogEntry =   "ServerID=" + $ServerID + "," + "HostName=" + $HostName + "," +  "PropertyName=" + $PropertyName + "," +  "CurrentState=" + $CurrentState
    
    Write-Host "LOG: $VMLogName LOGFILE : $VMLogFile" -ForegroundColor DarkGray
    Write-Host "LOG: $VMLogName ENTRY   : $VMLogEntry" -ForegroundColor DarkGray
    $VMLogEntry | Out-File -FilePath $VMLogFile -Force -Append

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}
function Write-CurrentState-old
{
    Param(
    [Parameter(Mandatory = $True)][string]$ServerID,
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$PropertyName,
    [Parameter(Mandatory = $True)][string]$CurrentState
    )

    ### Set Log Name
    ###---------------------------
    $VMLogName = "CurrentStateLog"
    $VMLogPath = $AutomationLogPath + "\" + $HostName + "\" 

    ### Set Log File Name
    ###---------------------------
    $VMLogFile = $VMLogPath + $VMLogName + "_" + $HostName + ".txt" #+ "_" + (Get-Date -format "MM-dd-yyyy_hh_mm_ss") + ".txt"
    if(-NOT(Test-Path -Path $VMLogFile)) {(New-Item -ItemType file -Path $VMLogFile -Force | Out-Null)}

    Set-Variable -Name $VMLogName -Value $VMLogFile -Option AllScope -Scope global -Force

    ### Export Log Entry
    ###---------------------------
    $VMLogEntry =   "ServerID=" + $ServerID + "," + "HostName=" + $HostName + "," +  "PropertyName=" + $PropertyName + "," +  "CurrentState=" + $CurrentState
    $VMLogEntry | Out-File -FilePath $VMLogFile -Force -Append
}

### Write Server Current State to SQL
### --------------------------------------------------
function Write-CurrentState-SQL
{
    #Param([Parameter(Mandatory = $True)][string]$ServerID)
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Set Log Name
    ###---------------------------
    $VMLogName = "CurrentStateLog"
    #$VMLogPath = $AutomationLogPath + "\" + $HostName  + "\" 
    $VMLogPath = $AutomationLogPath + "\" + $HostName + "\temp\" 
    $ConnectionString = $DevOps_DBConnectionString

    ### Open Database Connection
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open()   
    ### Insert Row
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $Connection    

    ### Import Log File
    ###----------------------
    $VMLastLog = Get-ChildItem -Path ($VMLogPath) | Where-Object {($_ -like $VMLogName + "*")} | Sort-Object LastAccessTime -Descending | Select-Object -First 1
    $VMLastLogFile = $VMLogPath + "\" + $VMLastLog
    
    $VMLastLogFile = Get-Content -Path $VMLastLogFile

    foreach ($Record in $VMLastLogFile)
    {
        #$Keys = $Null
        #$Values = $Null

        $ServerID     = ($Record.split(","))[0].split("=")[1]
        $HostName     = ($Record.split(","))[1].split("=")[1]
        $PropertyName = ($Record.split(","))[2].split("=")[1]
        $CurrentState = ($Record.split(","))[3].split("=")[1]
        
        $CurrentStateDateTime = "'" + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "'"

        if($CurrentState -eq "False"){$CurrentState = 0}
        if($CurrentState -eq "True"){$CurrentState = 1}
        else {$CurrentState = "'" + $CurrentState + "'"}

        ### FORMAT: UPDATE tblTable SET column1 = value1, column2 = value2...., columnN = valueN WHERE [condition];

        $Query = "UPDATE ServerCurrentState SET $PropertyName = $CurrentState, CurrentStateDateTime =  $CurrentStateDateTime WHERE ServerID = $ServerID"

        ### Show Results
        ###------------------------        
        write-host "SQLQuery: " $Query -ForegroundColor DarkCyan

        $cmd.CommandText = $Query
        $cmd.ExecuteNonQuery() #| Out-Null
    }
    ### Close
    $connection.Close()
}

###                                                         <--- why????
### --------------------------------------------------
function Write-ConfigReport 
{
    Param(
    [Parameter(Mandatory = $True, Position = 0)] [string]$Message,
    [Parameter(Mandatory = $False, Position = 1)] [string]$String,
    [Parameter(Mandatory = $False, Position = 2)] [string]$String2,
    [Parameter(Mandatory = $False, Position = 3)] [string]$String3,
    [Parameter(Mandatory = $False, Position = 4)] [string]$String4,
    [Parameter(Mandatory = $False, Position = 5)] [string]$String5,
    [Parameter(Mandatory = $False, Position = 6)] [string]$String6,
    [Parameter(Mandatory = $False, Position = 7)] [string]$String7,
    [Parameter(Mandatory = $False, Position = 8)] [string]$String8,
    [Parameter(Mandatory = $False, Position = 9)] [string]$String9,
    [Parameter(Mandatory = $False, Position = 10)] [string]$String10
    )
        function Start-ConfigReport 
    {
        ### Create Timestamp
        $VMLogName = "ConfigReport"
        $TimeStamp  = Get-Date -format "MM-dd-yyyy_hh_mm_ss"

        ### Create Log Folder
        $global:ConfigReportPath = $AutomationLogPath + "\" + $HostName + "\"
        $global:ConfigReportPath = $AutomationLogPath + "\" + $HostName + "\temp\" 
        if(-NOT(Test-Path -Path $ConfigReportPath)) {(New-Item -ItemType directory -Path $ConfigReportPath -Force | Out-Null) }
       
        ### Create Log File
        #$global:ConfigReportFile = $ConfigReportPath + "ConfigReport" + "_" + $TimeStamp + ".log"
        $global:ConfigReportFile = $ConfigReportPath + "ConfigReport" + "_" + $HostName + ".log"

        if(-NOT(Test-Path -Path $ConfigReportFile)) {(New-Item -ItemType file -Path $ConfigReportFile -Force | Out-Null) }
    }

    if (((Get-Variable 'ConfigReportFile' -Scope Global -ErrorAction 'Ignore')) -eq $Null) #if (-NOT($LogFile))
    {
        Start-ConfigReport
    }     

    ### Write the Message to the Config Report.
    $Message = $Message + $String + $String2 + $String3 + $String4 + $String5 + $String6
    Write-Host $Message
    $Message | Out-File -filepath $ConfigReportFile -append   # Write the Log File Emtry
}

### Server Build Tag     #<---------------------------------Rewrite or Delete?????????????
### --------------------------------------------------
function Write-ServerBuildTag
{
    Write-Host "Writing ServerBuildTag:"`r`n("-" * 50)

    ### Create Server Build Tag
    $ServerBuildTagPath = $AutomationLogPath + "ServerBuildTag_" + $VMName #+ "_" + $(get-date -f MM-dd-yyyy_HH_mm_ss) + ".txt"
    $ServerBuildTag = @()
    # Build Hash Table for Reports
    #------------------------------

    $hash = [ordered]@{            
        AD_OU                   = $ClientOU
        AD_UserPrincipalName    = $ADAccount.UserPrincipalName
        #EX_MailBox_EmailAddress = $MailBox.EmailAddresses
        EX_MailBox_Name         = $MailBox.Name            
        EX_DistinguishedName    = $MailBox.DistinguishedName            
        EX_Client_UPN           = $ClientUPN       = $ClientUPN            
    }                           
    $PSObject = New-Object PSObject -Property $hash
    $ReportData += $PSObject 
    $script:ReportData  = $ReportData
                    
                            
        $ServerBuildTag += (Get-ECI.EMI.Automation.ServerRecord-SQL -ServerID $ServerID)

        Get-ECI.EMI.Automation.ServerCurrentState-SQL -ServerID $ServerID
        Get-ECI.EMI.Automation.ServerDesiredState-SQL -ServerID $ServerID
        Get-ECI.EMI.Automation.ServerConfigLog-SQL    -ServerID $ServerID

   
    $ServerBuildTag     = [ordered]@{
        VMGuestName     = (Get-WmiObject Win32_ComputerSystem).Name
        VMGuestOS       = [environment]::OSVersion.Version
        VMGuestDomain   = (Get-WmiObject Win32_ComputerSystem).Domain
        BuildDate       = $(get-date)
        Engineer        = "CBrennan - (cbrennan@eci.com)"
    }
    $ServerBuildTag | Out-File -FilePath $ServerBuildTagPath -Force

    ### Get Module Meta Data
    $Modules = Get-Module | Where-Object {($_.Name -like "ECI.Core.*")}
    foreach($Module in $Modules)
    {
        $ModuleData = [ordered]@{
            Module        = $Module
            ModuleVersion = $Module.Version
        }
        $ModuleData | Out-File -FilePath $ServerBuildTagPath -Append
    
        Write-Host "Module: " $Module
        Write-Host "ModuleVersion: " $Module.Version   
    }

}

### Open SQL Server Connection - SQL
### --------------------------------------------------
function Open-SQLConnection
{    
    [OutputType([bool])]
    Param([Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]$ConnectionString)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    try
    {
        $Connection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString;
        $Connection.Open();
        $Connection.Close();

        Write-Host "SQL Connectivity Results: "
        Write-Host "ConnectionString: " $ConnectionString
        Return $True;
    }
    catch
    {
        Write-Host "SQL Connectivity Results: "
        Write-Host "ConnectionString: " $ConnectionString
        Return $False;
        $Abort = $True
        Invoke-AbortError
    }
}

### ===================================================================================================
### Get SQL Data - Get-ECI.EMI.Automation.SQLData  <---- CMDLET
### ===================================================================================================
function Get-ECI.EMI.Automation.SQLData
{
    [CmdletBinding(SupportsPaging = $true)]

    PARAM(
        [Parameter(Mandatory = $True)] [string]$DataSetName,
        [Parameter(Mandatory = $True)] [string]$ConnectionString,
        [Parameter(Mandatory = $True)] [string]$Query,
        [Parameter(Mandatory = $False)] [switch]$Quiet
    )

    BEGIN 
    {
        ### Database Connection Object
        $Connection = New-Object System.Data.SQLClient.SQLConnection
        $Connection.ConnectionString = $ConnectionString 
        $Connection.Open()    

        ### SQL Query Command Object
        $Command = New-Object System.Data.SQLClient.SQLCommand
        $Command.Connection = $Connection
        $Command.CommandText = $Query
        $Reader = $Command.ExecuteReader()
    }
    
    PROCESS
    {
        ### Datatable Object
        $Datatable = New-Object System.Data.DataTable
        $Datatable.Load($Reader)

        ### Get Columns from the  Datatable
        ###---------------------------------
        #Write-Host "Datatable.Rows.Count: " $Datatable.Rows.Count -ForegroundColor DarkGray
                    
        if($Datatable.Rows.Count -gt 0)
        {
            $Columns = $Datatable | Get-Member -MemberType Property,NoteProperty | ForEach-Object {$_.Name} | Sort-Object -Property Name
        }
        elseif($Datatable.Rows.Count -eq 0)
        {
            Write-Host $DataSetName ": No Records Found Matching Query!" -ForegroundColor Red
        }

        #$global:Parameters = @()
        $PSObject = New-Object PSObject 

        foreach($Column in $Columns)
        {
            ### .Trim() all Values
            [string]$Value = $Datatable.$Column
            $Value = $Value.Trim()

            ### Create Variables from Datatable
            #Set-Variable -Name $Column -Value $Datatable.$Column -Scope Global
            Set-Variable -Name $Column -Value $Value -Scope Global

            #$PSObject | Add-Member -MemberTypeNoteProperty -Name $Column -Value $Datatable.$Column
            $PSObject | Add-Member -type NoteProperty -Name $Column -Value $Datatable.$Column

            ### Build Parameter Set from Datatable
            #$Parameters += Get-Variable -Name $Column 
            
            ### Build All Parameters Set
            #$global:AllParameters += Get-Variable -Name $Column 
        }
        
        ### Name Dataset name = PSObject
        Write-Host "Getting DataSet from SQL: " $DataSetName -foregroundcolor DarkCyan
        Set-Variable -Name $DataSetName -Value $PSObject -Scope global
        
        ### Display Parameters (or Not)
        if(-NOT($Quiet))
        {
            $Datatable | FL
            #$Parameters | FT
        }
    }

    END 
    {
        ### Close Database Connection
        $Connection.Close()
    }
}


### Get System Config - SQL
### --------------------------------------------------
function Get-ECI.EMI.Automation.SystemConfig
{
    param(
    [Parameter(Mandatory = $True,Position=0)][string]$Env,
    [Parameter(Mandatory = $True,Position=0)][string]$DevOps_ConnectionString
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "SystemConfig"
    $ConnectionString = $DevOps_ConnectionString
    $Query = "SELECT * FROM SystemConfig WHERE Env = '$Env'"

    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query


    #$global:DevOps_ConnectionString = $DevOps_ConnectionString
    #Get-Variable -Name Portal_DBConnectionString

<#
    switch ($Env)
    {
        "Dev"   { $global:Portal_DBConnectionString = $DevPortal_DBConnectionString   }
        "Stage" { $global:Portal_DBConnectionString = $StagePortal_DBConnectionString }
        "Prod"  { $global:Portal_DBConnectionString = $ProdPortal_DBConnectionString  }
    }

    switch ($Env)
    {
        "Dev"   { $global:vCenter_Account = $DevvCenter_Account   }
        "Stage" { $global:vCenter_Account = $StagevCenter_Account }
        "Prod"  { $global:vCenter_Account = $ProdvCenter_Account  }
    }

    switch ($Env)
    {
        "Dev"   { $global:vCenter_Password = $DevvCenter_Password   }
        "Stage" { $global:vCenter_Password = $StagevCenter_Password }
        "Prod"  { $global:vCenter_Password = $ProdvCenter_Password  }
    }
#>

    Write-Host "DevOps_DBConnectionString  : " $DevOps_DBConnectionString
    Write-Host "Portal_DBConnectionString  : " $Portal_DBConnectionString
    Write-Host "vCenter_Account            : " $vCenter_Account
    Write-Host "vCenter_Password           : " (ConvertTo-SecureString $vCenter_Password -AsPlainText -Force)
    #$vCenter_Password
    
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### Get Build Version - SQL
### --------------------------------------------------
function Get-ECI.EMI.Automation.BuildVersion
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "ServerBuildVersion"
    $ConnectionString =  $DevOps_DBConnectionString
    $Query = "SELECT * FROM definitionServerBuildVersions WHERE Production = '$True'"

    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query
    
    Write-Host "ServerBuildVersion.BuildVersion: " $ServerBuildVersion.BuildVersion
    
    $global:BuildVersion = $ServerBuildVersion.BuildVersion
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $BuildVersion
}

### Get Server Request Parameters - SQL
### --------------------------------------------------
function Get-ECI.EMI.Automation.ServerRequest
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "ServerRequest"
    $ConnectionString =  $Portal_DBConnectionString
    $Query = "SELECT * FROM ServerRequest WHERE RequestID = '$RequestID'"
   
    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query   

    Write-Host "ServerRequest - RequestId  : $RequestId"     -ForegroundColor Cyan
    Write-Host "ServerRequest - GPID       : $GPID"          -ForegroundColor Cyan
    Write-Host "ServerRequest - CWID       : $CWID"          -ForegroundColor Cyan
    Write-Host "ServerRequest - HostName   : $HostName"`n`n  -ForegroundColor Cyan

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $global:RequestId
}

### Get Server Role - SQL
### --------------------------------------------------
function Get-ECI.EMI.Automation.ServerRole
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "ServerRoleData"
    $ConnectionString = $DevOps_DBConnectionString
    $Query = "SELECT * FROM definitionServerRoles WHERE ServerRole = '$RequestServerRole' AND BuildVersion = '$BuildVersion'"

    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query
    
    $global:ServerRole = $ServerRole
    Write-Host "ServerRole: " $ServerRole -ForegroundColor Cyan
    Return $ServerRole
}

### Get VMWare Template - SQL
### --------------------------------------------------
function Get-ECI.EMI.Automation.VMWareTemplate
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "VMWareTemplate"
    $ConnectionString = $DevOps_DBConnectionString
    $Query = "SELECT * FROM definitionVMTemplates WHERE ServerRole = '$ServerRole' AND BuildVersion = '$BuildVersion'"

    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query
    
    $global:VMTemplateName = $VMTemplateName
    Write-Host "VMTemplateName: " $VMTemplateName -ForegroundColor Cyan
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $global:VMTemplateName
}

### Get VMWare OSCustomizationSpec - SQL
### --------------------------------------------------
function Get-ECI.EMI.Automation.OSCustomizationSpec-encrypt
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "VMWareOSCustomizationSpec"
    $ConnectionString = $DevOps_DBConnectionString
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)

    $DataTable

    #Write-host "DecryptedPassword: " $DecryptedPassword -ForegroundColor Magenta

    Write-Host "OSCustomizationSpecName: " $OSCustomizationSpecName -ForegroundColor Cyan
    Return $global:OSCustomizationSpecName

    $Connection.Close()
}

function Get-ECI.OSCustomizationSpec-original
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "VMWareOSCustomizationSpec"
    $ConnectionString = $DevOps_DBConnectionString

    #OPEN SYMMETRIC KEY SQLSymmetricKey  DECRYPTION BY CERTIFICATE SelfSignedCertificate;  
    #SELECT FirstName, LastName,LoginID,UserPassword,EncryptedPassword,  CONVERT(varchar, DecryptByKey(EncryptedPassword)) AS 'DecryptedPassword'  FROM UserDetails; 

    ### Decrypt AdminPassword 
    $Query = "SELECT *, CONVERT(varchar, DecryptByKey(AdminPassword)) AS 'AdminPassword' FROM definitionVMOSCustomizationSpec WHERE ServerRole = '$ServerRole' AND BuildVersion = '$BuildVersion'" 

    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query

    Return $global:OSCustomizationSpecName
}

function Get-ECI.EMI.Automation.OSCustomizationSpec
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "VMWareOSCustomizationSpec"
    $ConnectionString = $DevOps_DBConnectionString
    $Query = "OPEN SYMMETRIC KEY SQLSymmetricKey  DECRYPTION BY CERTIFICATE SelfSignedCertificate; SELECT *, CONVERT(varchar, DecryptByKey(EncryptedPassword)) AS 'DecryptedPassword' FROM definitionVMOSCustomizationSpec WHERE ServerRole = '$ServerRole' AND BuildVersion = '$BuildVersion'"

    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $global:OSCustomizationSpecName
}

### Get VM Parameters - SQL
### --------------------------------------------------
function Get-ECI.EMI.Automation.VMParameters
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "VMParameters"
    $ConnectionString = $DevOps_DBConnectionString
    $Query = "SELECT * FROM definitionVMParameters WHERE serverRole = '$ServerRole' AND BuildVersion = '$BuildVersion'"

    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### Get OS Parameters - SQL
### --------------------------------------------------
function Get-ECI.EMI.Automation.OSParameters
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "OSParameters"
    $ConnectionString = $DevOps_DBConnectionString
    $Query = "SELECT * FROM definitionOSParameters WHERE ServerRole = '$ServerRole' AND BuildVersion = '$BuildVersion'"

    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### Check Server Record - SQL                           <--- Set Configuration Mode!!!!!!!!!!
### --------------------------------------------------
function Check-ECI.EMI.Automation.ServerRecord
{
    Param(
        [Parameter(Mandatory = $True)][string]$GPID,
        [Parameter(Mandatory = $True)][string]$CWID,
        [Parameter(Mandatory = $True)][string]$HostName
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    
    $ConnectionString = $DevOps_DBConnectionString
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Query = "SELECT * FROM Servers WHERE GPID = '$GPID' AND CWID = '$CWID' AND HostName = '$HostName'"
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $Datatable = New-Object System.Data.DataTable
    $Datatable.Load($Reader)

    ### Check if Server Record Exists
    ###--------------------------------
    if(($Datatable.Rows.Count) -eq 0)
    {
        $global:ServerExists = $False
        #$global:ConfigurationMode = "Configure"                                                                                             ### <--- ConfigurationMode    
        Write-Host "There is no existing ServerID record for this server." -ForegroundColor DarkCyan                                                 ### <--- ConfigurationMode
        Write-Host `r`n('=' * 75)`r`n "This is a New Server Request: Running in Configure Mode!" `r`n('=' * 75)`r`n -ForegroundColor Yellow  ### <--- ConfigurationMode
    }
    elseif(($Datatable.Rows.Count) -gt 0)
    {
        $global:ServerExists = $True
        #$global:ConfigurationMode = "Report"                                                                                   ### <--- ConfigurationMode 
        $global:ServerID = $ServerID
        Write-Host `r`n('=' * 75)`r`n "A Matching Server Record already Exists: Running in Report Mode!" `r`n('=' * 75)`r`n -ForegroundColor Yellow
        
        Return $global:ServerID
    }

    #Write-Host "ServerExists              : " $ServerExists -ForegroundColor Yellow                                            ### <--- ConfigurationMode 
    #Write-Host "Setting ConfigurationMode : " $ConfigurationMode -ForegroundColor DarkYellow                                   ### <--- ConfigurationMode 
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    #Return $global:ConfigurationMode                                                                                           ### <--- ConfigurationMode 
}

### Write Server Status - SQL
### --------------------------------------------------
function Create-ECI.EMI.Automation.ServerStatus
{
    Param(
    [Parameter(Mandatory = $True)][int]$RequestID,
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$ServerStatus
    )
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "SQL - WRITING SERVER STATUS:"  -ForegroundColor Cyan
    Write-Host "RequestID    :" $RequestID    -ForegroundColor DarkCyan
    Write-Host "HostName     :" $HostName     -ForegroundColor DarkCyan
    Write-Host "ServerStatus :" $ServerStatus -ForegroundColor DarkCyan
    
    $ConnectionString = $Portal_DBConnectionString
    $Query = "INSERT INTO ServerStatus(RequestID,ServerID,HostName,ServerStatus,ElapsedTime,VerifyErrorCount,Abort) VALUES('$RequestID','$ServerID','$HostName','$ServerStatus','$ElapsedTime','$VerifyErrorCount','$Abort')"
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open()   
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() | Out-Null
    $connection.Close()
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### Update Server Status - SQL
### --------------------------------------------------
function Update-ECI.EMI.Automation.ServerStatus
{
    Param(
    [Parameter(Mandatory = $True)][int]$RequestID,
    [Parameter(Mandatory = $True)][int]$ServerID,
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$VerifyErrorCount,
    [Parameter(Mandatory = $True)][string]$Abort,
    [Parameter(Mandatory = $False)][string]$ElapsedTime,
    [Parameter(Mandatory = $True)][string]$ServerStatus
    )
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "SQL - UPDATE SERVER STATUS : "                -ForegroundColor DarkCyan
    Write-Host "ServerStatus               : " $ServerStatus  -ForegroundColor DarkCyan
    Write-Host "RequestID                  : " $RequestID     -ForegroundColor DarkCyan
    Write-Host "ServerID                   : " $ServerID      -ForegroundColor DarkCyan
    Write-Host "HostName                   : " $HostName      -ForegroundColor DarkCyan
    Write-Host "Verify                     : " $Verify        -ForegroundColor DarkCyan
    Write-Host "Abort                      : " $Abort         -ForegroundColor DarkCyan
    Write-Host "ElsapsedTime               : " $ElapsedTime   -ForegroundColor DarkCyan

    $ConnectionString = $Portal_DBConnectionString
    $Query = "INSERT INTO ServerStatus(RequestID,ServerID,HostName,VerifyErrorCount,Abort,ElapsedTime,ServerStatus) VALUES('$RequestID','$ServerID','$HostName','$VerifyErrorCount','$Abort','$ElapsedTime','$ServerStatus')" #-f $RequestID,$ServerID,$HostName,$Verify,$Abort,$ElapsedTime,$ServerStatus
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open()   
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() | Out-Null
    $connection.Close()

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### Create Server Record - SQL
### --------------------------------------------------
function Create-ECI.EMI.Automation.ServerRecord
{
    Param(
    [Parameter(Mandatory = $True)][int]$RequestID,
    [Parameter(Mandatory = $True)][string]$GPID,
    [Parameter(Mandatory = $True)][string]$CWID,        
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$ServerRole,
    [Parameter(Mandatory = $True)][string]$BuildVersion
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ###-------------------------------
    ### Create Server Record
    ###-------------------------------
    Write-Host "SQL - CREATING SERVER RECORD: " -ForegroundColor Cyan
    Write-Host "RequestID    : " $RequestID     -ForegroundColor DarkCyan
    Write-Host "GPID         : " $GPID          -ForegroundColor DarkCyan
    Write-Host "CWID         : " $CWID          -ForegroundColor DarkCyan
    Write-Host "HostName     : " $HostName      -ForegroundColor DarkCyan
    Write-Host "ServerRole   : " $ServerRole    -ForegroundColor DarkCyan
    Write-Host "BuildVersion : " $BuildVersion  -ForegroundColor DarkCyan

    $ConnectionString = $DevOps_DBConnectionString
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open()   
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $Query = "INSERT INTO Servers(RequestID,GPID,CWID,HostName,ServerRole,InstanceLocation,IPv4Address,SubnetMask,DefaultGateway,PrimaryDNS,SecondaryDNS,ClientDomain,DomainUserName,BackupRecovery,DisasterRecovery,RequestDateTime,BuildVersion) VALUES('$RequestID','$GPID','$CWID','$HostName','$RequestServerRole','$InstanceLocation','$IPv4Address','$SubnetMask','$DefaultGateway','$PrimaryDNS','$SecondaryDNS','$ClientDomain','$DomainUserName','$BackupRecovery','$DisasterRecovery','$RequestDateTime','$BuildVersion')"
    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() | Out-Null
    $connection.Close()

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### --------------------------------------------------
function Update-ECI.EMI.Automation.ServerRecord
{
    Param(
    [Parameter(Mandatory = $True)][string]$ServerID,
    [Parameter(Mandatory = $True)][string]$VMName,
    [Parameter(Mandatory = $True)][string]$ServerUUID,
    [Parameter(Mandatory = $True)][string]$vCenterUUID,
    [Parameter(Mandatory = $True)][string]$VMID
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "UPDATING SERVER RECORD - ServerID: $ServerID  VMName: $VMName ServerUUID: $ServerUUID vCenterUUID: $vCenterUUID VMID: $VMID   "   -ForegroundColor Gray
    $ConnectionString = $DevOps_DBConnectionString
    $Query = "UPDATE Servers SET VMName = '$VMName',ServerUUID = '$ServerUUID',vCenterUUID = '$vCenterUUID',VMID = '$VMID'  WHERE ServerID = $ServerID"
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open()   
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() | Out-Null
    $connection.Close()

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


### Get Server ID - SQL                                 #<-------  (DATATABLE ROWS/COLUMNS!!!!!!)
### --------------------------------------------------
function Get-ECI.EMI.Automation.ServerID
{
    Param([Parameter(Mandatory = $True)][int]$RequestID)
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Getting Server ID for RequestID : " $RequestID
     
    ### Parameters
    ###---------------------------
    $DataSetName = "ServerID"
    $ConnectionString = $DevOps_DBConnectionString
    $Query = "SELECT ServerID FROM Servers WHERE RequestID = '$RequestID'"
    
    ### Execute Query
    ###---------------------------
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $Connection.Close()

    ### Return Values
    ###----------------------------
    foreach ($Datarow in $DataTable.Rows)
    {
       #Write-Host "Value: " $DataTable.Columns 
       #Write-Host "Value: " $DataRow[0] 
       Set-Variable -Name $DataTable.Columns -Value $DataRow[0] -Scope Global
    }
    
    $global:ServerID = $ServerID
    Write-Host "ServerID                        : " $ServerID -ForegroundColor Cyan

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $global:ServerID
}

### --------------------------------------------------  2!!!!
function Create-ECI.EMI.Automation.CurrentStateRecord
{
    Param([Parameter(Mandatory = $True)][int]$ServerID)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ###-------------------------------
    ### Create Current State Record
    ###-------------------------------
    Write-Host "CREATING CURRENT STATE RECORD : "            -ForegroundColor Cyan
    Write-Host "ServerID                      : " $ServerID  -ForegroundColor Cyan
    Write-Host "HostName                      : " $HostName  -ForegroundColor Cyan

    # Open Database Connection
    $ConnectionString = $DevOps_DBConnectionString
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open()   
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $Query = "INSERT INTO ServerCurrentState(ServerID,HostName) VALUES('$ServerID','$HostName')"
    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() | Out-Null
    $connection.Close()

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


### --------------------------------------------------
function Get-ECI.EMI.Automation.ServerRequest-SQL
{
    Param([Parameter(Mandatory = $True)][int]$RequestID)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "`nGetting Server Request - RequestID: $RequestID " `r`n('-' * 50)`r`n -ForegroundColor Cyan

    $ConnectionString = $Portal_DBConnectionString
    $Query = "SELECT * FROM ServerRequest WHERE RequestID = '$RequestID'"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $ConnectionString
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $result = $command.ExecuteReader()
    $table = new-object "System.Data.DataTable"
    $table.Load($result)
    $table | FL
    $connection.Close()

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### --------------------------------------------------
function Get-ECI.EMI.Automation.ServerRecord-SQL
{
    Param([Parameter(Mandatory = $True)][int]$ServerID)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "`nGetting Server Record - ServerID: $ServerID " `r`n('-' * 50)`r`n -ForegroundColor Cyan

    $ConnectionString = $DevOps_DBConnectionString
    $Query = "SELECT * FROM Servers WHERE ServerID = '$ServerID'"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $ConnectionString
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $result = $command.ExecuteReader()
    $table = new-object "System.Data.DataTable"
    $table.Load($result)
    $table | FL
    $connection.Close()

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### --------------------------------------------------
function Get-ECI.EMI.Automation.ServerCurrentState-SQL
{
    Param([Parameter(Mandatory = $True)][int]$ServerID)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "`r`nGetting Server Current State - ServerID: $ServerID " `r`n('-' * 50)`r`n -ForegroundColor Cyan

    $ConnectionString = $DevOps_DBConnectionString
    $Query = "SELECT * FROM ServerCurrentState WHERE ServerID = '$ServerID'"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $ConnectionString
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $result = $command.ExecuteReader()
    $table = new-object "System.Data.DataTable"
    $table.Load($result)
    $table | FL
    $connection.Close()

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### --------------------------------------------------
function Get-ECI.EMI.Automation.ServerDesiredState-SQL
{
    Param([Parameter(Mandatory = $True)][int]$ServerID)

    Write-Host "`r`nGetting Server Desired State - ServerID: $ServerID " `r`n('-' * 50) -ForegroundColor Cyan

    $ConnectionString = $DevOps_DBConnectionString
    $Query = "SELECT * FROM ServerDesiredState WHERE ServerID = '$ServerID'"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $ConnectionString
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $result = $command.ExecuteReader()
    $table = new-object "System.Data.DataTable"
    $table.Load($result)
    $table  | FT -AutoSize -Property HostName,PropertyName,CurrentState,DesiredState,Verify,Abort
    $connection.Close()

    $ServerDesiredState = $table

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### --------------------------------------------------
function Get-ECI.EMI.Automation.ServerConfigLog-SQL
{
    Write-Host "`r`nGetting Server ConfigLog - ServerID: $ServerID " `r`n('-' * 50)`r`n -ForegroundColor Cyan
    
    $ConnectionString = $DevOps_DBConnectionString
    $Query = "SELECT * FROM ServerConfigLog WHERE ServerID = '$ServerID'"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $ConnectionString
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $result = $command.ExecuteReader()
    $table = new-object "System.Data.DataTable"
    $table.Load($result)
    $table | FT -AutoSize -Property HostName,FunctionName,PropertyName,Verify,Abort
    $connection.Close()

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

### --------------------------------------------------
function Get-DecommissionData
{
    Param([Parameter(Mandatory = $True)][int]$ServerID)
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ### Parameters
    ###---------------------------
    $ConnectionString = $DevOps_DBConnectionString
    $Query = "SELECT * FROM Servers WHERE ServerID = '$ServerID'"
    
    ### Execute Query
    ###---------------------------
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    
    ### Return Values
    ###----------------------------
    
    $DecomData = @()
    foreach ($Datarow in $DataTable.Rows)
    {
       #Write-Host "Name: " $DataTable.Columns 
       #Write-Host "Value: " $DataRow[0] 
       Set-Variable -Name $DataTable.Columns -Value $DataRow[0] -Scope Global
       $DecomData += ($DataTable.Columns,$DataRow[0])
    }
    Write-Host "DecomData: " $DecomData
}

### --------------------------------------------------
function GetDBSize
{
    use "devops"
    exec sp_spaceused
}



function Start-ECI.EMI.Automation.Sleep
{
    Param(
    [Parameter(Mandatory = $False)][int16]$t,
    [Parameter(Mandatory = $False)][string]$Message,
    [Parameter(Mandatory = $False)][switch]$ShowRemaining
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor DarkGray

    If(!$t){$t = $WaitTime_StartSleep}

    if($Message)
    {
        Write-Host `r`n('- ' * 25)`r`n "START-ECI.SLEEP: $t seconds. $Message" `r`n('- ' * 25)`r`n -ForegroundColor Cyan
    } 
    else
    {
        Write-Host `r`n('- ' * 25)`r`n "START-ECI.SLEEP: $t seconds" `r`n('- ' * 25)`r`n -ForegroundColor Cyan
    }
    
    for ($i=$t; $i -gt 1; $i--) 
    {  
        if($ShowRemaining)
        {
            $a = [math]::Round((($i/$t)/1)*100)   ### Amount Remaining
        }
        else
        {
            $a = [math]::Round( (($t-$i)/$t)*100) ### Amount Completed
        }

        if($Message){$Status = "Waiting for... $Message"}else{$Status = "Waiting for... "}

        Write-Progress -Activity "ECI START-SLEEP - for $t seconds: " -SecondsRemaining $i -CurrentOperation "Completed: $a%" -Status $Status
        Start-Sleep 1
    }
    Write-Host "Done Sleeping." -ForegroundColor DarkGray
    Write-Progress -Activity 'Sleeping...' -Completed
}


function Generate-ECI.RandomAlphaNumeric
{
    Param([Parameter(Mandatory = $False)][int]$Length)

    if(!$Length){[int]$Length = 15}

    ##ASCII
    #48 -> 57 :: 0 -> 9
    #65 -> 90 :: A -> Z
    #97 -> 122 :: a -> z

    for ($i = 1; $i -lt $Length; $i++) {

        $a = Get-Random -Minimum 1 -Maximum 4 

        switch ($a) 
        {
            1 {$b = Get-Random -Minimum 48 -Maximum 58}
            2 {$b = Get-Random -Minimum 65 -Maximum 91}
            3 {$b = Get-Random -Minimum 97 -Maximum 123}
        }

        [string]$c += [char]$b
    }

    Return $c
}

#######################################
### Function: Set-TranscriptPath
#######################################
function Start-ECI.EMI.Automation.Transcript
{
    Param(
    [Parameter(Mandatory = $False)][string]$TranscriptPath,
    [Parameter(Mandatory = $False)][string]$TranscriptName
    )

    function Generate-RandomAlphaNumeric
    {
        Param([Parameter(Mandatory = $False)][int]$Length)

        if(!$Length){[int]$Length = 15}

        ##ASCII
        #48 -> 57 :: 0 -> 9
        #65 -> 90 :: A -> Z
        #97 -> 122 :: a -> z

        for ($i = 1; $i -lt $Length; $i++) 
        {
            $a = Get-Random -Minimum 1 -Maximum 4 
            switch ($a) 
            {
                1 {$b = Get-Random -Minimum 48 -Maximum 58}
                2 {$b = Get-Random -Minimum 65 -Maximum 91}
                3 {$b = Get-Random -Minimum 97 -Maximum 123}
            }
            [string]$c += [char]$b
        }

        Return $c
    }

    ### Stop Transcript if its already running
    try {Stop-transcript -ErrorAction SilentlyContinue} catch {} 
    
    $TimeStamp  = Get-Date -format "yyyyMMddhhmss"
    $Rnd = (Generate-RandomAlphaNumeric)
    
    ### Set Default Path
    if(!$TranscriptPath){$TranscriptPath = "C:\Scripts\Transcripts"}

    ### Make sure path ends in "\"
    $LastChar = $TranscriptPath.substring($TranscriptPath.length-1) 
    if ($LastChar -ne "\"){$TranscriptPath = $TranscriptPath + "\"}

    ### Create File Name
    if($TranscriptName)
    {
        $TranscriptFile = $TranscriptPath + "PowerShell_transcript" + "." + $TranscriptName + "." + $Rnd + "." + $TimeStamp + ".txt"
    }
    else
    {
        $TranscriptFile = $TranscriptPath + "PowerShell_transcript" + "." + $Rnd + "." + $TimeStamp + ".txt"
    }
    ### Start Transcript Log
    Start-Transcript -Path $TranscriptFile -NoClobber 
}



#################################################################
### ERROR HANDELING
#################################################################

### Write Error Stack - Try/Catch
### --------------------------------------------------
function Write-ECI.ErrorStack
{
    Param(
    [Parameter(Mandatory = $False)][switch]$Details,
    [Parameter(Mandatory = $False)][switch]$NoExit
    )

    ### https://kevinmarquette.github.io/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/   
    
<#


        ### Guest State
        ###----------------------------
        $VM = (Get-VM -Name $VMName -ErrorAction SilentlyContinue)
        $VMguestState                      = $VM.ExtensionData.guest.guestState                           ### <---- RETRUN: running/notRunning
        $VMguestOperationsReady            = $VM.ExtensionData.guest.guestOperationsReady                 ### <---- RETRUN: True/False
        $VMinteractiveGuestOperationsReady = $VM.ExtensionData.guest.interactiveGuestOperationsReady      ### <---- RETRUN: True/False
        $VMguestStateChangeSupported       = $VM.ExtensionData.guest.guestStateChangeSupported
        Write-Host "VMguestState                      :" $VMguestState                                    -ForegroundColor DarkGray
        Write-Host "VMguestOperationsReady            :" $VMguestOperationsReady                          -ForegroundColor DarkGray
        Write-Host "VMinteractiveGuestOperationsReady :" $VMinteractiveGuestOperationsReady               -ForegroundColor DarkGray
        Write-Host "VMguestStateChangeSupported       :" $VMguestStateChangeSupported                     -ForegroundColor DarkGray
#>    

    $Abort    = $True
    #$ECIError = $True
    $Alert    = $True
    
    if($global:Error.Count -eq 0)
    {
        Write-Host "No Errors in the PS-ErrorStack" -ForegroundColor Green
    }
    elseif($global:error.Count -gt 0)
    {
        ### $Error Variable
        ###------------------------------------------
        Write-Host `r`n`r`n('=' * 100)`r`n "START - ECI ERROR STACK: `r`n" ('=' * 100)`r`n               -ForegroundColor Red
        Write-Host "PS-Error.Count:"                   $global:error.Count                               -ForegroundColor Red
        Write-Host "PS-ERRROR[0]:"                     `r`n('-' * 20)`r`n                                -ForegroundColor Red
        Write-Host "PS-Error.InvocationInfo    [0]    : " ($global:Error[0].InvocationInfo.Line).Trim()  -ForegroundColor Red
        Write-Host "PS-Error.Exception         [0]    : " $global:Error[0].TargetObject                  -ForegroundColor Red
        Write-Host "PS-Error.ExceptionType     [0]    : " $global:Error[0].Exception.GetType().fullname  -ForegroundColor Red
        Write-Host "PS-Error.Exception.Message [0]    : " $global:Error[0].Exception.Message             -ForegroundColor Red
        #Write-Host "Error.ScriptStackTrace[0]     : " $global:Error[0].ScriptStackTrace                 -ForegroundColor DarkGray

        if($Details -eq $True)
        {
            ### ScriptStackTrace
            ###------------------------------------------
            $StackTrace = $global:Error.ScriptStackTrace
            foreach($Trace in $StackTrace)
            {
                Write-Host  ('-' * 50)                    -ForegroundColor Red
                Write-Host  "PS-ScriptStackTrace:"        -ForegroundColor Red

                $Call       = $Trace.Split()[1]
                $LineNumber = $Trace.Split()[4]
                $ScriptPath = (Split-Path(($Trace.Split()[2]).split(":")[0]) -Parent) + "\"
                $ScriptName = Split-Path ($Trace.Split()[2]) -Leaf

                #Write-Host "Trace       : " $Trace       -ForegroundColor yellow
                foreach($Item in $Trace)
                {
                    $Call       = $Item.Split()[1]
                    $LineNumber = $Item.Split()[4]
                    $ScriptPath = (Split-Path(($Item.Split()[2]).split(":")[0]) -Parent) + "\"
                    $ScriptName = Split-Path ($Item.Split()[2]) -Leaf

                    Write-Host  ('-' * 50)                    -ForegroundColor Red
                    Write-Host "PS-Call       : " $Call       -ForegroundColor Red
                    Write-Host "PS-ScriptPath : " $ScriptPath -ForegroundColor Red
                    Write-Host "PS-ScriptName : " $ScriptName -ForegroundColor Red
                    Write-Host "PS-LineNumber : " $LineNumber -ForegroundColor Red
                }
            }

            for($i = 0; $i -le $global:error.count -1; $i++)
            {
                Write-Host  ('-' * 50) -ForegroundColor DarkRed
                Write-Host "PS-Error.InvocationInfo    $i : " ($global:Error[$i].InvocationInfo.Line).Trim() -ForegroundColor DarkRed
                Write-Host "PS-Error.Exception.Message $i : " $global:Error[$i].Exception.Message -ForegroundColor DarkRed
                Write-Host "PS-Error.TargetObject      $i : " $global:Error[$i].TargetObject -ForegroundColor DarkRed
                Write-Host "PS-Error.ExceptionType     $i : " $global:Error[$i].Exception.GetType().fullname  -ForegroundColor DarkRed
                Write-Host "PS-Error.ScriptStackTrace  $i : " $global:Error[$i].ScriptStackTrace -ForegroundColor DarkRed
            }     
        }

        ### CallStack
        ###------------------------------------------
        $CallStack = Get-PSCallStack -Verbose -Debug
        Write-Host `r`n`r`n "PS-Callstack - Count             : " $CallStack.Count   -ForegroundColor DarkGray
        for($i = 0; $i -le $CallStack.count -1; $i++) 
        {
            Write-Host  ('-' * 50) -ForegroundColor DarkGray
            Write-Host "PS-Callstack.ScriptName[$i]       : " (Split-Path -Path $CallStack[$i].ScriptName -Leaf) -ForegroundColor DarkGray
            Write-Host "PS-Callstack.Command[$i]          : " $CallStack[$i].Command   -ForegroundColor DarkGray
       
            if(($CallStack[$i].Command) -ne ($CallStack[$i].FunctionName))
            {
                Write-Host "PS-Callstack.FunctionName[$i]     : " $CallStack[$i].FunctionName -ForegroundColor DarkGray
            }
        }

        Write-Host `r`n`r`n('=' * 100)`r`n "END - ERROR STACK: " `r`n('=' * 100)      -ForegroundColor Red

       
        ### Send Alert Message
        ###------------------------------------------
        if($Alert)
        {
            #Send-ECI.ServerStatus -ServerID $ServerID -Abort $Abort -VerifyErrorCount $VerifyErrorCount
            Send-ECI.Alert -ErrorMsg $Error[0]
        }

        if($NoExit)
        {
            Continue
        }
        elseif(!$NoExit)
        {
             ### Exit
            ###-------------------
            Throw "ABORT ERROR THROWN"     ### <--- Throw Terminating Error
            #[Environment]::Exit(1)        ### <--- Exits PS Session
            #Exit   
        }
    }
}


### Throw Abort Error
### --------------------------------------------------
function Throw-ECI.AbortError
{
    #https://kevinmarquette.github.io/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/
    Param(
        [Parameter(Mandatory = $False)][string]$ServerID,
        [Parameter(Mandatory = $False)][string]$HostName,
        [Parameter(Mandatory = $False)][string]$VMName,
        [Parameter(Mandatory = $False)][string]$FunctionName,
        [Parameter(Mandatory = $False)][string]$Verify,
        [Parameter(Mandatory = $False)][string]$AbortTrigger,
        [Parameter(Mandatory = $False)][string]$Abort
        ) 

    Write-Host `r`n("-=" * 50)`r`n(" " * 37)"THROWING ABORT ERROR!!!"`r`n("-+" * 50)`r`n  -ForegroundColor Red
    Write-Host "The scripts encountered an Abort Level Error." `n`n  -ForegroundColor Red
    

    #Write-Host "THROW-ABORTERROR: " "ServerID: " $ServerID "HostName: " $HostName "VMName: " $VMName "FunctionName:" $FunctionName "Verify:" $Verify "AbortTrigger:" $AbortTrigger "Abort:" $Abort -ForegroundColor Red
    Write-Host "PS-ERRORVAR.Count : " $global:Error.Count -ForegroundColor Yellow
    Write-Host "PS-ERRORVAR[0]    : " $global:Error[0] -ForegroundColor Yellow
    Write-Host `r`n`r`n

    #Write-AbortErrorLog
    #Write-AbortErrortoSQL
    #Write-ECI.ErrorStack

    Send-ECI.ServerStatus

    ### Exit
    ###-------------------
    Throw "ABORT ERROR THROWN"     ### <--- Throw Terminating Error
    #[Environment]::Exit(1)        ### <--- Exits PS Session
    #Exit                          ### <--- Exits Current Context
}

function Send-ECI.ServerStatus
{
    Param(
    [Parameter(Mandatory = $False)][int]$ServerID,
    [Parameter(Mandatory = $True)][bool]$Abort,
    [Parameter(Mandatory = $True)][int]$VerifyErrorCount
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    
    ### Abort Status
    ###----------------------------
    if($Abort -eq $False)
    {
        $Status      = "Success"
        $StatusColor = "Green"
    }
    elseif($Abort -eq $True)
    {
        $Status      = "Failure"
        $StatusColor = "Red"
    }

    ### Abort Status
    ###----------------------------
    if($ECIError -eq $False)
    {
        $ECIStatus      = "Success"
        $ECIStatusColor = "Green"
    }
    elseif($ECIError -eq $True)
    {
        $ECIStatus      = "Failure"
        $ECIStatusColor = "Red"
    }

    ### Verify Error Count
    ###----------------------------
    if($VerifyErrorCount -eq 0)
    {
        $VerifyStatus      = "No Verify Errors"
        $VerifyStatusColor = "Green"
    }
    elseif($VerifyErrorCount -gt 0)
    {
        $VerifyStatus      = "Verify Errors"
        $VerifyStatusColor = "Yellow"
    }
    
    ### Message Header
    ###----------------------------------------------------------------------------
    $Message = $Null
    
    $Header = "
        <style>
        #BODY{font-family: Lucida Console, Consolas, Courier New, monospace;font-size:9;font-color: #000000;text-align:left;}
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 0px; border-style: hidden; border-color: white; border-collapse: collapse;}
        TH {border-width: 0px; padding: 3px; border-style: hidden; border-color: white; background-color: #6495ED;}
        TD {border-width: 0px; padding: 3px; border-style: hidden; border-color: white;}
        
        </style>
    "
    $Message += $Header
    $Message += "<html><body>"
    $Message += "<table>"
    $Message += "<tr>"
    $Message += "<td align='right'>" + "Status : </td>"  
    $Message += "<td align='left'><font size='4';color='$StatusColor'>" + $Status   + "</font></td>"
    $Message += "</tr>"
    $Message += "<tr>"
    $Message += "<td align='right'>" + "HostName : </td>"  
    $Message += "<td align='left'><font size='4';color='$StatusColor'>" + $HostName + "</font></td>"
    $Message += "</tr>"
    $Message += "</table>"
    $Message += "<br>"
    $Message += "FOR ECI INTERNAL USE ONLY."                               + "`r`n" + "<br><br>"


    ### SERVER PROVISIONING STATUS
    ###----------------------------------------------
    $Message += "---------------------------------------------------------------------" + "`r`n" + "<br>"
    $Message += "<b>SERVER PROVISIONING STATUS: "                                       + "`r`n" + "</b><br>"
    $Message += "---------------------------------------------------------------------" + "`r`n" + "<br>"

    $StatusParams = [ordered]@{
        Status           = $Status
        HostName         = $HostName
        VerifyStatus     = $VerifyStatus
        PSErrorVar       = $global:Error.Count
        ECIErrorVar      = $global:ECIError.Count 
        VerifyErrorCount = $VerifyErrorCount
        Abort            = $Abort
    }

    $StatusMsg = "<table>"
    foreach($Param in $StatusParams.GetEnumerator())
    {
        $StatusMsg += "<tr>"
        $StatusMsg += "<td align='right'>" + $Param.Name + "&nbsp; : </td>"
        $StatusMsg += "<td align='left'>&nbsp; "  + $Param.Value + "</td>"
        $StatusMsg += "</tr>"
    }
    $StatusMsg += "</table>" 
    $Message += $StatusMsg

    ### SERVER SPECIFICATIONS
    ###----------------------------------------------
    $Message += "<br><br>"
    $Message += "---------------------------------------------------------------------" + "`r`n" + "<br>"
    $Message += "<b>SERVER SPECIFICATIONS : "                                           + "`r`n" + "</b><br>"
    $Message += "---------------------------------------------------------------------" + "`r`n" + "<br>"

    $DetailParams = [ordered]@{
        RequestDateTimeUTC    = $RequestDateTime
        Hostame               = $HostName
        VMame                 = $VMName
        GPID                  = $GPID
        RequestID             = $RequestID
        ServerID              = $ServerID
        InstanceLocation      = $InstanceLocation
        ServerRole            = $ServerRole
        ServerRoleDescription = $ServerRoleDescription
        BuildVersion          = $BuildVersion
        vCPUCount             = $vCPUCount
        vMemoryGB             = $vMemoryGB
        OSVolumeCapacityGB    = $OSVolumeCapacityGB
        SwapVolumeCapacityGB  = $SwapVolumeCapacityGB
        IPv4Address           = $IPv4Address
        ClientDomain          = $ClientDomain
        VMProvisionTime       = $VMElapsedTime
        OSConfigurationTime   = $OSElapsedTime
        RoleConfigurationTime = "00:00:00" # $RoleElapsedTime
        DeploymentQATime      = $QAElapsedTime
        TotalAutomationTime   = ((Get-Date) - $AutomationStartTime)
    }
    $details = "<table>"
    
    
    foreach($Param in $DetailParams.GetEnumerator())
    {
        $details += "<tr>"
        $details += "<td align='right'>" + $Param.Name + "&nbsp; : </td>"
        $details += "<td align='left'>&nbsp; "  + $Param.Value + "</td>"
        $details += "</tr>"
    }
    $details += "</table>" 
    $Message += $details
    $Message += "<br><br>"


    ### Display Desired State SQL Record
    ###----------------------------------------------------------------------------    
    $Message += "<font size='3';><b>SERVER DESIRED CONFIGURATION STATE:</b>"           + "</font><br>"
    $Header = "
        <style>
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
        </style>
    "
    $Message += $Header
    
    $DataSetName = "DesiredState"
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    $Query = "SELECT ServerID,HostName,PropertyName,DesiredState,CurrentState,Verify,Abort,RecordDateTimeUTC FROM ServerDesiredState WHERE ServerID = '$ServerID'"
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft
        
    $DesiredState += "<table>" 
    $DesiredState +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $DesiredState += "<b><u><td>"+$dt.Columns[$i].ColumnName+"</td></u></b>"  
    }
    $DesiredState +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $DesiredState +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $DesiredState += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $DesiredState +="</tr>"
    }

    $DesiredState += "</table></body></html>"
    $Message += $DesiredState    
    $Message += "<br><br>"

    
    ### Transcript Log 
    ###---------------------
    $TranscriptURL = "cloud-portal01.eci.cloud/vmautomationlogs/" + $HostName + "/" + (Split-Path $TranscriptFile -Leaf)
    $Message += "Transcript Log: " + "<a href=http://" + $TranscriptURL + ">" + $TranscriptURL + "</a>"
    $Message += "<br><br>"
    $Message += "Server Build Date: " + (Get-Date)
    $Message += "<br>"


    ### ECI-Error Array 
    ###---------------------
    if($global:ECIError)
    {
        $Message += "<br><b>ECI-ErrorVar:  " + $global:ECIError.count  + " </b><br>"
        for($i = 0; $i -le $global:ECIError.count -1; $i++)
        {
            $Message += "ECIError: $i<br>"
            $Message += ($global:ECIError[$i])
            $Message += "<br>"
        }
    }

    ### ECI-Error Log
    ###---------------------
    # Get-Content C:\scripts\_vmautomationlog\hostname\ecierrorlogs.log


    ### PS-Error Array 
    ###---------------------
    if($global:Error)
    {
        $Message += "<br><b>PS-ErrorVar:  " + $global:error.count + "</b><br>"
        for($i = 0; $i -le $global:error.count -1; $i++)
        {
            $Message += "ERROR: $i<br>"
            $Message += ($global:Error[$i])
            $Message += "<br>"
        }
    }

    ### Close Message
    ###---------------------
    $Message += "</body></html>"

    ### Email Constants
    ###---------------------
    $From    = "cbrennan@eci.com"
    if($Abort -eq $False)
    {
        $To      = "cbrennan@eci.com,sdesimone@eci.com,wercolano@eci.com,rgee@eci.com"
    }
    elseif($Abort -eq $True)
    {
        $To     = "cbrennan@eci.com"
        $Message += "PS-Error.Count: " + $Error.Count
        $Message += $Error
    }

    $SMTP    = "alertmx.eci.com"
    #$SMTP   = $SMTPServer
    $Subject = "SERVER PROVISIONING STATUS: " + $Status

    ### Email Message
    ###----------------------------------------------------------------------------
    Write-Host `r`n`r`n`r`n("=" * 50)`n"SENDING NOTIFICATION MESSAGE:" $Status`r`n("=" * 50)`r`n`r`n -ForegroundColor $StatusColor
    
    #Write-Host `n "MESSAGE: " $Message `n -ForegroundColor $StatusColor
    Write-Host "TO: " $To
    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP

    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function ECIHeader
{
    $Header  = "<style>"
    $Header += "BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}"
    $Header += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $Header += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}"
    $Header += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #FFEFD5}"
    $Header += "</style>"

    ### HTML Header
    ###---------------------
    $Header = "
        <style>
        BODY{font-family: Lucida Console, Consolas, Courier New, monospace;font-size:9;font-color: #000000;text-align:left;}
        #TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
        #TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
        #TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
        </style>
    "
}

function Set-ECI.PS.BufferSize
{
    #$BufferSize = $host.UI.RawUI.BufferSize
    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(160,5000)
}

function Write-ECI.Function
{
    Param(
    [Parameter(Mandatory = $True)][switch]$Head,
    [Parameter(Mandatory = $True)][switch]$Tail
    )

    if($Head)
    {
        $FunctionName = $((Get-PSCallStack)[0].Command)
        Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    }
    if($Tail)
    {
        $FunctionName = $((Get-PSCallStack)[0].Command)
        Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    }
}


function Report-ECI.EMI.ReadOnlyVMReport
{
    Param(
        [Parameter(Mandatory = $True)][string]$InstanceLocation,
        [Parameter(Mandatory = $True)][string]$GPID,
        [Parameter(Mandatory = $True)][string]$VMName,
        [Parameter(Mandatory = $True)][string]$ConfigurationMode,
        [Parameter(Mandatory = $True)][string]$ECIVMTemplate,
        [Parameter(Mandatory = $True)][string]$OSCustomizationSpecName,
        [Parameter(Mandatory = $True)][string]$ResourcePool,
        [Parameter(Mandatory = $True)][string]$PortGroup,
        [Parameter(Mandatory = $True)][string]$OSDataStore,
        [Parameter(Mandatory = $True)][string]$SwapDataStore,
        [Parameter(Mandatory = $True)][string]$vCPU,
        [Parameter(Mandatory = $True)][string]$vMemory,
        [Parameter(Mandatory = $True)][string]$IPv4Address,
        [Parameter(Mandatory = $True)][string]$SubnetMask,
        [Parameter(Mandatory = $True)][string]$DefaultGateway,
        [Parameter(Mandatory = $True)][string]$PrimaryDNS,
        [Parameter(Mandatory = $True)][string]$SecondaryDNS,
        [Parameter(Mandatory = $False)][string]$ReportMode_Timeout
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ############################
    ### HTML Header
    ############################
    $Header  = "<style>"
    $Header += "BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}"
    $Header += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $Header += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}"
    $Header += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #FFEFD5}"
    $Header += "</style>"
    
    ############################
    ### Format Report Data
    ############################

    $Message = $Null
    
    $Header = "
        <style>
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 0px; border-style: hidden; border-color: white; border-collapse: collapse;}
        TH {border-width: 0px; padding: 3px; border-style: hidden; border-color: white; background-color: #6495ED;}
        TD {border-width: 0px; padding: 3px; border-style: hidden; border-color: white;}
        
        </style>
    "
    $Message += $Header

    $Message += "<font size='3';color='gray'><i>Server Provisioning - Report Mode:</i></font><br>"
    $Message += "<font size='5';color='NAVY'><b>Parameters for New Server</b></font><br>"
    $Message += "<font size='2'>Request Date:" + (Get-Date) + "</font><br>"
    $Message += "<font size='2'>Requested By:" +  "</font><br><br><br>"
    $Message += "<font size='3';color='red'>This Server <b> WAS NOT </b> provisioned. These are the parameters that would have been used to create the new server: </font>"
    $Message += "<br><br><br>"

    ### Server Specs
    $Message += "<font size='2';color='NAVY'><b>SERVER SPECIFICATIONS:</b></font><br>"
    $Message += "<table>"
    $Message += "<tr><td align='right'>VMName : </td><td align='left'>"                  + $VMName                   + "</td></tr>"
    $Message += "<tr><td align='right'>ConfigurationMode : </td><td align='left'>"       + $ConfigurationMode        + "</td></tr>"
    $Message += "<tr><td align='right'>ECIVMTemplate : </td><td align='left'>"           + $ECIVMTemplate            + "</td></tr>"
    $Message += "<tr><td align='right'>OSCustomizationSpecName : </td><td align='left'>" + $OSCustomizationSpecName  + "</td></tr>"
    $Message += "</table>"

    $Message += "<br>"

    ### VCenter Resources
    $Message += "<font size='2';color='NAVY'><b>VCENTER RESOURCES:</b></font><br>"
    $Message += "<table border='1'>"
    
    $Message += "<tr><td align='right'>vCPU : </td><td align='left'>"                    + $vCPU                     + "</td></tr>"
    $Message += "<tr><td align='right'>vMemory : </td><td align='left'>"                 + $vMemory                  + "</td></tr>"
    
    $Message += "<font size='2.5';color='NAVY'>"

    $Message += "<tr><td align='right'>ResourcePool : </td><td align='left'>"            + $ResourcePool             + "</td></tr>"
    $Message += "<tr><td align='right'>PortGroup : </td><td align='left'>"               + $PortGroup                + "</td></tr>"
    $Message += "<tr><td align='right'>OSDataStore : </td><td align='left'>"             + $OSDataStore              + "</td></tr>"
    $Message += "<tr><td align='right'>SwapDataStore : </td><td align='left'>"           + $SwapDataStore            + "</td></tr>"
    $Message += "</font>"
    $Message += "</table>"

    $Message += "<br>"

    ### OS Customization Spec
    $Message += "<font size='2';color='NAVY'><b>OS CUSTOMIZATION SPEC:</b></font><br>"
    $DataSetName = "VMOSCustomizationSpec"
    $Query = "OPEN SYMMETRIC KEY SQLSymmetricKey DECRYPTION BY CERTIFICATE SelfSignedCertificate; SELECT BuildVersion,ServerRole,OSCustomizationSpecName,OSCustomizationSpecDescription,OSType,Type,NamingScheme,FullName,OrgName,ChangeSid,DeleteAccounts,TimeZone,ProductKey,LicenseMode,Workgroup,EncryptedPassword, CONVERT(varchar, DecryptByKey(EncryptedPassword)) AS 'DecryptedPassword' FROM definitionVMOSCustomizationSpec WHERE ServerRole = '$ServerRole' AND BuildVersion = '$BuildVersion'"
    #$Query = "OPEN SYMMETRIC KEY SQLSymmetricKey  DECRYPTION BY CERTIFICATE SelfSignedCertificate; SELECT *, CONVERT(varchar, DecryptByKey(EncryptedPassword)) AS 'DecryptedPassword' FROM definitionVMOSCustomizationSpec WHERE ServerRole = '$ServerRole' AND BuildVersion = '$BuildVersion'"    
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $DevOps_DBConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft
        
    $VMOSCustomizationSpec += "<table>" 
    $VMOSCustomizationSpec +="<tr>"
  
    
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $VMOSCustomizationSpec += "<b><u><td>"+$dt.Columns[$i].ColumnName+"</td></u></b>"  
    }
    $VMOSCustomizationSpec +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $VMOSCustomizationSpec +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $VMOSCustomizationSpec += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $VMOSCustomizationSpec +="</tr>"
    }

    $VMOSCustomizationSpec += "</table></body></html>"
    $Message += $VMOSCustomizationSpec    
    
    $Message += "<br>"
    
    ### OS CUSTOMIZATION NIC MAPPING:
    $Message += "<font size='2';color='NAVY'><b>OS CUSTOMIZATION NIC MAPPING:</b></font><br>"
    $Message += "<table>"
    $Message += "<tr><td align='right'>IPv4Address : </td><td align='left'>"             + $IPv4Address              + "</td></tr>"
    $Message += "<tr><td align='right'>SubnetMask : </td><td align='left'>"              + $SubnetMask               + "</td></tr>"
    $Message += "<tr><td align='right'>DefaultGateway : </td><td align='left'>"          + $DefaultGateway           + "</td></tr>"
    $Message += "<tr><td align='right'>PrimaryDNS : </td><td align='left'>"              + $PrimaryDNS               + "</td></tr>"
    $Message += "<tr><td align='right'>SecondaryDNS : </td><td align='left'>"            + $SecondaryDNS             + "</td></tr>"
    $Message += "</table>"

    $Message += "<br>"

    ### OS Config Parameters
    $Message += "<font size='2';color='NAVY'><b>OS CONFIGURATION PARAMETERS:</b></font><br>"
    $DataSetName = "OSConfiguration"
    $Query = "SELECT * FROM definitionOSParameters WHERE ServerRole = '$ServerRole' AND BuildVersion = '$BuildVersion'"

    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $DevOps_DBConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft
        
    $Message += "<table>" 
    $Message +="<tr>"
  
    
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $Message += "<b><u><td>"+$dt.Columns[$i].ColumnName+"</td></u></b>"  
    }
    $Message +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $Message +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $Message += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $Message +="</tr>"
    }

    $Message += "</table></body></html>"
    $Message += "<br>"


    ### Write Report to SQL
    ###------------------------
    Write-Host ("=" * 50)`n"Writing Report to SQL"`n("=" * 50)`n -ForegroundColor DarkCyan

    $SQLParams = {
        [Parameter(Mandatory = $True)][string]$InstanceLocation,
        [Parameter(Mandatory = $True)][string]$GPID,
        [Parameter(Mandatory = $True)][string]$VMName,
        [Parameter(Mandatory = $True)][string]$ConfigurationMode,
        [Parameter(Mandatory = $True)][string]$ECIVMTemplate,
        [Parameter(Mandatory = $True)][string]$OSCustomizationSpecName,
        [Parameter(Mandatory = $True)][string]$ResourcePool,
        [Parameter(Mandatory = $True)][string]$PortGroup,
        [Parameter(Mandatory = $True)][string]$OSDataStore,
        [Parameter(Mandatory = $True)][string]$SwapDataStore,
        [Parameter(Mandatory = $True)][string]$vCPU,
        [Parameter(Mandatory = $True)][string]$vMemory,
        [Parameter(Mandatory = $True)][string]$IPv4Address,
        [Parameter(Mandatory = $True)][string]$SubnetMask,
        [Parameter(Mandatory = $True)][string]$DefaultGateway,
        [Parameter(Mandatory = $True)][string]$PrimaryDNS,
        [Parameter(Mandatory = $True)][string]$SecondaryDNS
        }

    $Query = "INSERT INTO [Servers-ReadOnly](GPID,VMName,ServerRole,BuildVersion,ECIVMTemplate,OSCustomizationSpecName,vCPU,vMemory,ResourcePool,PortGroup,OSDatastore,SwapDataStore,IPv4Address,SubnetMask,DefaultGateway,PrimaryDNS,SecondaryDNS) VALUES('$GPID','$VMName','$ServerRole','$BuildVersion','$ECIVMTemplate','$OSCustomizationSpecName','$vCPU','$vMemory','$ResourcePool','$PortGroup','$OSDatastore','$SwapDataStore','$IPv4Address','$SubnetMask','$DefaultGateway','$PrimaryDNS','$SecondaryDNS')"

    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $DevOps_DBConnectionString 
    $Connection.Open()   
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() | Out-Null
    $connection.Close()
  


    ### Email HTML Report
    ###------------------------
    $From    = "cbrennan@eci.com"
    $SMTP = $SMTPServer
    $Subject = "Server Provisioning- Report Mode"

    #$To      = "cbrennan@eci.com,sdesimone@eci.com,wercolano@eci.com,rgee@eci.com"
    $To     = "cbrennan@eci.com"

    ### Email Message
    ###----------------------------------------------------------------------------
    Write-Host `r`n`r`n`r`n("=" * 50)`n "Sending New Server Report" `r`n("=" * 50)`r`n`r`n -ForegroundColor Magenta
    Write-Host "TO: " $To
    #Write-Host "MESSAGE:" $Message -ForegroundColor Magenta 
    

    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP
        
    #if(-NOT(Test-Path -Path $ReportFile)) {(New-Item -ItemType file -Path $ReportFile -Force | Out-Null)}
    #$NewVMParameters | Out-File $ReportFile -Force
    #start-process $ReportFile
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    
    if(!$ReportMode_Timeout)
    {
        $ReportMode_Timeout = 1
    }
    Start-ECI.EMI.Automation.Sleep -Message "Exiting after Sending Report." -t $ReportMode_Timeout
    [Environment]::Exit(0)
 }

function PreCheck-ECI.EMI.Automation
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Performing System Pre-Check Verification:" -ForegroundColor Cyan
    
    $PreCheckState = @{}

    ### Get ECI Modules & Version
    foreach($Module in (Get-Module ECI*))
    {
        $PreCheckState += $Module.Name
        $PreCheckState += $Module.Version
    }

    ### Get PowerCLI Modules & Version
    foreach($Module in (Get-Module $VMModulesPath vmware*))
    {
        $PreCheckState += $Module.Name
        $PreCheckState += $Module.Version
    }

    
    


    ### Connect vCenter
    Connect-VIServer -Server $vCenter -User $vCenter_Account -Password $vCenter_Password


    Get-Folder -Server $ECIvCenter -Name $vCenterFolder
 
 
 #$PreCheckState = [ordered]@{
 #}
 
 $PreCheckState = New-Object -TypeName PSObject -Property $PreCheckState
    
<#
    Portal-Int
    vCenterFolder
    Portal_DBConnectionString
    DevOps_DBConnectionString

    ISODatastore
    Windows ISO
    VMTools ISO
    SMTPServer
#>

Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray

}

function Get-VMLogs
{

    ### Get vCenter VM Logs On Failurer/Abort 
    ###---------------------------------------



    # export virtual machine logs from a Datastore to local computer.

    $vm = get-vm "VM NAME HERE"
    $target = New-Item -ItemType Directory -Force -Path c:\VM_Logs\$vm
    $datastore = get-vm $vm | Get-Datastore
    New-PSDrive -Location $datastore -Name ds -PSProvider VimDatastore -Root "\"
    Set-Location ds:\
    cd $vm
    Copy-DatastoreItem -Item *.log -Destination $target
    set-Location C:
    Remove-PSDrive -Name ds -Confirm:$false



}

function Get-MachineSID
{
  param(
  [string]$HostName,
  [switch]$DomainSID
  )

  ### SOURCE: https://gist.github.com/IISResetMe/36ef331484a770e23a81
  $VMTemplateSID = "S-1-5-21-1341700647-1908522465-1290903906-501"
  Write-Host "VMTemplateSID: " $VMTemplateSID -ForegroundColor DarkCyan

  # Retrieve the Win32_ComputerSystem class and determine if machine is a Domain Controller  
  $WmiComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
  $IsDomainController = $WmiComputerSystem.DomainRole -ge 4

  if($IsDomainController -or $DomainSID)
  {
    # We grab the Domain SID from the DomainDNS object (root object in the default NC)
    $Domain    = $WmiComputerSystem.Domain
    $SIDBytes = ([ADSI]"LDAP://$Domain").objectSid |%{$_}
    $SID = New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ([Byte[]]$SIDBytes),0
    Return $SID.Value
  }
  else
  {
    # Going for the local SID by finding a local account and removing its Relative ID (RID)
    $LocalAccountSID = Get-WmiObject -ComputerName $HostName -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" | Select-Object -First 1 -ExpandProperty SID
    $MachineSID      = ($p = $LocalAccountSID -split "-")[0..($p.Length-2)]-join"-"
    $SID = New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $MachineSID
    Return $SID.Value
  }
}

function Send-ECI.Alert
{
    Param(
        [Parameter(Mandatory = $False)][string]$Alert,
        [Parameter(Mandatory = $False)][string]$ErrorMsg,
        [Parameter(Mandatory = $False)][switch]$Exit
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ############################
    ### HTML Header
    ############################
    $Header  = "<style>"
    $Header += "BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}"
    $Header += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $Header += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}"
    $Header += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #FFEFD5}"
    $Header += "</style>"
    
    ############################
    ### Format Report Data
    ############################

    $Message = $Null
    
    $Header = "
        <style>
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 0px; border-style: hidden; border-color: white; border-collapse: collapse;}
        TH {border-width: 0px; padding: 3px; border-style: hidden; border-color: white; background-color: #6495ED;}
        TD {border-width: 0px; padding: 3px; border-style: hidden; border-color: white;}
        
        </style>
    "
    $Message += $Header
    $Message += "<font size='3';color='gray'><i>ECI EMI Server Automation</i></font><br>"
    $Message += "<font size='5';color='NAVY'><b>ECI Automation Error Alert</b></font><br>"
    $Message += "<font size='2'>Alert Date:  " + (Get-Date) + "</font>"
    $Message += "<br><br><br><br>"
    $Message += "<font size='3';color='black'>WARNING: This Server <b> COULD NOT </b> be provisioned.</font>"
    $Message += "<br><br>"


    if($Alert)
    {
        $Message += "<font size='3';color='red'><br><b>ALERT: </b></font><br>"
        $Message += "<font size='3';color='red'><b>" + $Alert +  "</b></font>"
    }
    if($ErrorMsg)
    {
        $Message += "<font size='3';color='red'><br><b>ERROR MESSAGE: </b></font><br>"
        $Message += "<font size='3';color='red'>" + $ErrorMsg +  " </font>"
    }
    if($ECIError)
    {
        $Message += "<font size='3';color='red'><br><b>ECI ERROR: </b></font><br>"
        $Message += "<font size='3';color='red'>" + $ECIError +  " </font>"
    }


    $Message += "<br><br><br>"

    ### Server Specs
    $Message += "<font size='3';color='NAVY'><b>SERVER SPECIFICATIONS:</b></font><br>"
    $Message += "<table>"
    $Message += "<font size='2';color='NAVY'>"
    $Message += "<tr><td align='right'>RequestID : </td><td align='left'>"               + $RequestID                + "</td></tr>"
    $Message += "<tr><td align='right'>HostName : </td><td align='left'>"                + $HostName                 + "</td></tr>"
    $Message += "<tr><td align='right'>VMName : </td><td align='left'>"                  + $VMName                   + "</td></tr>"
    $Message += "<tr><td align='right'>InstanceLocation : </td><td align='left'>"        + $InstanceLocation         + "</td></tr>"
    $Message += "<tr><td align='right'>GPID : </td><td align='left'>"                    + $GPID                     + "</td></tr>"
    $Message += "<tr><td align='right'>ServerRole : </td><td align='left'>"              + $ServerRole               + "</td></tr>"
    $Message += "</table>"
    $Message += "<br>"

<#
    ### Server Specs
    $Message += "<font size='3';color='NAVY'><b>SERVER SPECIFICATIONS:</b></font><br>"
    $Message += "<table>"
    $Message += "<font size='2';color='NAVY'>"
    $Message += "<tr><td align='right'>RequestID : </td><td align='left'>"               + $RequestID                + "</td></tr>"
    $Message += "<tr><td align='right'>VMName : </td><td align='left'>"                  + $VMName                   + "</td></tr>"
    $Message += "<tr><td align='right'>InstanceLocation : </td><td align='left'>"        + $InstanceLocation         + "</td></tr>"
    $Message += "<tr><td align='right'>GPID : </td><td align='left'>"                    + $GPID                     + "</td></tr>"
    $Message += "<tr><td align='right'>ServerRole : </td><td align='left'>"              + $ServerRole               + "</td></tr>"
    $Message += "<tr><td align='right'>Pod : </td><td align='left'>"                     + $Pod                      + "</td></tr>"
    $Message += "</table>"
    $Message += "<br>"

    ### VCenter Resources
    $Message += "<font size='3';color='NAVY'><b>VCENTER RESOURCES:</b></font><br>"
    $Message += "<table border='1'>"
    $Message += "<font size='2';color='NAVY'>"
    $Message += "<tr><td align='right'>ResourcePool : </td><td align='left'>"            + $ResourcePool             + "</td></tr>"
    $Message += "<tr><td align='right'>PortGroup : </td><td align='left'>"               + $PortGroup                + "</td></tr>"
    $Message += "<tr><td align='right'>osDatastoreCluster : </td><td align='left'>"      + $osDatastoreCluster       + "</td></tr>"
    $Message += "<tr><td align='right'>swapDatastoreCluster : </td><td align='left'>"    + $swapDatastoreCluster     + "</td></tr>"
    $Message += "<tr><td align='right'>dataDatastoreCluster : </td><td align='left'>"    + $dataDatastoreCluster     + "</td></tr>"
    $Message += "<tr><td align='right'>logDatastoreCluster : </td><td align='left'>"     + $logDatastoreCluster      + "</td></tr>"
    $Message += "<tr><td align='right'>swapDatastoreCluster : </td><td align='left'>"    + $swapDatastoreCluster     + "</td></tr>"
    $Message += "<tr><td align='right'>sysDatastoreCluster : </td><td align='left'>"     + $sysDatastoreCluster      + "</td></tr>"
    $Message += "</font>"
    $Message += "</table>"
    $Message += "<br>"
#>

    ### Display Server Request Record
    ###----------------------------------------------------------------------------    
    $Message += "<font size='3';color='NAVY'><b>SERVER REQUEST INFORMATION:</b>"           + "</font><br>"
    $Header = "
        <style>
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
        </style>
    "
    $Message += $Header

    $DataSetName = "ServerRequest"
    $ConnectionString = $Portal_DBConnectionString
    $Query = "SELECT * FROM ServerRequest WHERE RequestID = '$RequestID'"
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft
        
    $ServerRequest += "<table>" 
    $ServerRequest +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $ServerRequest += "<b><u><td>"+$dt.Columns[$i].ColumnName+"</td></u></b>"  
    }
    $ServerRequest +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $ServerRequest +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $ServerRequest += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $ServerRequest +="</tr>"
    }

    $ServerRequest += "</table></body></html>"
    $Message += $ServerRequest    
    $Message += "<br><br>"

    ### Transcript Log 
    ###---------------------
    $TranscriptURL = "cloud-portal01.eci.cloud/vmautomationlogs/" + $HostName + "/" + (Split-Path $TranscriptFile -Leaf)
    $Message += "Transcript Log: " + "<a href=http://" + $TranscriptURL + ">" + $TranscriptURL + "</a>"
    $Message += "<br><br>"
    $Message += "Server Build Date: " + (Get-Date)
    $Message += "<br>"


    ### ECI-Error Array 
    ###---------------------
    if($global:ECIError)
    {
        $Message += "<br><b>ECI-ErrorVar:  " + $global:ECIError.count  + " </b><br>"
        for($i = 0; $i -le $global:ECIError.count -1; $i++)
        {
            $Message += "ECIError: $i<br>"
            $Message += ($global:ECIError[$i])
            $Message += "<br>"
        }
    }

    ### ECI-Error Log
    ###---------------------
    # Get-Content C:\scripts\_vmautomationlog\hostname\ecierrorlogs.log


    ### PS-Error Array 
    ###---------------------
    if($global:Error)
    {
        $Message += "<br><b>PS-ErrorVar:  " + $global:error.count + "</b><br>"
        for($i = 0; $i -le $global:error.count -1; $i++)
        {
            $Message += "ERROR: $i<br>"
            $Message += ($global:Error[$i])
            $Message += "<br>"
        }
    }
    ### Close Message
    ###---------------------
    $Message += "</body></html>"

<#

    ### Write Report to SQL
    ###------------------------
    Write-Host ("=" * 50)`n"Writing Report to SQL"`n("=" * 50)`n -ForegroundColor DarkCyan

    $Query = "INSERT INTO Errors(GPID,VMName,ServerRole,ResourcePool,PortGroup,osDatastoreCluster,swapDatastoreCluster) VALUES('$GPID','$VMName','$ServerRole','$ResourcePool','$PortGroup','$osDatastoreCluster','$swapDatastoreCluster')"
    
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $DevOps_DBConnectionString 
    $Connection.Open()   
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() | Out-Null
    $connection.Close()
#>  


    ### Email HTML Report
    ###------------------------
    #$From   = "cbrennan@eci.com"
    $From    = $SMTPFrom
    $SMTP    = $SMTPServer
    $Subject = "Server Provisioning Alert"
    $To      = $SMTPTo
    #$To     = "cbrennan@eci.com,sdesimone@eci.com,wercolano@eci.com,rgee@eci.com"
    #$To     = "cbrennan@eci.com,sdesimone@eci.com"
    $To      = "cbrennan@eci.com"

    ### Email Message
    ###----------------------------------------------------------------------------
    Write-Host `r`n`r`n`r`n("=" * 50)`n "Sending Alert - $ErrorMsg" `r`n("=" * 50)`r`n`r`n -ForegroundColor Yellow
    Write-Host "TO: " $To

    

    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP
        
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    
    if($Exit)
    {
        [Environment]::Exit(1) 
    }
    else
    {
       Throw $ErrorMsg  ### DO NOT USE THROW if you want to exit PSSession
    }

 }