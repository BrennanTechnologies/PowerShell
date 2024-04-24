######################################
### Execute Commands In-Guest
### ECI.EMI.Automation.OS.InGuest.ps1
######################################

function Import-ECI.EMI.Configure.OS.ParametersInGuest
{

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    ### InGuest Log Path
    $InGuestParamFile = "C:\Scripts\_InGuestAutomationLogs\InGuestParams.txt"
    #$InGuestParamFile = "C:\Scripts\_InGuestAutomationLogs" + "\" + $HostName + "\" + "InGuestParams_" + $HostName + ".txt"
    #$InGuestParamFile = $InGuestLogPath + "\" + $HostName + "\" + "InGuestParams_" + $HostName + ".txt"

    Write-Host "InGuestParamFile: " $InGuestParamFile 
    $InGuestParamFile =  (Get-Item -Path $InGuestParamFile).FullName

    
    if($InGuestParamFile)
    {
        $InGuestParams = Import-Csv -Path $InGuestParamFile -Delimiter "," -Header Name,Value
        foreach($Param in $InGuestParams)
        {
            Write-Host "Importing Param: " $Param.Name ": " $Param.Value
            New-Variable -Name  $Param.Name -Value $Param.Value -Scope Global
        }
    }
    elseif(-NOT($InGuestParamFile))
    {
        Write-Host "ERROR: Parameter File Missing." 
    }
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Set-TranscriptPath
{
    $global:TranscriptPath = "C:\Scripts\_VMAutomationLogs\Transcripts"
    #$global:TranscriptPath = $AutomationLogPath + "\" + $HostName + "\"
    if(-NOT(Test-Path -Path $TranscriptPath)) {(New-Item -ItemType directory -Path $TranscriptPath | Out-Null);Write-Host "Creating TranscriptPath: " $TranscriptPath }
    Return $TranscriptPath
}

& { 
    BEGIN 
    {
        ### Initialize Script
        ###--------------------------
        Start-ECI.EMI.Automation.Transcript -TranscriptPath "C:\Scripts\_VMAutomationLogs\Transcripts\" -TranscriptName "ECI.EMI.Configure.OS.InGuest.$Env.ps1.Step-$Step"
        Write-Host "`r`n" ("=" * 75) "`nBEGIN BLOCK: $((Get-PSCallStack)[0].Command) STEP-$Step `r`n" ("=" * 75)
       
        Import-ECI.EMI.Modules
        Import-ECI.EMI.Configure.OS.ParametersInGuest
     }
    
    PROCESS 
    {
        ### Execute Module Functions
        ###--------------------------
        Write-Host "`r`n" ("=" * 75) "`nPROCESS BLOCK: $((Get-PSCallStack)[0].Command) STEP-$Step `r`n" ("=" * 75)

        ###----------------------------------------------
        ### STEP 1: Rename-ECI.LocalAdmin
        ###----------------------------------------------
        if ($Step -eq "Rename-ECI.EMI.Configure.OS.LocalAdministrator")
        {
            Rename-LocalAdministrator
        }

        ###----------------------------------------------
        ### STEP 2: Rename-ECI.GuestComputer
        ###----------------------------------------------
        if ($Step -eq "Rename-ECI.EMI.Configure.OS.GuestComputer")
        {
            Rename-ECI.EMI.Configure.OS.GuestComputer
            Restart-ECI.EMI.Configure.OS.GuestComputer
        }

        ###----------------------------------------------
        ### STEP 3: Configure OS
        ###----------------------------------------------
        if ($Step -eq "Configure-ECI.EMI.Configure.OS.GuestComputer")
        {
            Write-Host `r`n('-' * 50)`r`n "Executing: " $Step `r`n('-' * 50)`r`n 
           
            Configure-ECI.EMI.Configure.OS.NetworkInterface
            #Configure-ECI.EMI.Configure.OS.SMBv1
            Configure-ECI.EMI.Configure.OS.IPv6
            Configure-ECI.EMI.Configure.OS.CDROM
            Configure-ECI.EMI.Configure.OS.RemoteDesktop 
            Configure-ECI.EMI.Configure.OS.WindowsFirewallProfile
            Configure-ECI.EMI.Configure.OS.WindowsFirewallRules
            Configure-ECI.EMI.Configure.OS.InternetExplorerESC
            Configure-ECI.EMI.Configure.OS.WindowsFeatures
            Initialize-ECI.EMI.Configure.OS.HardDisks
            Configure-ECI.EMI.Configure.OS.Folders
            # ~~~ uNdEr dEvoL0PmEnt~~~ #
            Configure-ECI.EMI.Configure.OS.PageFileLocation   #<------ COMBINE
            Configure-ECI.EMI.Configure.OS.PageFileSize       #<------ COMBINE
            Configure-ECI.EMI.Configure.OS.JoinDomain
        }

        ###----------------------------------------------
        ### STEP 4: Configure Roles
        ###----------------------------------------------
        Write-Host `r`n('-' * 50)`r`n "Executing: " $Step `r`n('-' * 50)`r`n 
        Configure-ECI.EMI.Configure.OS.RegisterDNS

        ###----------------------------------------------
        ### STEP 5: Configure Roles
        ###----------------------------------------------
        Write-Host `r`n('-' * 50)`r`n "Executing: " $Step `r`n('-' * 50)`r`n 
        switch ( $Step )
        {
            "2016Server" 
            {
                Write-Host $Step
                Write-Host "The configuration for this Role is not available yet."
                Start-ECI.EMI.Automation.Sleep
            }

            "2016FS" 
            {
                Write-Host $Step
                Write-Host "The configuration for this Role is not available yet."
                Start-ECI.EMI.Automation.Sleep
            }
            "2016DC" 
            {
                Write-Host $Step
                Write-Host "The configuration for this Role is not available yet."
                Start-ECI.EMI.Automation.Sleep
            }
            "2016DCFS" 
            {
                Write-Host $Step
                Write-Host "The configuration for this Role is not available yet."
                Start-ECI.EMI.Automation.Sleep
            }
            "2016VDA" 
            {
                Write-Host $Step
                Import-Module ECI.EMI.Automation.Role.Citrix.Dev -DisableNameChecking
                Install-ECI.XenDesktopVDA 
                Configure-CrossForest
                Install-XenDesktopStudio
        
            }
            "2016SQL" 
            {
                Write-Host $Step
                Write-Host "The configuration for this Role is not available yet."
                Start-ECI.EMI.Automation.Sleep
            }
            "2016SQLOMS"  
            {
                Write-Host $Step
                Write-Host "The configuration for this Role is not available yet."
                Start-ECI.EMI.Automation.Sleep
            }
        }
    }

    END 
    {
        ### Close Script
        ###--------------------------
        Write-Host "`r`n" ("=" * 75) "`r`nEND CONFIGURE OS IN-GUEST: $((Get-PSCallStack)[0].Command) STEP-$Step `r`n" ("=" * 75)
        #Write-ServerBuildTag                                                               # <---- write new Server Build Tag function !!!!!!!!!!!!!!!
        Stop-Transcript

        ### END CONFIGURE OS IN-GUEST SCRIPT
    }
}
