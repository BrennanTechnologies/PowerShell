###############################################
### EMI Automation Script
### ECI.EMI.Automation.Prod.ps1
###############################################

#P-int
#7Gc^jfzaZnzD

### Get Parameters form Invoke-ServerRequest.ps1
###--------------------------------------------------
Param(
    [Parameter(Mandatory = $True,Position=0)][string]$RequestID,
    [Parameter(Mandatory = $True,Position=1)][string]$HostName,
    [Parameter(Mandatory = $True,Position=2)][string]$Env,
    [Parameter(Mandatory = $True,Position=3)][string]$AdministrativeUserName,
    [Parameter(Mandatory = $True,Position=4)][string]$AdministrativePassword,
    [Parameter(Mandatory = $False,Position=5)][string]$ConfigurationMode
)

#######################################
### Function: Set-TranscriptPath
#######################################
function Start-ECI.Transcript
{
    Param(
    [Parameter(Mandatory = $False)][string]$TranscriptPath,
    [Parameter(Mandatory = $False)][string]$TranscriptName,
    [Parameter(Mandatory = $False)][string]$HostName
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
        $global:TranscriptFile = $TranscriptPath + $HostName + "_PowerShell_transcript" + "." + $TranscriptName + "." + $Rnd + "." + $TimeStamp + ".txt"
    }
    else
    {
        $global:TranscriptFile = $TranscriptPath + "PowerShell_transcript" + "." + $Rnd + "." + $TimeStamp + ".txt"
    }
    ### Start Transcript Log
    Start-Transcript -Path $TranscriptFile -NoClobber 
}

#~~~~~~~~~~~~~~~~~ Temporary Kludges ~~~~~~~~~~~~~~~~~~~~~~~~
function cLoBbEr-HostName
{
    Param([Parameter(Mandatory = $True)][string]$HostName)
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Magenta

    $RNG = Get-Random -Minimum 1000 -Maximum 9999
    
    Write-Host "Original Request HostName  : " $HostName -ForegroundColor Magenta
    
    $HostName = $HostName + "-" + $RNG
    
    Write-Host "New RNG Host Name          : " $HostName -ForegroundColor Magenta
    
    $global:HostName = $HostName
    Return $HostName
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


### Set ECI Automation Environment Parameters
### --------------------------------------------------
function Set-ECI.RequestParameters
{
    param(
    [Parameter(Mandatory = $True)] [string]$RequestID,
    [Parameter(Mandatory = $True)] [string]$Env,
    [Parameter(Mandatory = $True)] [string]$AdministrativeUserName,
    [Parameter(Mandatory = $True)] [string]$AdministrativePassword
    )
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    switch ($Env)
    {
        "Dev"          { $global:Environment = "Development" }
        "Stage"        { $global:Environment = "Staging"     }
        "Prod"         { $global:Environment = "Production"  }
        "Development"  { $global:Environment = "Development" }
        "Staging"      { $global:Environment = "Staging"     }
        "Production"   { $global:Environment = "Production"  }
    }

    $RunasUser = Whoami

    #Write-Host "Setting Global Variable ENV: " $Env -ForegroundColor Cyan

    [int]$global:RequestID         = $RequestID
    $global:Env                    = $Env
    $global:Environment            = $Environment
    $global:AdministrativeUserName = $AdministrativeUserName
    $global:AdministrativePassword = $AdministrativePassword

    $Parameters = [ordered]@{
        RequestID              = $RequestID
        Env                    = $Env
        Environment            = $Environment
        AdministrativeUserName = $AdministrativeUserName
        AdministrativePassword = $AdministrativePassword
        RunasUser              = $RunasUser
    }

    Write-Host `r`n('=' * 75)`r`n  "Running PowerShell Worker Process as User: " $RunasUser `r`n('=' * 75)`r`n  -ForegroundColor DarkGray

    Return $Parameters
}

### Import ECI Modules
### --------------------------------------------------
function Import-ECI.Root.ModuleLoader
{
    Param([Parameter(Mandatory = $True)][string]$Env)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Cyan

    ######################################
    ### Bootstrap Module Loader
    ######################################

    ### Connect to the Repository & Import the ECI.ModuleLoader
    ### ----------------------------------------------------------------------
    $AcctKey         = ConvertTo-SecureString -String "VSRMGJZNI4vn0nf47J4bqVd5peNiYQ/8+ozlgzbuA1FUnn9hAoGRM9Ib4HrkxOyRJkd4PHE8j36+pfnCUw3o8Q==" -AsPlainText -Force
    $Credentials     = $Null
    $Credentials     = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\eciscripts", $AcctKey
    $RootPath        = "\\eciscripts.file.core.windows.net\clientimplementation"
    
    New-PSDrive -Name X -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Scope Global

    . "\\eciscripts.file.core.windows.net\clientimplementation\Root\$Env\ECI.Root.ModuleLoader.ps1" -Env $Env
}



### ==================================================
### Invoke ECI.EMI.Automation.VM
### ==================================================
function Invoke-ECI.EMI.Automation.VM
{
    Param(
            [Parameter(Mandatory = $True)][int]$ServerID,
            [Parameter(Mandatory = $True)][int]$RequestID,
            [Parameter(Mandatory = $True)][string]$HostName,
            [Parameter(Mandatory = $True)][string]$ConfigurationMode,
            [Parameter(Mandatory = $True)][string]$Env,
            [Parameter(Mandatory = $True)][string]$Environment
         )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('=' * 100)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('=' * 100) -ForegroundColor Cyan
    
    #####################
    ### Provision VM
    #####################
    
    $VMParameters = @{
            ServerID          = $ServerID
            RequestID         = $RequestID
            Environment       = $Environment
            ConfigurationMode = $ConfigurationMode
    }

    ### ECI.ConfigServer.Invoke-ProvisionVM.ps1
    ###------------------------------------------------
    $File = "ECI.EMI.Automation.VM"
    $FilePath =  "\\eciscripts.file.core.windows.net\clientimplementation\" + $Environment + "\ECI.Modules." + $Env + "\" + $File + "." + $Env + "\" + $File  + "." + $Env + ".ps1"
    #Try
    #{
        . ($FilePath) @VMParameters
    #}
    #Catch
    #{
    #    Write-ECI.ErrorStack       
    #}
}

### ==================================================
### Invoke ECI.EMI.Automation.OS
### ==================================================
function Invoke-ECI.EMI.Automation.OS
{
    Param(
            [Parameter(Mandatory = $True)][int]$ServerID,
            [Parameter(Mandatory = $True)][string]$HostName,
            [Parameter(Mandatory = $True)][string]$ConfigurationMode,
            [Parameter(Mandatory = $True)][string]$Env,
            [Parameter(Mandatory = $True)][string]$Environment
         )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('=' * 100)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('=' * 100) -ForegroundColor Cyan

    #####################c
    ### Configure OS
    #####################

    $OSParameters = @{
            ServerID                 = $ServerID
            HostName                 = $HostName
            ConfigurationMode        = $ConfigurationMode
            ServerRole               = $ServerRole
            IPv4Address              = $IPv4Address
            SubnetMask               = $SubnetMask
            DefaultGateway           = $DefaultGateway
            PrimaryDNS               = $PrimaryDNS
            SecondaryDNS             = $SecondaryDNS
            ClientDomain             = $ClientDomain
            AdministrativeUserName   = $AdministrativeUserName
            AdministrativePassword   = $AdministrativePassword
    }
        
    ### ECI.EMI.Automation.OSConfiguration.Invoke.ps1
    ###------------------------------------------------
    $File = "ECI.EMI.Configure.OS"
    $FilePath =  "\\eciscripts.file.core.windows.net\clientimplementation\" + $Environment + "\ECI.Modules." + $Env + "\" + $File + "." + $Env + "\" + $File + ".Invoke"  + "." + $Env + ".ps1"
    Try
    {         
        . ($FilePath) @OSParameters  
    }
    Catch
    {
        Write-ECI.ErrorStack 
    }
   
}

### ==================================================
### Invoke ECI.EMI.Automation.Role
### ==================================================
function InvokeECI.EMI.Automation.Role
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('=' * 100)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('=' * 100) -ForegroundColor Cyan
    
    #####################
    ### Configure Roles
    #####################
    
    $RoleParameters = @{
            ServerID     = $ServerID
            HostName     = $HostName
            ServerRole   = $ServerRole
            BuildVersion = $BuildVersion
    }
    
    ### ECI.ConfigServer.Invoke-ConfigureRoles.ps1
    ###------------------------------------------------
    $File = "ECI.EMI.Automation.Role"
    $FilePath =  "\\eciscripts.file.core.windows.net\clientimplementation\" + $Environment + "\ECI.Modules." + $Env + "\" + $File + "." + $Env + "\" + $File  + "." + $Env + ".ps1"
    
    Try
    {
        . ($FilePath) @RoleParameters
    }
    Catch
    {

        Write-ECI.ErrorStack
    }
}

### ==================================================
### Invoke ECI.EMI.Automation.QA
### ==================================================
function Invoke-ECI.EMI.Automation.QA
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('=' * 100)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('=' * 100) -ForegroundColor Cyan
    
    #####################
    ### Provision VM
    #####################
    
    $QAParameters = @{
            ServerID          = $ServerID
            Environment       = $Environment
            ConfigurationMode = $ConfigurationMode
    }

    ### ECI.ConfigServer.Invoke-ProvisionVM.ps1
    ###------------------------------------------------
    $File = "ECI.EMI.Automation.QA"
    $FilePath =  "\\eciscripts.file.core.windows.net\clientimplementation\" + $Environment + "\ECI.Modules." + $Env + "\" + $File + "." + $Env + "\" + $File  + "." + $Env + ".ps1"
    Try
    {
        . ($FilePath) @QAParameters
    }
    Catch
    {
        Write-ECI.ErrorStack        
    }
}

############
### Main
############
&{ ### Execute the Script

    BEGIN
    {
        ##################################################################
        ### START AUTOMATION PROCESS
        ##################################################################

        ### Set Variables       
        ###-------------------------------------
        $global:AutomationStartTime   = (Get-Date)
        $global:ProgressPreference    = "SilentlyContinue"
        $global:ErrorActionPreference = "Stop"
        $global:VerifyErrorCount      = 0
        $global:Abort                 = $False
        #$global:ECIError             = $False
        Start-ECI.Transcript -TranscriptPath "C:\Scripts\_VMAutomationLogs\$HostName\" -TranscriptName "ECI.EMI.Automation.$Env.ps1" -HostName $HostName
        Set-ECI.RequestParameters -RequestID $RequestID -Env $Env -AdministrativeUserName $AdministrativeUserName -AdministrativePassword $AdministrativePassword 

### PreCheck-ECI.EMI.Automation  ### need to develop this function!!!!!!!!!!!!!!!!!

        ### Default Configuration Mode
        ###-------------------------------------
        if(!$ConfigurationMode)
        {
            ### Set Default Configuration Mode
            #$global:ConfigurationMode     = "Configure"   ### Configure/Report
            $global:ConfigurationMode     = "Report"       ### Configure/Report
        }
        
        elseif($ConfigurationMode)
        {
            $global:ConfigurationMode = $ConfigurationMode
        }
        Write-Host "Configuration Mode: " $ConfigurationMode -ForegroundColor Yellow
                                      
        ### Import Modules   
        ###------------------------------------- 
        Import-ECI.Root.ModuleLoader -Env $Env  # <---- MOVE-TO-INVOKE-SERVERREQUEST.PS1 ?????
        Set-ECI.PS.BufferSize
        Import-ECI.EMI.Automation.VMWareModules -Env $Env -Environment $Environment -ModuleName "VMWare*" -ModuleVersion "10.0.0"

        ### Get Parameters from SQL        
        ###-------------------------------------
        $global:DevOps_ConnectionString  =  "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;” # <-- Need to Encrypt Password !!!!!!
        Get-ECI.EMI.Automation.SystemConfig -Env $Env -DevOps_ConnectionString $DevOps_ConnectionString 
        Get-ECI.EMI.Automation.BuildVersion
        Get-ECI.EMI.Automation.ServerRequest
        Get-ECI.EMI.Automation.ServerRole
        Get-ECI.EMI.Automation.VMWareTemplate
        Get-ECI.EMI.Automation.OSCustomizationSpec
        Get-ECI.EMI.Automation.VMParameters
        Get-ECI.EMI.Automation.OSParameters
        #cLoBbEr-HostName -HostName $HostName
        Create-ECI.EMI.Automation.VMName -GPID $GPID -HostName $HostName

        ### ECI Error Log
        $global:ECIErrorLogFile = $AutomationLogPath + "\" + $HostName + "\" + "ECIErrors_" + $HostName + ".txt" #!!!!!!!!!!!!!!!!!!! WRITE TO SQL
        Write-Host "ECIErrorLogFile:" $ECIErrorLogFile -ForegroundColor Magenta
    }

    PROCESS
    {
        ##################################################################
        ### EXECUTE AUTOMATION PROCESS
        ##################################################################

        Create-ECI.EMI.Automation.ServerStatus -RequestID $RequestID -HostName $HostName -ServerStatus "Server Request Recieved"

        ### Get/Set Server Record
        ###-----------------------------
        Check-ECI.EMI.Automation.ServerRecord -GPID $GPID -CWID $CWID -HostName $HostName

        if($ServerExists -eq $False)
        {
            ###                                                                                            ### <---------- ConfigurationMode --- MAIN SWITCH !!!!!
            #$global:ConfigurationMode = "Configure"
            #Write-Host "Automation Configuration Mode: " $ConfigurationMode -ForegroundColor DarkYellow
            
            $ServerParams = @{
                RequestID     = $RequestID 
                GPID          = $GPID 
                CWID          = $CWID 
                HostName      = $HostName 
                ServerRole    = $ServerRole 
                BuildVersion  = $BuildVersion 
            }
            Create-ECI.EMI.Automation.ServerRecord @ServerParams
            Get-ECI.EMI.Automation.ServerID -RequestID $RequestID
        }
        elseif($ServerExists -eq $True)
        {
            $global:ServerID = $ServerID
            #$global:ConfigurationMode = "Report"                                                         ### <---------- ConfigurationMode --- MAIN SWITCH !!!!!
            Write-Host "Automation Configuration Mode: " $ConfigurationMode `r`n('-' * 50)`r`n -ForegroundColor DarkYellow
        }
        
        Create-ECI.EMI.Automation.CurrentStateRecord -ServerID (Get-ECI.EMI.Automation.ServerID -RequestID $RequestID)

        ###-----------------------------
        ### Provision VM
        ###-----------------------------
        
        $StatusParams = @{
            RequestID         = $RequestID 
            ServerID          = $ServerID 
            HostName          = $HostName 
            VerifyErrorCount  = 0
            Abort             = $False 
            ServerStatus      = "VM Provisioning-Started"
            Environment       = $Environment
        }
        #Update-ECI.EMI.Automation.ServerStatus @StatusParams
        Update-ECI.EMI.Automation.ServerStatus -RequestID $RequestID -ServerID $ServerID -HostName $HostName -VerifyErrorCount "0" -Abort $False -ServerStatus "VM Provisioning-Started"
        
        $VMParams = @{
            ServerID          = $ServerID 
            HostName          = $HostName 
            ConfigurationMode = $ConfigurationMode
            Env               = $Env 
            Environment       = $Environment
        }        
        #Invoke-ECI.EMI.Automation.VM @VMParams
        Invoke-ECI.EMI.Automation.VM -ServerID $ServerID -RequestID $RequestID -HostName $HostName -ConfigurationMode $ConfigurationMode -Env $Env -Environment $Environment

        $ServerParams = @{
            ServerID          = $ServerID 
            VMName            = $VMName 
            ServerUUID        = $ServerUUID 
            vCenterUUID       = $vCenterUUID 
            VMID              = $VMID
        }        
        #Update-ECI.EMI.Automation.ServerRecord @ServerParams
        Update-ECI.EMI.Automation.ServerRecord -ServerID $ServerID -VMName $VMName -ServerUUID $ServerUUID -vCenterUUID $vCenterUUID -VMID $VMID

        $StatusParams = @{
            RequestID         = $RequestID 
            ServerID          = $ServerID 
            HostName          = $HostName 
            VerifyErrorCount  = $VerifyErrorCount 
            Abort             = $False 
            ElapsedTime       = $VMElapsedTime 
            ServerStatus      = "VM Provisioning-Completed"
        }        
        #Update-ECI.EMI.Automation.ServerStatus @StatusParams
        Update-ECI.EMI.Automation.ServerStatus -RequestID $RequestID -ServerID $ServerID -HostName $HostName -VerifyErrorCount $VerifyErrorCount -Abort $False -ElapsedTime $VMElapsedTime -ServerStatus "VM Provisioning-Completed"

        ###-----------------------------
        ### Configure OS
        ###-----------------------------        
        $StatusParams = @{
            RequestID         = $RequestID 
            ServerID          = $ServerID 
            HostName          = $HostName 
            VerifyErrorCount  = 0 
            Abort             = $False 
            ServerStatus      = "OS Configuration-Started"
        }
        #Update-ECI.EMI.Automation.ServerStatus @StatusParams
        Update-ECI.EMI.Automation.ServerStatus -RequestID $RequestID -ServerID $ServerID -HostName $HostName -VerifyErrorCount 0 -Abort $False -ServerStatus "OS Configuration-Started"
        
        $ConfigureOSParams = @{
            ServerID          = $ServerID 
            HostName          = $HostName 
            ConfigurationMode = $ConfigurationMode 
            Env               = $Env 
            Environment       = $Environment
        }
        #Invoke-ECI.EMI.Automation.OS @ConfigureOSParams
        Invoke-ECI.EMI.Automation.OS -ServerID $ServerID -HostName $HostName -ConfigurationMode $ConfigurationMode -Env $Env -Environment $Environment
        
        $StatusParams = @{
            RequestID         = $RequestID 
            ServerID          = $ServerID 
            HostName          = $HostName 
            VerifyErrorCount  = $VerifyErrorCount 
            Abort             = $False 
            ElapsedTime       = $OSElapsedTime 
            ServerStatus      = "OS Configuration-Completed"
        }        
        #Update-ECI.EMI.Automation.ServerStatus @StatusParams
        Update-ECI.EMI.Automation.ServerStatus -RequestID $RequestID -ServerID $ServerID -HostName $HostName -VerifyErrorCount $VerifyErrorCount -Abort $False -ElapsedTime $OSElapsedTime -ServerStatus "OS Configuration-Completed"

        ###-----------------------------
        ### Configure Role
        ###-----------------------------        
        #Update-ServerStatus -RequestID $RequestID -ServerID $ServerID -HostName $HostName -Verify $Verify -Abort $Abort -ServerStatus "Configuring Role"
        #Invoke-ECI.EMI.Automation.Role

        ###-----------------------------
        ### QA Server
        ###-----------------------------        
        #Update-ServerStatus -RequestID $RequestID -ServerID $ServerID -HostName $HostName -Verify $Verify -Abort $Abort -ServerStatus "Configuring Role"
        Invoke-ECI.EMI.Automation.QA

    }

    END
    {
        ##################################################################
        ### END AUTOMATION PROCESS
        ##################################################################
 
        ### Remove ECI Modules from Guest
        ###-------------------------------------------
        Delete-ECI.EMI.Automation.ECIModulesonVMGuest
        
        $script:AutomationStopTime = Get-Date
        $global:AutomationTime = ($AutomationStopTime-$AutomationStartTime)

        ### Build Complete: Update Server Final Status
        ###-------------------------------------------
        $StatusParams = @{
            RequestID         = $RequestID 
            ServerID          = $ServerID 
            HostName          = $HostName 
            VerifyErrorCount  = $VerifyErrorCount 
            Abort             = $False 
            ElapsedTime       = $AutomationTime 
            ServerStatus      = "Build Complete"
        }        
        #Update-ECI.EMI.Automation.ServerStatus @StatusParams
        Update-ECI.EMI.Automation.ServerStatus -RequestID $RequestID -ServerID $ServerID -HostName $HostName -VerifyErrorCount $VerifyErrorCount -Abort $False -ElapsedTime $AutomationTime -ServerStatus "Build Complete"     

        ### Write Status
        ###-------------------------------------------
        Write-Host `r`n('=' * 100)`r`n `r`n('*' * 100)`r`n`r`n('-' * 100)`r`n(' ' * 25)  "ALL PROVISIONING & CONFIGURATION IS COMPLETE!" `r`n('-' * 100)`r`n`r`n('*' * 100)`r`n `r`n('=' * 100)`r`n`r`n`r`n -ForegroundColor Cyan

        ### Get Server Current State from SQL
        ###-------------------------------------------        
        Write-Host `n`n('-' * 100)`n (' ' * 25)"GETTING SERVER SUMMARY FROM DATABASE" `n('-' * 100)`n -ForegroundColor Gray
        Get-ECI.EMI.Automation.ServerRequest-SQL      -RequestID $RequestID
        Get-ECI.EMI.Automation.ServerRecord-SQL       -ServerID $ServerID
        Get-ECI.EMI.Automation.ServerCurrentState-SQL -ServerID $ServerID
        Get-ECI.EMI.Automation.ServerDesiredState-SQL -ServerID $ServerID
        Get-ECI.EMI.Automation.ServerConfigLog-SQL    -ServerID $ServerID

        #########################################################
        ### Write Server Build Tag & Email Notification
        #########################################################
        Send-ECI.ServerStatus -ServerID $ServerID -Abort $Abort -VerifyErrorCount $VerifyErrorCount

        ### Write Script End
        ###-------------------------------------------
        Write-Host `r`n`r`n('=' * 75)`n "ECI.EMI.Automation: Total Execution Time:`t" $AutomationTime `r`n('=' * 75)`r`n -ForegroundColor Gray
        Write-Host "================= END ALL AUTOMATION SCRIPTS ================= " -ForegroundColor Gray
        Stop-Transcript

        $ECIDebuggingMode = $False
        if($ECIDebuggingMode -eq $True)
        {
            Write-ECI.ErrorStack -Detailed -NoExit | Out-File -FilePath $TranscriptFile -Append ### REMEMBER! Errors are expected from try/catch tests!
        }

        Write-Host "END ALL AUTOMATION SCRIPTS:" `r`n (Get-Date)
        ### END ALL AUTOMATION SCRIPTS
    }
}

### uNDer cOnStRucTioN ####################
### eNd cOnStRucTioN ####################

