#Firewall rules, outlook settings, file share settings, and the security settings  

###################################
### QA Script
### ECI.EMI.Automation.QA.Prod.ps1
###################################
Param(
        [Parameter(Mandatory = $True)][int]$ServerID,
        [Parameter(Mandatory = $True)][string]$Environment,
        [Parameter(Mandatory = $True)][string]$ConfigurationMode
     )

&{

    BEGIN
    {
        ### Write Header Information
        ###---------------------------------
        Write-Host `r`n`r`n('*' * 100)`r`n (' ' * 20)" --------- STARTING QA --------- " `r`n('*' * 100)  -ForegroundColor Cyan
        Write-Host ('-' * 50)`n                                                                    -ForegroundColor DarkCyan
        Write-Host "Env         : " $Env                                                           -ForegroundColor DarkCyan
        Write-Host "Environment : " $Environment                                                   -ForegroundColor DarkCyan
        Write-Host "Script      : " (Split-Path (Get-PSCallStack)[0].ScriptName -Leaf)             -ForegroundColor DarkCyan
        Write-Host `n('-' * 50)`n  

        $script:QAStartTime = Get-Date    
    }

    PROCESS
    {
        Test-IPConnectivity
        QA-SMBv1
    }

    END
    {
        $QAStopTime = Get-Date
        $global:QAElapsedTime = ($QAStopTime-$QAStartTime)
        Write-Host `n`n('=' * 75)`n "QA: Total Execution Time:`t" $QAElapsedTime `n('=' * 75)`n -ForegroundColor Gray
        Write-Host "END QA SCRIPTS" -ForegroundColor Gray
    }


}