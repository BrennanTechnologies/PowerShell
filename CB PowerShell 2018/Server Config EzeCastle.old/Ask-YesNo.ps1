cls

function Ask-Continue()
{
    $ReadHost = Read-Host "Continue? [y/n]"
    $ReadHost = $ReadHost.ToUpper()

    while($ReadHost -ne "y")
    {
        if ($ReadHost -eq 'n') 
        {
            write-host "No"
            exits
        }

        $ReadHost = Read-Host "Continue? [y/n]"
    }
}

### Method 1: Switch Statement
<#
# Yes/No From the command line  
Write-host "Continue? (Default is No)" -ForegroundColor Yellow 

$Readhost = Read-Host " ( y / n ) " 
$Readhost = $Readhost.ToUpper()

Switch ($ReadHost) 
    { 
    Y {Write-host "Yes, Download PublishSettings"; $PublishSettings=$true} 
    N {Write-Host "No, Skip PublishSettings"; $PublishSettings=$false} 
    Default {Write-Host "Default, Skip PublishSettings"; $PublishSettings=$false} 
    } 
#>

<#
### Method 1: Switch Statement
Write-host "Continue?"
$ReadHost = Read-Host " ( Y / N ) "
$Readhost = $Readhost.ToUpper()

while("Y","N" -notcontains $ReadHost)
{
	$ReadHost = Read-Host "Please enter Y or N"
}
elseif($ReadHost = "Y")
{
    write-host "You said YES"
}
elseif($ReadHost = "N")
{
    write-host "You said NO"
}
#>

<#

do{

...something

}while($(Read-Host "Continue? (Y)es or (N)o").ToLower() -match 'y')
#>
<#
### Method 1: Switch Statement
Write-host "Continue?"
$ReadHost = Read-Host " ( Y / N ) "
$Readhost = $Readhost.ToUpper()
$Readhost 
do
{
    write-host "Please answer Y or N"
}

while("Y","N" -notcontains $ReadHost)

if($ReadHost = "Y")
{
    write-host "You said YES"
}
elseif($ReadHost = "N")
{
    write-host "You said NO"
}
#>