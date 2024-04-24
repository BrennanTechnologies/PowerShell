Param(
        [Parameter(Mandatory=$true)][String]$serverName,
        [Parameter(Mandatory=$true)][String]$domain,
        [Parameter(Mandatory=$true)][String]$oUPath,
        [Parameter(Mandatory=$true)][String]$description,
        [Parameter(Mandatory=$true)][String]$vCenter,
        [Parameter(Mandatory=$true)][String]$vMHost,
        [Parameter(Mandatory=$true)][String]$vMTemplate,
        [Parameter(Mandatory=$true)][String]$datastore,
        #[Parameter(Mandatory=$true)][String]$location, ### <---- specifies vCenter Folder
        [Parameter(Mandatory=$true)][String]$vLAN,
        [Parameter(Mandatory=$true)][String]$oS,
        [Parameter(Mandatory=$true)][String]$iPAddress,
        [Parameter(Mandatory=$true)][String]$subnetMask,
        [Parameter(Mandatory=$true)][String]$defaultGateway,
        [Parameter(Mandatory=$true)][String]$dns,
        [Parameter(Mandatory=$true)][String]$numCpu,
        [Parameter(Mandatory=$true)][String]$memoryGB,
        [Parameter(Mandatory=$true)][String]$diskGB,
        [Parameter(Mandatory=$true)][String]$owner,
        [Parameter(Mandatory=$true)][String]$team,
        [Parameter(Mandatory=$true)][String]$environment,
        #[Parameter(Mandatory=$true)][String]$oSDrive,
        #[Parameter(Mandatory=$true)][String]$oSDriveSize,
        [Parameter(Mandatory=$true)][String]$backupType,
        [Parameter(Mandatory=$true)][String]$adAdminID,
        [Parameter(Mandatory=$true)][String]$adAdminPassword,
        [Parameter(Mandatory=$true)][String]$guestAdminId,
        [Parameter(Mandatory=$true)][String]$guestAdminPassword
    )

#######################################
### Function: Set-TranscriptPath
#######################################
function AST.Start-Transcript
{
    Param(
    [Parameter(Mandatory = $False)][string]$TranscriptPath,
    [Parameter(Mandatory = $False)][string]$TranscriptName,
    [Parameter(Mandatory = $False)][string]$HostName
    )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

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
        $global:TranscriptFile = $TranscriptPath + $HostName + "_PowerShell_transcript" + "." + $TranscriptName + "." + $Rnd + "." + $TimeStamp + ".txt"
    }
    else
    {
        $global:TranscriptFile = $TranscriptPath + "PowerShell_transcript" + "." + $Rnd + "." + $TimeStamp + ".txt"
    }
    ### Start Transcript Log
    
    Write-Host ("*" * 80) `r`n "Starting Trascript File: $TranscriptFile" `r`n ("*" * 80) -ForegroundColor Green
    Start-Transcript -Path $TranscriptFile -NoClobber 

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

#######################################
### Import AST Modules
#######################################

function AST.Import-ASTModules 
{

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    $ASTModulePath = "C:\Scripts\AST.Modules"
    $origPSModulePath = $env:PSModulePath.Split(";") | Where {$_ -notlike $ASTModulePath}
    
    foreach($path in $origPSModulePath) 
    {
        $newPSModulePath += $path + ";"
    }
    $env:PSModulePath = ($newPSModulePath + $ASTModulePath)
    
    Write-Host "Adding AST Module to PS Module Path:" -ForegroundColor Cyan
    Write-Host "NEW PS MODULE PATH:`r`n" $env:PSModulePath -ForegroundColor DarkCyan

    Get-Module -ListAvailable AST* | Import-Module -Force -DisableNameChecking

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


&{

    BEGIN 
    {
        ###---------------------------------------------------
        #Clear-Host
        $functionName = $MyInvocation.MyCommand; Write-Host `r`n ("=" * 75)`r`n " EXECUTING FUNCTION: " $functionName `n`r ("=" * 75) -ForegroundColor DarkGray    
        Write-Host "BEGIN: - "  (Get-PSCallStack)[1].Command -ForegroundColor Magenta
        Write-Host ("= " * 80 )`r`n (" " * 30) $MyInvocation.ScriptName `r`n("= " * 80) -ForegroundColor Green
        ###---------------------------------------------------



        $global:serverParams = @{
            serverName          = $serverName
            domain              = $domain
            oUPath              = $oUPath
            description         = $description
            vCenter             = $vCenter
            vMHost              = $vMHost
            vMTemplate          = $vMTemplate
            datastore           = $datastore
            #location           = $location
            vLAN                = $vLAN
            oS                  = $oS
            iPAddress           = $iPAddress
            subnetMask          = $subnetMask
            defaultGateway      = $defaultGateway
            dns                 = $dns
            numCpu              = $numCpu
            memoryGB            = $memoryGB
            diskGB              = $diskGB
            owner               = $owner
            team                = $team
            environment         = $environment
            #oSDrive            = $oSDrive
            #oSDriveSize        = $oSDriveSize
            backupType          = $backupType
            adAdminID           = $adAdminID
            adAdminPassword     = $adAdminPassword
            guestAdminID        = $guestAdminID
            guestAdminPassword  = $guestAdminPassword
        }

        Write-Host "Server Parameters: " -ForegroundColor Green
        $serverParams

        $global:AutomationStartTime   = (Get-Date)
        AST.Start-Transcript -TranscriptPath "C:\Scripts\_VMAutomationLogs\$serverName\" -TranscriptName "AST.Automation.$Env.ps1" -HostName $serverNameName
        AST.Import-ASTModules
        AST.Set-PowerCLIConfiguration
    }

    PROCESS 
    {

        Write-Host "PROCESS: - "  (Get-PSCallStack)[1].Command -ForegroundColor Magenta

        ####################################################
        ### Deploy VM
        ####################################################

        AST.Connect-VIServer               -vCenter $vCenter
        AST.Get-VMTemplate                 -VMTemplateName "Windows 2016 Template Not Hardened ast"
        AST.New-OSCustomizationSpec        -guestAdminID $guestAdminID -guestAdminPassword $guestAdminPassword
        AST.Set-OSCustomizationNicMapping
        AST.New-VM
        AST.Set-VM                         -serverName $serverName
        AST.Start-Sleep                    -t 45 -Message  "Creating VM." -ShowRemaining
        AST.Start-VM                       -serverName $serverName
        AST.Start-Sleep                    -t 160 -Message "Applying OS Customization Spec." -ShowRemaining
        AST.Wait-VMTools                   -serverName $serverName
        AST.Test-GuestReady                -serverName $serverName
        AST.Update-VMTools                 -serverName $serverName


        ####################################################
        ### Configure OS
        ####################################################

        $guestCreds = @{
            serverName         = $serverName 
            guestAdminID       = $guestAdminID 
            guestAdminPassword = $guestAdminPassword
        }

        AST.Invoke.Change-Description   @guestCreds -Description $description
        AST.Invoke.Activate-OS          @guestCreds
        AST.Invoke.Set-NetIPInterface   @guestCreds
        AST.Invoke.Rename-LocalComputer @guestCreds
 
        ####################################################
        ### Restart Computer - Required after Set-NetIPInterface
        ####################################################   

        AST.Invoke.Shutdown-GuestOS @guestCreds
        AST.Start-Sleep             -t 60 -Message "Waiting for Guest to ShutDown." -ShowRemaining
        AST.Start-VM                -ServerName    $serverName
        AST.Start-Sleep             -t 90 -Message "Waiting for Restart." -ShowRemaining
               
        ####################################################
        ### Join Domain
        ####################################################
       
        AST.Invoke.Join-Domain          @guestCreds -Domain $domain -oUPath $oUPath -adAdminID $adAdminID -adAdminPassword $adAdminPassword

        ####################################################
        ### Restart Computer - Required after Join-Domain
        ####################################################   

        AST.Invoke.Shutdown-GuestOS @guestCreds
        AST.Start-Sleep             -t 60 -Message "Waiting for Guest to ShutDown." -ShowRemaining
        AST.Start-VM                -ServerName $serverName
        AST.Start-Sleep             -t 90 -Message "Waiting for Restart." -ShowRemaining
        

        ####################################################
        ### Install Software
        ####################################################        

        AST.Install-Lumension
        AST.Install-Symantec
        AST.Install-IPMonitor
        AST.Add-WindowsFeatures

        ####################################################
        ### Send Notification
        ####################################################

        AST.Send-Notification
    }

    END {
    
        $script:AutomationStopTime = Get-Date
        $global:AutomationTime = ($AutomationStopTime-$AutomationStartTime)
        Write-Host "END: - "  (Get-PSCallStack)[1].Command -ForegroundColor Magenta
        Write-Host `r`n`r`n('=' * 75)`n "AST.Server.Automation: Total Execution Time:`t" $AutomationTime `r`n('=' * 75)`r`n -ForegroundColor Gray
        Stop-Transcript
    }

}



