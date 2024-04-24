$computername = "."
Get-ScheduledTask -TaskName * | Get-ScheduledTaskInfo