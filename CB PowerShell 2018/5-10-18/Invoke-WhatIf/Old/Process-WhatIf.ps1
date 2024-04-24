function Import-CBrennanModule 
    {
    ### Reload Module at RunTime
    if(Get-Module -Name "CBrennanModule"){Remove-Module -Name "CBrennanModule"}

    ### Set the Module Location
    if($env:USERDNSDOMAIN -eq "ECILAB.NET")   {$Module = "\\tsclient\P\CBrennanScripts\CBrennanModule\CBrennanModule\CBrennanModule.psm1"}
    if($env:USERDNSDOMAIN -eq "ECICLOUD.COM") {$Module = "\\tsclient\P\CBrennanScripts\CBrennanModule\CBrennanModule\CBrennanModule.psm1"}
    if($env:USERDNSDOMAIN -eq "ECI.CORP")     {$Module = "\\eci.corp\dfs\nyusers\cbrennan\CBrennanScripts\CBrennanModule\CBrennanModule\CBrennanModule.psm1"}
    
    ### Import the Module
    Import-Module -Name $Module -DisableNameChecking #-Verbose
    
    ### Test the Module - Exit Script on Failure
    if( (Get-Module -Name "CBrennanModule")){Write-Host "Loaded Custom Module: CBrennanModule" -ForegroundColor Green;Write-Host "Type Get-CBCommands (gcbc) to see commands`n" -ForegroundColor DarkGreen}
    if(!(Get-Module -Name "CBrennanModule")){Write-Host "The Custom Module CBrennanModule WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
}

function Process-WhatIf
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact="High")]
    Param(
    [Parameter(Mandatory = $True, Position = 0)] [string]$Target,
    [Parameter(Mandatory = $True, Position = 1)] [string]$Value,
    [Parameter(Mandatory = $True)] [scriptblock]$SetScriptBlock,
    [Parameter(Mandatory = $False)][scriptblock]$GetScriptBlock,
    [Parameter(Mandatory = $False)][scriptblock]$UndoScriptBlock,
#    [Parameter(Mandatory = $False)][switch] $Whatif,
#    [Parameter(Mandatory = $False)][switch] $Confirm,
    [Parameter(Mandatory = $False)][switch] $Commit,
    [Parameter(Mandatory = $False)][switch] $Rollback
    )

    ### Validate Target is a Single Object
    #--------------------------------------------------------
    if($Target -IsNot [System.Array] -and $Target.count -eq 1) 
    {write-host "Validated: Target is a Single Object"}
    else{write-log "Target is not a single object!." -ForegroundColor Red}

    ### Build Whatif $Results
    #---------------------------------------------
    $WhatifFile = $LogPath + "\Whatif_" + $ScriptName + "_" + $TimeStamp + ".txt"
    $Results = "`tTARGET:  " + $Target + "   `n`tVALUE:   " + $Value
    
    [string]$Command = ((($SetScriptblock -replace 'Target', $Target) -replace 'Value', $Value) -replace [char]36,$NULL)
    $Command = $Command.Replace('$','')

    ### "Rollback"/Undo Command
    #---------------------------------------------
    $CommitLog = $LogPath + "\Commit_" + $ScriptName + "_" + $TimeStamp + ".txt"
    $UndoCommand = "Set-Mailbox -identity $Target -EmailAddresses @{remove=$Value}"

    ###########################
    ### "Whatif" Flag is True
    ###########################
    
    ### NOTICE: in "Whatif" mode - Must Use "-Whatif:$false" to force any commands to run
    
    if ($WhatIfPreference)
    {
        ### Write the Command & Results
        #--------------------------------- 
        write-host "WHATIF Flag is True: Running Whatif Process ...." -ForegroundColor Green
        write-host "WHATIF COMMAND:`n`t $Command" -ForegroundColor Yellow
        write-host "WHATIF RESULTS:`n $Results" -ForegroundColor Yellow
        
        ### Log Command and Results
        #---------------------------------
        "WHATIF COMMAND: " + $Command | Out-file -FilePath $WhatifFile -Append -Force -Whatif:$false
        "WHATIF RESULTS: " + $Results | Out-file -FilePath $WhatifFile -Append -Force -Whatif:$false
    }

    ###########################
    ### "Commit" Flag is True
    ###########################
    elseif ($Commit)
    {
        ### Validate Target is a Single Object
        #--------------------------------------------------------
        if($Target -IsNot [System.Array] -and $Target.count -eq 1) 
        {
            write-host "Validated: Target is a Single Object"
            
            ### Write the Command & Results
            #---------------------------------
            write-host "COMMIT flag is True: Running COMMIT Logic ...." -ForegroundColor Green
            write-host "COMMIT COMMAND:`n`t $Command" -ForegroundColor Yellow

            ### Log Command and Results
            #---------------------------------
            "SET COMMAND: "+ $Command | Out-file -FilePath $CommitLog -Append -Force -Whatif:$false

            #######################################
            ### Log "Rollback"/Undo Command                        
            #######################################
            write-host "UNDO COMMAND:`n`t$UndoCommand" -ForegroundColor Yellow
            "UNDO COMMAND:" + $UndoCommand | Out-file -FilePath $CommitLog -Append -Force -Whatif:$false
                        
            #######################################
            ### Execute Scriptblock Commands
            #######################################
            try
            {
                Invoke-Command $SetScriptblock
            }
            catch
            {
                write-host "Setting Mailbox properties`t: $MailBox.DistinguishedName" -ForegroundColor Red
                write-log $Error[0] yellow
                write-log "Catch: $($PSItem.ToString())" yellow
            }
            
            ### Debugging
            #---------------
            #Get-Mailbox "Ham Burglar" | fl EmailAddresses
            #Set-Mailbox -identity "Ham Burglar" -EmailAddresses @{remove="Ham@macdonaldventures.com"}
        }
    }
    
    ###############################################################
    ### If No "-Whatif or "-Confirm" Flag used then -- Do nothing
    ###############################################################

    elseif (!$WhatIfPreference -OR !$Commit)
    {
        write-host "This funtion $FunctionName must be run with the switch -Whatif or -Commit." -ForegroundColor Yellow
    }
    elseif (!$WhatIfPreference -AND !$Commit)
    {
        write-host "This funtion $FunctionName must be run with ONLY one switch -Whatif or -Commit." -ForegroundColor Yellow
    }
}


function Do-Something
{
    ### GetScriptBlock Commands
    #---------------------------------------------
    #$SearchBase = "OU=Users,OU=Hong Kong,DC=eci,DC=corp"
    #$SearchBase = "OU=Users,OU=edlcap,OU=Clients,DC=ecicloud,DC=com"
    #$SearchBase = "CN=Ham Burglar,OU=Users,OU=MacdonaldVentures,OU=Clients,DC=ecilab,DC=net"
    $SearchBase = "OU=Users,OU=MacdonaldVentures,OU=Clients,DC=ecilab,DC=net"

    $Users = Get-ADUser -Filter * -properties * -SearchBase $SearchBase -SearchScope Subtree #-Identity ""
    
    $GetScriptBlock = 
    {
        $Users = Get-ADUser -Filter * -properties * -SearchBase $SearchBase -SearchScope Subtree #-Identity ""
    }
    Invoke-Command $GetScriptBlock


    ### Set the Target
    #--------------------------------------------- 
    foreach ($User in $Users)
    {
        Write-host "User: " $User.Name
        $Target = $User
    }

    ### Set the Value
    #--------------------------------------------- 
    $Value = "529 5th Ave"

    ### SetScriptBlock Commands
    #---------------------------------------------    
    $SetScriptBlock = 
    {
        Set-ADUser -Identity $Target -POBox $Value 
    }

    ### UndoScriptBlock Commands
    #---------------------------------------------    
    $UndoScriptBlock = 
    {
        Set-ADUser -Identity $Target -POBox $OriginalValue 
    }
        
    ### Run Whatif Processs
    #---------------------------------------------    
    Process-Whatif -Target $Target -Value $Value -SetScriptBlock $SetScriptBlock -whatif #-commit
}


function Execute-Script 
{
   
    BEGIN 
    {
        # Initialize Script
        #--------------------------
        Clear-Host
        Write-Host "`nRunning: BEGIN Block" -ForegroundColor Blue
        Import-CBrennanModule
        Set-ScriptVariables
        Start-Transcribing 
        Start-LogFiles
    }

    PROCESS 
    {
        Write-Log "`nRunning: PROCESS Block" -ForegroundColor Blue
        # Run Functions
        #--------------------------
        Do-Something
    }

    END 
    {
        Write-Log "`nRunning: END Block"  -ForegroundColor Blue

        # Export Reports
        #--------------------------
        #Export-Report-Console -ReportName $ReportName -Report $Report
        #Export-Report-CSV -ReportName $ReportName -Report $Report
        #Export-Report-HTML -ReportName $ReportName -Report $Report
        #Export-Report-EMAIL -ReportName $ReportName -Report $Report -From "cbrennan@eci.com" -To "cbrennan@eci.com"  

        # Close Script
        #--------------------------
        Close-LogFile
        Measure-Script
        Stop-Transcribing
    }
}
Execute-Script