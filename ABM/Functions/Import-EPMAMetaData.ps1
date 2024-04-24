function Import-EPMAMetadata{
	param(
	[string]
	$LocalDir
	,
	[string]
	$FileName
	,
	[string]
	$JobName
	)
	if(Test-Path "$LocalDir\$FileName"){
		### Delete Files
		### ---------------------------
		Write-Log  "Uploading $LocalDir\$FileName"
		$CmdLine = "deletefile `"$FileName`""
		$ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -Passthru -WindowStyle $ShowDosWindow
		Write-Log "Delete $FileName $($ReturnCode.ExitCode)"
	
		### Check for file size
		### ---------------------------
		CheckFileSize "$LocalDir\$FileName"

		### Upload Files
		### ---------------------------
		Write-Log "Uploading $LocalDir\$FileName "
		$CmdLine = "uploadfile `"${LocalDir}\${FileName}`"" 
		$ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -Passthru -WindowStyle $ShowDosWindow
		Write-Log "Uploading $LocalDir\$FileName $($ReturnCode.ExitCode)"
		if($ReturnCode.ExitCode -ne 0){
			return 1
		}
		### Import MetaData
		### ---------------------------
		Write-Log "Importing $LocalDir\$FileName "
		$CmdLine = "importmetadata `"$JobName`"" 
		$ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -Passthru -WindowStyle $ShowDosWindow
		Write-Log "Importing metadata $FileName $($ReturnCode.ExitCode)"
	}
	else{
	  Write-Log "ERROR: $LocalDir\$FileName does not exist"
	}
	Write-Log "Finished Uploading $FileName on EPM"
}