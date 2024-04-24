Param(
    [Parameter(Mandatory = $True,Position=0)][string]$VMMgmtOperation,
    [Parameter(Mandatory = $True,Position=1)][string]$VMMgmtValue,
    [Parameter(Mandatory = $True,Position=2)][string]$VMName,
    [Parameter(Mandatory = $True,Position=3)][string]$vCenterName,
    [Parameter(Mandatory = $True,Position=4)][string]$VMUUID,
    [Parameter(Mandatory = $True,Position=5)][string]$VMMoRef
    
)

function Import-ECI.Root.ModuleLoader
{
    ######################################
    ### Bootstrap Module Loader
    ######################################
    Param([Parameter(Mandatory = $False)][ValidateSet("Dev","Stage","Prod")] [string]$Env)

    ### Connect to the Repository & Import the ECI.ModuleLoader
    ### ----------------------------------------------------------------------
    $AcctKey         = ConvertTo-SecureString -String "VSRMGJZNI4vn0nf47J4bqVd5peNiYQ/8+ozlgzbuA1FUnn9hAoGRM9Ib4HrkxOyRJkd4PHE8j36+pfnCUw3o8Q==" -AsPlainText -Force
    $Credentials     = $Null
    $Credentials     = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\eciscripts", $AcctKey
    $RootPath        = "\\eciscripts.file.core.windows.net\clientimplementation"
  
    #$Invoke-Command -ScriptBlock {Net Use X: delete}
    

    $PSEnvDrives  = Get-PSDrive -PSProvider FileSystem | Where-Object {($_.Root -like "*eciscripts*") -OR ($_.DisplayRoot -like "*eciscripts*")}
    if($PSEnvDrives)
    {
        foreach($PSEnvDrive in $PSEnvDrives)
        {
            #Write-Host "Removing Drive: $PSEnvDrive" -ForegroundColor Yellow
            Remove-PSDrive -Name $PSEnvDrive -PSProvider FileSystem -Force
        }
    }
        ####New-PSDrive -Name $RootDrive -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Persist -Scope global
        New-PSDrive -Name X -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Scope Global


    #$PSDrive = New-PSDrive -Name X -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Persist -Scope Global

    ### Import the Module Loader - Dot Source
    ### ----------------------------------------------------------------------
    . "\\eciscripts.file.core.windows.net\clientimplementation\Root\$Env\ECI.Root.ModuleLoader.ps1" -Env $Env


}

&{

    BEGIN
    {
        Import-ECI.Root.ModuleLoader -Env $Env
    }
        
    PROCESS
    {
        Start-Process powershell.exe -ArgumentList ("-noexit -file \\eciscripts.file.core.windows.net\clientimplementation\" + $Environment + "\ECI.Modules." + $Env + "\ECI.EMI.VM.Mgmt." + $Env + "\ECI.EMI.VM.Mgmt" + $Env + ".ps1"), $VMMgmtOperation, $VMMgmtValue, $VMName, $vCenterName, $VMUUID, $VMMoRef
    }
    
    END {}

}
