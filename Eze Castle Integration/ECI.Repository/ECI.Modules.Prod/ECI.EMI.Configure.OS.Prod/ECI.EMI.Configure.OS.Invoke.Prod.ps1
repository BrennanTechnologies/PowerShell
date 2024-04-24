#############################################
### Invoke Commands on Guest from vCenter
### ECI.EMI.Automation.OS.Invoke.ps1
#############################################

Param(
    [Parameter(Mandatory = $True)] [string]$ServerID,
    [Parameter(Mandatory = $True)] [string]$ConfigurationMode,
    [Parameter(Mandatory = $True)] [string]$HostName,
    [Parameter(Mandatory = $True)] [string]$ServerRole,
    [Parameter(Mandatory = $True)] [string]$IPv4Address,
    [Parameter(Mandatory = $True)] [string]$SubnetMask,
    [Parameter(Mandatory = $True)] [string]$DefaultGateway,
    [Parameter(Mandatory = $True)] [string]$PrimaryDNS,
    [Parameter(Mandatory = $True)] [string]$SecondaryDNS,
    [Parameter(Mandatory = $True)] [string]$ClientDomain,
    [Parameter(Mandatory = $True)] [string]$AdministrativeUserName,
    [Parameter(Mandatory = $True)] [string]$AdministrativePassword
)

function Rename-ECI.EMI.Configure.OS.Invoke.LocalAdmin
{
    Param(
    [Parameter(Mandatory = $True)] [string]$NewName,
    [Parameter(Mandatory = $True)] [string]$LocalAdminName,
    [Parameter(Mandatory = $True)] [string]$LocalAdminPassword
    )
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $ECILocalAdminName = $NewName

    $Params = @{
        "#ECILocalAdminName#" = $ECILocalAdminName
    }

    Write-Host `r`n("=" * 20)`r`n"RENAMING LOCAL ADMIN:"`r`n("=" * 20)`r`n -ForegroundColor Yellow
    Write-Host "Old LocalAdminName   : $LocalAdminName"     -ForegroundColor Cyan
    Write-Host "New LocalAdminName   : $ECILocalAdminName"  -ForegroundColor Cyan

    $RenameLocalAdmin ={
        ### Use .NET to Find the Current Local Administrator Account
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $ComputerName         = [System.Net.Dns]::GetHostName()
        $PrincipalContext     = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $ComputerName)
        $UserPrincipal        = New-Object System.DirectoryServices.AccountManagement.UserPrincipal($PrincipalContext)
        $Searcher             = New-Object System.DirectoryServices.AccountManagement.PrincipalSearcher
        $Searcher.QueryFilter = $UserPrincipal

        ### The Administrator account is the only account that has a SID that ends with “-500”
        $Account = $Searcher.FindAll() | Where-Object {$_.Sid -Like "*-500"}
        $CurrentAdminName = $Account.Name
           
        $ECILocalAdminName = "#ECILocalAdminName#" 

        Rename-LocalUser -Name $CurrentAdminName -NewName $ECILocalAdminName -ErrorAction SilentlyContinue | Out-Null
    }


    ### Inject Variables into ScriptText Block
    ### ---------------------------------------
    foreach ($Param in $Params.GetEnumerator())
    {
        $RenameLocalAdmin =  $RenameLocalAdmin -replace $Param.Key,$Param.Value
    }

    try
    {
        ### IMPORTANT! Rename-Admin will genererate an excpected error, this is expected. Use "-ErrorAction SilentlyContinue | Out-Null".
        Invoke-VMScript -ScriptText $RenameLocalAdmin -VM $VMName -ScriptType Powershell -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword -ErrorAction SilentlyContinue | Out-Null 
    }
    catch
    {
        Write-ECI.ErrorStack
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

#######################################
### ORIGINAL: Execute Invoke Process
#######################################
[ScriptBlock]$BootStrapModuleLoader = 
{
    ipconfig /all
    ### BEGIN: Import BootStrap Module Loader
    Set-ExecutionPolicy ByPass -Scope CurrentUser
    $AcctKey=ConvertTo-SecureString -String "VSRMGJZNI4vn0nf47J4bqVd5peNiYQ/8+ozlgzbuA1FUnn9hAoGRM9Ib4HrkxOyRJkd4PHE8j36+pfnCUw3o8Q==" -AsPlainText -Force
    $Credentials=$Null
    $Credentials=New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\eciscripts", $AcctKey
    $RootPath="\\eciscripts.file.core.windows.net\clientimplementation"
    New-PSDrive -Name V -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Persist -Scope Global
    #. "\\eciscripts.file.core.windows.net\clientimplementation\Root\ECI.Root.ModuleLoader.ps1" -Env dev
    ### END: Import BootStrap Module Loader
} 
function Invoke-ECI.ScriptText-ORIGINAL
{

    ### Replace Parameters with #LiteralValues#
    ### ---------------------------------------
    $Params = @{
    "#Env#"                           = $Env
    "#Environment#"                   = $Environment
    "#Step#"                          = $Step
    "#VMName#"                        = $VMName
    "#ServerID#"                      = $ServerID
    "#ServerRole#"                    = $ServerRole
    "#HostName#"                      = $HostName
    "#ClientDomain#"                  = $ClientDomain
    "#IPv4Addres#"                    = $IPv4Address
    "#SubnetMask#"                    = $SubnetMask
    "#DefaultGateway#"                = $DefaultGateway
    "#PrimaryDNS#"                    = $PrimaryDNS
    "#SecondaryDNS#"                  = $SecondaryDNS
    "#BuildVersion#"                  = $BuildVersion
    "#CDROMLetter#"                   = $CDROMLetter
    "#InternetExplorerESCPreference#" = $InternetExplorerESCPreference
    "#IPv6Preference#"                = $IPv6Preference
    "#NetworkInterfaceName#"          = $NetworkInterfaceName
    "#SMBv1#"                         = $SMBv1
    "#RDPResetrictionsPreference#"    = $RDPResetrictionsPreference
    "#RemoteDesktopPreference#"       = $RemoteDesktopPreference
    "#PageFileLocation#"              = $PageFileLocation
    "#PageFileMultiplier#"            = $PageFileMultiplier
    "#WindowsFirewallPreference#"     = $WindowsFirewallPreference
    "#AdministrativeUserName#"        = $AdministrativeUserName
    "#AdministrativePassword#"        = $AdministrativePassword
    "#AutomationLogPath#"             = $AutomationLogPath
    }

    ### Inject Variables into ScriptText Block
    ### ---------------------------------------
    foreach ($Param in $Params.GetEnumerator())
    {
        $ScriptText =  $ScriptText -replace $Param.Key,$Param.Value
    }

    ### Inject BootStrap Module Loader into VM Host                                          # <----- not using bootstrap ????
    ### ---------------------------------------
    #$ScriptText =  $ScriptText -replace '#BootStrapModuleLoader#',$BootStrapModuleLoader

    ### Debugging: Write ScriptText Block to Screen
    ### ---------------------------------------
    #Write-Host "ScriptText:`r`n" $ScriptText -ForegroundColor Gray

    ###############################
    ### Inovke VMScript
    ###############################
    #---------------------------------------------------------
    #   Invoke-VMScript
    #     -Verbose 
    #     -Debug
    #     | Select -ExpandProperty ScriptOutput
    #     | Select -ExpandProperty ExitCode
    #---------------------------------------------------------

    Write-Host `r`n('*' * 55)`r`n`r`n "      ~~~~~~~~ INVOKING OS CONFIGURATION ~~~~~~~~  " `r`n`r`n(' ' * 18) "STEP:" $Step `r`n`r`n " --------- THIS PROCESS MAY TAKE SEVERAL MINUTES ---------  " `r`n`r`n('*' * 55)`r`n -ForegroundColor Cyan

    ### -------------------------------------------
    ### Production: Run Invoke as Variable
    ### -------------------------------------------

    ### Test Guest
    ###---------------------------------
    Start-ECI.EMI.Automation.Sleep -t $WaitTime_StartSleep -Message "Test Guest State"          #<---- COMBINE
    Wait-ECI.EMI.Automation.VM.VMTools -VMName $VMName               #<---- COMBINE
    Test-ECI.EMI.VM.GuestState -VMName $VMName                       #<---- COMBINE
    #Test-ECI.EMI.Automation.VM.InvokeVMScript -VMName $VMName          #<---- COMBINE

    ### Invoke Script Block
    ### ---------------------------------------
    Write-Host "Invoke: Please Wait. This may take a while ..." -ForegroundColor Yellow
    Write-Host "ScriptText: " `r`n $ScriptText -ForegroundColor DarkMagenta
    
    function Try-InvokeScriptext
    {
        $script:Invoke             = $False
        $script:InvokeRetryCounter = 0
        $script:RetryCount         = 3 

        Invoke-VMScript -ScriptText $ScriptText -VM $VMName -ScriptType Powershell -GuestUser $Creds.LocalAdminName -GuestPassword $Creds.LocalAdminPassword -ErrorAction Stop -ErrorVariable +ECIError
    }

    function Retry-InvokeScriptext
    {
        Param([Parameter(Mandatory = $True)][int]$script:InvokeRetryCounter)

        for ($i=1; $i -le $RetryCount; $i++)
        {
            Start-ECI.EMI.Automation.Sleep -t 30 -Message "Retry"
            Write-Warning "Re-trying Invoke....  Count: " <# $InvokeRetryCounter #> -WarningAction Continue
            Write-Host    "ERROR:" `r`n $Error[0] -ForegroundColor Red

            Try-InvokeScriptext
        }

        Write-Host "ABORT ERROR!" -ForegroundColor Red
        #Write-ECI.ErrorStack 
    }

    try
    {
        Try-InvokeScriptext
    }

    catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.GuestOperationsUnavailable]
    {
        ### The guest operations agent could not be contacted.
        
        $script:InvokeRetryCounter ++
        Write-Host "ERROR     :" `r`n $Error[0] -ForegroundColor Red
        Write-Host "CAUGHT    : VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.GuestOperationsUnavailable" -ForegroundColor DarkGray
        Write-Host "EXCEPTION :" $Error[0].Exception.GetType().Fullname -ForegroundColor Red

        Write-Host "Restarting VMTools."  -ForegroundColor Yellow
        Restart-ECI.EMI.VM.VMTools
        
        Write-Host "Re-Try Invoke."  -ForegroundColor Yellow
        Retry-InvokeScriptext -InvokeRetryCounter $InvokeRetryCounter
    }
    
    catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.SystemError]
    {
        $script:InvokeRetryCounter ++
        Write-Host "ERROR     :" `r`n $Error[0] -ForegroundColor Red
        Write-Host "CAUGHT    :  System.Management.Automation.ErrorRecord"  -ForegroundColor DarkGray
        Write-Host "EXCEPTION :" $Error[0].Exception.GetType().Fullname     -ForegroundColor Red
        
        Write-Host "Restarting VMTools."  -ForegroundColor DarkGray
        Restart-ECI.EMI.VM.VMTools

        Write-Host "Re-Try Invoke."  -ForegroundColor DarkGray
        Retry-InvokeScriptext -InvokeRetryCounter $InvokeRetryCounter
    }
    
    catch
    {
        $script:InvokeRetryCounter ++
        Write-Host "ERROR     :" `r`n $Error[0] -ForegroundColor Red
        Write-Host "CAUGHT    :  Error"  -ForegroundColor DarkGray
        Write-Host "EXCEPTION :" $Error[0].Exception.GetType().Fullname -ForegroundColor Red

        Write-Host "Restarting VMTools."  -ForegroundColor DarkGray
        Restart-ECI.EMI.VM.VMTools -InvokeRetryCounter $InvokeRetryCounter

        Write-Host "Re-Try Invoke."  -ForegroundColor DarkGray
        Retry-InvokeScriptext
    }
    
    finally
    {
        if($Invoke)
        {
            ### Check Exit Code for any Errors
            ### ---------------------------------------
            if (($Invoke.ExitCode) -eq 0) 
            {
                $ExitCodeStatus = "Success"
                $ExitCodeColor  = "Green"
            }
            elseif (($Invoke.ExitCode) -ne 0) 
            {
                $ExitCodeStatus = "Failure"
                $ExitCodeColor  = "Red"
            }
            Write-Host "Invoke.ExitCode Status :"       $ExitCodeStatus      -ForegroundColor $ExitCodeColor
            Write-Host "Invoke.ExitCode        :"       $Invoke.ExitCode     -ForegroundColor $ExitCodeColor
            Write-Host "Invoke.ScriptOutput    : " `r`n $Invoke.ScriptOutput -ForegroundColor $ExitCodeColor
        }
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}
function Invoke-ECI.EMI.Configure.OS.InGuest--ORIGINAL
{
    Param([Parameter(Mandatory = $True)] [string]$Step)
    $ScriptText = {
    #BootStrapModuleLoader#       
    $global:Env                               = "#Env#"    
    $global:Environment                       = "#Environment#"    
    $global:Step                              = "#Step#"    
    $global:VMName                            = "#VMName#"    
    $global:ServerID                          = "#ServerID#"  
    $global:ServerRole                        = "#ServerRole#"  
    $global:HostName                          = "#HostName#"
    $global:ClientDomain                      = "#ClientDomain#"
    $global:IPv4Address                       = "#IPv4Addres#"
    $global:SubnetPrefixLength                = "#SubnetPrefixLength#"
    $global:DefaultGateway                    = "#DefaultGateway#"
    $global:PrimaryDNS                        = "#PrimaryDNS#"
    $global:SecondaryDNS                      = "#SecondaryDNS#"
    $global:BuildVersion                      = "#BuildVersion#"
    $global:CDROMLetter                       = "#CDROMLetter#"
    $global:InternetExplorerESCPreference     = "#InternetExplorerESCPreference#"
    $global:IPv6Preference                    = "#IPv6Preference#"
    $global:NetworkInterfaceName              = "#NetworkInterfaceName#"
    $global:SMBv1                             = "#SMBv1#"
    $global:RDPResetrictionsPreference        = "#RDPResetrictionsPreference#"
    $global:RemoteDesktopPreference           = "#RemoteDesktopPreference#"
    $global:PageFileLocation                  = "#PageFileLocation#"
    $global:PageFileMultiplier                = "#PageFileMultiplier#"
    $global:WindowsFirewallPreference         = "#WindowsFirewallPreference#"
    $global:AdministrativeUserName            = "#AdministrativeUserName#"
    $global:AdministrativePassword            = "#AdministrativePassword#"
    $global:AutomationLogPath                 = "#AutomationLogPath#"
    foreach($Module in (Get-Module -ListAvailable ECI.*)){Import-Module -Name $Module.Path -DisableNameChecking}
    . "C:\Program Files\WindowsPowerShell\Modules\ECI.Modules.$Env\ECI.EMI.Configure.OS.$Env\ECI.EMI.Configure.OS.InGuest.$Env.ps1" 
} # END ScriptText


    ### Clean the Scripttext Block
    ###-----------------------------------------------------------------------
    $CleanScriptText = $Null
    foreach( $Line in (((($Scripttext -replace("  ","") -replace("= ","=")) -replace(" =","=") ) -split("`r`n"))) | ? {$_.Trim() -ne ""} )
    {
        $Line = ($Line) + "`r`n"
        $CleanScriptText = $CleanScriptText + $Line
    }
   
    [int]$CharLimit = 2869
    [int]$CharCount = ($CleanScriptText | Measure-Object -Character).Characters
    if($CharCount -gt $CharLimit)
    {
        Write-Warning "The Scripttect block exceeds $CharLimit Chararter Limit."
    }
    elseif($CharCount -lt $CharLimit)
    {
        Write-Host "The Scripttect block is under the $CharLimit Chararter Limit." -ForegroundColor DarkGreen
    }
    Write-Host "Scripttext Character Count: " $CharCount -ForegroundColor DarkGray
    $ScriptText = $CleanScriptText
    Invoke-ECI.ScriptText
}
#######################################
#######################################


########################
### Execute the Script
########################
&{ 
    BEGIN
    {
        #Start-Transcript -IncludeInvocationHeader -OutputDirectory (Set-TranscriptPath) #<--(Set Path)
        #Start-ECI.Transcript -TranscriptPath "C:\Scripts\ServerRequest\TranscriptLogs\" -TranscriptName "ECI.EMI.Configure.OS.Invoke.$Env.ps1"

        ### Write Header Information
        ###---------------------------------
        Write-Host `r`n`r`n('*' * 100)`r`n (' ' * 20)" --------- STARTING OS CONFIGURATION --------- " `r`n('*' * 100)  -ForegroundColor Cyan
        Write-Host `r`n('-' * 50)`r`n                                                  -ForegroundColor DarkCyan
        Write-Host "Env         : " $Env                                               -ForegroundColor DarkCyan
        Write-Host "Environment : " $Environment                                       -ForegroundColor DarkCyan
        Write-Host "Script      : " (Split-Path (Get-PSCallStack)[0].ScriptName -Leaf) -ForegroundColor DarkCyan
        Write-Host `r`n('-' * 50)`r`n                                                  -ForegroundColor DarkCyan

        ### Script Setup
        ###---------------------------------
        $script:OSStartTime = Get-Date
        $global:VerifyErrorCount = 0
        

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!        
### Waiting after OS Customization/Reboot
Write-Host `r`n`r`n "*** Waiting after OS Customization/Reboot *** " -ForegroundColor Magenta

Start-ECI.EMI.Automation.Sleep -t $WaitTime_StartSleep -Message "Start OS Configuration"                                    #<--- COMBINE!!!!!
Wait-ECI.EMI.Automation.VM.VMTools -VMName $VMName                                        #<--- COMBINE!!!!!
#Wait-ECI.EMI.GuestState -VMName $VMName
#Interrogate-ECI.EMI.Automation.VM.GuestState -VMName $VMName -HostName $HostName
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        Set-ECI.EMI.Automation.LocalAdminAccount -Template ###  Set Creds here for Execution Policy
        Configure-ECI.EMI.Automation.ExecutionPolicyonVMGuest -VMName $VMName
        Delete-ECI.EMI.Automation.ServerLogs -HostName $HostName
        
        ### Install ECI Modules on Guest
        ###---------------------------------
        $Params = @{
            Env         = $Env 
            Environment = $Environment
        }
        Install-ECI.EMI.Automation.ECIModulesonVMGuest @Params
        Write-ECI.EMI.OS.ParameterstoGuest -ServerID $ServerID -VMName $VMName -HostName $HostName
    }

    PROCESS
    {
        ##########################################
        ### Invoke Configuration in VM Guest
        ##########################################

        ###----------------------------------------------
        ### STEP 1: Rename-ECI.LocalAdmin
        ###----------------------------------------------
        function Rename-ECI.EMI.Configure.OS.LocalAdmin
        {
            $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

            #Delete-ECI.EMI.Automation.ServerLogs -HostName $HostName

            ###---------------------------------------------------------------------------------------------
            Set-ECI.EMI.Automation.LocalAdminAccount -Template
            
            Rename-ECI.EMI.Configure.OS.Invoke.LocalAdmin -NewName $ECILocalAdminName -LocalAdminName $Creds.LocalAdminName -LocalAdminPassword $Creds.LocalAdminPassword
            Set-ECI.EMI.Automation.LocalAdminAccount -ECI
            ###---------------------------------------------------------------------------------------------
           

            ### WARNING:  Dont use these functions here! There are no log files from this operation. Will generate terminating errors.
            ###------------------------------------------------------------------------------------------------------------------------------------
            #Copy-ECI.EMI.Automation.VMLogsfromGuest
            #Write-ECI.EMI.Automation.VMLogstoSQL
            #Delete-ECI.EMI.Automation.ServerLogs -HostName $HostName
            ###------------------------------------------------------------------------------------------------------------------------------------

            Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
        }

        ###----------------------------------------------
        ### STEP 2: Rename-ECI.GuestComputer
        ###----------------------------------------------
        function Rename-ECI.EMI.Configure.OS.GuestComputer
        {
            $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

            ###---------------------------------------------------------------------------------------------
            Wait-ECI.EMI.Automation.VM.VMTools -VMName $VMName
            $Step = "Rename-ECI.EMI.Configure.OS.GuestComputer"
            Invoke-ECI.EMI.Automation.ScriptTextInGuest -ScriptText (Process-ECI.EMI.Automation.ScriptText -Step $Step -Env $Env -Environment $Environment) -Step $Step 

            ###---------------------------------------------------------------------------------------------
            Write-Host "Guest OS was restarted after Renaming Computer:  `r`nWaiting for Guest OS to Resume . . ." -ForegroundColor Yellow
            Wait-ECI.EMI.Automation.VM.VMTools -VMName $VMName                                             #<---- Consolidate
            Start-ECI.EMI.Automation.Sleep -t $WaitTime_StartSleep -Message "Waiting after Rename Guest"                                            #<---- Consolidate
            
            ### Copy Log Files and Write to SQL
            ###---------------------------------            
            Copy-ECI.EMI.Automation.VMLogsfromGuest -VMName $VMName -HostName $HostName                  #<---- Consolidate
            Write-ECI.EMI.Automation.VMLogstoSQL                     #<---- Consolidate
            Delete-ECI.EMI.Automation.ServerLogs -HostName $HostName #<---- Consolidate

            Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
        }

        ###----------------------------------------------
        ### STEP 3: Configure OS
        ###----------------------------------------------
        function Configure-ECI.EMI.Configure.OS.GuestComputer
        {
            $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

            #Test-ECI.EMI.Automation.VM.InvokeVMScript -VMName $VMName                        #<---- Consolidate
            #Test.ECI.EMI.VM.GuestReady  -VMName $VMName                         #<---- Consolidate
            

            ### Mount OS ISO
            ###---------------------------------
            $Params = @{
                VMName      = $VMName 
                ISOName     = "2016Server"
            }
            Mount-ECI.EMI.Automation.VM.ISO -VMName $VMName -ISOName 2016Server
            Start-ECI.EMI.Automation.Sleep -t $WaitTime_StartSleep -Message "Mount CD-ROM ISO"                                           #<---- Consolidate

            ###---------------------------------------------------------------------------------------------
            #Invoke-ECI.EMI.Configure.OS.InGuest -Step Configure-ECI.EMI.Configure.OS.GuestComputer
            Wait-ECI.EMI.Automation.VM.VMTools -VMName $VMName
            $Step = "Configure-ECI.EMI.Configure.OS.GuestComputer"
            Invoke-ECI.EMI.Automation.ScriptTextInGuest -ScriptText (Process-ECI.EMI.Automation.ScriptText -Step $Step -Env $Env -Environment $Environment) -Step $Step 
            ###---------------------------------------------------------------------------------------------

            DisMount-ECI.EMI.Automation.VM.ISO -VMName $VMName 
            Start-ECI.EMI.Automation.Sleep -t 30 -Message "Dis-Mount CD-ROM ISO"                                           #<---- Consolidate

            
            ### Copy Log Files and Write to SQL
            ###---------------------------------
            Copy-ECI.EMI.Automation.VMLogsfromGuest -VMName $VMName -HostName $HostName                 #<---- Consolidate
            Write-ECI.EMI.Automation.VMLogstoSQL                     #<---- Consolidate
            Delete-ECI.EMI.Automation.ServerLogs -HostName $HostName #<---- Consolidate

            Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
        }

        ###----------------------------------------------
        ### STEP 4: RegisterDNS
        ###----------------------------------------------
        function Configure-ECI.EMI.Configure.RegisterDNS
        {        
            $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
            
            #Invoke-ECI.EMI.Configure.OS.InGuest -Step Configure-ECI.EMI.Configure.OS.RegisterDNS

            $Step = "Configure-ECI.EMI.Configure.OS.RegisterDNS"
            Invoke-ECI.EMI.Automation.ScriptTextInGuest -ScriptText (Process-ECI.EMI.Automation.ScriptText -Step $Step -Env $Env -Environment $Environment) -Step $Step           

            
            Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
        }
        
        ###----------------------------------------------
        ### STEP 5: Configure Roles
        ###----------------------------------------------
        function Configure-ECI.EMI.Configure.Roles.GuestComputer
        {
            $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
            
            Write-Host `r`n('=' * 75)`r`n "Configuring Server Role: " $ServerRole `r`n('=' * 75)`r`n -ForegroundColor Cyan
            Write-Host `r`n`r`n('*' * 100)`r`n (' ' * 20)" --------- STARTING ROLE CONFIGURATION --------- " `r`n('*' * 100)  -ForegroundColor Cyan

            ### Role Specific Configurerations
            ###---------------------------------
            switch ( $ServerRole )
            {
                "2016Server"
                {
                    $ConfigureRole = $False
                }
                "2016FS" 
                {
                    $ConfigureRole = $False
                }
                "2016DC" 
                {
                    $ConfigureRole = $False
                }
                "2016DCFS" 
                {
                    $ConfigureRole = $False
                }
                "2016VDA" 
                { 
                    $ConfigureRole = $True
                    Mount-ECI.EMI.Automation.VM.ISO -VM $VMName -ISOName "XenApp"
                }
                "2016SQL" 
                {
                    $ConfigureRole = $False
                }
                "2016SQLOMS"  
                {
                    $ConfigureRole = $False
                }
            }

            ### Execute Role Configureration
            ###---------------------------------
            if($ConfigureRole -eq $True)
            {
                Write-Host "ConfigureRole:  " $ConfigureRole -ForegroundColor Cyan
                Write-Host "Configuring Server Role . . . " -ForegroundColor Cyan
            
                ###---------------------------------------------------------------------------------------------
                #Invoke-ECI.EMI.Configure.OS.InGuest -Step $ServerRole
                Wait-ECI.EMI.Automation.VM.VMTools -VMName $VMName
                $Step = "$ServerRole"
                Invoke-ECI.EMI.Automation.ScriptTextInGuest -ScriptText (Process-ECI.EMI.Automation.ScriptText -Step $Step -Env $Env -Environment $Environment)   
                ###---------------------------------------------------------------------------------------------
            
                Copy-ECI.EMI.Automation.VMLogsfromGuest -VMName $VMName -HostName $HostName#<---- Consolidate
                Write-ECI.EMI.Automation.VMLogstoSQL    #<---- Consolidate
                Delete-ECI.EMI.Automation.ServerLogs  -HostName $HostName  #<---- Consolidate
            }

            elseif($ConfigureRole -eq $False)
            {
                Write-Host "ConfigureRole:  " $ConfigureRole -ForegroundColor Cyan
                Write-Host "There are no specific Role based configurations needed for this build." -ForegroundColor DarkCyan
            }
            Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
        }

        ###----------------------------------------------
        ### STEP 6: Restart Guest OS
        ###----------------------------------------------
        function Restart-ECI.EMI.Configure.OS.GuestComputer
        {
            

            ### Stop VM
            ###----------------------------
            Stop-ECI.EMI.Automation.VM                                               # <--- need gracefule shutdown and restart!!!!!!!!!!!!!!!!!!!
            
            ### Stop VM
            ###----------------------------
            Start-ECI.EMI.Automation.VM

            Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
        }

        &{
            PROCESS
            {
                ###-----------
                ### Step: 1
                ###-----------
                Rename-ECI.EMI.Configure.OS.LocalAdmin
                
                ###-----------
                ### Step: 2
                ###-----------
                Rename-ECI.EMI.Configure.OS.GuestComputer
                
                ###-----------
                ### Step: 3
                ###-----------
                Configure-ECI.EMI.Configure.OS.GuestComputer
                
                ###-----------
                ### Step: 4
                ###-----------
                Configure-ECI.EMI.Configure.RegisterDNS
                
                ###-----------
                ### Step: 5
                ###-----------
                Configure-ECI.EMI.Configure.Roles.GuestComputer
                
                ###-----------
                ### Step: 6
                ###-----------
                Restart-ECI.EMI.Configure.OS.GuestComputer

                ###-----------
                ### Wait
                ###-----------
                Start-ECI.EMI.Automation.Sleep -t $WaitTime_StartSleep -message "Guest Restarted"                        #<--- COMBINE !!!!!
                Wait-ECI.EMI.Automation.VM.VMTools -VMName $VMName                            #<--- COMBINE !!!!!

                ###-----------
                ### Step: 7
                ###-----------
                #QA-ECI.EMI.Configure.OS.GuestComputer

            }
        }
    }

    END
    {
        #Delete-ECI.EMI.Automation.ECIModulesonVMGuest
        $OSStopTime = Get-Date
        $global:OSElapsedTime = ($OSStopTime-$OSStartTime)
        Write-Host `r`n`r`n('=' * 75)`r`n "OS Configuration: Total Execution Time:`t" $OSElapsedTime `r`n('=' * 75)`r`n -ForegroundColor Gray
        Write-Host "END OS onfiguration Script" -ForegroundColor Gray
        #Stop-Transcript

        ### END CONFIGURE OS INVOKE SCRIPT
    }

}

