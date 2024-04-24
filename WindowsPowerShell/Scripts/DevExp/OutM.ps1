
    enum Cat
    {
        INFO
        PROMPT 
        WARN
        ERROR
    }
    
#Change current directory to parent dir of this script
if(!$PSScriptRoot) {
    $myScriptRoot = (Get-Location).Path
}
else {
    $myScriptRoot = $PSScriptRoot
}

#Initialize log file
if (!(Test-Path "$($myScriptRoot)\Logs")) {
    New-Item -ItemType Directory -Path $myScriptRoot -Name Logs | Out-Null
}
$logFile = "$($myScriptRoot)\Logs\VSAN_Cluster_Config_$(Get-Date -Format MMddyyyy_HHmmss).log"

"$(Get-Date -Format "MM/dd/yyyy HH:mm:ss") - INFO : VSAN_Cluster_Config.ps1 initiated by $($env:USERNAME)." | Out-File $logFile -Force

#Displays output and writes to a log file
function OutM {
    param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('INFO','PROMPT','WARN','ERROR')]
    [string]$Cat

    ,
    [string]$Msg
    ,
    [string]$Color)
    


    if($Color -eq "") {
        switch($Cat) { 
            "INFO" {$Color = "White"}
            "PROMPT" {$Color = "Yellow"}
            "WARN" {$Color = "DarkYellow"}
            "ERROR" {$Color = "Red"}
            default {$Color = "White"}
        }
    }

    Write-Host $Msg -ForegroundColor $Color
    if($Cat -ne "PROMPT"){
        "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss") - $Cat : $Msg" | Out-File -Append -Force $logFile
    }
}

OutM -Msg "This is a test" -Cat  