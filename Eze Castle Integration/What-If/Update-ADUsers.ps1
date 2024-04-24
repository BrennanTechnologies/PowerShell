    #region Document Properties
    <#----------------------------------------------------------------------------------------------

    .DATE
        April 2018

    .DESCRIPTION

        This function is a custom commandlet ...

        ... is an advanced "WhatIf" PowerShell function ... 

    .PARAMETERS

        -Target 
         [mandatory]
        
            Target object being changes.

        -Results 
         [mandatory]
        
            Displays the Results of the change before it is committed.

        -Action 
         [mandatory]
            Scriptblock of the action to be performed. 
            ex: Update-ADUser

        -Confirm 
         [optional]

            Ask for confirmation before making changes.

        -Commit
         [optional]
        
            Ask to commit changes after displaying the confirm messages

        -Rollback 
         [optional]

            Option to record any changes ("commits") made so they can be reverted ("rollback").

        -Record 
         [optional]
     
            Creates a Logfile of any changes

        -PageSize 
         [optional]

            Size of the results in the confirmation page.

    .USAGE

    
        usage:

            Function-Name [-Target] [-Action] [-Results] [-Confirm] [-Commit] [-Rollback] [-PageSize]

        example:

            Update-ADUser -confirm -record -pagesize



    .OUTPUT

        -Logfile

        -RollbackLog


    .Author
        Chris Brennan
        cbrennan@eci.com
        brennanc@hotmail.com


    .REFERENCE
        http://dille.name/blog/2017/08/27/how-to-use-shouldprocess-in-powershell-functions/
        https://4sysops.com/archives/the-powershell-whatif-parameter/
        https://blogs.technet.microsoft.com/heyscriptingguy/2011/11/21/make-a-simple-change-to-powershell-to-prevent-accidents/
        Get-help about_Functions_CmdletBindingAttribute
        $PSCmdlet 

    ----------------------------------------------------------------------------------------------#>
    #endregion

function Run-Whatif
{
    [CmdletBinding(SupportsShouldProcess=$True)]
    param($ScriptBlock)
<#
    [Parameter(Mandatory = $False, Position=0)]
    [String]$Whatif_ScriptBlock,
    [Parameter(Mandatory = $False, Position=1)]
    [String]$Rollback,
    [Parameter(Mandatory = $False, Position=2)]
    [String]$Confirm
    [Parameter(Mandatory = $False, Position=3)]
    [String]$Record
    [Parameter(Mandatory = $False, Position=4)]
    [String]$Target
    [Parameter(Mandatory = $False, Position=5)]
    [String]$Action
    [Parameter(Mandatory = $False, Position=6)]
    [String]$PageSize

#>
    Begin 
    {

        #region Begin
        Clear-Host
        Write-Host "Starting Function with WhatIf" -ForegroundColor Magenta
        ################################
        ### Set Default Preference
        ################################
        #$WhatIfPreference  = $False
        #$ConfirmPreference = #False
    
        ################################
        ### Debugging 
        ################################
        #write-host "WhatIfPreference : " $WhatIfPreference
        #write-host "ConfirmPreference: " $ConfirmPreference
        #endregion

    }

    Process 
    {
        #region Process
        Write-Host "Running Function with WhatIf" -ForegroundColor Yellow
        #endregion

<#
        function Record
        {
            ################################################
            ### Write Changes to Database
            ################################################

        }

        function Confirm-Action
        {
            write-host $Whatif_Results -ForegroundColor Red
        
            $ReadHost = Read-Host "Confirm [Y/N]"
            $ReadHost = $ReadHost.ToUpper()
            if ($ReadHost -eq "Y" )
            {
                write-host "Running Scriptblock Commands" -ForegroundColor Yellow
                write-host $Whatif_Results -ForegroundColor Red
                Invoke-Command $Whatif_ScriptBlock
                # Write Changes
            }
            elseif($ReadHost -eq "N")
            {
                write-host "Skipping ScriptBlock Commands" -ForegroundColor Yellow
                Continue
            }
            elseif (($ReadHost -ne "Y") -or ($ReadHost -ne "N"))
            {
                write-host "You did not enter Y/N! Please try again." -foregroundcolor Yellow
                Confirm-Action
            }
        } 

        If ($PSCmdlet.ShouldProcess($ADUser.Name,$Whatif_Results)) 
        {
            $Results
            Confirm-Action
        }
#>
    }


    End 
    {
        #region End
        Write-Host "Ening Function with WhatIf" -ForegroundColor Magenta
        #endregion
    }

}

Run-Whatif -ScriptBlock {Write-host "Test"}



<#
function Update-ADUser
{
    $ADUsers = Get-ADUser -Filter 'Name -like "Chris B*"' -Properties *

    foreach($ADUser in $ADUsers)
    {
        $OldADSurname = $ADUser.Surname
        $NewADSurname = "Brennan4"

        $Whatif_Results = "Replacing OldADSurname: $OldADSurname with NewADSurName: $NewADSurname"

        $Whatif_ScriptBlock = 
        {
            ### Execute Commands
            Set-ADUser -Identity $ADUser -Surname $NewADSurname #-Confirm
        }   
   
        ########################################################
        ### Excecute ScriptBlock Code Using Whatif Parameter
        ########################################################
        Execute-Whatif -whatif
   }    
}

Update-ADUser
#>    


