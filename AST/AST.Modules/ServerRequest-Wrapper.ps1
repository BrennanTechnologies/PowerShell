
#########################################################
### Get Parameters from Wrapper
#########################################################

Param(
        [Parameter(Mandatory=$true)][String]$serverName,
        [Parameter(Mandatory=$true)][String]$domain,
        [Parameter(Mandatory=$true)][String]$oUPath,
        [Parameter(Mandatory=$true)][String]$description,
        [Parameter(Mandatory=$true)][String]$vCenter,
        [Parameter(Mandatory=$true)][String]$vMHost,
        [Parameter(Mandatory=$true)][String]$vMTemplate,
        [Parameter(Mandatory=$true)][String]$datastore,
        #[Parameter(Mandatory=$true)][String]$location,
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

function AST.Automation.Invoke-Script {

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    ##############################
    ### Set Script Name & Path
    ##############################
        
    $scriptName = "AST.Automation.ps1"
    $script = $PSScriptRoot + "\AST.Automation\" + $scriptName

    ##############################
    ### Call Script
    ##############################
    
    Write-Host "Calling Script: " $script -ForegroundColor Magenta
    #. $script @params
    
    
    Invoke-Command -ScriptBlock {& $script @serverParams}

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

& {
    BEGIN 
    {
        $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray   
        Write-Host "BEGIN: - "  (Get-PSCallStack)[1].Command -ForegroundColor Magenta
    
        Write-Host ("= " * 80 )`r`n (" " * 30) $MyInvocation.ScriptName `r`n("= " * 80) -ForegroundColor Green
    }



    PROCESS 
    {
        Write-Host "PROCESS: - "  (Get-PSCallStack)[1].Command -ForegroundColor Magenta

        $serverParams = @{
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
    
        Write-Host "Params Passed to script: " -ForegroundColor Cyan
        $serverParams

        #####################################
        ### Invoke Automation Scripts
        #####################################
    
        AST.Automation.Invoke-Script @serverParams

    }

    END 
    {
        Write-Host "END: - "(Get-PSCallStack)[1].Command -ForegroundColor Magenta
    }
}


Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray

