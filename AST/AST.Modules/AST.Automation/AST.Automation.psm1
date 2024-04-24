

function AST.Install-VMWareModules
{
    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Installing VMWare Modules:" -ForegroundColor DarkCyan

    Get-Module -ListAvailable VM*
    Install-PackageProvider -Name NuGet
    Find-Module -Name VMware.PowerCLI
    Install-Module -Name VMware.PowerCLI -Scope CurrentUser -AllowClobber

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Set-PowerCLIConfiguration {

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray    

    Write-Host "Set PowerCLI Configuration:" -ForegroundColor DarkCyan

    #############################################
    ### SetPowerCLI Configuration
    #############################################

    #Get-PowerCLIConfiguration
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -ParticipateInCeip $false -Confirm:$false -Scope User

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Connect-VIServer {
    
    Param(
        [Parameter(Mandatory=$true)][String]$vCenter,
        [Parameter(Mandatory=$false)][String]$User,
        [Parameter(Mandatory=$false)][String]$Password
     )    
     
    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### Connect to vCenter
    #############################################
    if (-not $global:DefaultVIServers) {
        try {
            Write-Host "Connecting to vCenter: $vCenter" -ForegroundColor DarkCyan
            Connect-VIServer -Server $vCenter -User amstock\cbrennan -Password Welcome2019
        } catch {
            Write-Error -Message "ERROR: Could not Connect to VI Server." #$Error[0].Exception.Message -ErrorAction Continue -ErrorVariable +ASTError
        }
    } else {
        Write-Host "Using Current VI Server Connection: " $global:DefaultVIServers[0].Name
    }
    <#
    try {
        if (-not $global:DefaultVIServers[0].name) {
        
            if ($VIServerName) {
                Connect-VIServer -Server $VIServerName -User amstock\cbrennan -Password Welcome2019

            } else {

                Connect-VIServer -Server astvc03.amstock.com -User amstock\cbrennan -Password Welcome2019
            } 
        } else {
            Write-Host "Already Connected to VI-Server: $global:DefaultVIServers[0].name"
        }
    } catch {

        Write-Error -Message "ERROR: Could not Connect to VI Server." #$Error[0].Exception.Message -ErrorAction Continue -ErrorVariable +ASTError
        #"ERROR: Couldnt Connect to VI Server
    }

    #>

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Get-VMTemplate {

    Param(
        [Parameter(Mandatory=$false)][String]$VMTemplateName
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### Get VM Template
    #############################################

    if(-NOT $VMTemplateName) 
    {
        $VMTemplateName = "Windows 2016 Template Not Hardened ast" 
    }
    
    try {
        $VMTemplate = Get-Template -Name $VMTemplateName
        Write-Host "Template Found: " -ForegroundColor Cyan -NoNewline
        Write-Host $VMTemplate.Name -ForegroundColor White
    } catch {
        Write-Error -Message "ERROR: $Error[0].Exception.Meaasge" -ErrorAction Continue -ErrorVariable +ASTError
    }
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray


    Return $VMTemplate.Name
}

function AST.New-OSCustomizationSpec {
    Param(
        [Parameter(Mandatory=$true)][String]$guestAdminID,
        [Parameter(Mandatory=$true)][String]$guestAdminPassword
     )
    
    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray
    
    #########################################
    ### Compile PSCredentials
    #########################################
    

    $password   = ConvertTo-SecureString $guestAdminPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ('root', $password)

    #########################################
    ### OSCustomizationSpec Parameters
    #########################################
    $name                       = "ASTOSCustomizationSpec"
    $fullName                   = $GuestAdminID
    $adminPassword              = $GuestAdminPassword
    $orgName                    = "AST Financial"
    $workgroup                  = "Workgroup"
    #$domain                     = "Workgroup"
    #$DomainCredentials          = $credential
    $changeSid                  = $true
    #$dnsServer                  = "1.1.1.1"
    #$dnsSuffix                  = "dns.suffix.com"
    $oSType                     = "Windows"
    $type                       = "NonPersistent"        
    #$productKey                = ""
    #$domain                    = ""
    #$domainCredentials         = ""
    #$domainPassword            = ""
    #$domainUsername            = ""

    $OSCustomizationSpecParams = @{
        Name                    = $Name
        FullName                = $FullName
        AdminPassword           = $AdminPassword
        OrgName                 = $OrgName
        WorkGroup               = $Workgroup
        #Domain                  = $Domain
        #DomainCredentials       = $DomainCredentials
        ChangeSid               = $true
        #DnsServer               = $DnsServer
        #DnsSuffix               = $DnsSuffix
        OSType                  = $OSType
        Type                    = $Type
        #ProductKey             = $ProductKey
        #Domain                 = $Domain
        #DomainCredentials      = $DomainCredentials
        #DomainPassword         = $DomainPassword
        #DomainUsername         = $DomainUsername
    }

    
    ########################################
    ### Delete Existing OSCustomizationSpec
    ########################################

    if (Get-OSCustomizationSpec -Name $Name -ErrorAction SilentlyContinue) 
    {
        Write-Host "Removing Existing OSCustomizationSpec: " $OSCustomizationSpec -ForegroundColor Yellow
        Remove-OSCustomizationSpec -OSCustomizationSpec $Name -Confirm:$false
    }

    ########################################
    ### Create OSCustomizationSpec
    ########################################
    Write-Host "New OSCustomizationSpec Parameters: " -ForegroundColor DarkCyan
    $OSCustomizationSpecParams

    Write-Host "Creating OSCustomizationSpec: " -ForegroundColor Cyan
    New-OSCustomizationSpec -Name $name -FullName $fullName -AdminPassword $adminPassword -OrgName $orgName -OSType $oSType -Type $type -ChangeSid:$true -workgroup "Workgroup"  #-Domain $Domain

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Set-OSCustomizationNicMapping {

        $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

        ###----------------------------------------------------------
        ### Create New OSCustomizationSpec NIC Mapping
        ###----------------------------------------------------------    
        
        $OSCustomizationSpecName = "ASTOSCustomizationSpec"

Get-OSCustomizationSpec –Name ASTOSCustomizationSpec | Get-OSCustomizationNicMapping

        $OSCustomizationNicMapping = {
            IpMode          = 'UseStaticIp'
            IpAddress       = $IPAddress 
            SubnetMask      = $SubnetMask 
            DefaultGateway  = $DefaultGateway 
            #Dns             = $PrimaryDNS + "," + $SecondaryDNS
            Dns             = $Dns
        }
        
        Write-Host "Creating - OSCustomizationNicMapping  : $OSCustomizationSpecName" -ForegroundColor Cyan
        
        $NicMapping = @{

         IPMode         = "UseStaticIp "
         IpAddress      = $IPv4Address 
         SubnetMask     = $SubnetMask 
         DefaultGateway = $DefaultGateway 
         #Dns            = $PrimaryDNS,$SecondaryDNS
         Dns            = $Dns
        }

        $Dns = $Dns.Split(",")[0] + "," + $Dns.Split(",")[1]

        Get-OSCustomizationSpec -Name $OSCustomizationSpecName | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IPMode UseStaticIp -IpAddress $IPAddress -SubnetMask $SubnetMask -DefaultGateway $DefaultGateway -Dns $Dns.Split(",")[0],$Dns.Split(",")[1] #+ "," + $Dns.Split(",")[1]) #$Dns #-Dns $PrimaryDNS,$SecondaryDNS

        Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


function AST.New-VM {

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### Create New VM
    #############################################
    
    $VMTemplate        = "Windows 2016 Template Not Hardened ast"
    $OSCustomizationSpecName = "ASTOSCustomizationSpec"

    ### New VM
    $NewVMParams = @{
        vMHost              = $VMHost
        name                = $ServerName 
        template            = $VMTemplate 
        #location            = $vCenterFolder 
        #resourcePool        = $ResourcePool 

        datastore           = $DataStore 
        #numCPU              = $NumCpu
        #memoryGB            = $MemoryGB
        #portGroup           = $VLAN
        oSCustomizationSpecName = "ASTOSCustomizationSpec"
        diskStorageFormat   = "Thin"
        cD                  = $true
    }
    
    Write-Host "New VM Parameters: " -ForegroundColor Cyan
    $NewVMParams

    if (Get-VM -Name $ServerName -ErrorAction SilentlyContinue) {

        Write-Host "A VM Already exists with this Name!." -ForegroundColor Red
        
        ### Send Alert Email
        ###---------------------------
        AST.Automation.Send-Alert
        exit

    }
    else
    {

        $PortGroup = (Get-VirtualPortGroup -Name $VLAN -VMHost $VMHost | Select -Unique)

        #VMware.VimAutomation.Core\New-VM -Template $vMTemplate -VMHost $VMHost -Name $ServerName 
        VMware.VimAutomation.Core\New-VM -Name $serverName -VMHost $VMHost -Template $vMTemplate -Datastore $datastore -OSCustomizationSpec $oSCustomizationSpecName -diskStorageFormat Thin #-ResourcePool $ResourcePool -Location $vCenterFolder

        #-Datastore $DataStore -DiskGB $DiskGB
        #-CD:$true #-Portgroup $PortGroup

         #-NumCpu $NumCPU -MemoryGB $MemoryGB -Datastore $DataStore -DiskGB $DiskGB -Notes $Description -Portgroup $PortGroup -CD:$true
        #VMware.VimAutomation.Core\New-VM -VMHost $VMHost -Name $ServerName -NumCpu $NumCPU -MemoryGB $MemoryGB -Datastore $DataStore -DiskGB $DiskGB -Notes $Description -Portgroup $PortGroup -CD:$true -Template $vMTemplate
        #New-VM @NewVMParams
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Set-VM {
    Param(
        [Parameter(Mandatory=$true)][String]$serverName
     )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    try
    {
        Set-VM -VM $serverName -NumCpu $NumCPU -MemoryGB $MemoryGB -Notes $Description -confirm:$false
    }
    catch
     {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Start-VM {
    Param(
        [Parameter(Mandatory=$true)][String]$serverName
     )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    
    Write-Host "Starting VM: $serverName" -ForegroundColor Cyan
    
    try
    {
        Start-VM $serverName | Wait-Tools
    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Start-Sleep                   ### <------------------
{
    Param(
    [Parameter(Mandatory = $False)][int16]$t,
    [Parameter(Mandatory = $False)][string]$Message,
    [Parameter(Mandatory = $False)][switch]$ShowRemaining
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    If(!$t){$t = 60}

    if($Message)
    {
        Write-Host `r`n('- ' * 25)`r`n "AST.AUTOMATION.START-SLEEP: $t seconds. $Message" `r`n('- ' * 25)`r`n -ForegroundColor Cyan
    } 
    else
    {
        Write-Host `r`n('- ' * 25)`r`n "AST.AUTOMATION.START-SLEEP: $t seconds" `r`n('- ' * 25)`r`n -ForegroundColor Cyan
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

        Write-Progress -Activity "AST START-SLEEP - for $t seconds: " -SecondsRemaining $i -CurrentOperation "Completed: $a%" -Status $Status
        Start-Sleep 1
    }
    Write-Host "Done Sleeping." -ForegroundColor DarkGray
    Write-Progress -Activity 'Sleeping...' -Completed

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Wait-VMTools                    ### <------------------
{
    Param(
    [Parameter(Mandatory = $true)][string]$serverName
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Waiting for VMTools: " $serverName -ForegroundColor Yellow
    
    ###----------------------
    ### Setup Retry Loop
    ###----------------------
    $Retries            = 4
    $RetryCounter       = 0
    $Success            = $False
    $RetryTime          = 5
    $RetryTimeIncrement = $RetryTime
    $ErrorMsg        = "VM Tools Failed."
    $VMToolsTimeout     = 60

    while($Success -ne $True)
    {
        try
        {
            Start-Sleep -Seconds 60
            Wait-Tools -VM $serverName -TimeoutSeconds $VMToolsTimeout
            $Success = $True
            Write-Host "TEST: VM Tools Responded." -ForegroundColor Green
    
        }
        catch
        {
            if($RetryCounter -eq $Retries)
            {
                Throw "AST.Throw.Terminating.Error: $ASTErrorMsg"
            }
            else
            {
                ### Retry x Times
                ###----------------------------------
                $RetryCounter++

                ### Write Error Log
                ###---------------------------------
                Write-Error -Message ("ERROR.Exception.Message: " + $global:Error[0].Exception.Message) -ErrorAction Continue -ErrorVariable +ASTError 

                
                ### Error Handling Action
                ###----------------------------------               
                AST.Start-Sleep -Message "Retry CopyFiletoGuest." -t $RetryTime
                
                ### Set Bailout Value: Restart VM Tools
                ###----------------------------------
                if($RetryCounter -eq ($Retries - 1))
                {
                    Write-Host "Bailout Reached: Retry Counter..." $RetryCounter -ForegroundColor Magenta
                    AST.Restart-VMTools -VMName $VMName
                }
                $RetryTime = $RetryTime + $RetryTimeIncrement
            }
        }
    }
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Test-GuestReady                   ### <------------------
{
    Param ([Parameter(Mandatory = $True)][string]$serverName)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Waiting for Guest State:" $serverName -ForegroundColor Yellow

    $GuestState = [ordered]@{
        VMName                            = $VM
        VMHost                            = $VMHost
        State                             = $VM.Guest.State                                              ### <---- RETURN: Running/NotRunning
        ToolsRunningStatus                = $VM.ExtensionData.Guest.ToolsRunningStatus                   ### <---- RETURN: guestToolsRunning/guestToolsNotRunning
        guestOperationsReady              = $VM.ExtensionData.guest.guestOperationsReady                 ### <---- RETURN: True/False
        interactiveGuestOperationsReady   = $VM.ExtensionData.guest.interactiveGuestOperationsReady      ### <---- RETURN: True/False
        guestStateChangeSupported         = $VM.ExtensionData.guest.guestStateChangeSupported            ### <---- RETURN: True/False
    }

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
            $guestOperationsReady = (Get-VM -Name $serverName).ExtensionData.guest.guestOperationsReady
            if($guestOperationsReady -eq $True)
            {
                $Success = $True
                Write-Host "$FunctionName - Succeded: " $Success -ForegroundColor Green  
            }
            else
            {
                Write-Error -Message "GuestOperationsReady: False" -ErrorAction Continue -ErrorVariable +ASTError
            }
        }
        catch
        {
            if($RetryCounter -ge $Retries)
            {
                Throw "THROW.TERMINATING.ERROR: GuestOperationsReady Failed! "
            }
            else
            {
                ### Retry x Times
                ###--------------------
                $RetryCounter++
                
                ### Write Error Log
                ###---------------------------------
                Write-Error -Message ("ERROR.Exception.Message: " + $global:Error[0].Exception.Message) -ErrorAction Continue -ErrorVariable +ASTError
                if(-NOT(Test-Path -Path $ECIErrorLogFile)) {(New-Item -ItemType file -Path $ECIErrorLogFile -Force | Out-Null)}
                $ECIError | Out-File -FilePath $ECIErrorLogFile -Append -Force

                ### Error Handling Action
                ###----------------------------------                  
                AST.Start-Sleep -Message "Retry Invoke-VMScript." -t $RetryTimeOut

                ### Restart VM Tools
                ###--------------------                
                if($RetryCounter -eq ($Retries - 1))
                {
                    Write-Host "Bailout Reached: Retry Counter..." $RetryCounter -ForegroundColor Magenta
                    AST.Automation.Restart-VMTools -VMName $VMName
                }
                $RetryTimeOut = $RetryTimeOut + $RetryTimeIncrement
            }
        }
    }
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray 
}

function AST.Restart-VMTools                    ### <------------------
{
    Param ([Parameter(Mandatory = $True)][string]$VMName)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "Re-Starting VM Tools:" $serverName -ForegroundColor Yellow

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
        ### IMPORTANT:  Use These Args: "-ErrorAction SilentlyContinue -ErrorVariable +ASTError | Out-Null" 
        ### ---------   Because restarting VMTools will throw the following Invoke error:
        ###             "Invoke-VMScript - Index was outside the bounds of the array."
        #############################################################################################################

        Invoke-VMScript -ScriptText $RestartVMTools -VM $serverName -ScriptType Powershell -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword -ErrorAction SilentlyContinue -ErrorVariable +ASTError
        Start-Sleep -Seconds ($t * 2)
    }
    catch
    {
        ### Write Error Log
        Write-Error -Message ("AST.ERROR: " + $global:error[0].Exception.Message) -ErrorAction Continue -ErrorVariable +ASTError
        if(-NOT(Test-Path -Path $ASTErrorLogFile)) {(New-Item -ItemType file -Path $ASTErrorLogFile -Force | Out-Null)}
        $ASTError | Out-File -FilePath $ASTErrorLogFile -Append -Force
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
        Write-Error -Message ("AST.ERROR: " + $global:error[0].Exception.Message) -ErrorAction Continue -ErrorVariable +ASTError
        if(-NOT(Test-Path -Path $ASTErrorLogFile)) {(New-Item -ItemType file -Path $ASTErrorLogFile -Force | Out-Null)}
        $ASTError | Out-File -FilePath $ASTErrorLogFile -Append -Force

        ### Error Handling Action
        ###----------------------------------               
        #Throw-AbortError #<---- /w Email Alert
        Throw "THROW TERMINATING ERROR: VM Tools Not Running!"
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Invoke.Shutdown-GuestOS {
    Param(
        [Parameter(Mandatory=$true)][String]$serverName,
        [Parameter(Mandatory=$true)][String]$guestAdminID,
        [Parameter(Mandatory=$true)][String]$guestAdminPassword
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    ##########################################
    ### SHUTDOWN GUEST OS: 
    ##########################################

    $scriptText = {
        Stop-Computer -ComputerName #serverName#
    }
    
    ### Replace Parameters with #LiteralValues#
    ###--------------------------------------------------
    $replaceParams = @{"#serverName#"  = $serverName}
    
    foreach ($param in $replaceParams.GetEnumerator()) { $scriptText =  $scriptText -replace $param.Key,$param.Value}
    Write-Host "ScriptText: " -ForegroundColor DarkYellow
    $scriptText
        
    try
    {
        Write-Host "$functionName : $serverName" -ForegroundColor Cyan

        ########################################################
        ### Must Use Guest User Account w/ Local Admin Account
        ########################################################
        Invoke-VMScript -ScriptText $ScriptText -VM $serverName -GuestUser $guestAdminID -GuestPassword $guestAdminPassword -ErrorAction SilentlyContinue 
    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Update-VMTools {
    Param(
        [Parameter(Mandatory=$true)][String]$serverName
     )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### Update VM Tools
    #############################################
    
    Write-Host "$functionName - $serverName" -ForegroundColor Cyan

    try
    {
        Get-VMGuest $serverName | Update-Tools  
    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Invoke.Change-Description {
    Param(
        [Parameter(Mandatory=$true)][String]$serverName,
        [Parameter(Mandatory=$true)][String]$description,
        [Parameter(Mandatory=$true)][String]$guestAdminID,
        [Parameter(Mandatory=$true)][String]$guestAdminPassword
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### Change Description
    #############################################
   
    Write-Host "$functionName for: "  -ForegroundColor Cyan
    Write-Host "Server Name: " $serverName  -ForegroundColor Cyan
    Write-Host "Description: " $description -ForegroundColor Cyan

    $scriptText = {
        "Get-CimInstance -ClassName Win32_OperatingSystem | Set-CimInstance -Property @{Description =" + "#description#" + "} -ComputerName #serverName#"
    }

    ### Replace Parameters with #LiteralValues#
    ###--------------------------------------------------
    $replaceParams = @{
    "#description#" = $description
    "#serverName#"  = $serverName
    }
    
    foreach ($param in $replaceParams.GetEnumerator()) { $scriptText =  $scriptText -replace $param.Key,$param.Value}
    Write-Host "ScriptText: " -ForegroundColor DarkYellow
    $scriptText

    try
    {
        ########################################################
        ### Must Use Guest User Account w/ Local Admin Account
        ########################################################
        Invoke-VMScript -ScriptText $ScriptText -VM $serverName -GuestUser $guestAdminID -GuestPassword $guestAdminPassword -ScriptType Powershell 

    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
} 

function AST.Invoke.Rename-LocalComputer {
    Param(
        [Parameter(Mandatory=$true)][String]$serverName,
        [Parameter(Mandatory=$true)][String]$guestAdminID,
        [Parameter(Mandatory=$true)][String]$guestAdminPassword
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### Rename Local Computer
    #############################################
    
    Write-Host "$functionName : $serverName" -ForegroundColor Cyan
    
    $scriptText = {
        $currentName = (Get-CimInstance CIM_ComputerSystem).Name
        #$serverName = '"' + '#serverName#' + '"'

        Write-Host "Current Name : $currentName" 
        Write-Host "Server Name  : $serverName" 

        if($currentName -ne $serverName)
        {
            Rename-Computer –ComputerName . –NewName #serverName#            
        }
        else
        {
            Write-Host "The computer is already renamed."
        }
        
    }

    ### Replace Parameters with #LiteralValues#
    ###--------------------------------------------------
    $replaceParams = @{"#serverName#"  = $serverName}
    
    foreach ($param in $replaceParams.GetEnumerator()) {
        $scriptText =  $scriptText -replace $param.Key,$param.Value
    }

    Write-Host "ScriptText: " -ForegroundColor DarkYellow
    $scriptText


    try
    {
        ########################################################
        ### Must Use Guest User Account w/ Local Admin Account
        ########################################################
        Invoke-VMScript -ScriptText $ScriptText -VM $serverName -GuestUser $guestAdminID -GuestPassword $guestAdminPassword

    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Invoke.Set-NetIPInterface {
    Param(
        [Parameter(Mandatory=$true)][String]$serverName,
        [Parameter(Mandatory=$true)][String]$guestAdminID,
        [Parameter(Mandatory=$true)][String]$guestAdminPassword
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    Write-Host "$functionName" -ForegroundColor Cyan

    #############################################
    ### 
    #############################################
    
    $ScriptText = {
        $code = {
            $ifIndex = (Get-NetAdapter -Name "Ethernet0").ifIndex
            Set-NetIPInterface -InterfaceIndex $ifIndex -Dhcp Disabled -DadTransmits 0 -PolicyStore PersistentStore
        }
    
        Start-Process PowerShell.exe -Verb RunAs -ArgumentList $code
    }

    Write-Host "ScriptText: " -ForegroundColor DarkYellow
    $scriptText

<#
    netsh interface ipv4 show inte
    
    $Eth = netsh interface ipv4 show inte

    netsh interface ipv4 set interface 3 dadtransmits=0 store=persistent
    net stop dhcp
    sc config “dhcp” start=disabled
#>

    try
    {
        ########################################################
        ### Must Use Guest User Account w/ Local Admin Account
        ########################################################
        Invoke-VMScript -ScriptText $ScriptText -VM $serverName -GuestUser $guestAdminID -GuestPassword $guestAdminPassword        
    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Invoke.Activate-OS {

    Param(
        [Parameter(Mandatory=$true)][String]$serverName,
        [Parameter(Mandatory=$true)][String]$guestAdminID,
        [Parameter(Mandatory=$true)][String]$guestAdminPassword
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### Activating OS License Key
    #############################################
    
    Write-Host "$functionName : $serverName" -ForegroundColor Cyan

    Write-Host "Activating OS License Key:" -ForegroundColor DarkCyan

    $ScriptText = {
        Invoke-Expression -Command "slmgr /skms 172.17.100.108 //B /ato"
        #slmgr /skms 172.17.100.108 //B /ato
    }
    
    Write-Host "ScriptText: " -ForegroundColor DarkYellow
    $scriptText

    try
    {

        ########################################################
        ### Must Use Guest User Account w/ Local Admin Account
        ########################################################
        Invoke-VMScript -ScriptText $ScriptText -VM $serverName -GuestUser $guestAdminID -GuestPassword $guestAdminPassword
    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Invoke.Join-Domain
{
    Param(
        [Parameter(Mandatory=$true)][String]$serverName,
        [Parameter(Mandatory=$true)][String]$domain,
        [Parameter(Mandatory=$true)][String]$adAdminID,
        [Parameter(Mandatory=$true)][String]$adAdminPassword,
        [Parameter(Mandatory=$true)][String]$guestAdminID,
        [Parameter(Mandatory=$true)][String]$guestAdminPassword,
        [Parameter(Mandatory=$true)][String]$oUPath
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### Join Domain
    #############################################

    Write-Host "$functionName : $domain" -ForegroundColor DarkCyan
    Write-Host "Joining $serverName to Domain: $domain" -ForegroundColor Cyan


    $adAdminID = "cbrennan"
    $adAdminPassword = "Welcome2019"
    $adAdminID = "serverdeploy"
    $adAdminPassword = '@cT4cHr1$t0ph'

    $ScriptText = {

        $adAdminID        = "'" + '#adAdminID#' + "'"
        $adAdminPassword  = "'" + '#adAdminPassword#' + "'"
        $serverName       = "'" + '#ServerName#' + "'"
        $domain           = "'" + '#domain#' + "'"
        $oUPath           = "'" + '#oUPath#' + "'"

        $adAdminID = "cbrennan"
        $adAdminPassword = "Welcome2019"

    $adAdminID = "serverdeploy"
    $adAdminPassword = '@cT4cHr1$t0ph'

        $adAdminPassword = ConvertTo-SecureString $adAdminPassword -AsPlainText -Force
        $PSCredentials =  New-Object System.Management.Automation.PSCredential ($adAdminID, $adAdminPassword)

        [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($adAdminPassword))

        Write-Host "adAdminID: " $adAdminID
        Write-Host "adAdminPassword: " $adAdminPassword
        Write-Host "ServerName: " $ServerName
        Write-Host "domain: " $domain
        Write-Host "OUPath: " $oUPath
        
        Add-Computer  -Credential $PSCredentials -Force -Verbose -ComputerName #serverName# -DomainName #domain# 
        #-OUPath #oUPath#
    }

    ### Replace Parameters with #LiteralValues#
    ###--------------------------------------------------
    $replaceParams = @{
        "#adAdminID#"           = $adAdminID
        "#adAdminPassword#"     = $adAdminPassword
        "#domain#"              = $domain
        "#serverName#"          = $serverName
        "#guestAdminID#"        = $guestAdminID
        "#guestAdminPassword#"  = $guestAdminPassword
        "#oUPath#"              = $oUPath
    }
    
    foreach ($param in $replaceParams.GetEnumerator()) 
    {
        $scriptText =  $scriptText -replace $param.Key,$param.Value
    }

    Write-Host "ScriptText: " -ForegroundColor DarkYellow
    $scriptText

    try
    {
        ########################################################
        ### Must Use Guest User Account w/ Local Admin Account
        ########################################################

        
        Invoke-VMScript -ScriptText $ScriptText -VM $serverName -GuestUser $guestAdminID -GuestPassword $guestAdminPassword
    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }
        

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Add-WindowsFeatures {

    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### 
    #############################################

    Write-Host "$functionName : $serverName" -ForegroundColor DarkCyan

    $WindowsFeatures = @{
        IIS         = "Web-Server"
        #$DotNet      = ""
    }

    foreach($Feature in $WindowsFeatures) {

    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray


}

function AST.Install-Lumension {

    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### 
    #############################################
    
    Write-Host "$functionName : $VM" -ForegroundColor DarkCyan

    [scriptblock]$scriptBlock = {

    }

    try
    {

    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Install-Symantec {
    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### 
    #############################################
    
    Write-Host "$functionName : $VM" -ForegroundColor DarkCyan

    [scriptblock]$scriptBlock = {

    }

    try
    {

    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Install-IPMonitor {
    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### 
    #############################################
    
    [scriptblock]$scriptBlock = {

    }

    Write-Host "$functionName : $VM" -ForegroundColor DarkCyan

    try
    {

    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Send-Alert {

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### Send Alert
    #############################################

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
    $Message += "<font size='3';color='gray'><i>Server Automation</i></font><br>"
    $Message += "<font size='5';color='NAVY'><b>Automation Error Alert</b></font><br>"
    $Message += "<font size='2'>Alert Date:  " + (Get-Date) + "</font>"
    $Message += "<br><br><br><br>"
    $Message += "<font size='3';color='black'>WARNING: This Server <b> COULD NOT </b> be provisioned.</font>"
    $Message += "<br><br>"

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


    ### Email HTML Report
    ###------------------------

    #Name:    relay.amstock.com
    #$Address:  192.168.10.13

    $From   = "cbrennan@eci.com"
    $To      = $SMTPTo
    $To      = "cbrennan@eci.com"
    $Subject = "Server Provisioning Alert"

    $SMTP    = 192.168.10.13
    
    
    #$To     = "cbrennan@eci.com,sdesimone@eci.com,wercolano@eci.com,rgee@eci.com"
    #$To     = "cbrennan@eci.com,sdesimone@eci.com"


    ### Email Message
    ###----------------------------------------------------------------------------
    Write-Host `r`n`r`n`r`n("=" * 50)`n "Sending Alert - $ErrorMsg" `r`n("=" * 50)`r`n`r`n -ForegroundColor Yellow
    Write-Host "TO: " $To

    

    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP



    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Send-Notification {

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### Send Alert
    #############################################

    ############################
    ### HTML Header
    ############################
    $Header  = $null
    #$Header += "<style>"
    #$Header += "BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}"
    #$Header += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    #$Header += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}"
    #$Header += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #FFEFD5}"
    #$Header += "</style>"
    
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
    $Message += "<font font-family: Verdana, Arial, Helvetica, sans-serif;size='3';color='gray'><i>New Server Automation</i></font><br>"
    $Message += "<font font-family: Verdana, Arial, Helvetica, sans-serif;size='5';color='NAVY'><b>New Server Notification</b></font><br>"
    $Message += "<font font-family: Verdana, Arial, Helvetica, sans-serif;size='2'>Date:  " + (Get-Date) + "</font>"
    $Message += "<br><br><br>"

    ### Server Specs
    ###-----------------------------------
    $Message += "<font font-family: Verdana, Arial, Helvetica, sans-serif;font size='3';color='NAVY'><b>SERVER SPECIFICATIONS:</b></font><br>"
    $Message += "<table border=0>"
    $Message += "<font size='2';color='NAVY'>"
    $Message += "<tr><td align='right'>Server Name : </td><td align='left'>"               + $serverName                + "</td></tr>"
    $Message += "<tr><td align='right'>AD Domain : </td><td align='left'>"                + $domain                 + "</td></tr>"
    $Message += "<tr><td align='right'>Description : </td><td align='left'>"                  + $description                   + "</td></tr>"
    $Message += "<tr><td align='right'>vCenter : </td><td align='left'>"        + $vCenter         + "</td></tr>"
    $Message += "<tr><td align='right'>VM Host : </td><td align='left'>"                    + $vMHost                     + "</td></tr>"
    #$Message += "<tr><td align='right'>Server Parameters : </td><td align='left'>"                    + $serverParams                     + "</td></tr>"
    $Message += "</table>"
    $Message += "<br>"
    
    ### Server Params
    ###-----------------------------------
    $Message += "<font font font-family: Verdana, Arial, Helvetica, sans-serif;size='3';color='Gray'><b>SERVER PARAMETERS:</b></font><br>"
    $Message += "<table border=0>"
    foreach($param in $serverParams.GetEnumerator())
    {

        $Message += "<tr><td align='right'>" + $param.key + ": </td><td align='left'>"                    + $param.Value                     + "</td></tr>"
    }

    $Message += "</table>"
    $Message += "<br>"

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


    ### Email HTML Report
    ###------------------------

    #Name:    relay.amstock.com
    #$Address:  192.168.10.13

    $From   = "cbrennan@astfinancial.com"
    $To      = "cbrennan@astfinancial.com"
    $Subject = "New Server Provisioning Notification"

    $SMTP    = "192.168.10.13"
    
    
    #$To     = "cbrennan@eci.com,sdesimone@eci.com,wercolano@eci.com,rgee@eci.com"
    #$To     = "cbrennan@eci.com,sdesimone@eci.com"


    ### Email Message
    ###----------------------------------------------------------------------------
    Write-Host `r`n`r`n`r`n("=" * 50)`n "Sending Notification - $Subject" `r`n("=" * 50)`r`n`r`n -ForegroundColor Green
    Write-Host "TO: " $To

    

    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP



    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Delete-VM {

    Param(
        [Parameter(Mandatory=$true)][String]$VM
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### Remove-VM
    #############################################
    
    Write-Host "$functionName : $VM" -ForegroundColor DarkCyan

    try
    {
        #$VM = "astdeploy-4"
        Remove-VM -VM $VM -DeletePermanently -Confirm:$true
    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

###########################################
function AST.Get-ISOs {

    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### 
    #############################################

    ### Find ISO's
    dir VMware.VimAutomation.Core\VimDatastore::\LastConnectedVCenterServer\Amstock\BKVNX_2TB_SATA1\ISO
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}
function AST.Update-Server {

    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### 
    #############################################

    Write-Host "$functionName : $VM" -ForegroundColor DarkCyan

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}
function AST.Set-VLAN {

    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### 
    #############################################
    
    Write-Host "$functionName : $VM" -ForegroundColor DarkCyan

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}
function AST.Set-IPv4 {

    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### 
    #############################################

    Write-Host "$functionName : $VM" -ForegroundColor DarkCyan
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}
function AST.Backup-Image {

    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### 
    #############################################

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}
function AST.Backup-Data {

    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### 
    #############################################

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

########################################

function AST.Automation.Verb-Noun {

    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $functionName `r`n('-' * 75) -ForegroundColor Gray

    #############################################
    ### 
    #############################################
    
    [scriptblock]$scriptBlock = {

    }

    try
    {
        Write-Host "$functionName" -ForegroundColor Cyan
    }
    catch
    {
        Write-Error -Message "ERROR: $global:Error[0].Exception.Message" -ErrorAction Continue -ErrorVariable +ASTError
        #AST.Automation.Send-Alert
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}





function AST.Replace-Params {
    Param(
        [Parameter(Mandatory=$false)][String]$scriptText
     )
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

}