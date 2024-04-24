function New-Scheduled {
	[CmdletBinding()]
	param (
		[Parameter()]
		[String]
		$TaskName = "AutopilotBackgroundLogging "
		,

		[Parameter()]
		[String]
		$TaskDescription,

		[Parameter()]
		[String]
		[ValidateSet("Once", "Daily", "Weekly", "Monthly", "OnLogon", "OnIdle", "OnStart", "OnBoot", "OnSessionChange", "OnEvent")]
		$Schedule,

		[Parameter()]
		[String]
		$ScheduledTime,
		[Parameter()]
		[String]
		$ScriptPath = "C:\Scripts\AutopilotBackgroundLogging.ps1"
		,
		[Parameter()]
		[String]
		$ScriptArguments
		,
		[Parameter()]
		[String]
		$User = "NT AUTHORITY\SYSTEM"
	)
	$actions = (New-ScheduledTaskAction -Execute 'foo.ps1'), (New-ScheduledTaskAction -Execute 'bar.ps1')
	$trigger = New-ScheduledTaskTrigger -Daily -At '9:15 AM'
	$principal = New-ScheduledTaskPrincipal -UserId 'DOMAIN\user' -RunLevel Highest
	$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun
	$task = New-ScheduledTask -Action $actions -Principal $principal -Trigger $trigger -Settings $settings

	Register-ScheduledTask 'baz' -InputObject $task
}


$Trigger = New-ScheduledTaskTrigger -At 10:00am -Daily
$User = "NT AUTHORITY\SYSTEM"
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "C:\PS\StartupScript1.ps1"
Register-ScheduledTask -TaskName "StartupScript1" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest –Force


###############

#Variables
$TaskName = "Audit Large Lists"
$username = "Crescent\SP13_FarmAdmin"
$password = "Password Here"
 
#create a scheduled task with powershell
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "E:\Scripts\AuditLists.ps1"
$Trigger = New-ScheduledTaskTrigger -Daily -At 1am
$ScheduledTask = New-ScheduledTask -Action $action -Trigger $trigger 
 
Register-ScheduledTask -TaskName $TaskName -InputObject $ScheduledTask -User $username -Password $password 


#Read more: https://www.sharepointdiary.com/2013/03/create-scheduled-task-for-powershell-script.html#ixzz7xphqTZlw