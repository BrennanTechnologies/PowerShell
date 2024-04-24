

#########################################
### vCenter Resources
### ECI.EMI.Automation.VM.Resources.Prod.psm1
#########################################


###-----------------------------------------------
### Get Resource Pool
###-----------------------------------------------
function Get-ECI.EMI.Automation.VM.Resources.ResourcePool
{
    Param([Parameter(Mandatory = $True)][string]$GPID)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray
    
    Write-Host "Getting Resource Pools for - GPID : $GPID" -ForegroundColor Cyan

    #$Clusters = Get-Cluster -Server $ECIvCenter
    
    $ResourcePools = $null
    $ResourcePool  = $null

    #foreach($Cluster in $Clusters)
    #{
        # Cluster
        #$ResourcePools = (Get-ResourcePool -Location $Cluster | Where-Object {$_.Name -like "*$GPID*"}).Name

        $ResourcePools = (Get-ResourcePool -erroraction Silentlycontinue | Where-Object {$_.Name -like "*$GPID*"}).Name 
        
        if(!$ResourcePools)
        {
            $global:ResourcePool = "ResourcePooolNotFound"
        }
               
        ### Search All Resource Pools
        foreach($ResourcePool in $ResourcePools)
        {
            Write-Host "Resource Pool Found               : $ResourcePool " -ForegroundColor DarkCyan
        }
        if($ResourcePools.Count -eq 1)
        {
                $ResourcePool = $ResourcePools
                Write-Host "Single Resource Pool              : "  $ResourcePool -ForegroundColor DarkCyan
        }
        elseif($ResourcePools.Count -gt 1)
        {
            if(($ResourcePools | Where-Object {$_ -like ("multi_" + $GPID) }))
            {
                $global:ResourcePool =  $ResourcePools  | Where-Object {$_ -like ("multi_" + $GPID) }
                Write-Host "Exact Match                       : $ResourcePool" -ForegroundColor DarkCyan
            }
            elseif(($ResourcePools | Where-Object {$_ -like ("multi_*" ) }))
            {
                $global:ResourcePool = ($ResourcePools | Where-Object {$_ -like ("multi_*" ) })
                Write-Host "Multi*                            : $ResourcePool" -ForegroundColor DarkCyan
            }
            else
            {
                $global:AbortError = $True
                Write-Host "1: No Resource Pools Found." -ForegroundColor Red
                $ResourcePool = "ResourcePooolNotFound"
                #Write-Error -Message "1 No Resource Pools Found." -ErrorAction Continue -ErrorVariable ECIError
                #Throw-ECI.AbortError
            }
        }
        else
        {
                $global:AbortError = $True
                Write-Host "2: No Resource Pools Found." -ForegroundColor Red
                $ResourcePool = "ResourcePooolNotFound"
                #Write-Error -Message "2 No Resource Pools Found." -ErrorAction Continue -ErrorVariable ECIError
                #Throw-ECI.AbortError
        }
        
        if($ResourcePool -eq $Null)
        {
                $global:AbortError = $True
                Write-Host "3: No Resource Pools Found." -ForegroundColor Red
                $ResourcePool = "ResourcePooolNotFound"
                #Write-Error -Message "3 No Resource Pools Found." -ErrorAction Continue -ErrorVariable global:ECIError
                #Throw-ECI.AbortError
        }
        
        Write-Host "ResourcePool Selected              : $ResourcePool" -ForegroundColor Cyan
        
        Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
        $global:ResourcePool = $ResourcePool
        Return $ResourcePool
}

###-----------------------------------------------
### Get Port Group
###-----------------------------------------------
function Get-ECI.EMI.Automation.VM.Resources.PortGroup
{
    Param([Parameter(Mandatory = $True)][string]$GPID)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    Write-Host "Getting Port Group for GPID    : $GPID `n" -ForegroundColor DarkCyan
   
    ### Get Port Groups like GPID (vmware.vimautomation.vds)
    ###----------------------------------------------------------
    #$global:PortGroups = (Get-VDPortgroup).Name | Where-Object {$_ -Like "*$GPID*"} 
    $PortGroups = Get-VirtualPortGroup -erroraction silentlycontinue | Where-Object {$_.Name -Like "*$GPID*"} 
    if(!$PortGroups)
    {
        $PortGroup = $PortGroups
    }

    foreach($PortGroup in $PortGroups)
    {
        Write-Host "Found - Port Group             : " $PortGroup -ForegroundColor DarkCyan
    }

    if($PortGroups.Count -eq 1)
    {
        $global:PortGroup = $PortGroups
        Write-Host "Single Resource Pool           : "  $PortGroup -ForegroundColor DarkCyan
    }
    elseif($PortGroups.Count -gt 1)
    {
            if(($PortGroups | Where-Object {$_ -like ("multi_" + $GPID) }))
            {
                $global:PortGroup =  $PortGroups  | Where-Object {$_ -like ("multi_" + $GPID) }
                Write-Host "Exact Match                     : $PortGroup" -ForegroundColor DarkCyan
            }
            elseif(($PortGroups | Where-Object {$_ -like ("multi_*" ) }))
            {
                $global:PortGroup = ($PortGroups | Where-Object {$_ -like ("multi_*" ) })
                Write-Host "Multi*                         : " $ResourcePool -ForegroundColor DarkCyan
            }
            else
            {
                Write-Host "Else"
                $PortGroup = "PortGroupNotFound"
            }
    }

    #[string]$PortGroup = (Get-VirtualPortGroup | where {$_.name -like "multi_schoenermgmt_ptp"}).Name
    #[string]$PortGroup = $PortGroup.ToString()

#Test
#$PortGroup = "multi_schoenermgmt"

    Write-Host "PortGroup Selected             : " $PortGroup -ForegroundColor Cyan
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray

    if($PortGroup.count -eq 0)
    {
        write-host "PortGroup Count: " $PortGroup.count -ForegroundColor Magenta
        $PortGroup = "PortGroupNotFound"
    }
    
    $global:PortGroup = $PortGroup
    Return $PortGroup
}


function Get-ECI.EMI.Automation.VM.Resources.OSDataStore
{
    Param([Parameter(Mandatory = $True)][string]$ServerRole)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray
    switch ($ServerRole)
    {
        "2016Server"  { $string = "*LD5_EMI_os*" }
        #"2016Server"  { $string = "*EMS-Client-DC-OS*" }
        "2016VDA"     { $string = "*EMS-Client-Citrix-OS*" }
        "2016DC"      { $string = "*EMS-Client-DC-OS*" }
        "2016FS"      { $string = "*EMS-Client-Files*" }
        "2016DCFS"    { $string = "*EMS-Client-DC-OS*" }
        #"2016SQL"     { $string = "*EMS-Client-DC-OS*" }
        #"2016SQLOMS"  { $string = "*EMS-Client-DC-OS*" }
    }
    
    $global:OSDataStore = Get-Datastore | Where-Object {$_.Name -Like $string}

    Write-Host "Datastore Found: " $OSDataStore -ForegroundColor Cyan
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $OSDataStore
}


function Get-ECI.EMI.Automation.VM.Resources.DataStore
{
    Param(
    [Parameter(Mandatory = $True)][string]$Environment,
    [Parameter(Mandatory = $True)][string]$ServerRole
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray
<#
    switch ()
    {
    
    }
#>

    if ($Environment = "Production")
    {
        ### OS Datastore
        ###--------------------------------------
        switch ($ServerRole)
        {
            #"2016Server"  { $OSStr = "*EMS_Client_DC_OS*"        }
            "2016Server"  { $OSStr = "*LD5_EMI_os_401*"          }
            #"2016Server"  { $OSStr = "*QTS_EMI_os_201*"          }
            
            "2016VDA"     { $OSStr = "*EMS-Client-Citrix-OS*"    }
            "2016DC"      { $OSStr = "*EMS-Client-DC-OS*"        }
            "2016FS"      { $OSStr = "*EMS-Client-Files*"        }
            "2016DCFS"    { $OSStr = "*EMS-Client-DC-OS*"        }
            "2016SQL"     { $OSStr = "*EMS-Client-DC-OS*"        }
            "2016SQLOMS"  { $OSStr = "*EMS-Client-DC-OS*"        }
        }

        ### PageFile Datastore
        ###--------------------------------------
        switch ($ServerRole)
        {
            "2016Server"  { $SwapStr = "*EMS_Client_DC_Swap*"    }
            #"2016Server"  { $SwapStr = "*QTS_EMI_swap_201*"    }
            
            "2016VDA"     { $SwapStr = "*EMS-Client-Citrix-Swa*" }
            "2016DC"      { $SwapStr = "*EMS-Client-DC-Swap*"    }
            "2016FS"      { $SwapStr = "*EMS-Client-Files*"      }
            "2016DCFS"    { $SwapStr = "*EMS-Client-DC-OS*"      }
            "2016SQL"     { $SwapStr = "*EMS-Client-DC-OS*"      }
            "2016SQLOMS"  { $SwapStr = "*EMS-Client-DC-OS*"      }
        }

        ### Data Datastore
        ###--------------------------------------
        switch ($ServerRole)
        {
            "2016Server"  { $DataStr = ""                        }
            "2016VDA"     { $DataStr = "*EMS-Client-Citrix-Swa*" }
            "2016DC"      { $DataStr = "*EMS-Client-DC-Swap*"    }
            "2016FS"      { $DataStr = "*EMS-Client-Files*"      }
            "2016DCFS"    { $DataStr = "*EMS-Client-DC-OS*"      }
            "2016SQL"     { $DataStr = "*EMS-Client-DC-OS*"      }
            "2016SQLOMS"  { $DataStr = "*EMS-Client-DC-OS*"      }
        }

        ### Log Datastore
        ###-------------------------------------- 
        switch ($ServerRole)
        {
            "2016Server"  { $LogStr = ""                         }
            "2016VDA"     { $LogStr = "*EMS-Client-Citrix-Swa*"  }
            "2016DC"      { $LogStr = "*EMS-Client-DC-Swap*"     }
            "2016FS"      { $LogStr = "*EMS-Client-Files*"       }
            "2016DCFS"    { $LogStr = "*EMS-Client-DC-OS*"       }
            "2016SQL"     { $LogStr = "*EMS-Client-DC-OS*"       }
            "2016SQLOMS"  { $LogStr = "*EMS-Client-DC-OS*"       }
        }

        ### Sys Datastore
        ###--------------------------------------
        switch ($ServerRole)
        {
            "2016Server"  { $SysStr = ""                         }
            "2016VDA"     { $SysStr = "*EMS-Client-Citrix-Swa*"  }
            "2016DC"      { $SysStr = "*EMS-Client-DC-Swap*"     }
            "2016FS"      { $SysStr = "*EMS-Client-Files*"       }
            "2016DCFS"    { $SysStr = "*EMS-Client-DC-OS*"       }
            "2016SQL"     { $SysStr = "*EMS-Client-DC-OS*"       }
            "2016SQLOMS"  { $SysStr = "*EMS-Client-DC-OS*"       }
        }
    }

    elseif ($Environment = "Development")
    {
        ### OS Datastore
        ###--------------------------------------
        switch ($ServerRole)
        {
            "2016Server"  { $OSStr = "*EMS-Client-DC-OS*"        }
            "2016VDA"     { $OSStr = "*EMS-Client-Citrix-OS*"    }
            "2016DC"      { $OSStr = "*EMS-Client-DC-OS*"        }
            "2016FS"      { $OSStr = "*EMS-Client-Files*"        }
            "2016DCFS"    { $OSStr = "*EMS-Client-DC-OS*"        }
            "2016SQL"     { $OSStr = "*EMS-Client-DC-OS*"        }
            "2016SQLOMS"  { $OSStr = "*EMS-Client-DC-OS*"        }
        }
    
        ### PageFile Datastore
        ###--------------------------------------
        switch ($ServerRole)
        {
            "2016Server"  { $SwapStr = "*EMS-Client-DC-Swap*"    }
            "2016VDA"     { $SwapStr = "*EMS-Client-Citrix-Swa*" }
            "2016DC"      { $SwapStr = "*EMS-Client-DC-Swap*"    }
            "2016FS"      { $SwapStr = "*EMS-Client-Files*"      }
            "2016DCFS"    { $SwapStr = "*EMS-Client-DC-OS*"      }
            "2016SQL"     { $SwapStr = "*EMS-Client-DC-OS*"      }
            "2016SQLOMS"  { $SwapStr = "*EMS-Client-DC-OS*"      }
        }
    }    
    
    ### Get OS Datastore
    ###-----------------------
    try
    {   
        #$global:OSDataStore = Get-Datastore | Where-Object {$_.Name -Like $OSStr}
        $global:OSDataStore = Get-DatastoreCluster | Where-Object {$_.Name -Like $OSStr}
    }
    catch
    {
        Write-Host "PSCallStack       : " $((Get-PSCallStack)[0].Command) -ForegroundColor Red
        Write-Host "Exception.Message : " $_.Exception.Message -ForegroundColor Red
        Write-Host "ScriptStackTrace  : " $_.ScriptStackTrace -ForegroundColor Red
    }    

    ### Get Swap File Datastore
    ###-----------------------
    try
    {   
        #$global:SwapDatastore = Get-Datastore | Where-Object {$_.Name -Like $SwapStr}
        $global:SwapDatastore = Get-DatastoreCluster | Where-Object {$_.Name -Like $OSStr}
    }
    catch
    {
        Write-Host "PSCallStack       : " $((Get-PSCallStack)[0].Command) -ForegroundColor Red
        Write-Host "Exception.Message : " $_.Exception.Message -ForegroundColor Red
        Write-Host "ScriptStackTrace  : " $_.ScriptStackTrace -ForegroundColor Red
    }
    ### Get Data Datastore
    ###-----------------------
    try
    {   
        $global:DataDatastore = Get-Datastore | Where-Object {$_.Name -Like $DataStr}
    }
    catch
    {
        Write-Host "PSCallStack       : " $((Get-PSCallStack)[0].Command) -ForegroundColor Red
        Write-Host "Exception.Message : " $_.Exception.Message -ForegroundColor Red
        Write-Host "ScriptStackTrace  : " $_.ScriptStackTrace -ForegroundColor Red
    }
    ### Get Log File Datastore
    ###-----------------------
    try
    {   
        $global:LogDatastore = Get-Datastore | Where-Object {$_.Name -Like $LogStr}
    }
    catch
    {
        Write-Host "PSCallStack       : " $((Get-PSCallStack)[0].Command) -ForegroundColor Red
        Write-Host "Exception.Message : " $_.Exception.Message -ForegroundColor Red
        Write-Host "ScriptStackTrace  : " $_.ScriptStackTrace -ForegroundColor Red
    }
    ### Get Sys File Datastore
    ###-----------------------
    try
    {   
        $global:SysDatastore = Get-Datastore | Where-Object {$_.Name -Like $SysStr}  
    }
    catch
    {
        Write-Host "PSCallStack       : " $((Get-PSCallStack)[0].Command) -ForegroundColor Red
        Write-Host "Exception.Message : " $_.Exception.Message -ForegroundColor Red
        Write-Host "ScriptStackTrace  : " $_.ScriptStackTrace -ForegroundColor Red
    }

    $ECIDatastores = @{
        OSDataStore   = $OSDataStore
        SwapDatastore = $SwapDatastore
        DataDatastore = $DataDatastore
        LogDatastore  = $LogDatastore
        SysDatastore  = $SysDatastore
    }


    $global:ServerDataStores = @{}
    foreach($ECIDatastore in  $ECIDatastores.GetEnumerator())
    {
        if(([string]::IsNullOrEmpty($ECIDatastore.Value)) -ne $true)
        {
            Write-Host $ECIDatastore.Key `t"    : " $ECIDatastore.Value
            $ServerDatastores.add($ECIDatastore.Key, $ECIDatastore.Value)
        }
    }

    Write-Host "DataStores Selected : " $ServerDatastores -ForegroundColor Cyan
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $ServerDataStores
}

function Export-ECI.Template
{
    $Template = "ecibasetemplate"
    $Destination = "c:\scripts\ecibasetemplate"
    
    Get-VM -Name $Template | export-vapp -Destination $Destination -Force
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}




###################################################
#####################
###################################################


###-----------------------------------------------
### Get ECI Cluster
###-----------------------------------------------
function Get-ECI.Cluster
{
    param($ECIvCenter)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

    $global:Clusters = VMware.VimAutomation.Core\Get-Cluster #-Server $ECIvCenter
    #$global:Cluster = (Get-Cluster -Server $ECIvCenter | Get-ResourcePool -Name $ResourcePool).Name
   
    Write-Host "Clusters Found: $Clusters" -ForegroundColor Cyan
   
    #$global:Pod = $Cluster.Split("_")[2]
    #Write-Host "Pod Found: $Pod" -ForegroundColor Cyan
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    Return $Clusters
}
