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


function Call-Whatif
{
    [CmdletBinding()]
    param(
          
        [Parameter(Mandatory = $False)][switch] $Whatif,
        [Parameter(Mandatory = $False)][switch] $Commit
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
        $HashArguments = [ordered]@{
        Target             = $Target
        CommitValue        = $CommitValue 
        CommitScriptBlock  = $CommitScriptBlock
        UndoValue          = $UndoValue
        UndoScriptBlock    = $UndoScriptBlock
        Whatif             = $Whatif
        Commit             = $Commit
        }

        Process-Whatif @HashArguments
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
        Write-host "Target =  " $User.Name -ForegroundColor Cyan
        #Write-host "POBox =  " $User.POBox -ForegroundColor Cyan
        Call-Whatif -whatif #-commit
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
 
        # Close Script
        #--------------------------
        Close-LogFile
        Measure-Script
        Stop-Transcribing
    }
}
Execute-Script