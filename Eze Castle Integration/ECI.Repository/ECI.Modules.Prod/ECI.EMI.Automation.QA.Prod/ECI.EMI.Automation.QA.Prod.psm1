function Test-InternetConnectivity
{

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $Server = "www.google.com"
    
    Write-Host "Testing Internet Connectivity: " $Server -ForegroundColor Cyan
    
    $InetConn = Test-Connection -ComputerName $Server

    if($InetConn)
    {
        Write-Host "Internet Connectivity: Passed" -ForegroundColor Green
    }
    else
    {
        Write-Host "Internet Connectivity: Failed" -ForegroundColor Red
    }

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


function Test-IPConnectivity
{
$FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

Write-Host "Testing IP Connectivity." -ForegroundColor Cyan
Write-Host "IPv4:" -ForegroundColor DarkCyan
Write-Host "IPv6:" -ForegroundColor DarkCyan

Write-Host `n('-' * 50)`n"END FUNCTION:" $FunctionName -ForegroundColor DarkGray

}

function Write-ECI.EMI.QA.Report
{
    Param(
        [Parameter(Mandatory = $True)] [string]$FunctionName
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray
   
    $QAReportFile = "C:\Scripts\QAReport.txt"


    Write-Host `n('-' * 50)`n"END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function QA-SMBv1
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray
    
    
    $keyname = 'SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'

    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $server.Name)
    $key = $reg.OpenSubKey($keyname)
    $value = $key.GetValue('SMB1')

    if ($value -eq "0")
    {
        write-host -ForegroundColor Green $server.Name "SMBv1 Disabled"
    }    
    else
    {
       #Write-Host "QA Failed:" -ForegroundColor Red
       #write-host "SMBv1 Enabled" -ForegroundColor Red 
    }
    
    Write-Host `n('-' * 50)`n"END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Write-ECI.EMI.QA.Report -FunctionName $FunctionName 
}


function QA-WindowsFirewall
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    Get-Service -ComputerName . -DisplayName "Windows Firewall"
    Get-NetFirewallProfile -CimSession . -profile domain
    Write-Host `n('-' * 50)`n"END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function QA-Disks
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    $Disks=Get-WmiObject -Class Win32_logicalDisk -Filter "DriveType=3" -computer .

    foreach($Disk in $Disks)
    {
	    $usedsize=(($disk.size)-($Disk.FreeSpace))/1gb
	    $usedsize=[math]::truncate($usedsize)

        $freesize=($Disk.FreeSpace)/1gb
	    $freesize=[math]::truncate($freesize)

        $totalsize=($Disk.size)/1gb
	    $totalsize=[math]::truncate($totalsize)
        
	    write-host -ForegroundColor Cyan $server.Name
        write-host "Total Size" $Disk.DeviceID $Disk.VolumeName $totalsize "GB"
        write-host "Used" $Disk.DeviceID $usedsize "GB"

        if($freesize -le (.05*$totalsize))
        {
            write-host -ForegroundColor Red "Free" $Disk.DeviceID $freesize "GB"
        }

        else {
            write-host  "Free" $Disk.DeviceID $freesize "GB"
	    }
    }
    Write-Host `n('-' * 50)`n"END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function QA-SwapFile
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    # Output server name and DNS hostname
    Write-Host -ForegroundColor Green "Server Name"
    $server.DNSHostname

    # Check if x86 or x64
    Write-Host -ForegroundColor Green "OS Architecture"
    (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $server.DNSHostName).OSArchitecture

    # Check memory size
    Write-Host -ForegroundColor Green "Physical Memory"
    (Get-WMIObject -class Win32_PhysicalMemory -ComputerName $server.DNSHostName | Measure-Object -Property capacity -Sum).Sum / 1MB
   
    # Check swap file information
    Write-Host -ForegroundColor Green "Swap File Location (Size 0=System Managed Size)"
    (Get-WmiObject -Class Win32_pageFileSetting -ComputerName $server.DNSHostName)

    # Check swap file management
    Write-Host -ForegroundColor Green "Automatic Managed Paging File?"
    (Get-WmiObject -Class Win32_ComputerSystem -ComputerName $server.DNSHostname).AutomaticManagedPagefile

    Write-Host ""
    Write-Host ""

    Write-Host `n('-' * 50)`n"END FUNCTION:" $FunctionName -ForegroundColor DarkGray

}