
param(
      [switch]$downloadBackup = $false,
      [switch]$setVariables = $false,
      [switch]$importAttrMetadata = $false,
      [switch]$importMetadata = $false,
      [switch]$BUAttribute = $false,
      [switch]$databaseRefresh = $false, 
      [switch]$clearCubeActuals = $false,
      [switch]$loadDataFinance = $false,
      [switch]$loadDataLabor = $false,
      [switch]$sendUserEmail = $false,       
      [switch]$exportData = $false,
      [string]$ProcessName
      )


#Open Variables
$Scripts_Root_Path = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
#. "$Scripts_Root_Path\Variables.ps1"
. "Support\Variables.ps1"
# Add Functions
#. "$Scripts_Root_Path\Functions.ps1"
. "Support\Functions.ps1"

####################################################################################
### ENSURE PROPER FOLDERS EXIST
####################################################################################
CheckDir $Script_Path
CheckDir $Script_Log_Path
CheckDir $Script_Error_Path
CheckDir $Script_Backup_Path
CheckDir $Script_Archive_Path

###CheckDir $Script_Backup_Path
###CheckDir $Script_BackupEntity_Path
###CheckDir $Script_BackupData_Path

CheckDir $PathOfDataFiles
CheckDir $PathOfMetaDataFiles

####################################################################################
### DEFINE PROCESSS NAME
####################################################################################
$Process_Name = "${ProcessName}_${DateStamp}"#(Get-Item $PSCommandPath ).Basename -replace "_"," "

####################################################################################
### DELETE LOGS, ERRORS, AND SNAPSHOTS
####################################################################################
$ListOfFolders = @($Script_Error_Path,$Script_Log_Path)
ClearFolder $ListOfFolders $True

####################################################################################
### SET LOG NAMES
####################################################################################
#Start-Transcript -path  $Script_Log_Path + "\" + (Get-Item $PSCommandPath ).Basename + "_" + $DateStamp + ".log"
$Logfile = "$Script_Log_Path\${Process_Name}_Readable.log"
Start-Transcript "$Script_Log_Path\${Process_Name}_Powershell.log"

####################################################################################
### WRITE LOG HEADER
####################################################################################
LogHeader "Running for $Process_Name in $SysEnvironment".Replace("_${DateStamp}","")

####################################################################################
### LOG IN TO EPMAUTOMATE
####################################################################################
LogLine "Logging in"
$CmdLine = "login $EPM_UserId $EPM_UserPw $EPM_URL"
$ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
LogResult "Login" $ReturnCode.ExitCode
if( $ReturnResult -eq 1){Send_Email_Error;Exit}


####################################################################################
### Run Snapshot backup
####################################################################################
if($downloadBackup.IsPresent){
  #. "$Script_Path\BackupSnapshot.ps1"
  LogHeader "Running Backup for $EPM_URL"
  $Snapshot_Name = "`"Artifact Snapshot`""

  LogLine "Downloading Snapshot" 0 0
  $CmdLine = "downloadfile $Snapshot_Name"
  $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
  LogResult "Download SnapShot" $ReturnCode.ExitCode
  if($ReturnCode -eq 1){Send_Email_Error;Break}

  #Copy snapshot to backup folder
  $SnapshotRename = "Artifact_Snapshot"
  Rename-Item "$Script_Path\Artifact Snapshot.zip" "$SnapshotRename.zip"
  Move-Item "$Script_Path\$SnapshotRename.zip" "$Script_Backup_Path\${SysEnvironment}_${SnapshotRename}_$DateStamp.zip"
  LogLine "Archived Snapshot" 0 0
}


####################################################################################
### SET VARIABLES
####################################################################################
if($setVariables.IsPresent){
  LogLine "Setting Substitution Variables" 0 0

  SetVariable "varCurrMth" $(SetCurrentMonth) "Finance"
  SetVariable "varPriorMth" $(SetPriorMonth) "Finance"

  SetVariable "varCurrMth_YR" $(SetCurrentMonthYR) "Finance"
  SetVariable "varPriorMth_YR" $(SetPriorMonthYR) "Finance"

  SetVariable "varCurrMth" $(SetCurrentMonth) "Labor"
  SetVariable "varPriorMth" $(SetPriorMonth) "Labor"

  SetVariable "varCurrMth_YR" $(SetCurrentMonthYR) "Labor"
  SetVariable "varPriorMth_YR" $(SetPriorMonthYR) "Labor"
    
  LogLine "Finished Setting Variables" 2
}

####################################################################################
### IMPORT ATTRIBUTE METADATA
####################################################################################
if($importAttrMetadata.IsPresent){  
### METADATA IMPORT - BUSINESS_UNIT
  LogHeader "IMPORT ATTRIBUTE METADATA - BUSINESS_UNIT"

  $FileToLoad = "JDE_MetaData_Attr_JobStart.csv"
  $ImportName = "04_JDE_Metadata_Attr_JobStart"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_ECFlag.csv"
  $ImportName = "05_JDE_Metadata_Attr_ECFlag"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

<#
  LogLine "" 0 0
  $FileToLoad = "JDE_Metadata_Attr_Currency.csv"
  $ImportName = "06_JDE_Metadata_Attr_Currency"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}
#>

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_ParentCode.csv"
  $ImportName = "07_JDE_Metadata_Attr_ParentCode"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_Location.csv"
  $ImportName = "08_JDE_Metadata_Attr_Location"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_WCInsurance.csv"
  $ImportName = "09_JDE_Metadata_Attr_WCInsurance"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_LegacyDiv.csv"
  $ImportName = "10_JDE_Metadata_Attr_LegacyDiv"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_ProjectGrouping.csv"
  $ImportName = "11_JDE_Metadata_Attr_ProjectGrouping"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_AirportCode.csv"
  $ImportName = "12_JDE_Metadata_Attr_AirportCode"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_GeoCenter.csv"
  $ImportName = "13_JDE_Metadata_Attr_GeoCenter"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_RptSegment.csv"
  $ImportName = "14_JDE_Metadata_Attr_RptSegment"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_BUType.csv"
  $ImportName = "15_JDE_Metadata_Attr_BUType"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_BillType.csv"
  $ImportName = "16_JDE_Metadata_Attr_BillingType"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_JobEnd.csv"
  $ImportName = "17_JDE_Metadata_Attr_JobEnd"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_GLInsurance.csv"
  $ImportName = "18_JDE_Metadata_Attr_GLInsurance"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_Service.csv"
  $ImportName = "19_JDE_Metadata_Attr_Service"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_LegalEntity.csv"
  $ImportName = "20_JDE_Metadata_Attr_LegalEntity"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_UnionCode.csv"
  $ImportName = "21_JDE_Metadata_Attr_UnionCode"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_SubSegment.csv"
  $ImportName = "22_JDE_Metadata_Attr_SubSegment"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_MetroStatArea.csv"
  $ImportName = "23_JDE_Metadata_Attr_MetroStatArea"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_Earnout.csv"
  $ImportName = "24_JDE_Metadata_Attr_Earnout"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_NAICS.csv"
  $ImportName = "25_JDE_Metadata_Attr_NAICS"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_VerticalMarket.csv"
  $ImportName = "26_JDE_Metadata_Attr_VerticalMarket"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_PropertyManager.csv"
  $ImportName = "27_JDE_Metadata_Attr_PropertyManager"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "" 0 0
  $FileToLoad = "JDE_MetaData_Attr_UniformMaintFee.csv"
  $ImportName = "28_JDE_Metadata_Attr_UniformMaintFee"
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}
}

####################################################################################
### IMPORT METADATA
####################################################################################
if($importMetadata.IsPresent){  
### METADATA IMPORT - BUSINESS_UNIT
  LogHeader "IMPORT METADATA - BUSINESS_UNIT"
  LogLine "Importing Metadata: BUSINESS_UNIT_HIERARCHY" 0 0
  $FileToLoad = "JDE_MetaData_BusinessUnitHierarchy.csv" ###REPLACE WITH CORRECT FILE TO LOAD
  $ImportName = "01_JDE_Metadata_BusinessUnitHierarchy" ###REPLACE WITH CORRECT IMPORT NAME
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "Importing Metadata: BUSINESS_UNIT_PROJECT" 0 0
  $FileToLoad = "JDE_MetaData_BusinesUnitProject.csv" ###REPLACE WITH CORRECT FILE TO LOAD
  $ImportName = "02_JDE_Metadata_BusinessUnitProject" ###REPLACE WITH CORRECT IMPORT NAME
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "Importing Metadata: BUSINESS_UNIT" 0 0
  $FileToLoad = "JDE_MetaData_BusinessUnit.csv" ###REPLACE WITH CORRECT FILE TO LOAD
  $ImportName = "03_JDE_Metadata_BusinessUnit" ###REPLACE WITH CORRECT IMPORT NAME
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "Importing Metadata: POSITION" 0 0
  $FileToLoad = "JDE_MetaData_Position.csv" ###REPLACE WITH CORRECT FILE TO LOAD
  $ImportName = "L01_JDE_Metadata_Position" ###REPLACE WITH CORRECT IMPORT NAME
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "Importing Metadata: PAY_CODE_ABM" 0 0
  $FileToLoad = "JDE_MetaData_Pay_Code_ABM.csv" ###REPLACE WITH CORRECT FILE TO LOAD
  $ImportName = "L02_JDE_Metadata_Pay_Code_ABM" ###REPLACE WITH CORRECT IMPORT NAME
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "Importing Metadata: PAY_CODE_ABM" 0 0
  $FileToLoad = "JDE_MetaData_Pay_Code_GCA.csv" ###REPLACE WITH CORRECT FILE TO LOAD
  $ImportName = "L03_JDE_Metadata_Pay_Code_GCA" ###REPLACE WITH CORRECT IMPORT NAME
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

}


####################################################################################
### ASSIGN ATTRIB METADATA
####################################################################################
if($BUAttribute.IsPresent){  
### ASSIGN ATTIBUTE - BUSINESS_UNIT
  LogHeader "ATTIBUTE ASSIGN - BUSINESS_UNIT"
  LogLine "Importing Metadata: BUSINESS_UNIT_ATTRIBUTE" 0 0
  $FileToLoad = "JDE_MetaData_BusinessUnitAttrib.csv" ###REPLACE WITH CORRECT FILE TO LOAD
  $ImportName = "05_JDE_MetaData_BusinessUnitAttrib" ###REPLACE WITH CORRECT IMPORT NAME
  $ReturnResult = EPMA_ImportMetadata "${PathOfMetaDataFiles}" "${FileToLoad}" "${ImportName}" 
  LogLine "${FileToLoad} imported successfully" 1
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

}


####################################################################################
### RUN DATABASE REFRESH
####################################################################################
if($databaseRefresh.IsPresent){  
  LogHeader "Run Database Refresh"
  LogLine "Database Refresh" 0 0
  $ReturnResult = EPMA_DatabaseRefresh "Refresh_Cube"
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}
}


####################################################################################
### LOAD DATA - FINANCE
####################################################################################
if($loadDataFinance.IsPresent){
  LogHeader "Run Finance Data Loads"
  ### Verify all the files are available to load Actuals
  $ListOfFiles = @("Finance_Data_ABM.csv")
  $ReturnResult = CheckFileExistance $PathOfDataFiles $ListOfFiles
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}
  
  #Import and Transform
  $StartPeriod = "FY22"
  $ImportMode = "REPLACE"
  $ExportMode = "NO EXPORT"
  $RuleName = "JDE_LOAD_FINANCE_ACT"
  $FileToLoad = "Finance_Data_ABM.csv"

  LogLine "Loading ${PathOfDataFiles}\${FileToLoad}" 0 0
  $ReturnResult = EPMA_UploadFile "${PathOfDataFiles}" "inbox/JDE" "${FileToLoad}" "${RuleName}" $StartPeriod $EndPeriod $ImportMode $ExportMode
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  #Clear Current and Prior Month
  LogLine "Clearing Current Month Actuals" 0 0
  $ReturnResult = EPMA_clearCube "FIN_ClearCurrentMonthActuals"
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "Clearing Prior Month Actuals" 0 0
  $ReturnResult = EPMA_clearCube "FIN_ClearPriorMonthActuals"
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  #Export to Essbase
  $ImportMode = "NO IMPORT"
  $ExportMode = "MERGE"

  LogLine "Exporting ${PathOfDataFiles}\${FileToLoad}" 0 0
  $ReturnResult = EPMA_UploadFile "${PathOfDataFiles}" "inbox/JDE" "${FileToLoad}" "${RuleName}" $StartPeriod $EndPeriod $ImportMode $ExportMode
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}
  if( $ReturnResult -eq 2){Send_Email_Warning}

 ### Verify all the files are available to load Forecast
  $ListOfFiles = @("Finance_Data_ABM_Fcst.csv")
  $ReturnResult = CheckFileExistance $PathOfDataFiles $ListOfFiles
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}
  
  #Import and Transform
  $StartPeriod = "FY22"
  $ImportMode = "REPLACE"
  $ExportMode = "NO EXPORT"
  $RuleName = "JDE_LOAD_FINANCE_FCST"
  $FileToLoad = "Finance_Data_ABM_Fcst.csv"

  LogLine "Loading ${PathOfDataFiles}\${FileToLoad}" 0 0
  $ReturnResult = EPMA_UploadFile "${PathOfDataFiles}" "inbox/JDE" "${FileToLoad}" "${RuleName}" $StartPeriod $EndPeriod $ImportMode $ExportMode
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  #Clear Current and Prior Month
  LogLine "Clearing Current Month Actuals" 0 0
  $ReturnResult = EPMA_clearCube "FIN_ClearCurrentMonthFcst"
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "Clearing Prior Month Actuals" 0 0
  $ReturnResult = EPMA_clearCube "FIN_ClearPriorMonthFcst"
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  #Export to Essbase
  $ImportMode = "NO IMPORT"
  $ExportMode = "MERGE"

  LogLine "Exporting ${PathOfDataFiles}\${FileToLoad}" 0 0
  $ReturnResult = EPMA_UploadFile "${PathOfDataFiles}" "inbox/JDE" "${FileToLoad}" "${RuleName}" $StartPeriod $EndPeriod $ImportMode $ExportMode
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}
  if( $ReturnResult -eq 2){Send_Email_Warning}

}

####################################################################################
### LOAD DATA - LABOR
####################################################################################
if($loadDataLabor.IsPresent){
  LogHeader "Run Labor Data Loads"
  ### Verify all the files are available to load
  $ListOfFiles = @("Time_Data_GCA.csv","Time_Data_ABM.csv")
  $ReturnResult = CheckFileExistance $PathOfDataFiles $ListOfFiles
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}
  
  #Import and Transform
  $StartPeriod = "FY22"
  $ImportMode = "REPLACE"
  $ExportMode = "NO EXPORT"
  $RuleName = "LOC_LABOR_ACT"
  $FileToLoad = "Time_Data_GCA.csv"

  LogLine "Loading ${PathOfDataFiles}\${FileToLoad}" 0 0
  $ReturnResult = EPMA_UploadFile "${PathOfDataFiles}" "inbox/JDE" "${FileToLoad}" "${RuleName}" $StartPeriod $EndPeriod $ImportMode $ExportMode
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  #Clear Current and Prior Month
  LogLine "Clearing Current Month Actuals" 0 0
  $ReturnResult = EPMA_clearCube "LB_ClearCurrentMonthActuals"
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  LogLine "Clearing Prior Month Actuals" 0 0
  $ReturnResult = EPMA_clearCube "LB_ClearPriorMonthActuals"
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  #Export to Essbase
  $ImportMode = "NO IMPORT"
  $ExportMode = "MERGE"

  LogLine "Exporting ${PathOfDataFiles}\${FileToLoad}" 0 0
  $ReturnResult = EPMA_UploadFile "${PathOfDataFiles}" "inbox/JDE" "${FileToLoad}" "${RuleName}" $StartPeriod $EndPeriod $ImportMode $ExportMode
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}
  if( $ReturnResult -eq 2){Send_Email_Warning}

  #Import and Transform
  $StartPeriod = "FY22"
  $ImportMode = "REPLACE"
  $ExportMode = "NO EXPORT"
  $RuleName = "LOC_LABOR_ACT"
  $FileToLoad = "Time_Data_ABM.csv"

  LogLine "Loading ${PathOfDataFiles}\${FileToLoad}" 0 0
  $ReturnResult = EPMA_UploadFile "${PathOfDataFiles}" "inbox/JDE" "${FileToLoad}" "${RuleName}" $StartPeriod $EndPeriod $ImportMode $ExportMode
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}

  #Export to Essbase
  $ImportMode = "NO IMPORT"
  $ExportMode = "MERGE"

  LogLine "Exporting ${PathOfDataFiles}\${FileToLoad}" 0 0
  $ReturnResult = EPMA_UploadFile "${PathOfDataFiles}" "inbox/JDE" "${FileToLoad}" "${RuleName}" $StartPeriod $EndPeriod $ImportMode $ExportMode
  if( $ReturnResult -eq 1){Send_Email_Error;Exit}
  if( $ReturnResult -eq 2){Send_Email_Warning}
}


####################################################################################
### LOG OUT OF EPMAUTOMATE
####################################################################################
LogHeader "Log out of EPM Automate"
$CmdLine = "logout"
$ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru #-WindowStyle Hidden
LogResult "Logout" $ReturnCode.ExitCode


####################################################################################
### SENDING EMAIL TO ADMIN GROUP
####################################################################################
LogHeader "Send completion Email"
$ReturnCode = Send_Email "The process finished at $(Get-Date)."
LogResult "Email" $ReturnCode.ExitCode


####################################################################################
### SENDING EMAIL TO USER GROUP
####################################################################################
if($sendUserEmail.IsPresent){
LogHeader "Send completion Email to User Group"
$ReturnCode = Send_Email_Users "The process finished at $(Get-Date)."
LogResult "Email" $ReturnCode.ExitCode
}


####################################################################################
### STOP TRANSCRIPT
####################################################################################
Stop-Transcript