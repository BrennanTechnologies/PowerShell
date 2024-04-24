AST.Automation.Verb-Noun 
{
    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $MyInvocation.MyCommand; Write-Host `r`n ("=" * 75)`r`n " EXECUTING FUNCTION: " $functionName `n`r ("=" * 75) -ForegroundColor DarkGray

    #############################################
    ### 
    #############################################

    Write-Host `r`n " END FUNCTION: "$functionName `r`n ("-" * 50) -ForegroundColor DarkGray
}


function AST.Automation.Import-Modules
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    foreach($Module in (Get-Module -ListAvailable AST.*)){Import-Module -Name $Module.Path -DisableNameChecking}
    

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function AST.Automation.Rename-LocalComputer 
{
    Param(
        [Parameter(Mandatory=$true)][String]$serverName
     )

    $functionName = $MyInvocation.MyCommand; Write-Host `r`n ("=" * 75)`r`n " EXECUTING FUNCTION: " $functionName `n`r ("=" * 75) -ForegroundColor DarkGray

    #############################################
    ### Rename Local Computer
    #############################################

    $currentName = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName).ComputerName

    if(-NOT $currentName -eq $serverName) 
    {
        Rename-Computer –ComputerName . –NewName $serverName
    }
    elseif(-NOT $currentName -eq $serverName ) 
    {
        Write-Host "The New Computer Name is the same as the current computer name." -ForegroundColor Yellow
    }

    Write-Host `r`n " END FUNCTION: "$functionName `r`n ("-" * 50) -ForegroundColor DarkGray
}

AST.Automation.Join-Domain 
{
    Param(
        [Parameter(Mandatory=$true)][String]$ServerName,
        [Parameter(Mandatory=$true)][String]$Domain,
        [Parameter(Mandatory=$true)][String]$OUPath,
        [Parameter(Mandatory=$false)][String]$AdministrativeUserName,
        [Parameter(Mandatory=$false)][String]$AdministrativePassword
     )

    $functionName = $MyInvocation.MyCommand; Write-Host `r`n ("=" * 75)`r`n " EXECUTING FUNCTION: " $functionName `n`r ("=" * 75) -ForegroundColor DarkGray

    #############################################
    ### Join Domain
    #############################################

        $ScriptText = {
            #$AdministrativeUserName = "serverdeploy"
            #$AdministrativePassword = '@cT4cHr1$t0ph'

            $AdministrativePassword = ConvertTo-SecureString $AdministrativePassword -AsPlainText -Force
            $PSCredentials =  New-Object System.Management.Automation.PSCredential ($AdministrativeUserName, $AdministrativePassword)
            
            $AdminID = "serverdeploy"
            $AdminPassword = '@cT4cHr1$t0ph'
  
            Add-Computer -ComputerName $ServerName -DomainName $Domain -Credential $PSCredentials -Force -Verbose -OUPath $OUPath
            
        }

        Invoke-VMScript -ScriptText $SriptText -VM $serverName -GuestUser $adminID -GuestPassword $adminPassword
            


    Write-Host `r`n " END FUNCTION: "$functionName `r`n ("-" * 50) -ForegroundColor DarkGray
}


AST.Automation.Install-Symantec 
{
    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $MyInvocation.MyCommand; Write-Host `r`n ("=" * 75)`r`n " EXECUTING FUNCTION: " $functionName `n`r ("=" * 75) -ForegroundColor DarkGray

    #############################################
    ### Install Symantec
    #############################################

    Write-Host "Installing Symantec Endpoint Protection." -ForegroundColor Cyan


    Write-Host `r`n " END FUNCTION: "$functionName `r`n ("-" * 50) -ForegroundColor DarkGray
}

AST.Automation.Install-Lumension 
{
    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $MyInvocation.MyCommand; Write-Host `r`n ("=" * 75)`r`n " EXECUTING FUNCTION: " $functionName `n`r ("=" * 75) -ForegroundColor DarkGray

    #############################################
    ### Installing Lumension
    #############################################

    Write-Host "Installing Lumension." -ForegroundColor Cyan

    Write-Host `r`n " END FUNCTION: "$functionName `r`n ("-" * 50) -ForegroundColor DarkGray
}

AST.Automation.Install-Symantec {
    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $MyInvocation.MyCommand; Write-Host `r`n ("=" * 75)`r`n " EXECUTING FUNCTION: " $functionName `n`r ("=" * 75) -ForegroundColor DarkGray

    #############################################
    ### 
    #############################################

    Write-Host `r`n " END FUNCTION: "$functionName `r`n ("-" * 50) -ForegroundColor DarkGray
}

AST.Automation.Install-Symantec {
    Param(
        [Parameter(Mandatory=$false)][String]$param
     )

    $functionName = $MyInvocation.MyCommand; Write-Host `r`n ("=" * 75)`r`n " EXECUTING FUNCTION: " $functionName `n`r ("=" * 75) -ForegroundColor DarkGray

    #############################################
    ### 
    #############################################

    Write-Host `r`n " END FUNCTION: "$functionName `r`n ("-" * 50) -ForegroundColor DarkGray
}


function Configure-ECI.EMI.Configure.OS.WindowsFeatures
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    ##########################################
    ### DESIRED STATE PARAMETERS
    ##########################################
    $PropertyName      = "WindowsFeatures"
    $ConfigurationMode = "Configure" ### Report - Configure
    $AbortTrigger      = $False  ### $True - $False

    switch ( $ServerRole )
    {
        "2016Server"
        { $WindowsFeatures = 
            @(
                "NET-Framework-Features",
                "NET-Framework-Core",
                "GPMC",
                "Telnet-Client"
            )                      
        }
        "2016FS"
        { $WindowsFeatures = 
            @(
                "NET-Framework-Features",
                "NET-Framework-Core",
                "GPMC",
                "Telnet-Client",
                "RSAT"
            )                         
        }
        "2016DC"
        { $WindowsFeatures = 
        @(
            "NET-Framework-Features",
            "NET-Framework-Core",
            "GPMC",
            "Telnet-Client",
            "RSAT"
            )                         
        }
        "2016DCFS"
        { $WindowsFeatures = 
        @(
            "NET-Framework-Features",
            "NET-Framework-Core",
            "GPMC",
            "Telnet-Client",
            "RSAT"
            )                         
        }
         "2016VDA"
         { $WindowsFeatures = 
         @(
            "NET-Framework-Features",
            "NET-Framework-Core",
            "GPMC",
            "Telnet-Client",
            "RSAT"
            "AS-Net-Framework",
            "RDS-RD-Server"
            )                         
        }
        "2016SQL"
        { $WindowsFeatures = 
        @(
            "NET-Framework-Features",
            "NET-Framework-Core",
            "GPMC",
            "Telnet-Client",
            "RSAT"
            )                         
        }
        "2016SQLOMS"
        { $WindowsFeatures = 
        @(
            "NET-Framework-Features",
            "NET-Framework-Core",
            "GPMC",
            "Telnet-Client",
            "RSAT"
            )                         
        }
    }
    foreach ($Feature in $WindowsFeatures)
    {
        $script:DesiredState = $Feature
        write-host "DesiredState: " $DesiredState

        ##########################################
        ### GET CURRENT CONFIGURATION STATE: 
        ##########################################
        [scriptblock]$script:GetCurrentState =
        {
            $global:CurrentState = ((Get-WindowsFeature -Name $Feature) | Where-Object {$_.Installed -eq $True}).Name
        }

        ##########################################
        ### SET DESIRED-STATE:
        ##########################################
        [scriptblock]$script:SetDesiredState =
        {
            Write-Host "Installing Feature: " $Feature
            
            #$WindowsMediaSource = "R:\sources\sxs\microsoft-windows-netfx3-ondemand-package.cab"
            $WindowsMediaSource = "R:\sources\sxs"
            Install-WindowsFeature -Name $Feature -Source $WindowsMediaSource
        }
    
        ##########################################
        ### CALL CONFIGURE DESIRED STATE:
        ##########################################
        $Params = @{
            ServerID            = $ServerID
            HostName            = $HostName 
            FunctionName        = $FunctionName 
            PropertyName        = $PropertyName 
            DesiredState        = $DesiredState 
            GetCurrentState     = $GetCurrentState 
            SetDesiredState     = $SetDesiredState 
            ConfigurationMode   = $ConfigurationMode 
            AbortTrigger        = $AbortTrigger
        }
        Configure-DesiredState @Params
    }
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Rename-ECI.EMI.Configure.OS.GuestComputer
{

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    ##########################################
    ### DESIRED STATE PARAMETERS
    ##########################################
    $PropertyName      = "HostName"
    $DesiredState      = $HostName
    $ConfigurationMode = "Configure" ### Report - Configure
    $AbortTrigger      = $True  ### $True - $False

    ##########################################
    ### GET CURRENT CONFIGURATION STATE: 
    ##########################################
    [scriptblock]$script:GetCurrentState =
    {
        $global:CurrentState = 	(Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName).ComputerName

        #$ActiveComputerName = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName).ComputerName
        #$ComputerName = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName).ComputerName

    }

    ##########################################
    ### SET DESIRED-STATE:
    ##########################################
    [scriptblock]$script:SetDesiredState =
    {
        #Rename-Computer –ComputerName $(Get-CIMInstance CIM_ComputerSystem).Name –NewName $HostName
        #Rename-Computer –ComputerName $(Get-WmiObject Win32_Computersystem).Name –NewName $HostName
        Rename-Computer –ComputerName . –NewName $HostName
    }

    ##########################################
    ### CALL CONFIGURE DESIRED STATE:
    ##########################################
    ###----------------------------
    $Params = @{
        ServerID            = $ServerID
        HostName            = $HostName 
        FunctionName        = $FunctionName 
        PropertyName        = $PropertyName 
        DesiredState        = $DesiredState 
        GetCurrentState     = $GetCurrentState 
        SetDesiredState     = $SetDesiredState 
        ConfigurationMode   = $ConfigurationMode 
        AbortTrigger        = $AbortTrigger
    }
    Configure-DesiredState @Params
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}