Param(
    [Parameter(Mandatory = $True)][string]$Env,
    [Parameter(Mandatory = $True)][string]$ServerMgmtOperation,
    [Parameter(Mandatory = $True)][string]$ServerMgmtValue,
    [Parameter(Mandatory = $True)][string]$VMName,
    [Parameter(Mandatory = $True)][string]$vCenter,
    [Parameter(Mandatory = $True)][string]$VMUUID,
    [Parameter(Mandatory = $True)][string]$VMID
    
)

Write-Host `r`n("-" * 50)`r`n "VM Management Parameters:" `r`n("-" * 50)`r`n -ForegroundColor Yellow
Write-Host "ServerMgmtOperation : " $ServerMgmtOperation                     -ForegroundColor Yellow
Write-Host "ServerMgmtValue     : " $ServerMgmtValue                         -ForegroundColor Yellow
Write-Host "VMName              : " $VMName                                  -ForegroundColor Yellow
Write-Host "vCenter             : " $vCenter                                 -ForegroundColor Yellow
Write-Host "VMUUID              : " $VMUUID                                  -ForegroundColor Yellow
Write-Host "VMID                : " $VMID                                    -ForegroundColor Yellow
Write-Host `r`n("-" * 50)`r`n                                                -ForegroundColor Yellow



#######################################
### Function: Set-TranscriptPath
#######################################
function Start-ECI.EMI.VM.Mgmt.Transcript
{
    Param(
    [Parameter(Mandatory = $False)][string]$TranscriptPath,
    [Parameter(Mandatory = $False)][string]$TranscriptName,
    [Parameter(Mandatory = $True)][string]$VMName
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
    if(!$TranscriptPath){$global:TranscriptPath = "C:\Scripts\Transcripts"}

    ### Make sure path ends in "\"
    $LastChar = $TranscriptPath.substring($TranscriptPath.length-1) 
    if ($LastChar -ne "\"){$TranscriptPath = $TranscriptPath + "\"}

    ### Create Transcript File Name
    if($TranscriptName)
    {
        $global:TranscriptFile = $TranscriptPath + "PowerShell_transcript" + "." + $TranscriptName + "." + $VMName + "." + $Rnd + "." + $TimeStamp + ".txt"
    }
    else
    {
        $global:TranscriptFile = $TranscriptPath + "PowerShell_transcript" + "." + $VMName + "." + $Rnd + "." + $TimeStamp + ".txt"
    }
    ### Start Transcript Log
    Start-Transcript -Path $TranscriptFile -NoClobber 
}


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
    Param([Parameter(Mandatory = $True)][ValidateSet("Dev","Stage","Prod")] [string]$Env)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

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

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function ChangeState-ECI.EMI.Automation.VM.Mgmt.vCPU
{
}
function ChangeState-ECI.EMI.Automation.VM.Mgmt.vMemory
{
}
function ChangeState-ECI.EMI.Automation.VM.Mgmt.vDisk
{
}

function ChangeState-ECI.EMI.Automation.VM.Mgmt.PowerState
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

    Write-Host `r`n"PowerStateRequest: " $ServerMgmtValue -ForegroundColor Cyan

    $ServerIdentity = [ordered]@{
        VMName              = $VMName
        vCenter             = $vCenter
        VMUUID              = $VMUUID
        VMID                = $VMID
    }

    Write-Host "ServerIdentity:" ($ServerIdentity | Out-String) -ForegroundColor DarkCyan

    $CurrentPowerState = (Get-VM -Name $VMName).PowerState

    $ServerMgmt = [ordered]@{
        ServerMgmtRequestID = $ServerMgmtRequestID
        ServerMgmtOperation = $ServerMgmtOperation
        ServerMgmtValue     = $ServerMgmtValue
        VMName              = $VMName
        vCenter             = $vCenter
        VMUUID              = $VMUUID
        VMID                = $VMID
    }

    ### Power On
    if($ServerMgmtValue -eq "PowerOn")
    {
        if($CurrentPowerState -eq "PoweredOn")
        {
            Write-Warning "The VM is already Powered On" 
        }
        else
        {
            PowerOn-ECI.EMI.VM.Mgmt.PowerState @ServerMgmt #-ServerMgmtOperation $ServerMgmtOperation -ServerMgmtValue $ServerMgmtValue -ServerMgmtRequestID $ServerMgmtRequestID 
        }
    }
    
    ### Power Off
    elseif($ServerMgmtValue -eq "PowerOff")
    {
        if($CurrentPowerState -eq "PoweredOff")
        {
            Write-Warning "The VM is already Powered Off" -ErrorAction SilentlyContinue -ErrorVariable 
        }
        else
        {
            ### Is GuestState Ready?
            Get-ECI.EMI.Automation.VM.GuestState @ServerIdentity

            if($GuestReady -eq $True)
            {
                PowerOff-ECI.EMI.VM.Mgmt.PowerState @ServerMgmt #-ServerMgmtOperation $ServerMgmtOperation -ServerMgmtValue $ServerMgmtValue -ServerMgmtRequestID $ServerMgmtRequestID 
            }
            else
            {
                Write-Error -Message ("ECI.ERROR: Guest State NOT Ready.") -ErrorAction Continue -ErrorVariable +ECIError
                Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID -Status $Status -HostName $HostName
            }
        }
    }
    else
    {
        Write-Error -Message ("ECI.ERROR: Invalid Operation Request.") -ErrorAction Continue -ErrorVariable +ECIError
        Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID -Status $Status -HostName $HostName
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}



&{
    BEGIN
    {
        Start-ECI.EMI.VM.Mgmt.Transcript -VMName $VMName -TranscriptPath "C:\Scripts\_VMAutomationLogs\Transcripts\" -TranscriptName "ECI.EMI.VM.Mgmt.$Env.ps1"
        Import-ECI.Root.ModuleLoader -Env $Env
        $global:DevOps_ConnectionString  =  "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;” # <-- Need to Encrypt Password !!!!!!
        Get-ECI.EMI.Automation.SystemConfig -Env $Env -DevOps_ConnectionString $DevOps_ConnectionString 

        Connect-ECI.EMI.Automation.VIServer -vCenter $vCenter

        $ServerManagementRequest = @{
            VMName              = $VMName
            vCenter             = $vCenter
            VMUUID              = $VMUUID
            VMID                = $VMID
            ServerMgmtOperation = $ServerMgmtOperation
            ServerMgmtValue     = $ServerMgmtValue
        }
        Write-ServerMgmtRequesttoSQL @ServerManagementRequest

        $ServerManagementRequestID = @{
            VMName              = $VMName
            vCenter             = $vCenter
            VMUUID              = $VMUUID
            VMID                = $VMID
        }        
        Get-ServerManagementRequestID @ServerManagementRequestID

    }

    PROCESS
    {
        $VMIdentity = @{
            VMName       = $VMName 
            vCenter      = $vCenter
            VMUUID       = $VMUUID 
            VMID         = $VMID
        }
        
        ###--------------------------------------------
        ### Does VM Exist & Is VM Unique?
        ###--------------------------------------------
        Identify-ECI.EMI.Automation.VM @VMIdentity

        if($VMisUnique -eq $True)
        {
            ###--------------------------------------------
            ### Is GuestState Ready?
            ###--------------------------------------------
            $VMIdentity = @{
                #ServerMgmtOperation = $ServerMgmtOperation
                VMName      = $VMName 
                vCenter     = $vCenter
                VMUUID      = $VMUUID 
                VMID        = $VMID
            }
            Get-ECI.EMI.Automation.VM.GuestState @VMIdentity

            if($GuestReady = $true)
            {
                $ECIServerMgmt = @{
                    ServerMgmtOperation = $ServerMgmtOperation
                    ServerMgmtValue     = $ServerMgmtValue
                    VMName              = $VMName
                    vCenter             = $vCenter
                    VMUUID              = $VMUUID
                    VMID                = $VMID
                }
            
                switch ($ServerMgmtOperation)
                {
                    "PowerState"
                    {
                        ChangeState-ECI.EMI.Automation.VM.Mgmt.PowerState @ECIServerMgmt -ServerMgmtRequestID $ServerMgmtRequestID
                    }
                    "vCPU"
                    {
                        ChangeState-ECI.EMI.Automation.VM.Mgmt.vCPU @ECIServerMgmt -ServerMgmtRequestID $ServerMgmtRequestID
                    }
                    "vMemory"
                    {
                        ChangeState-ECI.EMI.Automation.VM.Mgmt.vMemory @ECIServerMgmt -ServerMgmtRequestID $ServerMgmtRequestID
                    }
                    "vDisk"
                    {
                        ChangeState-ECI.EMI.Automation.VM.Mgmt.vDisk @ECIServerMgmt -ServerMgmtRequestID $ServerMgmtRequestID
                    }
                }
            }
            elseif($GuestReady = $False)
            {
                Write-Error -Message ("ECI.ERROR: VM Guest State Not Ready.") -ErrorAction Continue -ErrorVariable +ECIError
                Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID -Status $Status -HostName $HostName
            }
        }
        else
        {
            Write-Error -Message ("ECI.ERROR: VM NOT Unique.") -ErrorAction Continue -ErrorVariable +ECIError
            Send-ECI.EMI.ServerMgmtAlert -ServerMgmtRequestID $ServerMgmtRequestID -Status $Status -HostName $HostName
        }
    }

    END 
    {
        Stop-Transcript
    }
}

