cls
#Reload-ECI.Modules

$vCenter_Account = "portal-int@eci.cloud"
$vCenter_Password = "7Gc^jfzaZnzD"
$secpasswd = ConvertTo-SecureString $vCenter_Password -AsPlainText -Force
$HostCreds = New-Object System.Management.Automation.PSCredential ($vCenter_Account, $secpasswd)
#Disconnect-VIServer -Server $global:DefaultVIServers -confirm:$false
#Connect-VIServer -Server $vCenter -User $vCenter_Account -Password $vCenter_Password



$Creds=@{
    LocalAdminName = "ECIAdmin"
    LocalAdminPassword = "cH3r0k33"
}



$global:VMName = "ETEST040_Test-LD5-p0Buq"
$global:HostName = "Test-LD5-p0Buq"

$global:RequestID = "999"
$global:ServerID = "1833"
$global:ServerRole = "2016Server"
$BuildVersion = "1.0.0"


$global:Env = "PROD"
$global:Environment = "Production"
$global:Step = "Configure-ECI.EMI.Configure.OS.GuestComputer"

$AdministrativeUserName = "cbrennan@eci.corp"
$AdministrativePassword = "Password123"

$global:AutomationLogPath = "C:\Scripts\_VMAutomationLogs"
$global:ECIErrorLogFile = $AutomationLogPath + "\" + $HostName + "\" + $HostName + "_ECIErrorLog.txt"
$global:InGuestLogPath = "C:\Temp\InGuestLogs"

$global:WaitTime_StartSleep = 30
$global:WaitTime_VMTools = 60


#### MAIN
& {
    BEGIN
    {
        Interrogate-ECI.EMI.Automation.VM.GuestState -VMName $VMName -HostName $HostName
        Copy-ECI.EMI.VM.FileToGuest -LocalToGuest -VM $VMName -Source "X:\Production\ECI.Modules.Prod\ECI.EMI.Configure.OS.Prod\InGuest-InvokeTest.ps1" -Destination "C:\Program Files\WindowsPowerShell\Modules\ECI.Modules.PROD\ECI.EMI.Configure.OS.PROD\"
        Write-ECI.EMI.OS.ParametersParametertoGuest -VMName $VMName -HostName $HostName
        exit
    }
    PROCESS
    {
        #[scriptblock]$ScriptText = {$global:Step="#Step#" 
        #. "C:\Program Files\WindowsPowerShell\Modules\ECI.Modules.PROD\ECI.EMI.Configure.OS.PROD\InGuest-InvokeTest.ps1"}
        
        #$ScriptText = {dir c:\}
        
        Invoke-ECI.EMI.Automation.InvokeScriptTextInGuest -ScriptText (Process-ECI.EMI.Automation.ScriptText -Step $Step -Env $Env -Environment $Environment)

    }

    END 
    { 
    
    }

}









#Start-ECI.EMI.Automation.Sleep -t $WaitTime_StartSleep
#Wait-ECI.EMI.Automation.VM.VMTools -VMName $VMName -t $WaitTime_VMTools 
#Test-ECI.EMI.VM.GuestState -VMName $VMName
#Test-ECI.EMI.Automation.VM.InvokeVMScript -VMName $VMName

    #in Invoke function
    #Restart-ECI.EMI.VM.VMTools
    #Retry-InvokeScriptext
