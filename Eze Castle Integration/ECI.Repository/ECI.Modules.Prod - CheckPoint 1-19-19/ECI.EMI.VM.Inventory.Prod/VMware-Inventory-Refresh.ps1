# ECI CLOUD - Refresh VM metadata (per VM)

<#
Param(
    [parameter(Mandatory=$True, HelpMessage="Virtual Machine Name")]
    [string]$VmName,

    [parameter(Mandatory=$True, HelpMessage="hosting vCenter Server")]
    [string]$vCenter,

    [parameter(Mandatory=$True, HelpMessage="Virtual Machine ID")]
    [string]$vmId,

    [parameter(Mandatory=$False, HelpMessage="Virtual Machine UUID")]
    [string]$VmUUID
)
#>

$VMName = "ETEST040_Test-LD5-QqhDy" # Good/On
$vCenter = "ld5vc.eci.cloud"
$VMID = "VirtualMachine-vm-12375"
$VMUUID = "421e8f66-e26c-1449-5a58-6cf4f2c89160"

<# TESTING ONLY
$vmName = "Archview-VPMApp"
$vmId = "VirtualMachine-vm-3582"
$vCenter = "cloud-qtsvc.eci.corp"
#>

$funcCallTimeStamp = get-date
write-host " ================  Lauching Refresh for $VMName @ $funcCallTimeStamp" -ForegroundColor Cyan

################################################################
###                  FUNCTION DEFINITIONS                    ###
################################################################


# Decrypt Secure String objects
function Decrypt([securestring]$securePwd){
    $marshal = [System.Runtime.InteropServices.Marshal]
    $ptr = $marshal::SecureStringToBSTR( $securePwd )
    $str = $marshal::PtrToStringBSTR( $ptr )
    $marshal::ZeroFreeBSTR( $ptr )
    return $str
}


# Translate vCenter name to Location Code
function get-locationCode([string]$vCenter){
    if($vCenter -like "*qtsvc*"){
        return "QTS"
    }
    elseif($vCenter -like "*sacvc*"){
        return "SAC"
    }
    elseif($vCenter -like "*lhcvc*"){
        return "LHC"
    }
    elseif($vCenter -like "*ld5vc*"){
        return "LD5"
    }
    elseif($vCenter -like "*hkvc*"){
        return "HK"
    }
    elseif($vCenter -like "*sgvc*"){
        return "SG"
    }
}



# Get GPID
function get-gpid([string]$stringToParse){
    # Parse GPID from input string, depending on VM Name or VMs resource pool name
    if($stringToParse -like "*-vfw*" -or $vm.Name -like "*-pavm-*"){
        $GPID = ($stringToParse.Split("-"))[0]
    }
    else{
        if($stringToParse -like "dr_emi_*" -or $stringToParse -like "dr_hosted_*"){
            $GPID = ($stringToParse.Split("_"))[2]  
        }
        else{
            $GPID = ($stringToParse.Split("_"))[1]
        }
    }

    # Check that GPID is formatted AAAAA111, return it if true, return NULL if false
    $GPID1 = $GPID.Substring(0,5)
    $GPID2 = $GPID.Substring(5,3)
    if($GPID1.length -eq 5 -and $GPID2.Length -eq 3 -and [regex]::Match($GPID2,"[0-9]") -and [regex]::Match($GPID1,"[a-zA-Z0-9]")){
        if($GPID -eq "aderi001"){
            return "HAYGR002"
        }
        else{
            return $GPID
        }
    }
    else{
        return "badGPID"
    }
}




################################################################
###                     BEGIN EXECUTION                      ###
################################################################


#Add-PSSnapin VMware.VimAutomation.Core
#Add-PSSnapin SqlServerCmdletSnapin100
#Add-PSSnapin SqlServerProviderSnapin100

write-host " ================  Modules load check completed @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan

# Define SQL DBs
$sqldatabase = "ECIPortal"
$sqlserver = "connectwisedb.eci.corp"
$tableVM = "VM_T"
$tableIP = "ServerIPAddress"
$tableDRLoc = "ServerDRLocation"
$tableDisk = "ServerDisk"
$tableNotes = "ServerNotes"
$sqlusername = "Cloud_integration"
$sqlPwdHash = "76492d1116743f0423413b16050a5345MgB8AEgATABUAGUAYwAzAGYAegBVAE8ATwBMAEQAeQAvADUANABIAFgAUgBjAFEAPQA9AHwAYgA2AGIANwBiADcANgAyADgAYQA5AGUAZABhAGQANgA5AGMAMABiAGMANgAyADUAOAAxAGUAYwAyADUAMQBkAGYAMAA1AGUAOAA1AGQAOAA0AGEAMQBmAGMANQAxAGIANwA1ADcAZgBmAGMAMgBiAGMANAAyAGYAYQA0AGIAMwA="
$sqlPwd = Decrypt ($sqlPwdHash | ConvertTo-SecureString -Key (3,4,2,3,56,34,254,222,0,1,2,23,42,54,33,233,1,34,2,7,6,5,35,42))

# Define ConnectWise DB from which to pull GPID for client in question
$CwSqlServer = "connectdb.eci.corp"
$CwSqlDatabase = "cwwebapp_eci"
$CwSqlUser = "acronis_job"
$CwSqlPwd = "Welcome1"

write-host " ================  Variables configured @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan

# Check existing VC connections and log into specific VC if required:
if($global:DefaultVIServers.Name -notcontains $vCenter){
    $VCpwdHash = "76492d1116743f0423413b16050a5345MgB8ADcATABlAHIAQwBMAHoAcABwADEAWQByAHkAbwBTAC8AcgBwAGQAQQAyAGcAPQA9AHwANAA3ADUAMwBlADgAMgA0AGUAYwAxADAAZgA0AGYAYwAyADUAYQA0AGYAMAAwAGYAZAAzADEAZgBkAGYAOABjADgAYgAxAGYAZABkADIAZgAyAGEANwBkADIAZgBmADEAZgBlAGUAMwA0AGMANABlADcANQAyADYAYwBjAGYANQA="
    $VCpwd = $VCpwdHash | ConvertTo-SecureString -Key (3,4,2,3,56,34,254,222,0,1,2,23,42,54,33,233,1,34,2,7,6,5,35,42)
    Remove-Variable VCpwdHash
    $VMwareCreds = New-Object System.Management.Automation.PSCredential('CLOUD\vcenterscriptingro',$VCpwd)
    Connect-VIServer -Server $vCenter -Credential $VMwareCreds -Force:$true
    write-host " ================  Logging into $vCenter @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Yellow
}

write-host " ================  $vCenter should be logged in now @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan



# Get metadata about Virtual Machine given as Parameter:
$vm = Get-VM -server $vCenter | Where-Object {$_.Name -eq $VmName -and $_.Id -eq $vmId}
if($vm -eq $null){  # IF VM is not found in VC then it may have been removed or renamed.  Flip INACTIVE boolean in SQL for this entry and exit Refresh script after variable clean-up
    write-host " ================  VM NOT FOUND in VC - marking INACTIVE and exiting Refresh subscript @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Yellow
    $LocationCode = Get-LocationCode $vCenter
    $query = "UPDATE $tableVM set Inactive='True' WHERE LocationCode='$LocationCode' and VM_ID='$vmId'"
    Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query
    Clear-Variable GPID,CWID,vCenter,LastUpdated,LocationCode,vCenter,ResourcePoolName,VmName,VmUUID,vmId,
            PowerState,FQDN,OSVersion,Instance,vCPU,vRAM,DR,Backups,inactive,nic*,disk*,nic*,disksAll,IPsAll,
            IPsInTable,disksAll,DisksInTable,SqlInsertQuery,SqlUpdateQuery -ErrorAction SilentlyContinue
    return $false
}


# Collect VM Information
write-host " ================  Starting stats collection @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan
if($vm.Name -like "*-vfw*" -or $vm.Name -like "*-pavm-*"){  # NOTE:  VFWs are in a shared resource pool, therefore GPID is asscertained differently than for server VMs
    $GPID = get-gpid $vm.Name
}
else{
    $GPID = get-gpid $vm.ResourcePool.Name
}
$CWID = (Invoke-Sqlcmd -ServerInstance $CwSqlServer -database $CwSqlDatabase -Username $CwSqlUser -Password $CwSqlPwd -query "select top 1 Company_RecID from cwwebapp_eci.dbo.company where Account_Nbr='$GPID'").Company_RecID
if($CWID -eq $null){  # IF CWID is null then this is not a client VM - therefore skip stat collection and exit Refresh script after variable clean-up
    write-host " ================  VM $vmname in $vCenter has NULL ConnectWise ID indicating a non-client - skipping refresh ($VM.ResourcePoolName = '"$VM.ResourcePool.Name"') @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Yellow
    Clear-Variable GPID,CWID,vCenter,LastUpdated,LocationCode,vCenter,ResourcePoolName,VmName,VmUUID,vmId,
            PowerState,FQDN,OSVersion,Instance,vCPU,vRAM,DR,Backups,inactive,nic*,disk*,nic*,disksAll,IPsAll,
            IPsInTable,disksAll,DisksInTable,SqlInsertQuery,SqlUpdateQuery -ErrorAction SilentlyContinue
    return $false
}
$vCenter = (Get-View -Server $vCenter -ViewType HostSystem -Property Name | Select Name,@{N='vCenter';E={([uri]$_.Client.ServiceUrl).Host}})[0].vcenter
$LastUpdated = Get-Date
$LocationCode = get-locationCode $vCenter
$ResourcePoolName = $vm.ResourcePool.Name
$VmName = $vm.Name
$VmUUID = $vm | %{(Get-View $_.Id).config.uuid}
$vmId = $vm.Id
$PowerState = $vm.PowerState
$FQDN = $vm.Guest.HostName
$OSVersion = $vm.Guest.OSFullName
$Instance = $null  #EMI instance, TO BE POPULATED
$vCPU = $vm.NumCpu
$vRAM = $vm.MemoryGB
$Backups = $false  #  TO BE POPULATED
$inactive = $false

# Collect VM IP Information
$x = 0;while($x -lt $vm.Guest.ExtensionData.Net.count){
    Set-Variable -Name nicIPAddress$x -Value $null
    Set-Variable -Name nicSubnetPrefix$x -Value $null
    Set-Variable -Name nicLabel$x -Value $null
    Set-Variable -Name nicPortGroupName$x -Value $null
    Set-Variable -Name nicPortGroupId$x -Value $null
    Set-Variable -Name nicMacAddress$x -Value $null
    Set-Variable -Name nicConnected$x -Value $null
    if($vm.Guest.ExtensionData.Net[$x].IpAddress -ne $null){
        foreach($item in $vm.Guest.ExtensionData.Net[$x].IpConfig.IpAddress){
            if($item.IpAddress -like "*.*.*.*"){
                Set-Variable -Name nicIPAddress$x -Value $item.IpAddress
                Set-Variable -Name nicSubnetPrefix$x -Value $item.PrefixLength
                Set-Variable -Name nicLabel$x -Value "Production_IP"
                Set-Variable -Name nicPortGroupName$x -Value $vm.Guest.ExtensionData.Net[$x].Network
                Set-Variable -Name nicPortGroupId$x -Value (Get-VirtualPortGroup | where {$_.Name -eq (Get-Variable -Name nicPortGroupName$x).Value}).Key  # NOTE:  after upgrading PowerCLI use 'Get-VDPortGroup' instead
                Set-Variable -Name nicMacAddress$x -Value $vm.Guest.ExtensionData.Net[$x].MacAddress
                Set-Variable -Name nicConnected$x -Value $vm.Guest.ExtensionData.Net[$x].Connected
            }
        }
    }
    $x++
}


# Collect VM Disk Information
[array]$disksAll = $vm | Get-HardDisk
$x = 0;while($x -lt $disksAll.count){
    Set-Variable -Name diskSize$x -Value $disksAll[$x].CapacityGB
    Set-Variable -Name diskId$x -Value $disksAll[$x].Id
    Set-Variable -Name diskScsiId$x -Value $null  #  TO BE POPULATED
    Set-Variable -Name diskLetter$x -Value $null  #  TO BE POPULATED
    $x++
}

# Collect VM Notes
if($vm.Notes -ne $null){
    [array]$notesAll = $vm.Notes.Split("`n")
    $notesAll = $notesAll.Where({$_.Length -gt 0})
    $x = 0;while($x -lt $notesAll.count){
        if($notesAll[$x] -like "PA-Serial:*"){
            Set-Variable -Name noteLabel$x -Value ($notesAll[$x].Split(":"))[0]
            Set-Variable -Name noteValue$x -Value ($notesAll[$x].Split(":"))[1]
        }
        elseif($notesAll[$x].Length -gt 0){
            Set-Variable -Name noteLabel$x -Value "Note$x"
            Set-Variable -Name noteValue$x -Value $notesAll[$x].Replace("'","")
        }
        $x++
    }
}




# Query SQL table to see if VM already exists - if it does, update the row with above data.  Otherwise insert a new row with above data
write-host " ================  Stats collected, querying SQL for existing entries @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan
$sqlFindPriKey = "(select top 1 serverID from $tableVM where LocationCode='$LocationCode' and UUID='$VmUUID' and VM_ID='$vmId')"
$existingVM = Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $sqlFindPriKey -ErrorVariable sqlError
if($existingVM.serverID){ # UPDATE SQL ROW
    
    # Check if DR is configured or not
    $query = "select serverID from $tableDRLoc where serverID='"+$existingVM.severID+"'"
    $drBool = Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
    if($drBool){
        $DR = $true
    }
    else{
        $DR = $false
    }
    
    
    # Update VM_T Table:  UPdate single row for VM with above metadata
    $SqlUpdateQuery = "UPDATE $tableVM SET GPID='$GPID',CWID='$CWID',vCenter='$vCenter',LastUpdated='$LastUpdated',LocationCode='$LocationCode',ResourcePoolName='$ResourcePoolName',VMName='$VmName',
                        UUID='$VmUUID',VM_ID='$vmId',PowerState='$PowerState',FQDN='$FQDN',OSVersion='$OSVersion',Instance='$Instance',vCPU='$vCPU',vRAM='$vRAM',DR='$DR',Backups='$Backups',Inactive='$inactive'
                        WHERE ServerId="+$existingVM.serverID+";"
    Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $SqlUpdateQuery -ErrorVariable sqlError


    # Update ServerIPAddress Table:
    $x = 0;while($x -lt $vm.Guest.ExtensionData.Net.count){
        if((Get-Variable -Name nicIPAddress$x).Value -ne $null){
            $query = "SELECT * FROM $tableIP WHERE ServerID='"+$existingVM.serverID+"' and IPAddress='"+(Get-Variable -Name nicIPAddress$x).Value+"'"
            $IPFoundBool = Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
            if($IPFoundBool){
                $query = "UPDATE $tableIP SET Label='"+(Get-Variable -Name nicLabel$x).Value+"',
                        SubnetPrefix='"+(Get-Variable -Name nicSubnetPrefix$x).Value+"',
                        PortGroupName='"+(Get-Variable -Name nicPortGroupName$x).Value+"',
                        PortGroupID='"+(Get-Variable -Name nicPortGroupId$x).Value+"',
                        MacAddress='"+(Get-Variable -Name nicMacAddress$x).Value+"',
                        Connected='"+(Get-Variable -Name nicConnected$x).Value+"'
                        WHERE ServerID='"+$existingVM.serverID+"' and IPAddress='"+(Get-Variable -Name nicIPAddress$x).Value+"'"
                Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
            }
            else{
                $query = "INSERT into $tableIP (serverID,IPAddress,Label,SubnetPrefix,PortGroupName,PortGroupID,MacAddress,Connected)
                    VALUES ('"+$existingVM.serverID+"',
                        '"+(Get-Variable -Name nicIPAddress$x).Value+"',
                        '"+(Get-Variable -Name nicLabel$x).Value+"',
                        '"+(Get-Variable -Name nicSubnetPrefix$x).Value+"',
                        '"+(Get-Variable -Name nicPortGroupName$x).Value+"',
                        '"+(Get-Variable -Name nicPortGroupId$x).Value+"',
                        '"+(Get-Variable -Name nicMacAddress$x).Value+"',
                        '"+(Get-Variable -Name nicConnected$x).Value+"')"
                Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
            }
        }
        $x++
    }
    # Remove IPs from SQL that are no longer configured on the VM
    $query = "SELECT * from $tableIP WHERE ServerId='"+$existingVM.serverID+"'"
    [array]$IPsInTable = Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
    [array]$IPsInVM = @()
    $x = 0;while($x -lt $vm.Guest.ExtensionData.Net.count){$IPsInVM += (Get-Variable -Name nicIPAddress$x).Value;$x++}
    foreach($IP in $IPsInTable){
        if($IPsInVM -notcontains $IP.IPAddress){
            $query = "DELETE from $tableIP WHERE ServerIPAddressId='"+$IP.ServerIPAddressId+"'"
            Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
        }
    }
       
    

    # Update ServerDisk Table:  Add disks missing from SQL, update existing disks in SQL, then delete disks in SQL that are no longer on the VM
    $x = 0;while($x -lt $disksAll.count){
        $query = "select * FROM $tableDisk WHERE serverId='"+$existingVM.serverID+"' and DiskID='"+(Get-Variable -Name diskId$x).Value+"'"
        $diskFoundBool = Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
        if($diskFoundBool){
            $query = "UPDATE $tableDisk SET DiskSize='"+(Get-Variable -Name diskSize$x).Value+"' WHERE serverId='"+$existingVM.serverID+"' and DiskID='"+(Get-Variable -Name diskId$x).Value+"'"
            Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
        }
        else{
            $query = "INSERT into $tableDisk (ServerId,DiskId,DiskSize) VALUES ('"+$existingVM.serverID+"','"+(Get-Variable -Name diskId$x).Value+"','"+(Get-Variable -Name diskSize$x).Value+"')"
            Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
        }
        $x++
    }
    # Remove Disks from SQL that are no longer configured on the VM
    $query = "SELECT ServerDiskID,ServerId,DiskId FROM $tableDisk WHERE ServerId='"+$existingVM.serverID+"'"
    [array]$DisksInTable = Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
    if($DisksInTable.count -ne $disksAll.count){
        foreach($disk in $DisksInTable){
            if($disksAll.id -notcontains $disk.DiskId){
                $query = "DELETE from $tableDisk WHERE serverDiskId='"+$disk.ServerDiskID+"'"
                Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
            }
        }
    }



    # Update ServerNotes Table:  Add Notes missing from SQL, update existing Notes disks in SQL, then delete notes in SQL that are no longer on the VM
    if($vm.Notes -ne $null){
        $x = 0;while($x -lt $notesAll.count){
            $query = "select * FROM $tableNotes WHERE serverId='"+$existingVM.serverID+"' and NoteLabel='"+(Get-Variable -Name noteLabel$x).Value+"'"
            $noteFoundBool = Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
            if($noteFoundBool){
                $query = "UPDATE $tableNotes SET NoteValue='"+(Get-Variable -Name NoteValue$x).Value+"' WHERE serverId='"+$existingVM.serverID+"' and NoteLabel='"+(Get-Variable -Name noteLabel$x).Value+"'"
                Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
            }
            elseif((Get-Variable -Name NoteValue$x).Value.Length -gt 0){
                $query = "INSERT into $tableNotes (ServerId,NoteLabel,NoteValue) VALUES ('"+$existingVM.serverID+"','"+(Get-Variable -Name noteLabel$x).Value+"','"+(Get-Variable -Name noteValue$x).Value+"')"
                Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
            }
            $x++
        }
        # Remove Notes from SQL that are no longer configured on the VM
        $query = "SELECT * FROM $tableNotes WHERE ServerId='"+$existingVM.serverID+"'"
        [array]$NotesInTable = Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
        if($NotesInTable.count -ne $notesAll.count){
            foreach($note in $NotesInTable){
                if(!($notesAll -match $note.NoteValue)){
                    #$query = "DELETE from $tableNotes WHERE serverNoteId='"+$note.ServerNoteID+"'"
                    #Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $query -ErrorVariable sqlError
                    write-host "script will delete "$note.notelabel", "$note.notevalue
                }
            }
        }
    }

}  # End of UPDATE ROW conditional statement
else{  # INSERT NEW SQL ROW

    write-host " ================  Entering ADD conditional statement @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan
    
    # Define base SQL query to insert VM metadata
    $SqlInsertQuery = "INSERT INTO $tableVM (GPID,CWID,vCenter,LastUpdated,LocationCode,ResourcePoolName,VMName,UUID,VM_ID,PowerState,FQDN,OSVersion,Instance,vCPU,vRAM,DR,Backups,Inactive)
            VALUES ('$GPID','$CWID','$vCenter','$LastUpdated','$LocationCode','$ResourcePoolName','$VmName','$VmUUID','$vmId','$PowerState','$FQDN','$OSVersion','$Instance','$vCPU','$vRAM','$DR','$Backups','$inactive')"

    write-host " ================  Base query defined @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan
    # Append IP Address data to base SQL query, for IPs that exist
    $x = 0;while($x -lt $vm.Guest.ExtensionData.Net.count){
        if((Get-Variable nicIPAddress$x).Value -ne $null){
            $SqlInsertQuery += "`nINSERT INTO $tableIP (ServerId,IPAddress,Label,SubnetPrefix,PortGroupName,PortGroupID,MacAddress,Connected)
                    VALUES ($sqlFindPriKey,
                        '"+(Get-Variable nicIPAddress$x).Value+"',
                        '"+(Get-Variable nicLabel$x).Value+"',
                        '"+(Get-Variable nicSubnetPrefix$x).Value+"',
                        '"+(Get-Variable nicPortGroupName$x).Value+"',
                        '"+(Get-Variable nicPortGroupId$x).Value+"',
                        '"+(Get-Variable nicMacAddress$x).Value+"',
                        '"+(Get-Variable nicConnected$x).Value+"')"
        }
        $x++
    }
    write-host " ================  IP adds appended to query @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan

    # Append Disk data to base SQL query, for those that exist
    $x = 0;while($x -lt $disksAll.count){
        $SqlInsertQuery += "`nINSERT INTO $tableDisk (serverID,DiskID,DiskSize,DiskScsiid,DiskLetter)
                VALUES ($sqlFindPriKey,
                    '"+(Get-Variable diskId$x).Value+"',
                    '"+(Get-Variable diskSize$x).Value+"',
                    '"+(Get-Variable diskScsiId$x).Value+"',
                    '"+(Get-Variable diskLetter$x).Value+"')"
        $x++
    }
    write-host " ================  Disk adds appended to query @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan  

    # Append Notes data to base SQL query, for those that exist
    if($vm.Notes -ne $null){
        $x = 0;while($x -lt $notesAll.count){
            if((Get-Variable NoteValue$x).Value.Length -gt 0){
                $SqlInsertQuery += "`nINSERT INTO $tableNotes (serverID,NoteLabel,NoteValue)
                        VALUES ($sqlFindPriKey,
                            '"+(Get-Variable NoteLabel$x).Value+"',
                            '"+(Get-Variable NoteValue$x).Value+"')"
            }
            $x++
        }
    }
    write-host " ================  Note adds appended to query @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan  
    
    # Execute the SQL query constructed above
    Invoke-Sqlcmd -ServerInstance $sqlserver -database $sqldatabase -Username $sqlusername -Password $sqlPwd -query $SqlInsertQuery -ErrorVariable sqlError
    write-host " ================  ADD Query executed @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan
}  # End of INSERT NEW ROW conditional statement



# Clean up variables to protect data spanning across loop iterations:
Clear-Variable GPID,CWID,vCenter,LastUpdated,LocationCode,vCenter,ResourcePoolName,VmName,VmUUID,vmId,
            PowerState,FQDN,OSVersion,Instance,vCPU,vRAM,DR,Backups,inactive,nic*,disk*,nic*,disksAll,IPsAll,note*,
            IPsInTable,disksAll,DisksInTable,NotesInTable,SqlInsertQuery,SqlUpdateQuery -ErrorAction SilentlyContinue

write-host " ================  Variables cleaned up, existing refresh function @ +"((Get-Date) - $funcCallTimeStamp) -ForegroundColor Cyan



# Return Boolean value representing succcess or failure
if($sqlError){
    return $false
}
else{
    return $true
}


# ================  END OF SCRIPT ================  #
