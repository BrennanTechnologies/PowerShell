<#
https://jdhitsolutions.com/blog/powershell/8128/powershell-puzzles-and-challenges/

https://gist.github.com/jdhitsolutions/e82e86efad8ed1ca1f66612d87c6e409


How many stopped services are on your computer?
list services set to autostart but are NOT running?
List ONLY the property names of the Win32_BIOS WMI class.
List all loaded functions displaying the name, number of parameter sets, and total number of lines in the function.
Create a formatted report of Processes grouped by UserName. Skip processes with no user name.
Using your previous code, display the username, the number of processes, the total workingset size. Set no username to NONE.
Create a report that shows files in %TEMP% by extension. Include Count,total size, % of total directory size.
Find the total % of WS memory a process is using. Show top 10 processes,count,total workingset and PctUsedMemory.
#>

<#
Get-Service | gm

Get-Service | Where-Object {$_.Status -eq "Running" -and $_.StartType -eq "Automatic"}

Get-WmiObject -Class Win32_BIOS -Property Name

Get-Service | Where-Object status -eq 'stopped' | Measure-Object -
#>



$services = Get-Service | Where-Object {$_.Status -eq "Running"}
$results = foreach($service in $services) {
	[PSCustomObject]@{
		Type 	= "Running Service"
		Name 	= $service.name
		Status 	= $service.status
	}
}
$results 




for($i=0;$i -eq 10;$i++){

	Write-Host $i
}

$functions = Get-ChildItem -Path function: | Where-Object { $_.CommandType -eq 'function'}
$results = foreach ($function in $functions) {
    [PSCustomObject]@{
        PSTypeName        = "PSFunctionInfo"
        Name              = $function.name
		Version           = $function.Version
        ParameterSetCount = $function.parametersets.count
        Lines             = ($function.Scriptblock | Measure-Object -Line).lines
        Source            = $function.source
    }
}
$results #| Sort-Object Lines,Name -Descending #| Select-Object -first 5
$results.count

$tempFiles = Get-ChildItem -Path $env:Temp | Where-Object {$_.Extension -eq ".jpg"}
$results = foreach ($tempFile in $tempFiles){
	[PSCustomObject]@{
		PSTypeName        = "tempFiles"
		Name              = $tempFiles.name
		#Count             = ($tempFiles.Scriptblock | Measure-Object -Line).Count
		#Length            = $tempFiles.Length
	}
}
$results | FT


# Create a formatted report of Processes grouped by UserName. Skip processes with no user name.
$processes = Get-Process | Group-Object -Property Company


#region 5. Create a formatted report of Processes grouped by UserName. Skip processes with no user name

#using Get-Process
Get-Process -IncludeUserName | Where-Object { $_.username} |
Sort-Object Username, Name |
Format-Table -GroupBy Username -Property Handles, WS, CPU, ID, ProcessName

###
$processes = Get-Process -IncludeUserName | Where-Object { $_.username} |
Sort-Object Username, Name 
$processes | Format-Table -GroupBy Username -Property Handles, WS, CPU, ID, ProcessName




#using CIM
#this isn't a speedy expression so I'll just use the first 10 processes
$processes = Get-CimInstance -ClassName Win32_Process | Select-object -first 100 |
Add-Member -MemberType Scriptproperty -Name Owner -Value {
    $user = Invoke-CimMethod -InputObject $this -MethodName GetOwner
    if ($user.returnValue -eq 0) {
        "$($user.Domain)\$($user.User)"
    }
} -PassThru -Force -outvariable a | Where-Object Owner |
Sort-Object -Property Owner, Name |
Format-Table -GroupBy Owner -Property ProcessID, Name, HandleCount, WorkingSetSize, VirtualSize

$processes | Format-Table -GroupBy Owner -Property ProcessID, Name, HandleCount, WorkingSetSize, VirtualSize


Invoke-CimMethod 
Invoke-CimMethod -ClassName Win32_Process  -MethodName Create | Select-Object Name

while(($inp = Read-Host -Prompt "Select a command") -ne "Q"){
	switch($inp){
	   L {"File will be deleted"}
	   A {"File will be displayed"}
	   R {"File will be write protected"}
	   Q {"End"}
	   default {"Invalid entry"}
	   }
	}

$arr = (1,2,3,4,5,6,7,8,9,10)

foreach($i in $arr){
	Write-Host $i
}

$arr = @(1,2,3,4,5,6,7,8,9,10)
$arr -is [hashtable]

do {
	Write-Host $arr
} while ($i -lt 5)

while( $arr -ne 10){
	Write-Host $i
}



$users = @{FirstName=”John”; LastName=”Smith”; MiddleInitial=”J”; Age=40}
#$users -is [hashtable]
foreach($user in $users.GetEnumerator( )){
	Write-Host $user.Key `t ": " $user.value
}


