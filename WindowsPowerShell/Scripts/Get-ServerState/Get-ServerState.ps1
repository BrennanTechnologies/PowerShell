<#
.SYNOPSIS
Get the State of Computers. Online, Offline, All.

.DESCRIPTION
Queries AD for computer objects, then performs test for Ping, DNS, RDP, UpTime, etc, to detrmine OnLine/OffLine state.

.PARAMETER OUFilter
[string[]] Filter for Get-ADUser command of AD OU's not to query.

.PARAMETER SearchBases
[array] Searchbases for Get-ADUser command.

.PARAMETER ADProperties
[array] Return AD Properties of computer objects. 

.PARAMETER Online
[switch] Conditional Logoic Switch to get all ONLINE Computers.

.PARAMETER Offline
[switch] Conditional Logoic Switch to get all OFFLINE Computers.

.EXAMPLE
Get-ServerState -State OnLine
Get-ServerState -State OffLine -SearchBase $SearchBase

.NOTES
General notes
#>
function Get-ServerState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string[]]
        $OUFilter = "OU=Deprovisioned,DC=memhosp,DC=com"
        ,
        [Parameter(Mandatory=$false)]
        [array]
        $SearchBases = @(
            "DC=memhosp,DC=com"
            #"OU=Servers,DC=memhosp,DC=com",
            #"OU=Workstations,DC=memhosp,DC=com",
            #"OU=Workstations W7,DC=memhosp,DC=com"
        )
        ,
        [Parameter(Mandatory=$false)]
        [array]
        $ADProperties = @(
            "SamAccountName",
            "Name",
            "Description",
            "DistinguishedName",
            "dNSHostName",
            "ObjectClass",
            "OperatingSystem",
            "LastLogon",
            "lastLogonTimestamp",
            "whenCreated"
        )
        ,
        [Parameter(Mandatory=$false)]
        [ValidateSet("All","Online","OffLine",$null)]
        [string]
        $State = $null
    )
    Begin{
        Clear-Host
        $TranscriptPath = "$PSScriptRoot\Transcript-Get-ServerState-$(Get-Date -F "MM-dd-yyyy").txt"
        Start-Transcript -Path $TranscriptPath

        ### Hide Progress Bar 
        $global:ProgressPreference = "SilentlyContinue" 

        ### Set Conditional Logic Statements
        ###------------------------------------
        switch ($State)
        {
            $OnLine {
                ### Host is OnLine
                ###---------------
                $LogicSwitch = '( $Computer.PingIPAddress -ne $null ) 
                                    -AND 
                                ( $Computer.ResolveDNS -ne $null ) 
                                    -AND 
                                ( $Computer.TcpTestSucceeded -ne $true ) 
                                    -AND 
                                ( $Computer.LastLogonTimestamp -lt  $(Get-Date).AddDays(-30) )'
            }
            $OffLine {
                ### Host is OffLine
                ###---------------
                $LogicSwitch = '( $Computer.PingIPAddress -eq $null ) 
                                    -AND 
                                ( $Computer.ResolveDNS -eq $null ) 
                                    -AND 
                                ( $Computer.TcpTestSucceeded -eq $true ) 
                                    -AND 
                                ( $Computer.LastLogonTimestamp -lt  $(Get-Date).AddDays(-30) )'
            }
            { @("All","Default",$null) } {
                $LogicSwitch = $true
            }
        }
    }
    Process {
        $ADComputers = @()
        foreach($SearchBase in $SearchBases){
            $ADComputers += Get-ADComputer -Filter * -SearchBase $SearchBase -Properties $ADProperties | 
                Select-Object -Property $ADProperties  | Where-Object { $_.DistinguishedName -notlike "*,$OUFilter" }
            Write-Host "$SearchBase Count: " $ADComputers.Count -ForegroundColor Magenta
        }
        $ALLComputers = @()
        foreach($Computer in $ADComputers){
            Write-Host "Computer Name       :" $Computer.Name -ForegroundColor Cyan
            $LastBootUpTime     = $null
            $UpTimeDays         = $null

            ### Ping IP Address (ICMP Ping Test)
            ###---------------------------------------------------
            try{
                $PingTest = Test-Connection -ComputerName $Computer.Name -Count 1 -ErrorAction Stop 
                [System.Net.IPAddress]$PingIPAddress = $PingTest.IPV4Address.IPAddressToString
            }catch{
                $PingIPAddress = $null
            }
            Write-Host "PingResult          :"  $PingIPAddress

            ### Resolve DNS Name (NSLookup)
            ###---------------------------------------------------
            try{
                $ResolveDNS = Resolve-DnsName -Name $Computer.Name -ErrorAction Stop
                [System.Net.IPAddress]$ResolveDNSIP = $ResolveDNS.IP4Address
            }catch{
                $ResolveDNSIP = $null
            }
            Write-Host "ResolveDNSIP        :" $ResolveDNSIP

            ### Get DNS Host Entry (Query DNS Server)
            ###---------------------------------------------------
            try{
                $GetDNSHostEntry = [System.Net.Dns]::GetHostEntry($Computer.dNSHostName).HostName
            }catch{
                $GetDNSHostEntry = $null
            }
            Write-Host "GetDNSHostEntry     :" $GetDNSHostEntry              

            ### Get IP DNS Host Entry (Reverse Lookup by IP)
            ###---------------------------------------------------
            try{
                $ReversePDNSLookup = [System.Net.Dns]::GetHostEntry($PingIPAddress).HostName
            }catch{
                $ReversePDNSLookup = $null
            }
            Write-Host "ReversePDNSLookup   :" $ReversePDNSLookup 
                        
            ### Test RDP Port 3389 (RDP Port 3389 Is Open)
            ###---------------------------------------------------
            try{
                $TestConnection = Test-NetConnection -ComputerName $Computer.Name -Port 3389 -ErrorAction Stop 
                [boolean]$RDPPort3389 = $TestConnection.TcpTestSucceeded
            }catch{
                $RDPPort3389 = $null
            }
            Write-Host "RDPPort3389         :" $RDPPort3389

            ### Test Host Name UNC Path (UNC Administrative Share by HostName)
            ###---------------------------------------------------
            try{
                $TestHostNameUNCPath = Test-Path -Path "\\$($Computer.dNSHostName)\C$" -ErrorAction Stop
            }catch{
                $TestHostNameUNCPath = $null
            }
            Write-Host "TestHostNameUNCPath :" $TestHostNameUNCPath

            ### Last Login Date
            ###---------------------------------------------------
            [DateTime]$LastLogon = [datetime]::FromFileTime($Computer.LastLogon).ToString('MM/dd/yyyy')
            [DateTime]$LastLogonTimestamp = [DateTime]::FromFileTime($Computer.LastLogonTimestamp).ToString('MM/dd/yyyy')
            $LastLogonDays = $(Get-Date) - $LastLogonTimestamp
            $LastLogonDays = $LastLogonDays.Days
            Write-Host "LastLogon           :" $LastLogon
            Write-Host "LastLogonTimestamp  :" $LastLogonTimestamp
               
            ### Get UpTime
            ###---------------------------------------------------
            if($GetDNSHostEntry){
                try{
                    $WSMan = Test-WSMan -ComputerName $GetDNSHostEntry -ErrorAction Stop
                }catch{
                    $WSMan = $null
                }
                if($WSMan){
                    Write-Host "WSMan       : " $WSMan -ForeGroundColor Green
                    try{
                        $OS = Get-WmiObject Win32_OperatingSystem -ComputerName $GetDNSHostEntry
                        $LastBootUpTime = $OS.ConvertToDateTime($OS.LastBootUpTime)
                        $UpTimeDays = ((Get-Date) -  $LastBootUpTime).Days
                    }catch{
                        $LastBootUpTime = $null
                        $UpTimeDays     = $null                   
                    }
                    Write-Host "LastBootUpTime      : " $LastBootUpTime  -ForeGroundColor Yellow
                    Write-Host "UpTimeDays          : " $UpTimeDays      -ForeGroundColor Yellow
                }else{
                    Write-Host "WSMan       : False" -ForeGroundColor Red
                }
            }
            $Computer = [PSCustomObject]@{
                Name                = $Computer.Name
                dNSHostName         = $Computer.dNSHostName
                Description         = $Computer.Description
                DistinguishedName   = $Computer.DistinguishedName
                ObjectClass         = $Computer.ObjectClass
                OperatingSystem     = $Computer.OperatingSystem
                PingIPAddress       = $PingIPAddress
                ResolveDNSIP        = $ResolveDNSIP
                GetDNSHostEntry     = $GetDNSHostEntry
                ReversePDNSLookup   = $ReversePDNSLookup
                RDPPort3389         = $RDPPort3389
                TestHostNameUNCPath = $TestHostNameUNCPath
                TestIPUNCPath       = $TestIPUNCPath
                LastLogon           = $LastLogon
                LastLogonTimestamp  = $LastLogonTimestamp
                LastLogonDays       = $LastLogonDays
                WSMan               = $WSMan
                LastBootUpTime      = $LastBootUpTime
                UpTimeDays          = $UpTimeDays               
                whenCreated         = $Computer.whenCreated    
            }
            $AllComputers += $Computer
        }
        
        ### Execute Conditional Logic Statements
        ###------------------------------------
        $Computers = @()
        foreach($Computer in $AllComputers){
            if($LogicSwitch){
                $Computers += $Computer
            }
        }
    }
    End{
        ### Show Computer Counts
        ###-----------------------
        Write-Host "All Computers Count  ;" $ADComputers.Count -ForegroundColor Magenta
        Write-Host "Live Computers Count ;" $Computers.Count -ForegroundColor Magenta
        
        ### Export Data File
        ###-----------------------
        $ExportPath = "$PSSCriptRoot\MemHosp-Depro-Computers-$(Get-Date -f MM-dd-yyyy).csv"
        Write-Host "ExportPath: " $ExportPath
        $Computers | Export-CSV -Path $ExportPath -NoTypeInformation -Delimiter ';'
        Start-Process $ExportPaths
        
        Stop-Transcript
    }
}
Get-ServerState -State Online
