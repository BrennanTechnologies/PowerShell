<#
.DESCRIPTION
       
    This function provides Whatif, Commit, Confirm, Undo, and Rollback capabilities to any "SET" commands.

.DATE
    4-27-18
    
.AUTHOR
    Chris Brennan  cbrennan@eci.com

.FUNCTION

This function uses a custom cmdlet called "Process-WhatIf" that is located in the module "CommonFunctions".

    INPUTS:
        $Target
        $CommitValue 
        $CommitScriptBlock
        $UndoValue
        $UndoScriptBlock

    CommitScriptBlock:

        - "Set" Command(s) to perform.

            $CommitScriptBlock = 
            {
                Set-ADUser -Identity "$Target" -POBox "$CommitValue"
            }

    UndoScriptBlock:
    
        - Command(s) to reverse te action of the Set command.

            $UndoScriptBlock = 
            {
                Set-ADUser -identity "$Target" -POBox @{Remove = "$UndoValue"}
            }
        
    SWITCHES:
        -Whatif
        -Commit
        -Force
        -RollBack

    - Whatif
        Does not Set, only Logs Results of Set Command.
 
        - Confirm
        Confirms the Set command.
                   
    - Commit
        - Runs Set Command and. Logs the Set Command, Results, and Undo Command.
        - A "Confirm" action response is required for each Set Target action.
        
    - Force
        - Overrides the Confirm request for all sets.
        
    - Rollback
        _ Uno the actions of the Set/Commit command.

    USAGE:  - Must use either -Whatif or -Commit.
            - Can ONLY use EITHER -Whatif or -Commit. Not Both!
            - Force is optional when -Commit is used.

            - Whatif : This switch ONLY runs a whatif and show the result. NO SETS or COMMITS are made.
            - Commit : This switch will Commit the Set command actionss. By default the -Confirm switch is set to on. (You will be prompted to Confirm Actions)
            - Force  : This switch will overide the -Confirm switch and force all commit actions. (You WILL NOT be prompted to Confirm Actions)
            - RollBack  : Rolls back all chanches made by the commit command.

    USAGE:  - Must use either -Whatif or -Commit -Force
            
    EXAMPLES:
                Invoke-Whatif -Whatif 
                Invoke-Whatif -Commit
                Invoke-Whatif -Commit -Force
                Invoke-Whatif -Commit -Rollback

.OUTPUT
    
    $SCRIPTPATH\LOGS:
    
        ErrorLog:
            - Error Logs of ll errors trapped by the Error-Trap function.
        TrnscriptLog:
            - Complete Transcript of the script execution.

    $SCRIPTPATH\REPORTS
    
        WhatifLog:
             - Logs of what the results would be when the script is executed.

            Example:
                WHATIF COMMAND: Set-Mailbox -Identity CN=Ted Percival,OU=Users,OU=MacdonaldVentures,OU=Clients,DC=ecilab,DC=net -EmailAddresses @{add = tpercival@corp.macdonaldventures.com} -confirm 
                WHATIF RESULTS: 	
                                TARGET:  CN=Ted Percival,OU=Users,OU=MacdonaldVentures,OU=Clients,DC=ecilab,DC=net   
	                            VALUE:   tpercival@corp.macdonaldventures.com

        CommitLog:
            - Containts each "Set" command and the variable values
            - Contains the "Undo" command and the variable values

            Example:
                SET COMMAND: Set-Mailbox -Identity CN=Ted Percival,OU=Users,OU=MacdonaldVentures,OU=Clients,DC=ecilab,DC=net -EmailAddresses @{add = tpercival@corp.macdonaldventures.com} -confirm 
                UNDO COMMAND:Set-Mailbox -identity CN=Ted Percival,OU=Users,OU=MacdonaldVentures,OU=Clients,DC=ecilab,DC=net -EmailAddresses @{remove=tpercival@corp.macdonaldventures.com}


        RollBackDataFile:
            - CSV Data Files of the the changes made that would required to completely "Undo" the Conmmits
                - $Target
                - $OriginalValue
                - $NewValue

            Example:
                "Target","CommitValue","UndoValue"
                "CN=Mufasa LKing,OU=Users,OU=MacdonaldVentures,OU=Clients,DC=ecilab,DC=net","529 5th Ave","529 5th Ave"
#>

function Import-CommonFunctions 
{
    ### Reload Module at RunTime
    if(Get-Module -Name "CommonFunctions"){Remove-Module -Name "CommonFunctions"}

    ### Set the Module Location
    if($env:USERDNSDOMAIN -eq "ECILAB.NET")   {$Module = "\\tsclient\P\CBrennanScripts\Modules\CommonFunctions\CommonFunctions.psm1"}
    if($env:USERDNSDOMAIN -eq "ECICLOUD.COM") {$Module = "\\tsclient\P\CBrennanScripts\Modules\CommonFunctions\CommonFunctions.psm1"}
    if($env:USERDNSDOMAIN -eq "ECI.CORP")     {$Module = "\\eci.corp\dfs\nyusers\cbrennan\CBrennanScripts\Modules\CommonFunctions\CommonFunctions.psm1"}
    
    ### Import the Module
    Import-Module -Name $Module -DisableNameChecking #-Verbose
    
    ### Test the Module - Exit Script on Failure
    if( (Get-Module -Name "CommonFunctions")){Write-Host "Loading Custom Module: CommonFunctions" -ForegroundColor Green}
    if(!(Get-Module -Name "CommonFunctions")){Write-Host "The Custom Module CommonFunctions WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
}

function Invoke-Whatif
{
    [CmdletBinding()]
    param(
          
        [Parameter(Mandatory = $False)][switch] $Whatif,
        [Parameter(Mandatory = $False)][switch] $Commit,
        [Parameter(Mandatory = $False)][switch] $Force,
        [Parameter(Mandatory = $False)][switch] $RollBack
    )   

        ### Set the $TARGET
        #--------------------------------------------- 
        #Write-host "Target =  " $User.Name -ForegroundColor Cyan
        $Target    = $User

        ### Set the $VALUE
        #--------------------------------------------- 
        $CommitValue = "529 5th Ave"
        $UndoValue =  $User.POBox

        ### SetScriptBlock Commands
        #---------------------------------------------    
        $CommitScriptBlock = 
        {
            Set-ADUser -Identity "$Target" -POBox "$CommitValue"
        }

        ### UndoScriptBlock Commands
        #---------------------------------------------    
        $UndoScriptBlock = 
        {
            Set-ADUser -identity "$Target" -POBox @{Remove = "$UndoValue"}
        }
        
        ### Run Whatif Processs
        #---------------------------------------------    
     
        ### Need to use Splat to pass arguments with Hash table to pass switches -Whatif & -Commit
        $WhatifArguments   = [ordered]@{
        Target             = $Target
        CommitValue        = $CommitValue 
        CommitScriptBlock  = $CommitScriptBlock
        UndoValue          = $UndoValue
        UndoScriptBlock    = $UndoScriptBlock
        Whatif             = $Whatif
        Commit             = $Commit
        Force              = $Force
        RollBack           = $RollBack
        }

        Process-Whatif @WhatifArguments
}

function Do-Something
{
    ### GetScriptBlock Commands
    #---------------------------------------------
    
    $SearchBase = "OU=Users,OU=MacdonaldVentures,OU=Clients,DC=ecilab,DC=net"
    
    $Users = Get-ADUser -Filter * -properties * -SearchBase $SearchBase -SearchScope Subtree #-Identity ""
    
    $GetScriptBlock = 
    {
        $Users = Get-ADUser -Filter * -properties * -SearchBase $SearchBase -SearchScope Subtree #-Identity ""
    }
    
    Invoke-Command $GetScriptBlock


    ### Set the $TARGET
    #--------------------------------------------- 
    foreach ($User in $Users)
    {
        ### Set Target
        $Target = $User
        Write-host "Target =  " $User.Name -ForegroundColor Cyan
        
        ### Execute the Scriptblock
        #--------------------------------------------- 

        <############################################################################################
            USAGE:  - Must use either -Whatif or -Commit.
                    - Can ONLY use EITHER -Whatif or -Commit. Not Both!
                    - Force is optional when -Commit is used.

                    - Whatif : This switch ONLY runs a whatif and show the result. NO SETS or COMMITS are made.
                    - Commit : This switch will Commit the Set command actionss. By default the -Confirm switch is set to on. (You will be prompted to Confirm Actions)
                    - Force  : This switch will overide the -Confirm switch and force all commit actions. (You WILL NOT be prompted to Confirm Actions)
                    - RollBack  : Rolls back all chanches made by the commit command.

            USAGE:  - Must use either -Whatif or -Commit -Force
            
            EXAMPLES:
                     Invoke-Whatif -Whatif 
                     Invoke-Whatif -Commit
                     Invoke-Whatif -Commit -Force
                     Invoke-Whatif -Commit -Rollback
        <#############################################################################################>
        
        #Invoke-Whatif -Whatif
        #Invoke-Whatif -Commit
        Invoke-Whatif -Commit -Force
        #Invoke-Whatif -RollBack
    }
}



function Execute-Script 
{
   
    BEGIN 
    {
        # Initialize Script
        #--------------------------
        Clear-Host
        Write-Host "`nRunning: BEGIN Block" -ForegroundColor Blue
        Import-CommonFunctions 
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
 
        # Close Script
        #--------------------------
        Close-LogFile
        Measure-Script
        Stop-Transcribing
    }
}
Execute-Script