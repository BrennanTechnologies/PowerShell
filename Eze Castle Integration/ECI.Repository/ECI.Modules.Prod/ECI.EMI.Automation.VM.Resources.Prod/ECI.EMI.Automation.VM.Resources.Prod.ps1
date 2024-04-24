
Param(
    [Parameter(Mandatory = $True)][string]$RequestID,
    [Parameter(Mandatory = $True)][string]$InstanceLocation,
    [Parameter(Mandatory = $True)][string]$ServerRole,
    [Parameter(Mandatory = $True)][string]$GPID,
    [Parameter(Mandatory = $True)][string]$VMName,
    [Parameter(Mandatory = $False)][switch]$Invoke
)


function Import-ECI.Root.ModuleLoader
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `n('-' * 100)`n "Executing Function: " $FunctionName `n('-' * 100) -ForegroundColor Gray

    ######################################
    ### Bootstrap Module Loader
    ######################################

    ### Set Execution Policy to ByPass
    #Write-Host "Setting Execution Policy: ByPass"
    #Set-ExecutionPolicy Bypass

    ### Connect to the Repository & Import the ECI.ModuleLoader
    ### ----------------------------------------------------------------------
    $AcctKey         = ConvertTo-SecureString -String "VSRMGJZNI4vn0nf47J4bqVd5peNiYQ/8+ozlgzbuA1FUnn9hAoGRM9Ib4HrkxOyRJkd4PHE8j36+pfnCUw3o8Q==" -AsPlainText -Force
    $Credentials     = $Null
    $Credentials     = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\eciscripts", $AcctKey
    $RootPath        = "\\eciscripts.file.core.windows.net\clientimplementation"
    
    
            
#New-PSDrive -Name X -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Persist -Scope Global

    #((Get-PSDrive | Where {((Get-PSDrive).Root) -like "\\eciscripts*"}) | Remove-PSDrive -Force ) | Out-Null

    $Mapped = (Get-PSDrive -PSProvider FileSystem).Name -like "X"
    
    

    if(!$Mapped)
    {
        ####New-PSDrive -Name $RootDrive -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Persist -Scope global
        New-PSDrive -Name X -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Scope Global
    }

    #$PSDrive = New-PSDrive -Name X -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Persist -Scope Global

    ### Import the Module Loader - Dot Source
    ### ----------------------------------------------------------------------
    . "\\eciscripts.file.core.windows.net\clientimplementation\Root\Prod\ECI.Root.ModuleLoader.ps1" -Env Prod
}


function Import-VMModules
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `n('-' * 100)`n "Executing Function: " $FunctionName `n('-' * 100) -ForegroundColor Gray

    $VMModulesPath = "C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Modules\"
    $env:PSModulePath = $env:PSModulePath + ";" +  $VMModulesPath

    Get-Module -ListAvailable VM* | Import-Module
}


function Connect-ECI.VIServer
{
    Param([Parameter(Mandatory = $True)][string]$InstanceLocation)
    
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `n('-' * 100)`n "Executing Function: " $FunctionName `n('-' * 100) -ForegroundColor Gray

    switch ( $InstanceLocation )
    {
        "Lab" { $vCenter = "ecilab-bosvcsa01.ecilab.corp" }
        "BOS" { $vCenter = "bosvc.eci.cloud"      }
        "QTS" { $vCenter = "cloud-qtsvc.eci.corp" }
        "SAC" { $vCenter = "sacvc.eci.cloud"      }
        "LHC" { $vCenter = "lhcvc.eci.cloud"      }
        "LD5" { $vCenter = "ld5vc.eci.cloud"      }
        "HK"  { $vCenter = "hkvc.eci.cloud"       }
        "SG"  { $vCenter = "sgvc.eci.cloud"       }
    }

    $global:vCenter = $vCenter
    Connect-VIServer -Server $vCenter  -User portal-int@eci.cloud -Password 7Gc^jfzaZnzD
    #Connect-VIServer -Server $vCenter  -User ezebos\cbrennan -Password Tolkien43743
    
    Return $vCenter
}


&{
    BEGIN
    {
        #Start-Transcript
        Write-Host `r`n`r`n('*' * 100)`r`n (' ' * 20)" --------- Getting VM vCenter Resources --------- " `r`n('*' * 100)  -ForegroundColor Cyan
        
        if($Invoke)
        {
            Import-ECI.Root.ModuleLoader
            Reload-ECI.Modules
            Import-VMModules
            Connect-ECI.VIServer -InstanceLocation $InstanceLocation
        
            ### Get DB Connection for Report
            $global:DevOps_ConnectionString  =  "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;” # <-- Need to Encrypt Password !!!!!!
            Get-ECI.EMI.Automation.SystemConfig -Env $Env -DevOps_ConnectionString $DevOps_ConnectionString 
        }
    }

    PROCESS 
    {
        ###----------------------
        ### Get vCenter Resources
        ###----------------------
        try
        {
            try
            {
                get-vmResourceByGpidServerRole -ServerRole $ServerRole -gpid $gpid
                #Write-Host "resourceObj: " $resourceObj -ForegroundColor Green
            }
            catch
            {
                $ErrorMsg = "ECI.ERROR Executing Function: get-vmResourceByGpidServerRole -  " + $Error[0]
                #Write-Error -Message $ErrorMsg -ErrorAction Stop
                Write-Host $ErrorMsg -ForegroundColor Red
            }


            if($resourceObj)
            {
                #write-host "resourceObj:" $resourceObj -ForegroundColor Green
            }
            else
            {
                $ErrorMsg = "ECI.ERROR:  No resourceObj Returned. "
                #Write-Error -Message $ErrorMsg -ErrorAction Continue -ErrorVariable +ECIError
                Write-Host $ErrorMsg -ForegroundColor Red
            }
            

            $VMResources = @{}
            foreach($resource in $resourceObj.PSObject.Properties)
            {
                $VMResources.Add($resource.Name, $resource.Value)
                #Write-Host $resource.Name ": " $resource.Value -ForegroundColor Gray
            }
        
            ###----------------------
            ### Check Port Group
            ###----------------------
            if($resourceObj.portGroup)
            {
                Write-Host "SELECTED - portGroup    : " $resourceObj.portGroup -ForegroundColor Cyan
                $global:PortGroup = $resourceObj.portGroup
            }
            else
            {
                #$ErrorMsg = "No Port Group was Found. GPID: $GPID SERVERROLE: $ServerRole"
                $ErrorMsg = "Port Group was NOT Found. GPID: "
                Write-Host "ECI.ERROR: " $ErrorMsg -ForegroundColor Red
                Report-ECI.EMI.MissingVMResources @VMResources -ErrorMsg $ErrorMsg -RequestID $RequestID -InstanceLocation $InstanceLocation -VMName $VMName
            }

            ###----------------------
            ### Check Resource Pool
            ###----------------------
            if($resourceObj.resourcePool)
            {
                Write-Host "SELECTED - resourcePool: " $resourceObj.resourcePool -ForegroundColor Cyan
                $global:ResourcePool = $resourceObj.resourcePool
            }
            else
            {
                #$ErrorMsg = "No Resource Pool was Found. GPID: $GPID SERVERROLE: $ServerRole"
                $ErrorMsg = "Resource Pool was NOT Found."
                Write-Host "ECI.ERROR: " $ErrorMsg -ForegroundColor Red
                Report-ECI.EMI.MissingVMResources @VMResources -ErrorMsg $ErrorMsg -RequestID $RequestID -InstanceLocation $InstanceLocation -VMName $VMName
            }

            ###----------------------
            ### Return Datastore
            ###----------------------
            #$global:OSDataStore = $datastore.Name | Where {$_.Name -like "*OS*"}
            #$global:SwapDataStore = $datastore.Name | Where {$_.Name -like "*Swap*"}

            #Write-Host "OSDataStore: $OSDataStore" -ForegroundColor Magenta
            #Write-Host "SwapDataStore $SwapDataStore" -ForegroundColor Magenta

            ###----------------------
            ### Check Datastore
            ###----------------------
            foreach($datastore in $resourceObj.PSObject.Properties | where {$_.Name -like "*Datastore*"})
            {
                if($datastore.Name)
                {
                    if($datastore.Value -eq $Null)
                    {
                        $ErrorMsg = "Datastore was NOT Found." 
                        #$ErrorMsg = "Datastore was NOT Found. gpid: $GPID serverrole: $ServerRole" 
                        Write-Host "ECI.ERROR: " $ErrorMsg -ForegroundColor Red
                        Report-ECI.EMI.MissingVMResources @VMResources -ErrorMsg $ErrorMsg -RequestID $RequestID -InstanceLocation $InstanceLocation -VMName $VMName
                        Break
                    }

                    New-Variable -Name $datastore.Name -Value $datastore.Value -Scope Global
                    Write-Host "SELECTED -" $datastore.Name ": " $datastore.Value -ForegroundColor Cyan
                }
                else
                {
                    #$ErrorMsg = "No Datastore was Found. $GPID SERVER ROLE: $ServerRole" 
                    $ErrorMsg = "Datastore was NOT Found." 
                    Write-Host "ECI.ERROR: " $ErrorMsg -ForegroundColor Red
                    Report-ECI.EMI.MissingVMResources @VMResources -ErrorMsg $ErrorMsg -RequestID $RequestID -InstanceLocation $InstanceLocation -VMName $VMName
                }
            }
        }
        catch
        {
            $ErrorMsg = "Error Executing Function: " + $Error[0].Exception.Message
            Write-Host "ECI.TRY-CATCH.ERROR: " $ErrorMsg -ForegroundColor Red
            Report-ECI.EMI.MissingVMResources -ErrorMsg $ErrorMsg -RequestID $RequestID -InstanceLocation $InstanceLocation -VMName $VMName
            Throw $ErrorMsg
        }
    }
    END
    {
        #Stop-Transcript
    }
}


<#
&{
    BEGIN
    {
        $ECIVMResouceError = $null
        
        Write-Host `r`n`r`n('*' * 100)`r`n (' ' * 20)" --------- Getting vCenter Resources --------- " `r`n('*' * 100)  -ForegroundColor Cyan

        #Import-ECI.Root.ModuleLoader
        #Reload-ECI.Modules
        #Import-VMModules
        #Connect-ECI.VIServer -InstanceLocation $InstanceLocation
        
        #$global:DevOps_ConnectionString  =  "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;” # <-- Need to Encrypt Password !!!!!!
        #Get-ECI.EMI.Automation.SystemConfig -Env $Env -DevOps_ConnectionString $DevOps_ConnectionString 
    }

    PROCESS 
    {
        ###----------------------
        ### Get vCenter Resources
        ###----------------------
        try
        {
            get-vmResourceByGpidServerRole -ServerRole $ServerRole -gpid $gpid
        }
        catch
        {
            $ErrorMsg = "Error Executing Function: " + $Error[0].Exception.Message
            Write-Host "ECI.ERROR: " $ErrorMsg -ForegroundColor Red
            Report-ECI.EMI.MissingVMResources -ErrorMsg $ErrorMsg -RequestID $RequestID -InstanceLocation $InstanceLocation -VMName $VMName
            
            Throw $ErrorMsg
        }

        $VMResources = @{}
        foreach($resource in $resourceObj.PSObject.Properties)
        {
            $VMResources.Add($resource.Name, $resource.Value)
            #Write-Host $resource.Name ": " $resource.Value -ForegroundColor Gray
        }
        
        ###----------------------
        ### Check Port Group
        ###----------------------
        if($resourceObj.portGroup)
        {
            Write-Host "SELECTED - portGroup    : " $resourceObj.portGroup -ForegroundColor Green
            $global:PortGroup = $resourceObj.portGroup
        }
        else
        {
            $ErrorMsg = "No Port Group was Found."
            Write-Host "ECI.ERROR: " $ErrorMsg -ForegroundColor Red
            Report-ECI.EMI.MissingVMResources @VMResources -ErrorMsg $ErrorMsg -RequestID $RequestID -InstanceLocation $InstanceLocation -VMName $VMName
        }

        ###----------------------
        ### Check Resource Pool
        ###----------------------
        if($resourceObj.resourcePool)
        {
            Write-Host "SELECTED - resourcePool: " $resourceObj.resourcePool -ForegroundColor Green
            $global:ResourcePool = $resourceObj.resourcePool
        }
        else
        {
            $ErrorMsg = "No Resource Pool was Found."
            Write-Host "ECI.ERROR: " $ErrorMsg -ForegroundColor Red
            Report-ECI.EMI.MissingVMResources @VMResources -ErrorMsg $ErrorMsg -RequestID $RequestID -InstanceLocation $InstanceLocation -VMName $VMName
        }

        ###----------------------
        ### Check Datastore
        ###----------------------
        foreach($datastore in $resourceObj.PSObject.Properties | where {$_.Name -like "*Datastore*"})
        {
            if($datastore.Name)
            {
                Write-Host "SELECTED -" $datastore.Name ": " $datastore.Value -ForegroundColor Green
            }
            else
            {
                $ErrorMsg = "No Datastore was Found." 
                Write-Host "ECI.ERROR: " $ErrorMsg -ForegroundColor Red
                Report-ECI.EMI.MissingVMResources @VMResources -ErrorMsg $ErrorMsg -RequestID $RequestID -InstanceLocation $InstanceLocation -VMName $VMName
            }
        }
    }
}
#>