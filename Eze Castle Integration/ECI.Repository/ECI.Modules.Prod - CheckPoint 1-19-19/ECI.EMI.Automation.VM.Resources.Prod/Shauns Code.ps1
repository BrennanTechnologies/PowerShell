cls


<#
Connect-ECI.EMI.Automation.VIServer ld5

$ECIvCenter = "ld5vc.eci.cloud"
$vCenter_Account = "portal-int@eci.cloud"
$vCenter_Password = "7Gc^jfzaZnzD"
Disconnect-VIServer -Server $global:DefaultVIServers -confirm:$false
$global:VISession = Connect-VIServer -Server $ECIvCenter -User $vCenter_Account -Password $vCenter_Password
$gpid = "ETEST040"
Get-vdPortGroup | Where-Object {$_.Name -Like "*" + $gpid + "*"}
#>

$vsphereClientResourceInfo = @()
#$serverType = "emi"
#$gpidList = Import-Csv -Path C:\Users\sdesimone\Documents\portalGpidTesting\GPIDs.csv

#$gpidList = Import-Csv -Path X:\Production\ECI.Modules.Prod\ECI.EMI.Automation.VM.Resources.Prod\GPIDs.txt
#$gpidList = "ETEST040" #"colch001"#"north021"#"tiede001", "apexf401" ,"etest040"
$gpidList = "APEX"
foreach($line in $gpidList)
    {
        #$line
        <#$tempGpidWildCard = "*" + $line.gpid + "*" COMMENTED OUT FOR NOW#>
        $tempGpidWildCard = "*" + $line.gpid + "*"
        #$tempClientPortGroups = Get-vdPortGroup $tempGpidWildCard #testing removing this| Where-Object {$_.Name -Like $tempGpidWildCard}
        $tempClientPortGroups = Get-vdPortGroup | Where-Object {$_.Name -Like $tempGpidWildCard}
            foreach($group in $tempClientPortGroups)
                {
                    #$tempPodNum = (Get-VDPortgroup -Name $group.name | Get-VDSwitch).name.split("\-")[1].Replace("POD","")
                    switch($group.datacenter) {
                                                'Hong Kong' {$vcenter = "hkvc.eci.cloud" ; $vcenterID = "hk"}
                                                'Jersey City' {$vcenter = "cloud-qtsvc.eci.corp" ; $vcenterID = "qts"}
                                                'LHC' {$vcenter = "lhcvc.eci.cloud" ; $vcenterID = "lhc"}
                                                'LD5' {$vcenter = "ld5vc.eci.cloud" ; $vcenterID = "ld5"}
                                                'Sacramento' {$vcenter = "sacvc.eci.cloud" ; $vcenterID = "sac"}
                                                'Singapore' {$vcenter = "sgvc.eci.cloud" ; $vcenterID = "sg"}
                                              }#switch through the datacenter name to have the appropriate vcenter
                    $tempNetworkView = Get-View -ViewType network -Property name -Filter @{"Name" = $group.name}
                    $tempNetworkView.UpdateViewData("vm.name","vm.resourcepool","vm.config.datastoreurl")
                    $tempDvswitchName = (get-view ($group.ExtensionData.Config.DistributedVirtualSwitch -join ($_.type, "-", $_.value))).name
                        foreach($VM in $tempNetworkView.LinkedView.Vm)
                            {
                                $tempVmName = $vm.name
                                if(!$vm.ResourcePool)
                                    {                                        
                                        $tempResourcePoolName = "NO RESOURCEPOOL FOR $tempVmName"
                                        #Clear-Variable tempVmName
                                    }#if no resource pool for the current vm then output that here
                                else
                                    {
                                        $tempResourcePoolName = (Get-View ($vm.ResourcePool -join ($_.type, "-", $_.value))).name
                                    }#else get the name of the resource pool
                                    foreach($tempVmDsUrl in $vm.Config.DatastoreUrl)
                                        {
                                            $tempDsName = $tempVmDsUrl.name
                                            $tempDs = get-view -viewtype datastore -filter @{"Name" = $tempDsName}
                                                if($tempDs.count -gt 1)
                                                    {
                                                        $tempDsParentMorefId = ($tempDs | select -first 1).parent -join ($_.type, "-", $_.value)
                                                    }#if more than one volume in the same datastore select first one
                                                else
                                                    {
                                                        $tempDsParentMorefId = ($tempDs).parent -join ($_.type, "-", $_.value)
                                                    }#else if only one then just create the parent morefid from that one object
                                            $tempDsParentClusterName = (Get-View $tempDsParentMorefId).name
                                            $vsphereInfoHash = [ordered]@{
                                                                            'vmName' = $tempVmName
                                                                            'portGroupName' = $group.name                                                                            
                                                                            'dvswitchName' = $tempDvswitchName
                                                                            'datastoreCluster' = $tempDsParentClusterName 
                                                                            'resourcePool' = $tempResourcePoolName                                                                           
                                                                            'datacenterName' = $vcenter
                                                                            'vcenterDatacenterId' = $group.datacenter
                                                                         }
                                            $obj = New-Object -TypeName psobject -Property $vsphereInfoHash
                                            $vsphereClientResourceInfo += $obj

                                            Clear-Variable tempDsName,tempDs,tempDsParentMorefId,tempDsParentClusterName
                                        }#loop through each datastore url attached to the vm to get the appropriate information on it from vsphere 
                                         
                                Clear-Variable tempResourcePoolName,tempVmName
                            }#loop through each adapter and pull all the appropriate information from vsphere
                    
                    Clear-Variable tempNetworkView,tempDvswitchName
                }#loop through all port groups with the gpid identifier found in vcenter

        Clear-Variable tempGpidWildCard,tempClientPortGroups
    }#loop through each gpid and get info

$vsphereClientResourceInfo# | sort -Unique datastorecluster

$vsphereClientResourceInfo.count
#$vsphereClientResourceInfo.vmName 	 	 
 	 
 	 