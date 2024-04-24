########################################################
### ECI EMI Server Management Module
### ECI.EMI.VM.Mgmt.psm1
########################################################


function Write-ServerMgmtRequesttoSQL
{
    Param(
        [Parameter(Mandatory = $True)][string]$VMName,
        [Parameter(Mandatory = $True)][string]$vCenter,
        [Parameter(Mandatory = $True)][string]$VMUUID,
        [Parameter(Mandatory = $True)][string]$VMID,
        [Parameter(Mandatory = $True)][string]$ServerMgmtOperation,
        [Parameter(Mandatory = $True)][string]$ServerMgmtValue
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray
   
    Write-Host "Writing ServerMgmtRequest for VMName: $VMName" -ForegroundColor Cyan
    $Query = "INSERT INTO ServerMgmtRequest(VMName,vCenter,VMUUID,VMID,ServerMgmtOperation,ServerMgmtValue) VALUES('$VMName','$vCenter','$VMUUID','$VMID','$ServerMgmtOperation','$ServerMgmtValue')"

    ### Open Database Connection
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $ConnectionString = $DevOps_DBConnectionString
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open()   
    ### Insert Row
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $Connection 

    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() #| Out-Null
    $connection.Close()

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Get-ServerManagementRequestID
{
    Param(
        [Parameter(Mandatory = $True)][string]$VMName,
        [Parameter(Mandatory = $True)][string]$vCenter,
        [Parameter(Mandatory = $True)][string]$VMUUID,
        [Parameter(Mandatory = $True)][string]$VMID
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray
   
    Write-Host "Getting ServerMgmtRequestID for HostName: $VMName" -ForegroundColor Cyan
    
    $Query = "Select MAX(ServerMgmtRequestID) AS ServerMgmtRequestID FROM ServerMgmtRequest WHERE VMName = '$VMName' AND vCenter = '$vCenter' AND VMUUID = '$VMUUID' AND VMID = '$VMID' "

    ### Execute DB Query
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $ConnectionString = $DevOps_DBConnectionString
    $connection.ConnectionString = $ConnectionString
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $result = $command.ExecuteReader()
    $Datatable = new-object "System.Data.DataTable"
    $Datatable.Load($result)
    $Datatable | FT
    $connection.Close()
    
    if($Datatable.Rows.Count -eq 1)
    {
        $Column = $Datatable | Get-Member -MemberType Property,NoteProperty | ForEach-Object {$_.Name} | Sort-Object -Property Name
        $global:ServerMgmtRequestID = $Datatable.$Column

    }
    elseif($Datatable.Rows.Count -gt 1)
    {
        Write-Error -Message "ECI.ERROR: Too many Records Returned!" -ErrorAction Continue
        Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID

    }
    elseif($Datatable.Rows.Count -eq 0)
    {
        Write-Error -Message "ECI.ERROR: No Records Found Matching Query!" -ErrorAction Continue
        Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID
    }

    $ServerMgmtRequestID = $Datatable.$Column
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray

    #$global:ServerMgmtRequestID = $ServerMgmtRequestID
    Return $ServerMgmtRequestID
}

function Identify-ECI.EMI.Automation.VM
{
    Param(
        [Parameter(Mandatory = $True)][string]$VMName,
        [Parameter(Mandatory = $True)][string]$vCenter,
        [Parameter(Mandatory = $True)][string]$VMUUID,
        [Parameter(Mandatory = $True)][string]$VMID
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    Write-Host "Idenifying VM: " $VMName -ForegroundColor Cyan

    ### Does VM Exist?
    ###------------------
    $VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue   ###<--- Use -ErrorAction SilentlyContinue because VM may not exist.
    if($VM)
    {
        $VMExists = $True
        Write-Host `r`n('-' * 50)`r`n"VMExist: " $VMExists `r`n('-' * 50)`r`n -ForegroundColor Green

        ### Get Unique VM Values
        Write-Host "Verifying VM Unique Identifiers:" -ForegroundColor DarkGray
        
        $verifyVMName      = $VM.Name
        $verifyVMUUID      = $VM | %{(Get-View $_.Id).config.uuid}
        $verifyVMID        = $VM.ID
        $verifyvCenter     = (($VM.UID).split("@")[1]).split(":")[0]
                
        Write-Host "verifyVMName      : " $verifyVMName      -ForegroundColor DarkCyan
        Write-Host "verifyVMUUID      : " $verifyVMUUID      -ForegroundColor DarkCyan
        Write-Host "verifyVMID        : " $verifyVMID        -ForegroundColor DarkCyan
        Write-Host "verifyvCenter     : " $verifyvCenter     -ForegroundColor DarkCyan

        ### ----------------------------------
        ### Identify Unique VM
        ### ----------------------------------
        if( ($VMName -eq $verifyVMName) -AND ($vCenter -eq $verifyvCenter) -AND ($VMUUID -eq $verifyVMUUID) -AND ($VMID -eq $verifyVMID) )
        {
            $VMisUnique  = $True 
            $UniqueColor = "Green"
        }
        else
        {
            $VMisUnique  = $False
            $UniqueColor = "Red"
            Write-Error -Message "ECI.ERROR: VMName is not Unique." -ErrorAction Continue -ErrorVariable +ECIError
            Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID
        }
        Write-Host `r`n('-' * 50)`r`n"VMisUnique: " $VMisUnique `r`n('-' * 50)`r`n -ForegroundColor $UniqueColor
    }
    elseif(!$VM)
    {
        $VMExists   = $False
        $VMisUnique = $False
        Write-Error -Message "ECI.ERROR: VMName does not exist." -ErrorAction Continue -ErrorVariable +ECIError
        Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID
    }
    $global:VMisUnique = $VMisUnique
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray

    Return $VMisUnique
}

function Get-ECI.EMI.Automation.VM.GuestState
{
    Param(
        [Parameter(Mandatory = $True)][string]$VMName,
        [Parameter(Mandatory = $True)][string]$vCenter,
        [Parameter(Mandatory = $True)][string]$VMUUID,
        [Parameter(Mandatory = $True)][string]$VMID
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    Write-Host "Getting VM Current State: " $VMName -ForegroundColor Cyan

    ###----------------------------
    ### Guest Ready State
    ###----------------------------
    $VM = (Get-VM -Name $VMName -ErrorAction SilentlyContinue)
    $GuestState = @{
        "PowerState"                 = $VM.PowerState                                         ### <---- RETRUN: PoweredOn/PoweredOff
        "GuestState"                 = $VM.ExtensionData.guest.guestState                     ### <---- RETRUN: running/notRunning
        "GuestOperationsReady"       = $VM.ExtensionData.guest.guestOperationsReady           ### <---- RETRUN: True/False                                                                            
        "GuestStateChangeSupported"  = $VM.ExtensionData.guest.guestStateChangeSupported      ### <---- RETRUN: True/False 
    }
    $GuestState = New-Object -TypeName PSObject -Property $GuestState

    if(($GuestState.PowerState -eq "PoweredOn") -AND ($GuestState.GuestState -eq "running") -AND ($GuestState.GuestOperationsReady -eq $True) -AND ($GuestState.GuestStateChangeSupported -eq $True))
    {
        $GuestReady = $True
        $Color = "Green"
    }
    else
    {
        $GuestReady = $False
        $Color = "Red"
        Write-Error -Message "ECI.ERROR: VM Guest State not ready." -ErrorAction Continue -ErrorVariable +ECIError
        Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID
    }

    $GuestState | Add-Member @{ECIGuestReady = $GuestReady} 
    $global:GuestState    = $GuestState 
    $global:GuestReady = $GuestReady

    Write-Host `r`n"GuestState: " ($GuestState | Out-String) -ForegroundColor DarkCyan
    Write-Host "ECIGuestReady: " $GuestReady -ForegroundColor $Color

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    
    Return $GuestReady
}


function PowerOn-ECI.EMI.VM.Mgmt.PowerState
{
    Param(
        [Parameter(Mandatory = $True)][string]$ServerMgmtRequestID,
        [Parameter(Mandatory = $True)][string]$ServerMgmtOperation,
        [Parameter(Mandatory = $True)][string]$ServerMgmtValue,
        [Parameter(Mandatory = $True)][string]$VMName,
        [Parameter(Mandatory = $True)][string]$vCenter,
        [Parameter(Mandatory = $True)][string]$VMUUID,
        [Parameter(Mandatory = $True)][string]$VMID
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    Write-Host "Powering On VM Guest." -ForegroundColor Cyan
     
    $ECIServerMgt = @{
        VMName              = $VMName 
        vCenter             = $vCenter
        VMUUID              = $VMUUID 
        VMID                = $VMID
        ServerMgmtRequestID = $ServerMgmtRequestID
    }
 
    ### VM Current Power State
    $VMPowerState = (Get-VM -Name $VMName).PowerState
    Write-Host "VM Current PowerState: " $VMPowerState -ForegroundColor DarkCyan

    if($VMPowerState -eq "PoweredOn")
    {
        Write-Host "The VM is already Powered On." -ForegroundColor Yellow
    }
    elseif($VMPowerState -ne "PoweredOff")
    {
        Write-Host "The VM is Not in a Powered Off State." -ForegroundColor Red
    }
    elseif($VMPowerState -eq "PoweredOff")
    {
        ###----------------------
        ### Retry Loop
        ###----------------------
        $Retries            = 3
        $RetryCounter       = 0
        $RetryTime          = 60
        $RetryTimeIncrement = ($RetryTime * 2)
        $Success            = $False

        while($Success -ne $True)
        {
            try
            {
                #####################
                ### PowerOn VM
                #####################
                Write-Host "Powering ON VM: " $VMName -ForegroundColor Yellow
                
                if($VMName.count -eq 1 -and $VMName -isnot [system.array])
                {
                    Start-VM -VM $VMName | Out-Null
                }
                else
                {
                    Write-Error -Message "ECI.Error: VMName is not Unique." -ErrorAction Continue -ErrorVariable +ECIError
                }

                Start-ECI.EMI.Automation.Sleep -t $WaitTime_GuestOSRestart -Message "Powering On VM"
                if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).PowerState -eq "PoweredOn")
                {
                    $Success = $True
                    Write-Host "$FunctionName - Succeded: " $Success -ForegroundColor Green  
                }
            }
            catch
            {
                if($RetryCounter -ge $Retries)
                {
                    Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID
                    Throw "ECI.THROW.TERMINATING.ERROR: Power On Operation Failed! "
                }
                else
                {
                    ### Retry x Times
                    ###--------------
                    $RetryCounter++
                
                    ### Write ECI Error Log
                    ###---------------------------------
                    Write-Error -Message ("ECI.RETRY: PowerOn") -ErrorAction Continue -ErrorVariable +ECIError
                    if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
                    $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force

                    ### Error Handling Action
                    ###----------------------------------
                    Start-ECI.EMI.Automation.Sleep -Message "Retry Power On Operation." -t $RetryTime

                    $RetryTime = $RetryTime + $RetryTimeIncrement
                }
            }
        }
    }
    else
    {
        Write-Error -Message ("ECI.ERROR: The VM Powered State was not determined.") -ErrorAction Continue -ErrorVariable +ECIError
        Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID
    }

    ### Verify Power State
    ###----------------------------------
    $VerifyVMPowerState = (Get-VM -Name $VMName).PowerState
    Write-Host "Verified VM Power State: " $VerifyVMPowerState -ForegroundColor Magenta
    if($VerifyVMPowerState -eq "PoweredOn")
    {
        $OperationVerified = $True
        $OperationVerifiedColor = "Green"
    }
    else
    {
        $OperationVerified = $False
        $OperationVerifiedColor = "Red"
        Write-Error -Message ("ECI.ERROR: The VM Powered State was not determined.") -ErrorAction Continue -ErrorVariable +ECIError
        Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID
    }
    Write-Host "Verified VM Power State: " $OperationVerified -ForegroundColor $OperationVerifiedColor


    ### Report Power State
    ###----------------------------------
    $ServerMgmtUpdate = @{
        ServerMgmtRequestID  = $ServerMgmtRequestID
        VMName               = $VMName
        vCenter              = $vCenter
        VMUUID               = $VMUUID
        VMID                 = $VMID
        ServerMgmtOperation  = $ServerMgmtOperation
        ServerMgmtValue      = $ServerMgmtValue
        OperationVerified    = $OperationVerified
    
    }
    Update-ECI.EMI.VM.Mgmt.ServerMgmtOperations-SQL @ServerMgmtUpdate


    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


function PowerOff-ECI.EMI.VM.Mgmt.PowerState
{
    Param(
        [Parameter(Mandatory = $True)][string]$ServerMgmtRequestID,
        [Parameter(Mandatory = $True)][string]$ServerMgmtOperation,
        [Parameter(Mandatory = $True)][string]$ServerMgmtValue,
        [Parameter(Mandatory = $True)][string]$VMName,
        [Parameter(Mandatory = $True)][string]$vCenter,
        [Parameter(Mandatory = $True)][string]$VMUUID,
        [Parameter(Mandatory = $True)][string]$VMID
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    Write-Host "Powering Off VM Guest." -ForegroundColor Cyan
     
 
    ### VM Current Power State
    $VMPowerState = (Get-VM -Name $VMName).PowerState
    Write-Host "VM Current PowerState: " $VMPowerState -ForegroundColor DarkCyan

    if($VMPowerState -eq "Poweredff")
    {
        Write-Host "The VM is ia already Powerd off." -ForegroundColor Yellow
    }
    elseif($VMPowerState -ne "PoweredOn")
    {
        Write-Host "The VM is Not in a Powered On State." -ForegroundColor Red
    }
    elseif($VMPowerState -eq "PoweredOn")
    {
        ### Is GuestState Ready?
        $VMIdentity = @{
            #ServerMgmtOperation = $ServerMgmtOperation
            VMName      = $VMName 
            vCenter     = $vCenter
            VMUUID      = $VMUUID 
            VMID        = $VMID
        }
        Get-ECI.EMI.Automation.VM.GuestState @VMIdentity

        if($GuestReady -eq $True)
        {
            ###----------------------
            ### Retry Loop
            ###----------------------
            $Retries            = 3
            $RetryCounter       = 0
            $RetryTime          = 60
            $RetryTimeIncrement = ($RetryTime * 1.5)
            $Success            = $False

            while($Success -ne $True)
            {
                try
                {
                    ### Initiate Command
                    ###-------------------------------------------------------------
                    Write-Host "Powering OFF VM: " $VMName -ForegroundColor Yellow
                    
                    ######################
                    ### Soft Shutdown VM
                    ######################    
                    
                    ### Soft Shutdown
                    Shutdown-VMGuest -VM $VMName -confirm:$false
                    Start-ECI.EMI.Automation.Sleep -t $RetryTime -Message "Issuing Shutdown Command: $RetryCounter"

                    if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).PowerState -eq "PoweredOff")
                    {
                        $Success = $True
                        Write-Host "$FunctionName - Succeded: " $Success -ForegroundColor Green  
                    }
                }
                catch
                {
                    if($RetryCounter -ge $Retries)
                    {
                        #####################
                        ### Hard Shutdown
                        #####################
                        Stop-VM -VM $VMName -Confirm:$false
                        
                        ###  Multiply Wait time by 4x
                        Start-ECI.EMI.Automation.Sleep -t ($RetryTime * 4.5) -Message "Issuing Final Shutdown Command: $RetryCounter"
                        
                        if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).PowerState -eq "PoweredOff")
                        {
                            $Success = $True
                            Write-Host "$FunctionName - Succeded: " $Success -ForegroundColor Green 
                        }
                        elseif((Get-VM -Name $VMName -ErrorAction SilentlyContinue).PowerState -ne "PoweredOff")
                        {
                            ### Wait 60 Minutes
                            Start-ECI.EMI.Automation.Sleep -t 3600 -Message "Issuiung Stop"
                            if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).PowerState -eq "PoweredOff")
                            {
                                $Success = $True
                                Write-Host "$FunctionName - Succeded: " $Success -ForegroundColor Green  
                            }
                            elseif((Get-VM -Name $VMName -ErrorAction SilentlyContinue).PowerState -ne "PoweredOff")
                            {
                                #####################
                                ### Kill
                                #####################
                                Stop-VM -VM $VMName -Kill -Confirm:$false
                                Start-ECI.EMI.Automation.Sleep -t 7200 -Message "Issued Kill Command"
                                if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).PowerState -eq "PoweredOff")
                                {
                                    $Success = $True
                                    Write-Host "$FunctionName - Succeded: " $Success -ForegroundColor Green 
                                }
                                elseif((Get-VM -Name $VMName -ErrorAction SilentlyContinue).PowerState -ne "PoweredOff")
                                {
                                    Write-Error  -Message "ECI.ERROR: Power Off Operation Failed!" -ErrorAction Continue -ErrorVariable +ECIError
                                    Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID
                                }
                            }
                        }
                    }
                    else
                    {
                        ### Retry x Times
                        ###--------------------
                        $RetryCounter++
                
                        ### Write ECI Error Log
                        ###---------------------------------
                        Write-Error -Message ("ECI.RETRY: Retry PowerOff") -ErrorAction Continue -ErrorVariable +ECIError
                        if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
                        $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force

                        ### Error Handling Action
                        ###----------------------------------                  
                        Start-ECI.EMI.Automation.Sleep -Message "Retry Power Off Operation." -t $RetryTime

                        $RetryTime = $RetryTime + $RetryTimeIncrement
                    }
                }
            }
        }
        else
        {
            Write-Error -Message ("ECI.ERROR: Guest State NOT Ready.") -ErrorAction Continue -ErrorVariable +ECIError
            Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID
        }
    }
    else
    {
        Write-Error -Message ("ECI.ERROR: The VM Powered State was not determined.") -ErrorAction Continue -ErrorVariable +ECIError
        Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID
    }

    ### Verify Power State
    ###----------------------------------
    function Verify-ServerState
    {
        $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

        Write-Host "Verifying VM Power State." -ForegroundColor Cyan

        $VerifyVMPowerState = (Get-VM -Name $VMName).PowerState
        
        if($VerifyVMPowerState -eq "PoweredOff")
        {
            $OperationVerified = $True
            $OperationVerifiedColor = "Green"
        }
        else
        {
            $OperationVerified = $False
            $OperationVerifiedColor = "Red"
            Write-Error -Message ("ECI.ERROR: The VM Powered State was not determined.") -ErrorAction Continue -ErrorVariable +ECIError
            Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID
        }
        Write-Host "VerifyVMPowerState : " $VerifyVMPowerState -ForegroundColor DarkCyan
        Write-Host "OperationVerified  : " $OperationVerified -ForegroundColor $OperationVerifiedColor

        Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray

        $global:OperationVerified = $OperationVerified
        Return $OperationVerified

    }
    Verify-ServerState

    ### Report Power State
    ###----------------------------------
    $ServerMgmtUpdate = @{
        ServerMgmtRequestID  = $ServerMgmtRequestID
        VMName               = $VMName
        vCenter              = $vCenter
        VMUUID               = $VMUUID
        VMID                 = $VMID
        ServerMgmtOperation  = $ServerMgmtOperation
        ServerMgmtValue      = $ServerMgmtValue
        OperationVerified    = $OperationVerified
    
    }
    Update-ECI.EMI.VM.Mgmt.ServerMgmtOperations-SQL @ServerMgmtUpdate

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Update-ECI.EMI.VM.Mgmt.ServerMgmtOperations-SQL
{
    Param(
        [Parameter(Mandatory = $True)][string]$ServerMgmtRequestID,
        [Parameter(Mandatory = $True)][string]$ServerMgmtOperation,
        [Parameter(Mandatory = $True)][string]$ServerMgmtValue,
        [Parameter(Mandatory = $True)][string]$VMName,
        [Parameter(Mandatory = $True)][string]$vCenter,
        [Parameter(Mandatory = $True)][string]$VMUUID,
        [Parameter(Mandatory = $True)][string]$VMID,
        [Parameter(Mandatory = $True)][string]$OperationVerified
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    $ServerMgmtFunction = $FunctionName
    $Query = "INSERT INTO ServerMgmtOperations(ServerMgmtRequestID,VMName,vCenter,VMUUID,VMID,ServerMgmtOperation,ServerMgmtValue,OperationVerified) VALUES('$ServerMgmtRequestID','$VMName','$vCenter','$VMUUID','$VMID','$ServerMgmtOperation','$ServerMgmtValue','$OperationVerified')"
    $ConnectionString  = $DevOps_DBConnectionString
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


function Send-ECI.EMI.ServerMgmtAlert
{
    Param(
    [Parameter(Mandatory = $True)][int]$ServerMgmtRequestID,
    [Parameter(Mandatory = $False)][string]$Status,
    [Parameter(Mandatory = $False)][string]$HostName
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    ### Message Header
    ###----------------------------------------------------------------------------
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
    $Message += "<html><body>"


    $Message += "<font size='3';color='gray'><i>ECI EMI Server Automation</i></font><br>"
    $Message += "<font size='5';color='NAVY'><b>ECI Error Alert</b></font><br>"
    $Message += "<font size='2'>Request Date:" + (Get-Date) + "</font>"
    $Message += "<br><br><br><br>"
    $Message += "<font size='3';color='black'>WARNING: This Server <b> COULD NOT </b> be provisioned.</font>"
    $Message += "<br><br>"
    $Message += "<font size='3';color='red'><br><b>ERROR MESSAGE: </b></font><br>"
    
    
    $Message += "<font size='3';color='red'>" + $Error[0] +  " </font>"
    #$Message += "<font size='3';color='red'>" + $ErrorMsg +  " </font>"
    
    $Message += "<br><br><br>"

    $Message += "<table>"
    $Message += "<tr>"
    $Message += "<td align='right'>" + "Status : </td>"  
    $Message += "<td align='left'><font size='4';color='$black'>" + $Status   + "</font></td>"
    $Message += "</tr>"
    $Message += "<tr>"
    $Message += "<td align='right'>" + "HostName : </td>"  
    $Message += "<td align='left'><font size='4';color='black'>" + $VMName + "</font></td>"
    $Message += "</tr>"
    $Message += "</table>"
    $Message += "<br>"
    $Message += "FOR ECI INTERNAL USE ONLY."                               + "`r`n" + "<br><br>"


    ### Message Status
    ###----------------------------------------------
    $Message += "---------------------------------------------------------------------" + "`r`n" + "<br>"
    $Message += "<b>SERVER PROVISIONING STATUS: "                                       + "`r`n" + "</b><br>"
    $Message += "---------------------------------------------------------------------" + "`r`n" + "<br>"

    ### Display Desired State SQL Record
    ###----------------------------------------------------------------------------    
    $Message += "<font size='3';><b>SERVER CONFIGURATION STATE:</b>"           + "</font><br>"
    $Header = "
        <style>
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
        </style>
    "
    $Message += $Header
    
    $DataSetName = "DesiredState"
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    $Query = "SELECT * FROM ServermgmtRequest WHERE ServerMgmtRequestID = '$ServerMgmtRequestID'"
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
    $Message += "<br><br>"

    ### Transcript Log 
    ###---------------------
    $TranscriptURL = "cloud-portal01.eci.cloud/vmautomationlogs/Transcripts/" + (Split-Path $TranscriptFile -Leaf)
    $Message += "Transcript Log: " + "<a href=http://" + $TranscriptURL + ">" + $TranscriptURL + "</a>"
    $Message += "<br><br>"
    $Message += "Server Build Date: " + (Get-Date)
    $Message += "<br>"
        
    ### Close Message
    ###---------------------
    $Message += "</body></html>"

    ### Email Constants
    ###---------------------
    $From    = "cbrennan@eci.com"
    #$To      = "cbrennan@eci.com,sdesimone@eci.com,wercolano@eci.com,rgee@eci.com"
    $To      = "cbrennan@eci.com"
    $SMTP    = "alertmx.eci.com"
    #$SMTP   = $SMTPServer
    $Subject = "SERVER PROVISIONING STATUS: " + $Status

    ### Email Message
    ###----------------------------------------------------------------------------
    Write-Host `r`n`r`n`r`n("=" * 50)`n"SENDING ALERT:" $Status`r`n("=" * 50)`r`n`r`n -ForegroundColor Yellow
    
    #Write-Host `n "MESSAGE: " $Message `n -ForegroundColor $StatusColor
    Write-Host "TO: " $To
    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP

    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray

}





















