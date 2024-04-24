cls
$log = "C:\Users\administrator-risk\Documents\Security.evtx"
$UserName = "test171"

#$UserName = "Veeam"

#$Events = 


#Get-WinEvent -Path $log -FilterHashtable @{logname='Security';data=$UserName}


Get-WinEvent -FilterHashtable @{Path=$log;data=$UserName}

#$events