



function Import-ECI.EMI.Automation.Modules
{
    ### Import ECI Automation Modules
    ###----------------------------------------
    foreach($Module in (Get-Module -ListAvailable ECI.*)){Import-Module -Name $Module.Path -DisableNameChecking}
}


function Import-ECI.EMI.OS.ParametertoGuest
{
    $InGuestParamFile =  (Get-Item -Path "C:\Temp\InGuestLogs\InGuestParams.txt").FullName
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
}



Import-ECI.EMI.OS.ParametertoGuest

Write-Host "PageFileLocation: " $PageFileLocation
Write-Host "Step: " $Step
Write-Host "Env: " $Env
Write-Host "Environment: " $Environment