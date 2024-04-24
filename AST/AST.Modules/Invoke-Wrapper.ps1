cls

#####################################
### Input Parameters (fromWeb Page)
#####################################

$global:serverName         = "astdeploy-1"
$global:domain             = "amstock.com"
#$global:oUPath             = "OU=UAT,OU=Servers_Secured,DC=amstock,DC=com"
$global:oUPath             = "OU=Servers_Secured,DC=amstock,DC=com"
$global:description        = "AST Deployment Server"
$global:vCenter            = "ASTVC03.amstock.com"
$global:vMHost             = "producs-c1s6.amstock.com"
$global:vMTemplate         = "Windows 2016 Template Not Hardened ast"
$global:datastore          = "PURE_AST_T1_Dev3_258"
#$global:location          `= "x"
$global:vLAN               = "VLAN100"
$global:oS                 = "Win 2016"
$global:iPAddress          = "172.17.100.251"
$global:subnetMask         = "255.255.255.0"
$global:defaultGateway     = "172.17.100.1"
$global:dns                = "172.17.100.138,172.17.100.135"
$global:numCpu             = "2"
$global:memoryGB           = "4"
$global:diskGB             = "50"
$global:owner              = "Chris Brennan"
$global:team               = "Server Engineering"
$global:environment        = "UAT"
#$global:oSDrive           = "C"
#$global:oSDriveSize       = "60"
$global:backupType         = "Image"
$global:adAdminID          = "serverdeploy"
$global:adAdminPassword    = '@cT4cHr1$t0ph'
$global:guestAdminID       = "Administrator"
$global:guestAdminPassword = 'Password1234!'

$wrapperParams = @{
    serverName         = $serverName
    domain             = $domain
    oUPath             = $oUPath
    description        = $description
    vCenter            = $vCenter
    vMHost             = $vMHost
    vMTemplate         = $vMTemplate
    datastore          = $datastore
    #location          = $location
    vLAN               = $vLAN
    oS                 = $oS
    iPAddress          = $iPAddress
    subnetMask         = $subnetMask
    defaultGateway     = $defaultGateway
    dns                = $dns
    numCpu             = $numCpu
    memoryGB           = $memoryGB
    diskGB             = $diskGB
    owner              = $owner
    team               = $team
    environment        = $environment
    #oSDrive           = $oSDrive
    #oSDriveSize       = $oSDriveSize
    backupType         = $backupType
    adAdminID          = $adAdminID
    adAdminPassword    = $adAdminPassword
    guestAdminID       = $guestAdminID
    guestAdminPassword = $guestAdminPassword
}

#########################
#### Export Parameters
#########################

$outFile = "c:\scripts\DeployedServers.txt"
Write-Host "Adding Parameters to File: $outFile" -ForegroundColor Cyan
$wrapperParams
$wrapperParams | Out-File -FilePath $outFile -Append -Force


function AST.Automation.Invoke-Wrapper {

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray  

    ##############################
    ### Set Script Name & Path
    ##############################

    $scriptName = "ServerRequest-Wrapper.ps1"
    $wrapper = $PSScriptRoot + "\" + $scriptName
    
    ##############################
    ### Call Wrapper Script
    ##############################

    Write-Host "Calling Wrapper: " $wrapper -ForegroundColor Magenta
    #. $wrapper @wrapperParams
    Invoke-Command -ScriptBlock {& $wrapper @wrapperParams}

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

AST.Automation.Invoke-Wrapper