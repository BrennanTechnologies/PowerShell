function Wait-ECI.EMI.GuestReady
{
    Param ([Parameter(Mandatory = $True)][string]$VMName)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Waiting for Guest State:" $VMName -ForegroundColor Yellow


    ###----------------------
    ### Guest State Retry Loop
    ###----------------------
    $Retries            = $Invoke_RetryCount
    $RetryCounter       = 0
    $RetryTimeOut       = $Invoke_RetryTimeOut
    $RetryTimeIncrement = $RetryTimeOut
    $Success            = $False

    while($Success -ne $True)
    {
        try
        {
            ### Initiate Invoke Command
            ###-------------------------------------------------------------
            $guestOperationsReady = (Get-VM -Name $VMName).ExtensionData.guest.guestOperationsReady
            if($guestOperationsReady -eq $True)
            {
                $Success = $True
                Write-Host "$FunctionName - Succeded: " $Success -ForegroundColor Green  
            }
            else
            {
                Write-Error -Message "GuestOperationsReady: False" -ErrorAction Continue -ErrorVariable +ECIError
            }
        }
        catch
        {
            if($RetryCounter -ge $Retries)
            {
                Throw "ECI.THROW.TERMINATING.ERROR: GuestOperationsReady Failed! "
            }
            else
            {
                ### Retry x Times
                ###--------------------
                $RetryCounter++
                
                ### Write ECI Error Log
                ###---------------------------------
                Write-Error -Message ("ECI.ERROR.Exception.Message: " + $global:Error[0].Exception.Message) -ErrorAction Continue -ErrorVariable +ECIError
                if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
                $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force

                ### Error Handling Action
                ###----------------------------------                  
                Start-ECI.EMI.Automation.Sleep -Message "Retry Invoke-VMScript." -t $RetryTimeOut

                ### Restart VM Tools
                ###--------------------                
                if($RetryCounter -eq ($Retries - 1))
                {
                    Write-Host "Bailout Reached: Retry Counter..." $RetryCounter -ForegroundColor Magenta
                    Restart-ECI.EMI.VM.VMTools -VMName $VMName
                }
                $RetryTimeOut = $RetryTimeOut + $RetryTimeIncrement
            }
        }
    }
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray 
}

function Restart-ECI.EMI.VM.VMTools
{
    Param ([Parameter(Mandatory = $True)][string]$VMName)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Re-Starting VM Tools:" $VMName -ForegroundColor Yellow

    ### Re-Start VM Tools
    ###------------------------------
    $t = 20
   
    #$RestartVMTools  = "C:\temp\Restart-VMTools.ps1"    
    #$RestartVMTools  = { (get-Service -ComputerName . -Name "VMWare Tools" | Restart-Service) }
    #$RestartVMTools  = { (Get-Service -Name "VMWare Tools" | Stop-Service)} #<----- for testing - dont stop but start tools
    
    $RestartVMTools  = { (Get-Service -Name "VMWare Tools" | Stop-Service);(Start-Sleep -Seconds ($t));(Get-Service -Name "VMWare Tools" | Start-Service) }

    try
    {
        #############################################################################################################
        ### IMPORTANT:  Use These Args: "-ErrorAction SilentlyContinue -ErrorVariable +ECIError | Out-Null" 
        ### ---------   Because restarting VMTools will throw the following Invoke error:
        ###             "Invoke-VMScript - Index was outside the bounds of the array."
        #############################################################################################################

        Invoke-VMScript -ScriptText $RestartVMTools -VM $VMName -ScriptType Powershell -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword -ErrorAction SilentlyContinue -ErrorVariable +ECIError
        Start-Sleep -Seconds ($t * 2)
    }
    catch
    {
        ### Write ECI Error Log
        Write-Error -Message ("ECI.ERROR: " + $global:error[0].Exception.Message) -ErrorAction Continue -ErrorVariable +ECIError
        if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
        $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force
    }
   
    ### Test VM Tools Status
    ###------------------------------
    $VMToolsStatus = (Get-VM -Name $VMName).ExtensionData.Guest.ToolsRunningStatus
    
    if($VMToolsStatus -eq "guestToolsRunning")
    {
        Write-Host "VMware Tools has Restarted." -ForegroundColor Green
    }
    if($VMToolsStatus -ne "guestToolsRunning")
    {
        ### Abort Error
        ###----------------------------------
        Write-Error -Message ("ECI.ERROR: " + $global:error[0].Exception.Message) -ErrorAction Continue -ErrorVariable +ECIError
        if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
        $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force

        ### Error Handling Action
        ###----------------------------------               
        #Throw-ECI.AbortError #<---- /w Email Alert
        Throw "THROW TERMINATING ERROR: VM Tools Not Running!"
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


function Interrogate-ECI.EMI.Automation.VM.GuestState
{
    Param (
    [Parameter(Mandatory = $True)][string]$VMName,
    [Parameter(Mandatory = $True)][string]$HostName
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ###--------------------------------------------------------------
    ### Interrogate Guest States
    ###--------------------------------------------------------------
    $ECIGuestStateError = $Null
    $VM     = (Get-VM -Name $VMName)
    $VMHost = (Get-VMHost -VM $VMName)

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

    ### Write Each Guest State
    ###---------------------------------
    foreach($State in $GuestState.GetEnumerator())
    {
        Write-Host "VMState: " $State.Key ":  " $State.Value -ForegroundColor DarkCyan
    }
   
    ###--------------------------------------------------------------
    ### Verify Each Guest State
    ###--------------------------------------------------------------

    ### Guest State (Running/NotRunning)
    ###---------------------------------

    if($GuestState.State -ne "Running")
    {
        Write-Error -Message ("ECI.ERROR: " + $GuestState.State) -ErrorAction Continue -ErrorVariable +ECIError
        if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
        $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force
        Throw "ECI.Throw.Terminating.Error: Guest Not Running! "
    }
    elseif($GuestState.State -ne "Running")
    {
        Write-Host "GuestState: " $GuestState.State -ForegroundColor Green
    }

    ### VM Tools
    ###---------------------------------
    if($GuestState.ToolsRunningStatus -ne "guestToolsRunning")
    {
        Write-Error -Message ("ECI.ERROR: " + $GuestState.ToolsRunningStatus) -ErrorAction Continue -ErrorVariable +ECIError 
        if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
        $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force
        Throw "ECI.Throw.Terminating.Error: VMTools Not Running!"
    }
    elseif($GuestState.ToolsRunningStatus -eq "guestToolsRunning")
    {
        Write-Host "ToolsRunningStatus: " $GuestState.ToolsRunningStatus  -ForegroundColor Green
    }

    ### Guest Operations Ready
    ###---------------------------------
    if($GuestState.guestOperationsReady -ne "True")
    {
        Write-Error -Message ("ECI.ERROR: " + $GuestState.guestOperationsReady) -ErrorAction Continue -ErrorVariable +ECIError
        if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
        $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force
        Throw "ECI.Throw.Terminating.Error: Guest Operations Not Ready! "
    }
    elseif($GuestState.guestOperationsReady -eq "True")
    {
        Write-Host "guestOperationsReady: " $GuestState.guestOperationsReady  -ForegroundColor Green
    }

    ### Interactive Guest Operations Ready
    ###---------------------------------
    if($GuestState.interactiveGuestOperationsReady -ne "True")
    {
        Write-Error -Message ("ECI.ERROR: " + $GuestState.interactiveGuestOperationsReady) -ErrorAction Continue -ErrorVariable +ECIError
        if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
        $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force
        Throw "ECI.Throw.Terminating.Error: Guest Operations Not Ready! "
    }
    elseif($GuestState.interactiveGuestOperationsReady -eq "True")
    {
        Write-Host "interactiveGuestOperationsReady: " $GuestState.interactiveGuestOperationsReady  -ForegroundColor Green
    }

    ###--------------------------------------------------------------
    ### Write Guest State Log File
    ###--------------------------------------------------------------
    if($ECIGuestStateError)
    {
        Write-Host "ECIGuestStateError: " $ECIGuestStateError -ForegroundColor Red
        $GuestState.Add("ECIGuestStateError",$ECIGuestStateError)
    }
    $GuestStateFile = $AutomationLogPath + "\" + $HostName + "\" + $HostName + "_GuestState.txt"
    $GuestState  | Out-File -FilePath $GuestStateFile

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


function Copy-ECI.EMI.VM.GuestFile
{
    ###https://mcpmag.com/articles/2015/05/20/functions-that-support-the-pipeline.aspx
    #[parameter(ValueFromPipelineByPropertyName,ValueFromPipeline)]

    [CmdletBinding()]
    Param(
    [Parameter(Mandatory = $True)][string]$VMName,
    [Parameter(Mandatory = $True)][string]$Source,
    [Parameter(Mandatory = $True)][string]$Destination,
    [Parameter(Mandatory = $False)][switch]$LocalToGuest,
    [Parameter(Mandatory = $False)][switch]$GuestToLocal
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    Write-Host "Initiate Guest File Transfer: " $VMName  -ForegroundColor Cyan
    Write-Host "Source      :" $Source                   -ForegroundColor DarkCyan
    Write-Host "Destination :" $Destination              -ForegroundColor DarkCyan

    ### Cleanup Params
    ###----------------------
    if(($Destination.Substring($Destination.Get_Length()-1)) -ne "\") {$Destination = $Destination + "\" }
    
    ###----------------------
    ### Setup Retry Loop
    ###----------------------
    $Retries            = $Invoke_RetryCount
    $RetryCounter       = 0
    $Success            = $False
    $RetryTimeOut       = $Invoke_RetryTimeOut
    $RetryTimeIncrement = $Invoke_RetryCount
    
    while($Success -ne $True)
    {
        try
        {
            ### Initiate File Transefer to Guest
            ###----------------------------------
            if($LocalToGuest)
            {
                Write-Host "Direction   : GuestToLocal" -ForegroundColor DarkGray
                Write-Host "Local       :" (HostName)   -ForegroundColor DarkGray
                Write-Host "Guest       :" $VMName      -ForegroundColor DarkGray
                Copy-VMGuestFile -ToolsWaitSecs $WaitTime_VMTools -VM $VMName -LocalToGuest:$True -Source $Source -Destination $Destination -Force -Confirm:$false -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword -ErrorVariable +ECIError
            }
            if($GuestToLocal)
            {
                Write-Host "Direction   : GuestToLocal" -ForegroundColor DarkGray
                Write-Host "Local       :" (HostName)   -ForegroundColor DarkGray
                Write-Host "Guest       :" $VMName      -ForegroundColor DarkGray
                Copy-VMGuestFile -ToolsWaitSecs $WaitTime_VMTools -VM $VMName -GuestToLocal:$True -Source $Source -Destination $Destination -Force -Confirm:$false -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword -ErrorVariable +ECIError
            }
            $Success = $True
            Write-Host "$FunctionName - Succeded: " $Success -ForegroundColor Green  
        }
        catch
        {
            if($RetryCounter -eq $Retries)
            {
                Throw "ECI.Throw.Terminating.Error: Copy-VMGuestFile Failed! "
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
                Start-ECI.EMI.Automation.Sleep -Message "Retry CopyFiletoGuest." -t $RetryTimeOut
                
                ### Set Bailout Value: Restart VM Tools
                ###----------------------------------
                if($RetryCounter -eq ($Retries - 1))
                {
                    Write-Host "Bailout Reached: Retry Counter..." $RetryCounter -ForegroundColor Magenta
                    Restart-ECI.EMI.VM.VMTools -VMName $VMName
                }
                $RetryTimeOut = $RetryTimeOut + $RetryTimeIncrement
            }
        }
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


function Write-ECI.EMI.OS.ParameterstoGuest
{
    Param(
    [Parameter(Mandatory = $True)][string]$VMName,
    [Parameter(Mandatory = $True)][string]$HostName,
    [Parameter(Mandatory = $True)][string]$ServerID
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $Params = @{}
    
    ### ---------------------------------------
    ### Get ServerRequest Params
    ### ---------------------------------------
    $DataSetName      = "ServerRequest"
    $ConnectionString =  "server=10.3.3.75;database=ECIPortal;User ID=portal_servermgmt;Password=lTo3ese4ve!r;"
    $Query            = "SELECT * FROM ServerRequest WHERE RequestID = '$RequestID'"
    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query -quiet 
    #Write-Host "DataSet: " `r`n $ServerRequest -ForegroundColor DarkGray
    
    foreach ($Property in ($ServerRequest.PSObject.Properties))
    {
        Write-Host `t "Property: " $Property.Name ": " $Property.Value -ForegroundColor DarkGray
        $Params.add($Property.Name,$Property.Value)
    }

    ### ---------------------------------------
    ### Get OS Params
    ### ---------------------------------------
    $DataSetName      = "OSParameters"
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    $Query            = "SELECT * FROM definitionOSParameters WHERE ServerRole = '$ServerRole' AND BuildVersion = '$BuildVersion'"
    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query -quiet
    #Write-Host "DataSet: " `r`n $OSParameters -ForegroundColor DarkGray
    
    foreach ($Property in ($OSParameters.PSObject.Properties))
    {
        Write-Host `t "Property: " $Property.Name ": " $Property.Value -ForegroundColor DarkGray
        $Params.add($Property.Name,$Property.Value)
    }

<#   ----- Not Needed??????????????? 
    ### ---------------------------------------
    ### Get Server Params
    ### ---------------------------------------
    $DataSetName      = "ServerParams"
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    $Query            = "SELECT * FROM Servers WHERE ServerIS = '$ServerIS'"
    Get-ECI.EMI.Automation.SQLData -DataSetName $DataSetName -ConnectionString $ConnectionString -Query $Query -quiet
    #Write-Host "DataSet: " `r`n $OSParameters -ForegroundColor DarkGray
    
    foreach ($Property in ($---------------------------------------.PSObject.Properties))
    {
        Write-Host `t "Property: " $Property.Name ": " $Property.Value -ForegroundColor DarkGray
        $Params.add($Property.Name,$Property.Value)
    }
#>

    ### InGuest Log File
    ###-----------------
    #$InGuestParamFile = $InGuestLogPath + "InGuestParams_" + $HostName + ".txt"
    $InGuestParamFile = "C:\Scripts\_InGuestAutomationLogs\InGuestParams.txt"
    Write-Host "InGuestParamFile: " $InGuestParamFile
    if((Test-Path -Path $InGuestParamFile)) {(Remove-Item -Path $InGuestParamFile -Force | Out-Null)}
    elseif(-NOT(Test-Path -Path $InGuestParamFile)) {(New-Item -ItemType file -Path $InGuestParamFile -Force | Out-Null)}

    foreach($Param in $Params.GetEnumerator())
    {
        $ParamString = ($Param.Key + "," + $Param.Value)
        $ParamString | Out-File -FilePath $InGuestParamFile -Force -Append
    }

    ### ---------------------------------------
    ### Custom Params
    ### ---------------------------------------
    $CustomParams = @{
        ServerID               = $ServerID
        AutomationLogPath      = $AutomationLogPath
        AdministrativeUserName = $AdministrativeUserName
        AdministrativePassword = $AdministrativePassword
        ConfigurationMode      = $ConfigurationMode 
    }

    foreach($Param in $CustomParams.GetEnumerator())
    {
        $ParamString = ($Param.Key + "," + $Param.Value)
        $ParamString | Out-File -FilePath $InGuestParamFile -Force -Append
    }
    
    ### ---------------------------------------
    ### Copy Param File to Guest 
    ### ---------------------------------------
    Write-Host "Source/GuestParamOutFile:" $GuestParamOutFile
    Copy-ECI.EMI.VM.GuestFile -VM $VMName -Source $InGuestParamFile -Destination $InGuestLogPath -LocalToGuest

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


function Process-ECI.EMI.Automation.ScriptText
{
    Param(
    [Parameter(Mandatory = $True)][string]$Step,
    [Parameter(Mandatory = $True)][string]$Env,
    [Parameter(Mandatory = $True)][string]$Environment,
    [Parameter(Mandatory = $False)][string]$ScriptText
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Processing Script Text Block: " -ForegroundColor Cyan

    if(!$ScriptText)
    {
        [string]$ScriptText = 
        {   
            $global:Env = "#Env#"
            $global:Environment = "#Environment#"    
            $global:Step = "#Step#"
            Write-Host "Invoking: ECI.EMI.Configure.OS.InGuest.$ENV.ps1"

            . "C:\Program Files\WindowsPowerShell\Modules\ECI.Modules.$ENV\ECI.EMI.Configure.OS.$ENV\ECI.EMI.Configure.OS.InGuest.$ENV.ps1" -Step $Step -Env $Env -Environment $Environment

            ### Testing
            #. "C:\Program Files\WindowsPowerShell\Modules\ECI.Modules.PROD\ECI.EMI.Configure.OS.PROD\InGuest-InvokeTest.ps1" -Step $Step -Env $Env -Environment $Environment
        } # END ScriptText
    }

    ### Clean the Scripttext Block
    ###--------------------------------------------------
    $CleanScriptText = $Null
    foreach( $Line in (((($Scripttext -replace("  ","") -replace("= ","=")) -replace(" =","=") ) -split("`r`n"))) | ? {$_.Trim() -ne ""} )
    {
        $Line = ($Line) + "`r`n"
        $CleanScriptText = $CleanScriptText + $Line
    }
    [string]$ScriptText = $CleanScriptText

    ### Count Character Limit
    ###--------------------------------------------------
    [int]$CharLimit = 2869
    [int]$CharCount = ($ScriptText | Measure-Object -Character).Characters
    if($CharCount -gt $CharLimit)
    {
        Write-Warning "The ScriptText block exceeds $CharLimit Chararter Limit."
    }
    Write-Host "ScriptText Character Count:" $CharCount "/" $CharLimit "Limit." -ForegroundColor DarkCyan

    ### Replace Parameters with #LiteralValues#
    ###--------------------------------------------------
    $ReplaceParams = @{
    "#Env#"          = $Env
    "#Environment#"  = $Environment
    "#Step#"         = $Step  
    }

    ### Inject Parameters into ScriptText Block
    ### ---------------------------------------
    foreach ($Param in $ReplaceParams.GetEnumerator())
    {
        $ScriptText =  $ScriptText -replace $Param.Key,$Param.Value
    }

    ### Inject ECI BootStrap Module Loader into VM Host                                          # <----- not using bootstrap ????
    ### ---------------------------------------
    #$ScriptText =  $ScriptText -replace '#BootStrapModuleLoader#',$BootStrapModuleLoader

    ### Debugging: Write ScriptText Block to Screen
    ### ---------------------------------------
    Write-Host "ScriptText:`r`n" $ScriptText -ForegroundColor DarkGray

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray

    Return [string]$ScriptText
    
}


function Invoke-ECI.EMI.Automation.ScriptTextInGuest
{
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory = $False)] [string]$ScriptText,
    [Parameter(Mandatory = $False)] [string]$Step
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    
    Write-Host `r`n "STEP: " $Step -ForegroundColor Cyan

    ###----------------------
    ### Setup Retry Loop
    ###----------------------
    $Retries            = $Invoke_RetryCount
    $RetryCounter       = 0
    $Success            = $False
    $RetryTimeOut       = $Invoke_RetryTimeOut
    $RetryTimeIncrement = $RetryTimeOut
    
    while($Success -ne $True)
    {
        try
        {
            ### Initiate Invoke Command
            ###-------------------------------------------------------------
            Write-Host "Invoking VM SCript Text" -ForegroundColor Magenta
            Invoke-VMScript -ToolsWaitSecs $WaitTime_VMTools -ScriptText $ScriptText -VM $VMName -ScriptType Powershell -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword -ErrorAction Stop -ErrorVariable +ECIError
            $Success = $True
            Write-Host "$FunctionName - Succeded: " $Success -ForegroundColor Green  
        }
        catch
        {
            if($RetryCounter -ge $Retries)
            {
                Throw "ECI.THROW.TERMINATING.ERROR: Invoke-VMScript Failed! "
            }
            else
            {
                ### Retry x Times
                ###--------------------
                $RetryCounter++
                
                ### Write ECI Error Log
                ###---------------------------------
                Write-Error -Message ("ECI.ERROR.Exception.Message: " + $global:Error[0].Exception.Message) -ErrorAction Continue -ErrorVariable +ECIError


#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# <-------- Get ECI ERROR LOG file from Global variable!!!!!!!!!    
Write-Host "Get ECI ERROR LOG file from Global variable!!!!!!!!!    " -ForegroundColor Magenta
Write-Host "ECIErrorLogFile:" $ECIErrorLogFile -ForegroundColor Magenta
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

                
                if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
                $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force

                ### Error Handling Action
                ###----------------------------------                  
                Start-ECI.EMI.Automation.Sleep -Message "Retry Invoke-VMScript." -t $RetryTimeOut

                ### Restart VM Tools
                ###--------------------                
                if($RetryCounter -eq ($Retries - 1))
                {
                    Write-Host "Bailout Reached: Retry Counter..." $RetryCounter -ForegroundColor Magenta
                    Restart-ECI.EMI.VM.VMTools -VMName $VMName
                }
                $RetryTimeOut = $RetryTimeOut + $RetryTimeIncrement
            }
        }
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


