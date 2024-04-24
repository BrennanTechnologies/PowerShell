### Variable File
### ---------------------------------------------------------
$EPM_URL              	= "https://epmdev1-test-eiqg.epm.us-ashburn-1.ocs.oraclecloud.com/HyperionPlanning/"
$EPM_Domain           	= "eiqg"
$EPM_UserId           	= "EPM-MR-Help@abm.com"
$EPM_UserPw           	= "Db9FKHjDy@PDZRk!.AELPGvHw"
$Backup_History_Days  	= 15 # The amount of days to keep archives 
$ShowDosWindow			= "Hidden" # Do you want to show the epm automate window calls {Normal | Hidden | Minimized | Maximized}
$Culture              	= [System.Globalization.CultureInfo]::CurrentCulture

### Email Info
### ---------------------------------------------------------
$EmailRecipients      	= @("jeffrey.wasserman@abm.com","santiago.perez@abm.com")
$EmailRecipientsUsers 	= @("jeffrey.wasserman@abm.com")
$EmailSender          	= "svc_EPMAutomate@abm.com" # $EPM_UserId ###replace with SERVICE ACCT CREDS
$EmailServer          	= "abmsmtp.abm.com"

$DateStamp            	= get-date -format "yyyyMMdd_HH-mm"
$Process_Name         	= (Get-Item $PSCommandPath ).Basename -replace "_"," "

### Path and Locations
### ---------------------------------------------------------
$EPMAutomate_Path 		= "C:\Oracle\EPM Automate\bin"
$PathOfDataFiles      	= "C:\Oracle\ABM\Data"
$PathOfMetaDataFiles  	= "C:\Oracle\ABM\Metadata"
$Script_Path          	= $Scripts_Root_Path + "\Scripts"
$Script_Log_Path      	= $Scripts_Root_Path + "\Logs"
$Script_Error_Path    	= $Scripts_Root_Path + "\Errors"
$Script_Archive_Path  	= $Scripts_Root_Path + "\Archive"
$Script_Backup_Path   	= $Scripts_Root_Path + "\Backup"
###$Script_Backup_Path 	= $Scripts_Root_Path + "\SnapShot"
###$Script_BackupEntity_Path = $Script_Backup_Path + "\Entity"
###$Script_BackupData_Path = $Script_Backup_Path + "\Data"

### Set Environment
### ---------------------------------------------------------
if ($EPM_URL -like '*test*'){
	$SysEnvironment = "TEST"
}else{
	$SysEnvironment = "PRODUCTION"
}
