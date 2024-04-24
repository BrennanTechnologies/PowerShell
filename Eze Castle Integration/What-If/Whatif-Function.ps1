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

function Whatif-Function  
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact="Low")]
    param (
        
        [Parameter(Mandatory=$false)]
        [switch] $Whatif1,
        [Parameter(Mandatory=$false)]
        [switch] $Confirm1,
        [Parameter()]
        [switch] $Record,
        [Parameter()]
        [switch] $Rollback,
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Target,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $Results,
        [Parameter(Mandatory=$false, Position=2)]
        [int] $PageSize

    )

    Begin {
        Write-Host "Starting Whatif Function" $(Get-Date -Format u) -ForegroundColor Blue
    }

    Process {
        Write-Host "Executing Whatif Function" -ForegroundColor Yellow

        function Confirm-Action {
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

        ####################
        ### Whatif
        ####################
        function Execute-Whatif {
        If ($PSCmdlet.ShouldProcess($Target,$Results)) 
        {
            
            #$Results
            Write-Host "No Whatif - Executing Scriptblock" -ForegroundColor Red
            #Confirm-Action
        }
        else
        {
          write-host  "What if Else"
        }

        ####################
        ### Confirm
        ####################
        $Confim
        exit
        if ($Confim) 
        {
            write-host "Confirm On"
            write-host "Confirm: " $Confirm

            If ($PSCmdlet.ShouldContinue("Are you sure that you know what you are doing?","Delete with -Force parameter!")) 
            {  
                    write-Host "Confirm On" -ForegroundColor Red
                    #Remove-Item $File -Force
            } Else 
            {  
                    write-host "Confirm Denied"
                    write-host "Mission aborted!"     
            } 
        }
        if (!$Confim)
        {
            write-host "Confirm Off"
            write-host "Confirm: " $Confirm
        }

        ####################
        ### Record
        ####################
        if ($Record) {
            write-host "Record On"
            write-host $Record
        }
        if  (!$Record) {
            write-host "Record Off"
            write-host $Record
        }

        ###############################################################################
        }

        Execute-Whatif
    }

    End {
        Write-Host "Ending Whatif Function" $(Get-Date -Format u) -ForegroundColor Blue
    }
}

function Test-Function {
    $SearchBase = "OU=Users,OU=CBrennan,OU=Clients,DC=ecilab,DC=net"
    $Filter = "Name -like 'Chris B*'"
    
    $ADUsers = Get-ADUser -SearchBase $SearchBase -SearchScope 2 -Filter $Filter -Properties *

    foreach($ADUser in $ADUsers)
    {
        #Test
        #write-host $ADUser.Name -ForegroundColor Green

        $OldADSurname = $ADUser.Surname
        $NewADSurname = "Brennan4"
        
        $Target  = $ADUser.Name
        $Results = "Target: $Target Replacing OldADSurname: $OldADSurname with NewADSurName: $NewADSurname"
    }
    
    Whatif-Function $Target $Results -WhatIf #-confirm #-Record 
}



function Update-ADUser {
    $ADUsers = Get-ADUser -Filter 'Name -like "Chris B*"' -Properties *

    foreach($ADUser in $ADUsers)
    {
        $OldADSurname = $ADUser.Surname
        $NewADSurname = "Brennan4"
        
        $Target = $ADUser.Name
        $Results = "Target: $Target Replacing OldADSurname: $OldADSurname with NewADSurName: $NewADSurname"

        $Whatif_ScriptBlock = {
            
            ### Execute Commands
            Set-ADUser -Identity $ADUser -Surname $NewADSurname #-Confirm
        }   
   
        ########################################################
        ### Excecute ScriptBlock Code Using Whatif Parameter
        ########################################################
        Whatif-Function #-whatif $Target, $Results
   }    
}


cls
#Whatif-Function
#Update-ADUser
Test-Function