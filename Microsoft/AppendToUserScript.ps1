AppendToUserScript
Christopher Brennan (HCL Technologies Corporate Ser) <v-cbrennan@microsoft.com>
​
You
​
function AppendToUserScript {

    Param(

        [Parameter(Position = 0, Mandatory = $true)]

        [string]$Content

    )

 

    Add-Content -Path "$($CustomizationScriptsDir)\$($RunAsUserScript)" -Value $Content

}

 

