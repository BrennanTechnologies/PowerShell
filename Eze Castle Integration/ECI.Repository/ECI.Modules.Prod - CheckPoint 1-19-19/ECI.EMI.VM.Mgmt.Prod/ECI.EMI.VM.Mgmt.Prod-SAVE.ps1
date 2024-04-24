Param(
    [Parameter(Mandatory = $True)][string]$VMMgmtOperation,
    [Parameter(Mandatory = $True)][string]$VMMgmtValue,
    [Parameter(Mandatory = $True)][string]$VMName,
    [Parameter(Mandatory = $True)][string]$vCenterName,
    [Parameter(Mandatory = $True)][string]$VMUUID,
    [Parameter(Mandatory = $True)][string]$VMMoRef
    
)

#Get-Module -ListAvailable eci* | Import-Module -DisableNameChecking -Force

Write-Host "Test"
Start-Sleep -Seconds 60

# Variables from DB
$WaitTime_GuestOSRestart = 180

### Connect VICenter
###-----------------------------------
$vCenter_Account = "portal-int@eci.cloud"
$vCenter_Password = "7Gc^jfzaZnzD"
$ECIvCenter = "ld5vc.eci.cloud" 
Connect-VIServer -Server $ECIvCenter -User $vCenter_Account -Password $vCenter_Password


function Import-ECI.Root.ModuleLoader
{
    ######################################
    ### Bootstrap Module Loader
    ######################################
    Param([Parameter(Mandatory = $False)][ValidateSet("Dev","Stage","Prod")] [string]$Env)


    switch ($Env)
    {
        "Dev"          { $global:Environment = "Development" }
        "Stage"        { $global:Environment = "Staging"     }
        "Prod"         { $global:Environment = "Production"  }
        "Development"  { $global:Environment = "Development" }
        "Staging"      { $global:Environment = "Staging"     }
        "Production"   { $global:Environment = "Production"  }
    }

    ### Connect to the Repository & Import the ECI.ModuleLoader
    ### ----------------------------------------------------------------------
    $AcctKey         = ConvertTo-SecureString -String "VSRMGJZNI4vn0nf47J4bqVd5peNiYQ/8+ozlgzbuA1FUnn9hAoGRM9Ib4HrkxOyRJkd4PHE8j36+pfnCUw3o8Q==" -AsPlainText -Force
    $Credentials     = $Null
    $Credentials     = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\eciscripts", $AcctKey
    $RootPath        = "\\eciscripts.file.core.windows.net\clientimplementation"
  
    #$Invoke-Command -ScriptBlock {Net Use X: delete}
    

    $PSEnvDrives  = Get-PSDrive -PSProvider FileSystem | Where-Object {($_.Root -like "*eciscripts*") -OR ($_.DisplayRoot -like "*eciscripts*")}
    if($PSEnvDrives)
    {
        foreach($PSEnvDrive in $PSEnvDrives)
        {
            #Write-Host "Removing Drive: $PSEnvDrive" -ForegroundColor Yellow
            Remove-PSDrive -Name $PSEnvDrive -PSProvider FileSystem -Force
        }
    }
        ####New-PSDrive -Name $RootDrive -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Persist -Scope global
        New-PSDrive -Name X -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Scope Global


    #$PSDrive = New-PSDrive -Name X -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Persist -Scope Global

    ### Import the Module Loader - Dot Source
    ### ----------------------------------------------------------------------
    . "\\eciscripts.file.core.windows.net\clientimplementation\Root\$Env\ECI.Root.ModuleLoader.ps1" -Env $Env


}

function Write-ServerManagementRequesttoSQL
{
   
    Write-Host "Inserting Server Request for HostName: $HostName" -ForegroundColor Yellow
    $Query = "INSERT INTO ServerMgmtRequest(GPID,CWID,ClientDomain,HostName,RequestServerRole,IPv4Address,SubnetMask,DefaultGateway,PrimaryDNS,SecondaryDNS,InstanceLocation,DomainUserName,BackupRecovery,DisasterRecovery) VALUES('$GPID','$CWID','$ClientDomain','$HostName','$RequestServerRole','$IPv4Address','$SubnetMask','$DefaultGateway','$PrimaryDNS','$SecondaryDNS','$InstanceLocation','$DomainUserName','$BackupRecovery','$DisasterRecovery')"
    
    # Open Database Connection
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open()   
    # Insert Row
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() | Out-Null
    #Close
    $connection.Close()
}


function Get-SQLData
{
    #$Query = “SELECT RequestID FROM ServerRequest WHERE HostName = '$HostName'”
    $Query = “SELECT TOP 1 RequestID FROM ServerRequest ORDER BY RequestID DESC”

    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $Datatable = New-Object System.Data.DataTable
    $Datatable.Load($Reader)
    $RequestID = $Datatable[0]
    Return $RequestID

}


function Change-ECI.EMI.Automation.VM.Mgmt.PowerState
{
    Param(
        [Parameter(Mandatory = $True)][string]$VMName,
        [Parameter(Mandatory = $True)][string]$vCenterName,
        [Parameter(Mandatory = $True)][string]$VMUUID,
        [Parameter(Mandatory = $True)][string]$VMMoRefID
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    Write-Host `r`n"PowerStateRequest: " $PowerStateRequest -ForegroundColor Yellow

    ### Power On
    if($PowerStateRequest -eq "PowerOn")
    {
        PowerOn-ECI.EMI.Automation.VM @ECIVMMgmt -ServerMgmtRequestID $ServerMgmtRequestID #-PowerState PowerOn
    }
    
    ### Power Off
    elseif($PowerStateRequest -eq "PowerOff")
    {
        ### Is GuestState Ready?
        Get-ECI.EMI.Automation.VM.GuestState @ECIServerMgt

        if($GuestReady -eq $True)
        {
            PowerOff-ECI.EMI.Automation.VM @ECIServerMgt -ServerMgmtRequestID $ServerMgmtRequestID #-PowerState PowerOff
        }
        else
        {
            Write-Error -Message ("ECI.ERROR: Guest State NOT Ready.") -ErrorAction Continue -ErrorVariable +ECIError
            Send-ECI.Alert
        }
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}



&{
    BEGIN
    {
        Start-Transcript
        Import-ECI.Root.ModuleLoader
        #Write-ServerManagementRequesttoSQL
    }

    PROCESS
    {
        $VMIdentity = @{
            VMName              = $VMName 
            vCenterName         = $vCenterName 
            VMUUID              = $VMUUID 
            VMMoRef             = $VMMoRef
        }
        
        ### Does VM Exist & Is VM Unique?
        Identify-ECI.EMI.Automation.VM @VMIdentity

        if($VMisUnique -eq $True)
        {
            if($VMMgmtOperation -eq "PowerState")
            {
                Change-ECI.EMI.Automation.VM.Mgmt.PowerState @VMIdentity -VMMgmtValue $VMMgmtValue
            }
            elseif($VMMgmtOperation -eq "vCPU")
            {
                Change-ECI.EMI.Automation.VM.Mgmt.vCPU @VMIdentity -VMMgmtValue $VMMgmtValue
            }
            elseif($VMMgmtOperation -eq "vMemory")
            {
                Change-ECI.EMI.Automation.VM.Mgmt.PowerState @VMIdentity -VMMgmtValue $VMMgmtValue
            }
            elseif($VMMgmtOperation -eq "vDisk")
            {
                Change-ECI.EMI.Automation.VM.Mgmt.vDisk @VMIdentity -VMMgmtValue $VMMgmtValue
            }
            else
            {
                Write-Error -Message ("ECI.ERROR: Invalid Operation") -ErrorAction Continue -ErrorVariable +ECIError
                Send-ECI.Alert
            }
        }
        else
        {
            Write-Error -Message ("ECI.ERROR: VM NOT Unique") -ErrorAction Continue -ErrorVariable +ECIError
            Send-ECI.Alert
        }
    }

    END 
    {
        Stop-Transcript
    }
}

