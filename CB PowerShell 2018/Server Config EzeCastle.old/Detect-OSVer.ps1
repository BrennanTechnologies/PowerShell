cls

### Detect OS Version
<#
Function Check-OSVersion

{

    ### Use WMI to get the Server OS Version
    $OSVersion = (Get-CimInstance Win32_OperatingSystem).version

    ### Alternate OS Version Detection w/ Major/Minor Build Nos.
    #$OSVersion = [environment]::OSVersion.Version
    #$OSVersion.version -match "(\d{1,1})\.(\d{1,1})\.(\d{1,4})" | out-null    
    #$OSVersion.Major
    #$OSVersion.Minor
    #$OSVersion.Build
 
    ### Check if OS Version Equals 2012 R2
    if ($OSVersion.version -eq "6.3.9600")
    {
        write-host "OS is 2012 R2"
    }

    $OSVerSion
}

#>

function Check-OSVersion
{
    $expectedVersion = "6.3.9600" # 2012 R2

    ### Using WMI to get OS Version
    $OSVersion = (Get-CimInstance Win32_OperatingSystem).version
    $OSVersion = [environment]::OSVersion.Version 

    if ($OSVersion -eq $expectedVersion)
    {
        Write-Host "This Server IS 2012 R2 - This version is $OSVersion" -ForegroundColor Green
    }
    else
    {
        Write-Host "This Server IS NOT 2012 R2 - This version is $OSVersion" -ForegroundColor Red
    }

}


Check-OSVersion