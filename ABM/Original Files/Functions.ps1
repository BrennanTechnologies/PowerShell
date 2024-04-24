$ErrorDescription = @("Operation completed without errors.","Operation failed to execute because of an error","Cancel pending.","Operation is terminated by the user.","Incorrect parameters.","Insufficient privileges.","Service is not available.","Invalid command.","Invalid parameter.","Invalid user name, password or identity domain.","Expired password.","Service is not available.")

#get current month
function SetCurrentMonth {
    $Date = (Get-Date -Format MMM)
    $Date
}

function SetCurrentMonthYR {
    $Date = (Get-Date -Format yy)
    IF(($SetCurrentMonth -eq "Nov") -or ($SetCurrentMonth -eq "Dec"))
        {
            $Date = [int]$Date + 1
        }
        "FY$Date"
}

#get prior month
function SetPriorMonth {
    $Date = (Get-Date (Get-Date).AddMonths(-1) -Format MMM)
    $Date
}

function SetPriorMonthYR {
    $Date = (Get-Date -Format yy)
    IF(($SetPriorMonth -eq "Nov") -or ($SetPriorMonth -eq "Dec"))
       {
        $Date = [int]$Date + 1
        }
        "FY$Date"
}

Function LogHeader([string]$strValue){
  Add-content $Logfile -value ""    
  $Line1 = "#" * ($strValue.length + 4)
  $Line2 = "# $strValue #"
  Add-content $Logfile -value $Line1
  Add-content $Logfile -value $Line2
  Add-content $Logfile -value $Line1
}

Function LogLine([string]$strValue,[int64]$iDivider = 0,[int64]$iIndent = 5){
  $iIndent = 5
  $NowStamp = get-date -uformat "%Y %m %d @ %H:%M:%S"
  Add-content $Logfile -value ("${NowStamp} | ".PadRight(${iIndent} + "${NowStamp} | ".length) + "${strValue}")
  Write-Host ("${NowStamp} | ".PadRight(${iIndent} + "${NowStamp} | ".length) + "${strValue}")
  for ($i=1; $i -le $iDivider; $i++)
  {
    Add-content $Logfile -value ""    
  }
}

function LogResult([string]$ProcessName , [int64]$ReturnValue){
  $NowStamp = get-date -uformat "%Y %m %d @ %H:%M:%S"
  LogLine "COMMAND: $CmdLine"
  if($ReturnValue -eq 0)
    {
    #Add-content $Logfile -value "${NowStamp} | ${ProcessName} finished successfully"
    Logline "${ProcessName} finished successfully" 0 0
    }
  else
    {
    #Add-content $Logfile -value "${NowStamp} | ${ProcessName} failed with a return code of $ReturnValue"
    LogLine "${ProcessName} failed with a return code of $ReturnValue" 0 0
    $ErrorPrint = $ErrorDescription[$ReturnValue]
    #Add-content $Logfile -value "${NowStamp} | ${ErrorPrint}"
    Logline "${ErrorPrint}" 0 0
    }
}

function SetVariable ([string]$VarName, [string]$VarValue,[string]$VarScope){
  # use ALL or plan type name for the scope

  LogHeader "Setting Variable $varName to $VarValue for $VarScope"

  ###LogLine "Setting Variable" 0 0
  $CmdLine = "setsubstvars $VarScope $VarName=$VarValue"
  LogLine $CmdLine
  $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
  LogResult "Set Variable" $ReturnCode.ExitCode
  $ErrorOccured = $ErrorOccured + $ReturnCode.ExitCode
  ###LogLine "Variable Set"
}

function EPMA_UploadFile{
  param([string]$strLocalDir,[string]$strInboxDir,[string]$strFileName,[string]$strRuleName,[string]$StartPeriod,[string]$EndPeriod,[string]$ImportMode,[string]$ExportMode)

  LogLine "Uploading $strLocalDir\$strFileName"
  #Check for file existance   
  if(Test-Path "$strLocalDir\$strFileName"){
    if($ImportMode -ne "NO EXPORT")
    { #LastWriteTime DateCreated
      if(([DateTime](Get-Date) - [DateTime](Get-Item "$strLocalDir\$strFileName").LastWriteTime).TotalDays -lt 1)
      {
        write-host ([DateTime](Get-Date) - [DateTime](Get-Item "$strLocalDir\$strFileName").LastWriteTime).TotalDays
        $CmdLine = "deletefile `"$strInboxDir/$strFileName`""
        $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
        LogResult "Deleted $strInboxDir/$strFileName" $ReturnCode.ExitCode

        CheckFileSize "$strLocalDir\$strFileName"

        $CmdLine = "uploadfile `"$strLocalDir\$strFileName`" `"$strInboxDir`""
        $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
        LogResult "Uploaded `"$strLocalDir\$strFile`"" $ReturnCode.ExitCode
        if($ReturnCode.ExitCode -ne 0){return 1}
      }
      else
      {
        $DateDisplay = (Get-Item "$strLocalDir\$strFileName").LastWriteTime.ToString("MM/dd/yyyy")
        LogLine "$strLocalDir\$strFile was skipped because it has not changed since $DateDisplay"
        return 0
      }
    }
    
    LogLine "Run Integration $strRuleName started"
    LogLine "  Period     :  $StartPeriod"
    LogLine "  Import Mode:  $ImportMode"
    LogLine "  Export Mode:  $ExportMode"
       
    $CmdLine = "runIntegration `"$strRuleName`" importMode=`"$ImportMode`" exportMode=`"$ExportMode`" periodName={`"$StartPeriod`"} inputFileName=`"$strInboxDir/$($strFileName)`""
    $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
    LogLine "Run Data Rule $strRuleName finished"
    LogResult "Processing FDMEE Load Rule $strRuleName with $strFileName" $ReturnCode.ExitCode
    if($ReturnCode.ExitCode -ne 0){return 2}
  }
  else{
    LogLine "ERROR: $strLocalDir\$strFileName does not exist"
  }

  LogLine "Finished Uploading $strFileName on EPM" 1
}

function EPMA_UploadAndImport{
  param([string]$strLocalDir,[string]$strInboxDir,[string]$strImportProfile,[string]$strFileName)

  LogLine "Uploading $strLocalDir\$strFileName"
  #Check for file existance   
  if(Test-Path "$strLocalDir\$strFileName"){
    $CmdLine = "deletefile `"$strFileName`""
    $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
    LogResult "Delete $strInboxDir/$strFileName" $ReturnCode.ExitCode
  
    CheckFileSize "$strLocalDir\$strFileName"

    $CmdLine = "uploadfile `"$strLocalDir\$strFileName`""
    $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
    LogResult "Uploading $strLocalDir\$strFile" $ReturnCode.ExitCode
    if($ReturnCode.ExitCode -ne 0){return 1}
  
    LogLine "Importing $strLocalDir\$strFile started"
    $CmdLine = "importdata $strImportProfile $strFileName"
    $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
    LogLine "Importing $strLocalDir\$strFile finished"

    LogResult "Importing $strFileName" $ReturnCode.ExitCode
    if($ReturnCode.ExitCode -ne 0){return 2}

  }
  else{
    LogLine "ERROR: $strLocalDir\$strFileName does not exist"
  }

  LogLine "Finished Uploading $strFileName on EPM" 1
}


function EPMA_RunCalc{
  param([string]$strBusRule,[string[]]$strVariables)
  LogLine "Running Business Rule $strBusRule"
  $CmdLine = "runbusinessrule `"$strBusRule`""
  #Loop through variables
  if($strVariables.count -gt 0)
  {
    Foreach($v in $strVariables)
    {
      LogLine "  VAR: $v"
      $CmdLine = "$CmdLine `"$v`""  
    }
  }
  else
  {
    LogLine "  No Variables Present"
  }

  $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
  LogResult "Executing Business Rule" $ReturnCode.ExitCode
  LogLine "Finished Business Rule $strBusRule" 1
  Return $ReturnCode.ExitCode 
}

function EPMA_DataPush{
  param([string]$strMap,[boolean]$strClear)
  LogLine "Running Data Push $strMap with clear set to $strClear"
  $CmdLine = "runplantypemap `"$strMap`""
  if($strClear){
    $CmdLine = "$CmdLine clearData=true" 
  }
  else{
    $CmdLine = "$CmdLine clearData=false" 
  }
  $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
  LogResult "Running Data Push" $ReturnCode.ExitCode
  LogLine " Data Push Finished" 1
  
}


function EPMA_DatabaseRefresh{
  param([string]$strRefreshJob)
  LogLine "Running Database Refresh"
  $CmdLine = "refreshCube `"$strRefreshJob`""
  $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
  LogResult "Running Database Refresh" $ReturnCode.ExitCode
  #LogLine " Database Refresh Finished" 1 
}

function EPMA_ClearCube{
  param([string]$strClearJob)
  LogLine "Starting Clear Cube"
  $CmdLine = "clearCube `"$strClearJob`""
  $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
  LogResult "Clear Cube" $ReturnCode.ExitCode
  #LogLine " Clear Cube complete" 1 
}


function EPMA_ExportMetadata{
  param([string]$strExportName,[string]$strLocalDir,[string]$strFileName)

  LogLine "Exporting Metadata for $strLocalDir to $strLocalDir\$strFileName"
  $CmdLine = "exportmetadata $strExportName $($strFileName)"
  $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
  LogResult "Exporting file to $strLocalDir" $ReturnCode.ExitCode

  LogLine "Downloading file"
  $CmdLine = "downloadfile `"${strFileName}`""
  $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
  LogResult "Downloading file to $strLocalDir" $ReturnCode.ExitCode

  LogLine "Moving/Renaming file from `"$Script_Path\${strFileName}`" to `"$strLocalDir`""
  Move-Item "$Script_Path\${strFileName}" "$strLocalDir"
  LogResult "Export Finished" $ReturnCode.ExitCode

}

function EPMA_ExportData{
  param([string]$JobName,[string]$strLocalDir,[string]$strFileName)

  LogLine "Exporting Data for $JobName to $strLocalDir\$strFileName"
  $CmdLine = "exportdata $JobName $($strFileName)"
  $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
  LogResult "Exporting file to $strFileName" $ReturnCode.ExitCode

  LogLine "Downloading file"
  $CmdLine = "downloadfile `"${strFileName}`""
  $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
  LogResult "Downloading file to $strLocalDir" $ReturnCode.ExitCode

  LogLine "Moving/Renaming file from `"$Script_Path\${strFileName}`" to `"$strLocalDir`""
  Move-Item "$Script_Path\${strFileName}" "$strLocalDir"
  LogResult "Export Finished" $ReturnCode.ExitCode

}

function EPMA_ImportMetadata{
  param([string]$strLocalDir,[string]$strFileName,[string]$strImportName)

  LogLine "Uploading $strLocalDir\$strFileName"
  #Check for file existance   
  if(Test-Path "$strLocalDir\$strFileName"){
    $CmdLine = "deletefile `"$strFileName`""
    $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
    LogResult "Delete $strFileName" $ReturnCode.ExitCode
  
    CheckFileSize "$strLocalDir\$strFileName"

    $CmdLine = "uploadfile `"${strLocalDir}\${strFileName}`"" #`"$strInboxDir`"
    $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
    LogResult "Uploading $strLocalDir\$strFileName" $ReturnCode.ExitCode
    if($ReturnCode.ExitCode -ne 0){return 1}
  
    LogLine "Importing $strLocalDir\$strFileName started"
    $CmdLine = "importmetadata `"$strImportName`"" # `"$strFileName`"
    $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
    LogLine "Loading $strLocalDir\$strFileName finished"

    LogResult "Importing metadata $strFileName" $ReturnCode.ExitCode
  }
  else{
    LogLine "ERROR: $strLocalDir\$strFileName does not exist"
  }

  LogLine "Finished Uploading $strFileName on EPM" 1
}

function Send_Email_Warning
  {
    LogLine "***************************************************************"
    LogLine "The script encounted an error, but the process continued"
    LogLine "An email was sent to the administrative group"
    LogLine "***************************************************************"

    Send-MailMessage -To $EmailRecipients -From $EmailSender `
    -Subject "An error occured in $SysEnvironment" `
    -Body "The process encounted an error, but continued.  This is likely due to rejected data during data loads.  Check the Data Management and Planning Proccesses logs for more information.  A partial log is attached" `
    -SmtpServer $EmailServer -port 25 -Attachments "$Script_Log_Path\${Process_Name}_Readable.log"
    # recipients = @("Marcel <marcel@turie.eu>", "Marcelt <marcel@nbs.sk>")
    # -Attachments "data.csv" 
  }

function Send_Email_Error
  {
    LogLine "****************************************************"
    LogLine "The script was terminated and an email was sent"
    LogLine "An email was sent to the administrative group"
    LogLine "****************************************************"

    Send-MailMessage -To $EmailRecipients -From $EmailSender -Subject "An error occured in $SysEnvironment" -Body "The process was terminated.  The log is attached" -SmtpServer $EmailServer -port 25 -Attachments "$Script_Log_Path\${Process_Name}_Readable.log"
    # recipients = @("Marcel <marcel@turie.eu>", "Marcelt <marcel@nbs.sk>")
    # -Attachments "data.csv" 
  }

function Send_Email{
  param([string]$Message)

    LogLine "****************************************************"
    LogLine "Log was sent"
    LogLine "An email was sent to the administrative group"
    LogLine "****************************************************"

    Send-MailMessage -To $EmailRecipients -From $EmailSender -Subject "$Process_Name - $SysEnvironment" -Body "${Message}. Attached is the log." -SmtpServer $EmailServer -port 25 -Attachments "$Script_Log_Path\${Process_Name}_Readable.log"
    # recipients = @("Marcel <marcel@turie.eu>", "Marcelt <marcel@nbs.sk>")
    # -Attachments "data.csv" 
  }


function Send_Email_Users{
  param([string]$Message)

    LogLine "****************************************************"
    LogLine "Log was sent"
    LogLine "An email was sent to the users group"
    LogLine "****************************************************"

    Send-MailMessage -To $EmailRecipientsUsers -From $EmailSender -Subject "Hyperion Data Load: $Process_Name - $SysEnvironment" -Body "${Message}" -SmtpServer $EmailServer -port 25
    # recipients = @("Marcel <marcel@turie.eu>", "Marcelt <marcel@nbs.sk>")
    # -Attachments "data.csv" 
  }


############################################################################################################################
### WORK IN PROGRESS BELOW HERE
############################################################################################################################

function GetCurWeekYear {
  #Get Yesterday's week's year
  $Date = Get-Date -format yy
  "FY$Date"
}


  IF($GetCurWeek -eq 1)
  {
    $Date = $Date - 1
  }
  "FY$Date"




function GetCurWeek {
	param(
		$Date = (Get-Date)
	)
	
	# get current culture object
	$Culture = [System.Globalization.CultureInfo]::CurrentCulture
	
	# retrieve calendar week
	"Week_" + $Culture.Calendar.GetWeekOfYear($Date, "FirstDay", "Sunday")
}
function GetPriorWeek {
	param(
		$Date = (Get-Date)
	)
	
	# get current culture object
	$Culture = [System.Globalization.CultureInfo]::CurrentCulture
	
	# retrieve calendar week
	if ($Culture.Calendar.GetWeekOfYear($Date.AddDays(0), "FirstDay", "Sunday") -eq 1)
    {
      "Week_53"
    }
    else
    {
    "Week_" + ($Culture.Calendar.GetWeekOfYear($Date, "FirstDay", "Sunday") - 1)
    }
}

function GetPriorWeek2 {
	param(
		$Date = (Get-Date)
	)
	
	# get current culture object
	$Culture = [System.Globalization.CultureInfo]::CurrentCulture
	
	# retrieve calendar week
	if ($Culture.Calendar.GetWeekOfYear($Date.AddDays(0), "FirstDay", "Sunday") -eq 1)
    {
      "Week_53"
    }
    else
    {
    "Week_" + ($Culture.Calendar.GetWeekOfYear($Date, "FirstDay", "Sunday") - 2)
    }


}

function GetPriorWeek3 {
	param(
		$Date = (Get-Date)
	)
	
	# get current culture object
	$Culture = [System.Globalization.CultureInfo]::CurrentCulture
	
	# retrieve calendar week
	if ($Culture.Calendar.GetWeekOfYear($Date.AddDays(0), "FirstDay", "Sunday") -eq 1)
    {
      "Week_53"
    }
    else
    {
    "Week_" + ($Culture.Calendar.GetWeekOfYear($Date, "FirstDay", "Sunday") - 3)
    }


}

function GetCurWeekYear {
  #Get Yesterday's week's year
  $Date = Get-Date -format yy
  "FY$Date"
}
function GetPriorWeekYear {
  #Get Yesterday's prior week's year
  $Date = Get-Date -format yy 
  IF($GetCurWeek -eq 1)
  {
    $Date = $Date - 1
  }
  "FY$Date"
}
function GetPriorWeek2Year {
  #Get Yesterday's prior week's year
  $Date = Get-Date -format yy 
  IF($GetCurWeek -eq 1)
  {
    $Date = $Date - 2
  }
  "FY$Date"
}
function GetPriorWeek3Year {
  #Get Yesterday's prior week's year
  $Date = Get-Date -format yy 
  IF($GetCurWeek -eq 1)
  {
    $Date = $Date - 3
  }
  "FY$Date"
}


function GetNextMonthYr {
  #Get next month's year
  $Date = Get-Date (Get-Date).AddMonths(1) -format yy
  "FY$Date"
}
function GetNextTwoMonthsOutYr {
  #Get next two month's year
  $Date = Get-Date (Get-Date).AddMonths(2) -format yy
  "FY$Date"
}
function GetSchedMthYr {
  #Get current month's year to drive scheduled hours push
  $Date = Get-Date (Get-Date).AddMonths(0) -format yy
  "FY$Date"
}
function GetSchedMthYr2 {
  #Get next three month's year to drive scheduled hours push
  $Date = Get-Date (Get-Date).AddMonths(3) -format yy
  "FY$Date"
}
function GetSchedDay {

    $Weekday = (Get-Date).DayofWeek
switch ($Weekday) 
    { 
        "Sunday" {"Day_1";break}
        "Monday" {"Day_2";break}
        "Tuesday" {"Day_3";break}
        "Wednesday" {"Day_4";break}
        "Thursday" {"Day_5";break}
        "Friday" {"Day_6";break}
        "Saturday" {"Day_7";break}
    }
}
function GetSchedWeek {
	param(
		$Date = (Get-Date),
$MonthCount = 0
	)
	
# retrieve calendar week
	"Week_" + $Culture.Calendar.GetWeekOfYear(($Date).AddMonths($MonthCount), "FirstDay", "Sunday")
}


function GetNextMonth {
  #Get next month
  $Date = (Get-Date (Get-Date).AddMonths(1) -format m).subString(0,3)
  #$Date
}
function GetNextTwoMonthsOut {
  #Get month of 2 months out
  $Date = (Get-Date (Get-Date).AddMonths(2) -format m).subString(0,3)
  #$Date
}
function GetSchedMth1 {
  #Get current month to drive scheduled hours push
  $Date = (Get-Date (Get-Date).AddMonths(0) -format MMM)
  "$Date"
}
function GetSchedMth2 {
  #Get next month to drive scheduled hours push
  $Date = (Get-Date (Get-Date).AddMonths(1) -format MMM)
  "$Date"
}
function GetSchedMth3 {
  #Get two months out to drive scheduled hours push
  $Date = (Get-Date (Get-Date).AddMonths(2) -format MMM)
  "$Date"
}
function GetSchedMth4 {
  #Get three months out to drive scheduled hours push
  $Date = (Get-Date (Get-Date).AddMonths(3) -format MMM)
  "$Date"
}



# File / Folder Management Functions
function DeleteFile([string]$strFileName){
  If (Test-Path $strFileName)
  {
	Remove-Item $strFileName
    Write-Host "$strFileName was removed"
  }
}
function CheckFileExistance{
  param($strPath, [string[]]$strFiles)
  LogLine "Verifying all files exist"
  Foreach($s in $strFiles)
  {
    if(!(Test-Path -Path $strPath\$s )){
      Write-Host "$s is not available"
      LogLine "$s is not available"
      $ReturnValue = 1}    
      else{LogLine "$s exists"}
  }
  Return $ReturnValue
}
function ClearFolder{
  param([string[]]$strFolders,[bool]$LogResults = $false)
  Foreach($s in $strFolders)
  {
    Get-ChildItem -Path $s -Include ${ProcessName}* -Exclude -File -Recurse | foreach { $_.Delete()} 
    #remove-item "${s}\*" | Where { ! $_.PSIsContainer }
    #if($LogResults)
    #{
    #  LogLine "All files in $s were removed"
    #}
  }
}
function RemoveOldFiles{
  param([string[]]$strFolders,[string]$Wildcard = "*",[int]$KeepDays = 15,[bool]$LogResults = $false)
  Foreach($s in $strFolders)
  {
    $FileCount = 0
    $now = Get-Date
    Get-ChildItem $s -include $Wildcard |
    Where-Object {-not $_.PSIsContainer -and $now.Subtract($_.CreationTime).Days -gt $KeepDays -and $_.CreationTime.day -ne 1 } | Remove-Item | LogLine $_.Name + " was deleted" 
    if($LogResults)
    {
      LogLine "All files in $s were removed created prior to $(Get-Date (Get-Date).AddDays(-$KeepDays) -UFormat %D)" 
    }
  }
}




  

function CheckFileSize([string]$FileName){
  $NewFileSize = 0
  $fileSize = (Get-ItemProperty $FileName).length
  write-host $fileSize 
  While ($filesize -ne $NewFileSize) {
    $fileSize = (Get-ItemProperty $FileName).length

    Start-Sleep -s 5
    $NewFileSize = (Get-ItemProperty $FileName).length

    $FormattedSize = "{0:N0}" -f $NewFileSize
    if($fileSize -ne $NewFileSize){
      LogLine "The process paused as $FileName is currently growing in size, currently at $FormattedSize Bytes"
    }
  } 
}

#Folders
Function CheckDir([string]$TARGETDIR){
if(!(Test-Path -Path $TARGETDIR )){
    New-Item -ItemType directory -Path $TARGETDIR
    LogLine "$TARGETDIR Created"
    #write-host "$TARGETDIR Created"
  }
}