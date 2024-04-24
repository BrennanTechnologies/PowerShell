# If the IP returned is 159.251.x.x then it’s using BJC proxy.  If it’s anything else then it’s not.

& {
    Begin{
        CLS
        $TranscriptPath = "$PSScriptRoot\Transcript-Get-ProxyRegKeys_$(Get-Date -f "MM-dd-yyyy").txt"
        try{
            #Start-Transcript -Path $TranscriptPath
        }catch{}

        <#
        $ComputerGroup = @(
            #"BJC19500029", # Jason
            "BJC20610945" # Chris
            #"BJC11292509", # Brian Test
            #"BIOMEDLT01", # Brian Test
            #"CRPACSDX178", # Brian Test
            #"BJC20610945" # Brian Test
        )
        #>

        ### Import CSV Data
        $CSVPath = "D:\Chris.Brennan\Scripts\Get-RegKeys\MemHosp-DNSSuffix.csv"
        $ComputerGroup = Import-CSV -Path $CSVPath

        ### Get Credentials for PSSessions
        $PSCreds = Get-Credential -Message "Enter Password:" -UserName "CB47067_AD" 
    }
    Process{
        $Counter = 0
        $Computers = @()
        foreach($Computer in $ComputerGroup){
            $Counter++
            Write-Host "Computer $Counter of $($ComputerGroup.Count)"
            Write-Host "Computer   : " $Computer  -ForegroundColor Magenta

            if($Computer.GivenName){
                $Computer = $Computer.GivenName
            }
            
            ### Create Computer PSSession
            $PSSession = New-PSSession -ComputerName $Computer -Credential $PSCreds 
            Write-Host "Session ID : " $PSSession  -ForegroundColor Magenta
            if(-NOT $PSSession){
                Write-Host "NO PSSession for Computer Object: " $Computer -ForegroundColor Yellow
                $Computer = [PSCustomObject]@{
                    envCOMPUTERNAME      = $Computer
                    ProxySettingsPerUser = "NA"
                    AutoDetect           = "NA"
                    ProxyEnable          = "NA"
                    ProxyServer          = "NA"
                    ExternalIP           = "NA"
                    ServiceStatus        = "NA"
                    Serialnumber         = "NA"
                    RecordDate           = $(Get-Date -f "MM-dd-yyyy")
                }
            }
            
            ### ScriptBlock for Invoke-Command
            $ScriptBlock = {
                ### Get Computer Info
                Set-Service -Name RemoteRegistry -StartupType Automatic -Status Running
                Get-Service -Name RemoteRegistry | Start-Service

                $Service = Get-Service -Name RemoteRegistry 
                Write-Host "Service Name   : " $Service.Name
                Write-Host "Service Status : " $Service.Status

                $SerialNumber = $(Get-WmiObject win32_bios | select Serialnumber).Serialnumber
                Write-Host "SerialNumber   : " $Serialnumber

                $UserName = $(Get-WmiObject -Class Win32_ComputerSystem | select username)
                Write-Host "UserName       : " $UserName

                function Set-ProxyRegKeys {
                    Param(
                        ### Param Switch to Execute Set Registry Values
                        [Parameter()]
                        [switch]
                        $SetRegKey 
                    )
                    
                    ### ProxySettingsPerUser
                    ### -----------------       
                    $Key    = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\"
                    $Name   = "ProxySettingsPerUser"
                    $Type   = "REG_DWORD"
                    $Value  = "0"

                    $ProxySettingsPerUser = $(Get-ItemProperty -Path $Key ).ProxySettingsPerUser

                    if($ProxySettingsPerUser -eq $Value){
                        Write-Host "Current  - ProxySettingsPerUser: " $ProxySettingsPerUser -ForegroundColor Green
                    }else{
                        Write-host "Setting Reg Key                : " $Name -ForegroundColor Yellow 
                        Write-Host "Current Value                  : " $ProxySettingsPerUser -ForegroundColor Yellow
                        if($SetRegKey){
                            
                            Set-ItemProperty -Path $Key -Name $Name -Value $Value -Force
                        }
                    }
                    $ProxySettingsPerUser = $(Get-ItemProperty -Path $Key ).ProxySettingsPerUser
                    Write-Host "Verified - ProxySettingsPerUser: " $ProxySettingsPerUser -ForegroundColor Cyan

                    ### AutoDetect
                    ### -----------------
                    $Key     = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\"
                    $Name    = "AutoDetect"
                    $Type    = "REG_DWORD"
                    $Value   = "1"
    
                    $AutoDetect  = $(Get-ItemProperty -Path $Key).AutoDetect

                    if($AutoDetect -eq $Value){
                        Write-Host "Current  - AutoDetect          : " $AutoDetect -ForegroundColor Green
                    }else{
                        Write-host "Setting Reg Key                : " $Name -ForegroundColor Yellow 
                        Write-Host "Current Value                  : " $ProxySettingsPerUser -ForegroundColor Yellow
                        if($SetRegKey){
                            Set-ItemProperty -Path $Key -Name $Name -Value $Value
                        }
                    }
                    $AutoDetect  = $(Get-ItemProperty -Path $Key).AutoDetect
                    Write-Host "Verified - AutoDetect          : " $AutoDetect -ForegroundColor Cyan

                    ### ProxyEnable    
                    ### -----------------
                    $Key    = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\"
                    $Name   = "ProxyEnable"
                    $Type   = "REG_DWORD"
                    $Value  = "0"
    
                    $ProxyEnable = $(Get-ItemProperty -Path $Key).ProxyEnable

                    if($ProxyEnable -eq $Value){
                        Write-Host "Current  - ProxyEnable         : " $ProxyEnable -ForegroundColor Green
                    }else{
                        Write-host "Setting Reg Key                : " $Name -ForegroundColor Yellow 
                        Write-Host "Current Value                  : " $ProxySettingsPerUser -ForegroundColor Yellow
                        if($SetRegKey){
                            Set-ItemProperty -Path $Key -Name $Name -Value $Value
                        }
                    }
                    $ProxyEnable = $(Get-ItemProperty -Path $Key).ProxyEnable
                    Write-Host "Verified - ProxyEnable         : " $ProxyEnable -ForegroundColor Cyan

                    ### ProxyServer
                    ### -----------------
                    $Key        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\"
                    $Name       = "ProxyServer"
                    $Type       = "REG_DWORD"
                    $Value      = "0"
    
                    $ProxyServer = $(Get-ItemProperty -Path $Key).ProxyServer

                    if($ProxyServer -eq $Value){
                        Write-Host "Current  - ProxyServer         : " $ProxyServer -ForegroundColor Green
                    }else{
                        Write-host "Setting Reg Key                : " $Name -ForegroundColor Yellow 
                        Write-Host "Current Value                  : " $ProxySettingsPerUser -ForegroundColor Yellow
                        if($SetRegKey){
                            Set-ItemProperty -Path $Key -Name $Name -Value $Value
                        }
                    }
                    $ProxyServer = $(Get-ItemProperty -Path $Key).ProxyServer
                    Write-Host "Verified - ProxyServer         : " $ProxyServer -ForegroundColor Cyan

                    $URL = "http://ifconfig.me/ip"
                    $ExternalIP = (Invoke-WebRequest -uri $Url).Content

                    if( $ExternalIP.Split(".")[0] + "." + $ExternalIP.Split(".")[1] -eq "159.251" ){
                        Write-Host "ExternalIP is using Proxy Server (159.251): " $ExternalIP -ForegroundColor Green
                    }else{
                        Write-Host "ExternalIP is NOT using Proxy Server (should be 159.251): " $ExternalIP -ForegroundColor Yellow
                    }
                    ### Create Computer Object for Export
                    $Computer = [PSCustomObject]@{
                        envCOMPUTERNAME      = $env:COMPUTERNAME
                        ProxySettingsPerUser = $ProxySettingsPerUser
                        AutoDetect           = $AutoDetect
                        ProxyEnable          = $ProxyEnable
                        ProxyServer          = $ProxyServer
                        ExternalIP           = $ExternalIP
                        ServiceStatus        = $Service.Status
                        Serialnumber         = $Serialnumber
                        RecordDate           = $(Get-Date -f "MM-dd-yyyy")
                    }
                    Return $Computer
                }  
                ### Execute Function
                Set-ProxyRegKeys
            }
            ### Invoke Script Block on Remote Computers
            $Computer = Invoke-Command -Session $PSSession -ScriptBlock $ScriptBlock
            $Computers += $Computer
            $Computers 

            ### Close PSSession
            if($PSSession){
                Remove-PSSession -Session $PSSession
            }
        }
    }
    End{
        ### Export Data
        $ExportFile = "C:\temp\ComputerProxySettings_$(Get-Date -f "MM-dd-yyyy_HH-MM-ss").csv" 
        Write-Host "Exporting File: " $ExportFile
        $Computers | Export-Csv -Path $ExportFile -NoTypeInformation
        Start-Process $ExportFile

        try{Stop-Transcript}catch{}
    }
}


