<#



 ====================================================================================================
 START - ECI ERROR STACK:
 ====================================================================================================

PS-Error.Count: 4
PS-ERRROR[0]:
 --------------------

PS-Error.InvocationInfo    [0]    :  New-VM -Name $VMName -Template $ECIVMTemplate -Location $vCenterFolder -ResourcePool $ResourcePool -Datastore $OSDataStore -OSCustomizationSpec $OSCustomizationSpecName
PS-Error.Exception         [0]    :
PS-Error.ExceptionType     [0]    :  VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InsufficientResourcesFault
PS-Error.Exception.Message [0]    :  1/18/2019 4:06:06 PM       New-VM          The Storage DRS requirements of this VirtualMachine cannot be satisfied. storagePlacement Insufficient disk space on datastore 'n401-ems-client-dc-os-1'.


#>

#########################################
### vCenter Resources
### ECI.EMI.Automation.VM.Resources.Prod.psm1
#########################################
#P-int
#7Gc^jfzaZnzD

### Function: Get vCenter Resources
###---------------------------------------
function get-vmResourceByGpidServerRole
{
    param(
            [parameter(mandatory = $true)]
            [string]$ServerRole,
            [string]$gpid
         )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $tempGpidWildCard = "*" + $gpid + "*"
    $tempClientPortGroups = Get-vdPortGroup $tempGpidWildCard
        if(!$tempClientPortGroups)
            {
                Write-Host "No Client Exists with $gpid as a GPID"

                $ErrorMsg = "No Client Exists with $gpid as a GPID"
                Write-Host "ECI.ERROR: " $ErrorMsg -ForegroundColor Red
                Report-ECI.EMI.MissingVMResources @VMResources -ErrorMsg $ErrorMsg -RequestID $RequestID -InstanceLocation $InstanceLocation -VMName $VMName

                break
            }#exit with error

    $tempClientPortGroupMulti = $tempClientPortGroups | ?{$_.name -like "multi_*" -and $_.name -notlike "*_**_*" }
        if ($tempClientPortGroupMulti.count -gt 1)
            {
                $tempClientPortGroupMulti = $tempClientPortGroupMulti | select -First 1
            }#select first 1

    $tempClientResourcePool = get-resourcepool $tempGpidWildCard
        if($tempClientResourcePool.count -gt 1)
            {
                foreach($pool in $tempClientResourcePool)
                    {
                        switch ($ServerRole)
                            {                            
                                "2016VDA" 
                                    {
                                        if($pool.name -like "hybrid2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if hybrid2 pool exists then choose this pool and move forward

                                        if($pool.name -like "ems2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if ems2 pool exists then choose this pool and move forward
                                        if($pool.name -like "*ctx*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                            }#if ctx pool found, use this name
                                    }#citrix goes in hybrid2/ems2 if they exist, else it would be ctx
                                "2016DC"
                                    {
                                        if($pool.name -like "hybrid2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if hybrid2 pool exists then choose this pool and move forward

                                        if($pool.name -like "ems2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if ems2 pool exists then choose this pool and move forward
                                        if($pool.name -notlike "*ctx*" -and $pool.name -notlike "*emi*" -and $pool.name -notlike "*hosted*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                    if($tempResourcePoolName.count -gt 1)
                                                        {
                                                            $tempResourcePoolName = $tempResourcePoolName | select -First 1
                                                        }#if there is more than one pool (i.e. multi_gpid and multi_gpid_lan) choose the first one
                                            }#get the pool that doesn't match ctx/emi/hosted
                                    }#dc goes in hybrid2/ems2 if they exist, else it would be the pool that didn't have ctx/emi/hosted in the name
                                "2016FS"
                                    {
                                        if($pool.name -like "hybrid2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if hybrid2 pool exists then choose this pool and move forward

                                        if($pool.name -like "ems2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if ems2 pool exists then choose this pool and move forward
                                        if($pool.name -notlike "*ctx*" -and $pool.name -notlike "*emi*" -and $pool.name -notlike "*hosted*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                    if($tempResourcePoolName.count -gt 1)
                                                        {
                                                            $tempResourcePoolName = $tempResourcePoolName | select -First 1
                                                        }#if there is more than one pool (i.e. multi_gpid and multi_gpid_lan) choose the first one
                                            }#get the pool that doesn't match ctx/emi/hosted
                                    }#file goes in hybrid2/ems2 if they exist, else it would be the pool that didn't have ctx/emi/hosted in the name
                                "2016SQLOMS"
                                    {
                                        if($pool.name -like "hybrid2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if hybrid2 pool exists then choose this pool and move forward

                                        if($pool.name -like "ems2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if ems2 pool exists then choose this pool and move forward

                                        if($pool.name -like "emi*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if emi pool name found, use this name

                                        if($pool.name -like "hosted*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                            }#if hosted pool name found, use this name
                                    }#omsApp goes in hybrid2/ems2 if they exist, else it would be hosted/emi
                                "2016SQL" 
                                    {
                                        if($pool.name -like "hybrid2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if hybrid2 pool exists then choose this pool and move forward

                                        if($pool.name -like "ems2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if ems2 pool exists then choose this pool and move forward

                                        if($pool.name -like "emi*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if emi pool name found, use this name

                                        if($pool.name -like "hosted*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                            }#if hosted pool name found, use this name
                                    }#sql goes in hybrid2/ems2 if they exist, else it would be hosted/emi

                                "2016Server" ### Copy of DC
                                    {
                                        if($pool.name -like "hybrid2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if hybrid2 pool exists then choose this pool and move forward

                                        if($pool.name -like "ems2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if ems2 pool exists then choose this pool and move forward
                                        if($pool.name -notlike "*ctx*" -and $pool.name -notlike "*emi*" -and $pool.name -notlike "*hosted*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                    if($tempResourcePoolName.count -gt 1)
                                                        {
                                                            $tempResourcePoolName = $tempResourcePoolName | select -First 1
                                                        }#if there is more than one pool (i.e. multi_gpid and multi_gpid_lan) choose the first one
                                            }#get the pool that doesn't match ctx/emi/hosted
                                    }# default = copy of DC


                                "default" ### Copy of DC
                                    {
                                        if($pool.name -like "hybrid2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if hybrid2 pool exists then choose this pool and move forward

                                        if($pool.name -like "ems2*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                break
                                            }#if ems2 pool exists then choose this pool and move forward
                                        if($pool.name -notlike "*ctx*" -and $pool.name -notlike "*emi*" -and $pool.name -notlike "*hosted*")
                                            {
                                                $tempResourcePoolName = $pool.name
                                                    if($tempResourcePoolName.count -gt 1)
                                                        {
                                                            $tempResourcePoolName = $tempResourcePoolName | select -First 1
                                                        }#if there is more than one pool (i.e. multi_gpid and multi_gpid_lan) choose the first one
                                            }#get the pool that doesn't match ctx/emi/hosted
                                    }# default = copy of DC
                            }#swtich through server types returning hosted/emi for emi, ctx for citrix, ems2 for everything, hybrid2 for everything (hybrid2 first all lines have continue)
                    }#look at the names of resource pool to pick the appropriate one for each server type  
            }#if more than one resource pool found loop through them
        else        
            {            
                $tempResourcePoolName = $tempClientResourcePool.name        
            }#else only one pool found

    $tempDvswitchName = (get-view ($tempClientPortGroupMulti.ExtensionData.Config.DistributedVirtualSwitch -join ($_.type, "-", $_.value))).name
    $tempPodNumber = $tempDvswitchName.Split("-")[1].trimstart("POD")
    $tempPodNumberWildCard = "*" + $tempPodNumber + "*"
    $tempDatastoreClusterPod = get-datastorecluster $tempPodNumberWildCard

    switch($ServerRole)
        {
            "2016VDA"
                {
                    if($tempResourcePoolName -like "ems2*" -or $tempResourcePoolName -like "hybrid2*")
                        {
                            $tempOsDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*emi_os*"}).name
                            $tempSwapDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*emi_swap*"}).name
                            #$tempDataDatastoreClusterName = "NONE"
                        }#if pool name like ems2/hybrid2 then put in emi datastores
                    else
                        {
                            $tempOsDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*citrix_os*"}).name
                            $tempSwapDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*citrix_swap*"}).name
                        }#else put in ems_client_citrix datastores
                }#citrix goes in emi if hybrid2/ems2 and citrix for all others
            "2016DC"
                {
                    $tempOsDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*dc_os*"}).name
                    $tempSwapDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*dc_swap*"}).name
                    $tempDataDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*client_files*"}).name
                }#dc goes into client_dc datastores
            "2016DCFS"
                {
                    $tempOsDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*dc_os*"}).name
                    $tempSwapDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*dc_swap*"}).name
                    $tempDataDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*client_files*"}).name
                }#file goes into client_dc datastores
            "2016SQLOMS"
                {
                    $tempOsDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*emi_os*"}).name
                    $tempSwapDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*emi_swap*"}).name
                    $tempDataDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*emi_data*"}).name
                }#omsApp goes into emi datastores
            "2016SQL"
                {
                    $tempOsDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*emi_os*"}).name
                    $tempSwapDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*emi_swap*"}).name
                    $tempDataDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*emi_data*"}).name
                    $tempLogDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*emi_data*"}).name
                    $tempSysDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*emi_data*"}).name
                }#sql goes in emi datastores

            "2016Server" ### Copy of DC
                {
                    $tempOsDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*dc_os*"}).name
                    $tempSwapDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*dc_swap*"}).name
                }#default = copy of DC 

            "default" ### Copy of DC
                {
                    $tempOsDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*dc_os*"}).name
                    $tempSwapDatastoreClusterName = ($tempDatastoreClusterPod | ?{$_.name -like "*dc_swap*"}).name
                }#default = copy of DC 

        }#switch through server types returning emi for emi or ctx with hybrid2/ems2 resource pools, citrix for non "2" resource pools, and ems_client_dc for file/dc

    switch($ServerRole)
        {
            "2016VDA"
                {
                    $resourceHash = [ordered]@{
                                                'ServerRole' = $ServerRole
                                                'gpid' = $gpid
                                                'portGroup' = $tempClientPortGroupMulti
                                                'resourcePool' = $tempResourcePoolName
                                                'pod' = $tempPodNumber
                                                'osDatastore' = $tempOsDatastoreClusterName
                                                'swapDatastore' = $tempSwapDatastoreClusterName
                                              }#splatting info for object
                    $resourceObj = New-Object -TypeName psobject -Property $resourceHash
                    $global:resourceObj = $resourceObj
                    return $resourceObj
                }#citrix resource object
            "2016DC"
                {
                    $resourceHash = [ordered]@{
                                                'ServerRole' = $ServerRole
                                                'gpid' = $gpid
                                                'portGroup' = $tempClientPortGroupMulti
                                                'resourcePool' = $tempResourcePoolName
                                                'pod' = $tempPodNumber
                                                'osDatastore' = $tempOsDatastoreClusterName
                                                'swapDatastore' = $tempSwapDatastoreClusterName
                                                'dataDatastore' = $tempDataDatastoreClusterName
                                              }#splatting info for object
                    $resourceObj = New-Object -TypeName psobject -Property $resourceHash
                    $global:resourceObj = $resourceObj
                    return $resourceObj
                }#dc resource object
            "2016DCFS"
                {
                    $resourceHash = [ordered]@{
                                                'ServerRole' = $ServerRole
                                                'gpid' = $gpid
                                                'portGroup' = $tempClientPortGroupMulti
                                                'resourcePool' = $tempResourcePoolName
                                                'pod' = $tempPodNumber
                                                'osDatastore' = $tempOsDatastoreClusterName
                                                'swapDatastore' = $tempSwapDatastoreClusterName
                                                'dataDatastore' = $tempDataDatastoreClusterName
                                              }#splatting info for object
                    $resourceObj = New-Object -TypeName psobject -Property $resourceHash
                    $global:resourceObj = $resourceObj
                    return $resourceObj
                }#file resource object
            "2016SQLOMS"
                {
                    $resourceHash = [ordered]@{
                                                'ServerRole' = $ServerRole
                                                'gpid' = $gpid
                                                'portGroup' = $tempClientPortGroupMulti
                                                'resourcePool' = $tempResourcePoolName
                                                'pod' = $tempPodNumber
                                                'osDatastore' = $tempOsDatastoreClusterName
                                                'swapDatastore' = $tempSwapDatastoreClusterName
                                                'dataDatastore' = $tempDataDatastoreClusterName                                            
                                              }#splatting info for object
                    $resourceObj = New-Object -TypeName psobject -Property $resourceHash
                    $global:resourceObj = $resourceObj
                    return $resourceObj
                }#omsApp resource object
            "2016SQL"
                {
                    $resourceHash = [ordered]@{
                                                'ServerRole' = $ServerRole
                                                'gpid' = $gpid
                                                'portGroup' = $tempClientPortGroupMulti
                                                'resourcePool' = $tempResourcePoolName
                                                'pod' = $tempPodNumber
                                                'osDatastore' = $tempOsDatastoreClusterName
                                                'swapDatastore' = $tempSwapDatastoreClusterName
                                                'dataDatastore' = $tempDataDatastoreClusterName
                                                'logDatastore' = $tempLogDatastoreClusterName
                                                'sysDatastore' = $tempSysDatastoreClusterName
                                              }#splatting info for object
                    $resourceObj = New-Object -TypeName psobject -Property $resourceHash
                    $global:resourceObj = $resourceObj
                    return $resourceObj
                }#sql resource object

            "2016Server" ### Copy of DC
                {
                    $resourceHash = [ordered]@{
                                                'ServerRole' = $ServerRole
                                                'gpid' = $gpid
                                                'portGroup' = $tempClientPortGroupMulti
                                                'resourcePool' = $tempResourcePoolName
                                                'pod' = $tempPodNumber
                                                'osDatastore' = $tempOsDatastoreClusterName
                                                'swapDatastore' = $tempSwapDatastoreClusterName
                                              }#splatting info for object
                    $resourceObj = New-Object -TypeName psobject -Property $resourceHash
                    $global:resourceObj = $resourceObj
                    return $resourceObj
                }#default = copy of DC

            "default" ### Copy of DC
                {
                    $resourceHash = [ordered]@{
                                                'ServerRole' = $ServerRole
                                                'gpid' = $gpid
                                                'portGroup' = $tempClientPortGroupMulti
                                                'resourcePool' = $tempResourcePoolName
                                                'pod' = $tempPodNumber
                                                'osDatastore' = $tempOsDatastoreClusterName
                                                'swapDatastore' = $tempSwapDatastoreClusterName
                                              }#splatting info for object
                    $resourceObj = New-Object -TypeName psobject -Property $resourceHash
                    $global:resourceObj = $resourceObj
                    return $resourceObj
                }#default = copy of DC

        }#switch through server types building and returning the object with the information in it we need
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray

}#end function


function Report-ECI.EMI.MissingVMResources
{
    Param(
        
        [Parameter(Mandatory = $False)][string]$RequestID,
        [Parameter(Mandatory = $False)][string]$InstanceLocation,
        [Parameter(Mandatory = $False)][string]$ServerRole,
        [Parameter(Mandatory = $False)][string]$gpid,
        [Parameter(Mandatory = $False)][string]$VMName,
        [Parameter(Mandatory = $False)][string]$pod,
        [Parameter(Mandatory = $False)][string]$resourcePool,
        [Parameter(Mandatory = $False)][string]$portGroup,
        [Parameter(Mandatory = $False)][string]$osDatastoreCluster,
        [Parameter(Mandatory = $False)][string]$swapDatastoreCluster,
        [Parameter(Mandatory = $False)][string]$sysDatastoreCluster,
        [Parameter(Mandatory = $False)][string]$dataDatastoreCluster,
        [Parameter(Mandatory = $False)][string]$logDatastoreCluster,
        [Parameter(Mandatory = $False)][string]$ErrorMsg
        
    )

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    ############################
    ### HTML Header
    ############################
    $Header  = "<style>"
    $Header += "BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}"
    $Header += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $Header += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}"
    $Header += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #FFEFD5}"
    $Header += "</style>"
    
    ############################
    ### Format Report Data
    ############################

    $Message = $Null
    
    $Header = "
        <style>
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 0px; border-style: hidden; border-color: white; border-collapse: collapse;}
        TH {border-width: 0px; padding: 3px; border-style: hidden; border-color: white; background-color: #6495ED;}
        TD {border-width: 0px; padding: 3px; border-style: hidden; border-color: white;}
        
        </style>
    "
    $Message += $Header
    $Message += "<font size='3';color='gray'><i>ECI EMI Server Automation</i></font><br>"
    $Message += "<font size='5';color='NAVY'><b>vCenter Resource Selection</b></font><br>"
    $Message += "<font size='2'>Request Date:" + (Get-Date) + "</font>"
    $Message += "<br><br><br><br>"
    $Message += "<font size='3';color='black'>WARNING: This Server <b> COULD NOT </b> be provisioned.</font>"
    $Message += "<br><br>"
    $Message += "<font size='3';color='red'><br><b>ERROR MESSAGE: </b></font><br>"
    $Message += "<font size='3';color='red'>" + $ErrorMsg +  " </font>"
    $Message += "<br>"
    $Message += "<font size='3';color='red'><br>GPID: " + $GPID +  " </font>"
    $Message += "<font size='3';color='red'><br>Server Role: " + $ServerRole +  " </font>"


    
    $Message += "<br><br><br>"

    ### Server Specs
    $Message += "<font size='3';color='NAVY'><b>SERVER SPECIFICATIONS:</b></font><br>"
    $Message += "<table>"
    $Message += "<font size='2';color='NAVY'>"
    $Message += "<tr><td align='right'>RequestID : </td><td align='left'>"               + $RequestID                + "</td></tr>"
    $Message += "<tr><td align='right'>VMName : </td><td align='left'>"                  + $VMName                   + "</td></tr>"
    $Message += "<tr><td align='right'>InstanceLocation : </td><td align='left'>"        + $InstanceLocation         + "</td></tr>"
    $Message += "<tr><td align='right'>GPID : </td><td align='left'>"                    + $GPID                     + "</td></tr>"
    $Message += "<tr><td align='right'>ServerRole : </td><td align='left'>"              + $ServerRole               + "</td></tr>"
    $Message += "<tr><td align='right'>Pod : </td><td align='left'>"                     + $Pod                      + "</td></tr>"
    $Message += "</table>"
    $Message += "<br>"

    ### VCenter Resources
    $Message += "<font size='3';color='NAVY'><b>VCENTER RESOURCES:</b></font><br>"
    $Message += "<table border='1'>"
    $Message += "<font size='2';color='NAVY'>"
    $Message += "<tr><td align='right'>ResourcePool : </td><td align='left'>"            + $ResourcePool             + "</td></tr>"
    $Message += "<tr><td align='right'>PortGroup : </td><td align='left'>"               + $PortGroup                + "</td></tr>"
    $Message += "<tr><td align='right'>osDatastoreCluster : </td><td align='left'>"      + $osDatastoreCluster       + "</td></tr>"
    $Message += "<tr><td align='right'>swapDatastoreCluster : </td><td align='left'>"    + $swapDatastoreCluster     + "</td></tr>"
    $Message += "<tr><td align='right'>dataDatastoreCluster : </td><td align='left'>"    + $dataDatastoreCluster     + "</td></tr>"
    $Message += "<tr><td align='right'>logDatastoreCluster : </td><td align='left'>"     + $logDatastoreCluster      + "</td></tr>"
    $Message += "<tr><td align='right'>swapDatastoreCluster : </td><td align='left'>"    + $swapDatastoreCluster     + "</td></tr>"
    $Message += "<tr><td align='right'>sysDatastoreCluster : </td><td align='left'>"     + $sysDatastoreCluster      + "</td></tr>"
    $Message += "</font>"
    $Message += "</table>"
    $Message += "<br>"

    ### Display Desired State SQL Record
    ###----------------------------------------------------------------------------    
    $Message += "<font size='3';color='NAVY'><b>SERVER REQUEST INFORMATION:</b>"           + "</font><br>"
    $Header = "
        <style>
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
        </style>
    "
    $Message += $Header

    $DataSetName = "ServerRequest"
    $ConnectionString = $Portal_DBConnectionString
    $Query = "SELECT * FROM ServerRequest WHERE RequestID = '$RequestID'"
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft
        
    $ServerRequest += "<table>" 
    $ServerRequest +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $ServerRequest += "<b><u><td>"+$dt.Columns[$i].ColumnName+"</td></u></b>"  
    }
    $ServerRequest +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $ServerRequest +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $ServerRequest += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $ServerRequest +="</tr>"
    }

    $ServerRequest += "</table></body></html>"
    $Message += $ServerRequest    
    $Message += "<br><br>"
<#

    ### Write Report to SQL
    ###------------------------
    Write-Host ("=" * 50)`n"Writing Report to SQL"`n("=" * 50)`n -ForegroundColor DarkCyan

    $Query = "INSERT INTO Errors(GPID,VMName,ServerRole,ResourcePool,PortGroup,osDatastoreCluster,swapDatastoreCluster) VALUES('$GPID','$VMName','$ServerRole','$ResourcePool','$PortGroup','$osDatastoreCluster','$swapDatastoreCluster')"
    
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $DevOps_DBConnectionString 
    $Connection.Open()   
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $Query
    $cmd.ExecuteNonQuery() | Out-Null
    $connection.Close()
#>  


    ### Email HTML Report
    ###------------------------
    #$From   = "cbrennan@eci.com"
    $From    = $SMTPFrom
    $SMTP    = $SMTPServer
    $Subject = "Server Provisioning- Missing VM Resources"
    $To      = $SMTPTo
    #$To     = "cbrennan@eci.com,sdesimone@eci.com,wercolano@eci.com,rgee@eci.com"
    #$To     = "cbrennan@eci.com,sdesimone@eci.com"
    $To      = "cbrennan@eci.com"

    ### Email Message
    ###----------------------------------------------------------------------------
    Write-Host `r`n`r`n`r`n("=" * 50)`n "Sending Alert - vCenter Resource Not Found" `r`n("=" * 50)`r`n`r`n -ForegroundColor Yellow
    Write-Host "TO: " $To

    

    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP
        
    
    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
 }

 

