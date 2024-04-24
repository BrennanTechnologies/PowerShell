
Param(
    [parameter(Mandatory=$True)][string]$VmName,
    [parameter(Mandatory=$True)][string]$vCenter,
    [parameter(Mandatory=$True)][string]$vmId,
    [parameter(Mandatory=$False)][string]$VmUUID
)

$global:Env = "Prod"
$global:Environment = "Production"

function Import-ECI.Root.ModuleLoader
{
    ######################################
    ### Bootstrap Module Loader
    ######################################
    Param([Parameter(Mandatory = $True)][ValidateSet("Dev","Stage","Prod")] [string]$Env)


    ### Set Repository Name Space
    ###-------------------------------------
    if ($Env -eq "Dev")          {$global:Environment = "Development"}
    if ($Env -eq "Prod")         {$global:Environment = "Production"}
    if ($Env -eq "Development")  {$global:Environment = "Development"}
    if ($Env -eq "Production")   {$global:Environment = "Production"}


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
        Start-ECI.Transcript -TranscriptPath "C:\Scripts\_VMAutomationLogs\Transcripts\" -TranscriptName "ECI.EMI.VM.Inventory.$Env.ps1"

        $global:DevOps_ConnectionString  =  "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;” # <-- Need to Encrypt Password !!!!!!
        Get-ECI.EMI.Automation.SystemConfig -Env $Env -DevOps_ConnectionString $DevOps_ConnectionString 

        Import-ECI.EMI.Automation.VMWareModules -Env $Env -Environment $Environment -ModuleName "VMWare*" -ModuleVersion "10.0.0"
        Connect-ECI.EMI.Automation.VIServer -vCenterName $vCenter -vCenter_Account $vCenter_Account -vCenter_Password $vCenter_Password
        exit
    }
        
    PROCESS
    {
        
        $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray

        . "\\eciscripts.file.core.windows.net\clientimplementation\Production\ECI.Modules.Prod\ECI.EMI.VM.Inventory.Prod\VMware-Inventory-Refresh.ps1" -VMName $VMName -vCenter $vCenter -VMID $VMID -VmUUID $VmUUID

        Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    }
    
    END 
    {
        Stop-Transcript
    }

}