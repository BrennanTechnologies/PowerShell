cls
$global:HostName = "Test-LD5-p0Buq"
$global:AutomationLogPath = "C:\Scripts\_VMAutomationLogs"

function Import-ECI.EMI.Configure.OS.ParametersInGuest
{
    Get-Content -Path ("C:\Scripts\_VMAutomationLogs" + "\" + $HostName + "\InGuestParams.txt" )
    
}

Import-ECI.EMI.Configure.OS.ParametersInGuest


function Import-ECI.EMI.Configure.OS.ParametersInGuest
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

Import-ECI.EMI.Configure.OS.ParametersInGuest