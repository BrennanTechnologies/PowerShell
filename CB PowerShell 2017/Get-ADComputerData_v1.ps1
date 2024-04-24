cls
import-module ActiveDirectory


Report = @()

$Domains = @()
$Domains += "risk-strategies.com"
$Domains += "dewittstern.com"


function Get-ComputerData
{
    ############################
    # Convert LastLogonTime
    ############################
            
    if ($Computer.lastlogontimestamp -gt 0)
    {
        $logindatetime = $Computer.lastlogontimestamp
        $lastlogintime = [datetime]::FromFileTime($logindatetime) 
    }
    else 
    {
        $usertime = "<Never>"
    }

    ############################
    # Build Hash Table
    ############################

    $hash = [ordered]@{            

        Domain             = $Domain
        Ping               = $Ping                  
        Name               = $Computer.name            
        CanonicalName      = $Computer.CanonicalName            
        Description        = $Computer.Description            
        DisplayName        = $Computer.DisplayName            
        DistinguishedName  = $Computer.DistinguishedName            
        DNSHostName        = $Computer.DNSHostName            
        IPv4Address        = $Computer.Login            
        OperatingSystem    = $Computer.OperatingSystem   
        whenCreated        = $Computer.whenCreated   
        whenChanged        = $Computer.whenChanged
        lastlogintime      = $lastlogintime
    }                           

    $PSObject =  New-Object PSObject -Property $hash
    $Report   += $PSObject   
}



foreach ($Domain in $Domains)
{

    $Domain = Get-ADDomain -Identity $Domain
    $Domain = $Domain.DistinguishedName

    write-host "Getting computers for domain: " -ForegroundColor Yellow -NoNewline
    write-host $Domain -ForegroundColor Cyan

    $Computers = Get-ADComputer -Filter * -Properties * -SearchBase $Domain -SearchScope SubTree
    

    foreach ($Computer in $Computers)
    {
        ############################
        # Ping each Computer name
        ############################

        write-host "Pinging . . . $computer" -ForegroundColor cyan
        $Ping = Test-Connection  "Server01" -Credential Domain01\Admin01 $Computer.name -BufferSize 16 -Count 1 #-quiet


        if($Ping)
        {
            $Ping = $Ping.IPV4Address.IPAddressToString
            Get-CompterData
        }
        else
        {
            $Ping = "Not Available"
        }
        write-host $Computer.name $Ping -foregroundcolor yellow
    }
} 
 

############################
# Export & Show the File
############################
$Path = "c:\reports\"
$ReportDate = Get-Date -Format ddmmyyyy
$ReportFile = $Path + "\1Report_$reportdate.txt"

$Report | Export-Csv -Path $ReportFile -NoTypeInformation 
start-process $ReportFile
