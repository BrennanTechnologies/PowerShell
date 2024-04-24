param (
	[Parameter()]
	[switch]
	$DownloadBackup
	,
	[Parameter()]
	[switch]
	$SetVariables
	,
	[Parameter()]
	[switch]
	$ImportAttrMetadata
	,
	[Parameter()]
	[switch]
	$ImportMetadata
	,
	[Parameter()]
	[switch]
	$BUAttribute
	,
	[Parameter()]
	[switch]
	$DatabaseRefresh
	, 
	[Parameter()]
	[switch]
	$ClearCubeActuals
	,
	[Parameter()]
	[switch]
	$LoadDataFinance
	,
	[Parameter()]
	[switch]
	$LoadDataLabor
	,
	[Parameter()]
	[switch]
	$SendUserEmail
	,
	[Parameter()]
	[switch]
	$ExportData
	,
	[Parameter()]
	[string]
	$ProcessName
)

&{
	begin{

		$Scripts_Root_Path = Split-Path (Split-Path $PSCommandPath -Parent) -Parent

		### Import Support Files
		$importFolders = @('Functions','Support')
		foreach($folder in $importFolders){
			foreach($file in Get-ChildItem -Path ".\Support" -Recurse -Include *.ps1){
				. $file
			}
		}
	}
	process{
		### Login to EMP Automate
		### --------------------------------
		$params = @{
			EPM_UserId = $EPM_UserId 
			EPM_UserPw = $EPM_UserPw 
			EPM_URL    = $EPM_URL
		}
		Connect-ToEPMAutomate @params
exit
		### Run Snapshot backup
		### --------------------------------
		if($DownloadBackup.IsPresent){
			Invoke-SnapshotBackup
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
			$metaData = Import-CSV -Path 'C:\Users\brenn\OneDrive\Documents\__Repo\PowerShell\ABM\Support\MetaData.csv'
			foreach($row in $metaData){
				$FileName = $row.File
				$JobName  = $row.JobName

				$ReturnResult = Import-EPMAMetadata "${PathOfMetaDataFiles}" "${FileName}" "${JobName}" 
				if( $ReturnResult -eq 1){
					Send_Email_Error
					Exit
				}

			}


		}


		}
	}
	end{}
}

