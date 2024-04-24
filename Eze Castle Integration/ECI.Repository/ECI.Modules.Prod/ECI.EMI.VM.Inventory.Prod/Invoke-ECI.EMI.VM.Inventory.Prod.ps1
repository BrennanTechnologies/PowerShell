cls
$global:env = "Prod"


$VMName = "ETEST040_Test-LD5-QqhDy" # Good/On
$vCenter = "ld5vc.eci.cloud"
$VMID = "VirtualMachine-vm-12375"
$VMUUID = "421e8f66-e26c-1449-5a58-6cf4f2c89160"


function Start-ECI.Transcript
{
    Param(
    [Parameter(Mandatory = $False)][string]$TranscriptPath,
    [Parameter(Mandatory = $False)][string]$TranscriptName,
    [Parameter(Mandatory = $False)][string]$HostName
    )

    function Generate-RandomAlphaNumeric
    {
        Param([Parameter(Mandatory = $False)][int]$Length)

        if(!$Length){[int]$Length = 15}

        ##ASCII
        #48 -> 57 :: 0 -> 9
        #65 -> 90 :: A -> Z
        #97 -> 122 :: a -> z

        for ($i = 1; $i -lt $Length; $i++) 
        {
            $a = Get-Random -Minimum 1 -Maximum 4 
            switch ($a) 
            {
                1 {$b = Get-Random -Minimum 48 -Maximum 58}
                2 {$b = Get-Random -Minimum 65 -Maximum 91}
                3 {$b = Get-Random -Minimum 97 -Maximum 123}
            }
            [string]$c += [char]$b
        }

        Return $c
    }

    ### Stop Transcript if its already running
    try {Stop-transcript -ErrorAction SilentlyContinue} catch {} 
    
    $TimeStamp  = Get-Date -format "yyyyMMddhhmss"
    $Rnd = (Generate-RandomAlphaNumeric)
    
    ### Set Default Path
    if(!$TranscriptPath){$global:TranscriptPath = "C:\Scripts\Transcripts"}

    ### Make sure path ends in "\"
    $LastChar = $TranscriptPath.substring($TranscriptPath.length-1) 
    if ($LastChar -ne "\"){$TranscriptPath = $TranscriptPath + "\"}

    ### Create Transcript File Name
    if($TranscriptName)
    {
        $global:TranscriptFile = $TranscriptPath + "PowerShell_transcript" + "." + $TranscriptName + "." + $Rnd + "." + $TimeStamp + ".txt"
    }
    else
    {
        $global:TranscriptFile = $TranscriptPath + "PowerShell_transcript" + "." + $Rnd + "." + $TimeStamp + ".txt"
    }
    ### Start Transcript Log
    Start-Transcript -Path $TranscriptFile -NoClobber 
}

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
    }
        
    PROCESS
    {
        
        $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 50)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 50) -ForegroundColor Gray
        `
        #Start-Process powershell.exe -ArgumentList ("-noexit -file \\eciscripts.file.core.windows.net\clientimplementation\ECI.Modules.$Env\ECI.EMI.VM.Inventory.$Env\ECI.EMI.VM.Inventory.$env.ps1") , $Env
        #Start-Process powershell.exe -ArgumentList ("-noexit -file \\eciscripts.file.core.windows.net\clientimplementation\ECI.Modules.$Env\ECI.EMI.VM.Inventory.$Env\VMware-Inventory-Refresh.ps1") , $VMName, $VMID ,$vCenter
        Start-Process powershell.exe -ArgumentList ("-noexit -file \\eciscripts.file.core.windows.net\clientimplementation\Production\ECI.Modules.Prod\ECI.EMI.VM.Inventory.Prod\ECI.EMI.VM.Inventory.Prod.ps1") , $VMName, $vCenter, $VMID, $VmUUID


        Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
    }
    
    END {}

}