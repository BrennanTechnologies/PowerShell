cls
### Set Default Preference
$WhatIfPreference = $False
#write-host "WhatIfPreference" $WhatIfPreference 
#$WhatIfPreference 

Function Do-Stuff
{
        <#
        commandlet parameters
        -Verbose
        -Debug
        -WarningAction
        -WarningVariable
        -ErrorAction
        -ErrorVariable
        -OutVariable
        -OutBuffer
        #>

    [CmdletBinding(SupportsShouldProcess=$True)]
    param([string[]]$Objects)
     

    $ADUsers = Get-ADUser -Filter 'Name -like "Chris B*"' -Properties *

    $ScriptBlock = 
    {
        $Msg = "Chris.Brennan"
        $Msg.split(".")[0]
    }
    $Do = Invoke-Command $ScriptBlock
    
    write-host "WhatIfPreference : " $WhatIfPreference
    write-host "ConfirmPreference: " $ConfirmPreference
    ForEach($Object in $Objects)
    {
        <#
        ### Test if -WhatIf flag was used
        if ($pscmdlet.ShouldProcess("$Object", "Do"))
        {
            ### Do the action
            write-host "DO"
            #"Actually performing $ScriptBlock on $Object"
        }
        
        if(-not($pscmdlet.ShouldProcess($Object, "Test")))
        {
            ### Test the Action
            write-host "TEST"
            #write-host "Testing `$Action on $Object"
        }
        #>

        If ($PSCmdlet.ShouldProcess($Object, $Do)) 
        {
            #Invoke-Command $ScriptBlock
        }


    }
}

Do-Stuff -objects "hello", "Sweetie", "Goodbye" -whatif
    
# https://4sysops.com/archives/the-powershell-whatif-parameter/
#https://blogs.technet.microsoft.com/heyscriptingguy/2011/11/21/make-a-simple-change-to-powershell-to-prevent-accidents/

#Get-help about_Functions_CmdletBindingAttribute
#$PSCmdlet 