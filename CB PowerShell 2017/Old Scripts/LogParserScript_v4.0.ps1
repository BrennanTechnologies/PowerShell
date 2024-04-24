#Import CSC for ServerApps.csv
	#$rptQueries = Import-Csv $rptData 
	#$rptQueries
	#Exit
	#$rptQueries | ForEach-Object {

#	member, symptom checker, proxy api, api farm (apiws server), regapi, food and fitness planner


#  affws farm too (like api 2 farm)


		
#=============================================================================
#   Script Name:     LogParserScript.ps1 
#=============================================================================
#   Author:          Chris Brennan (cbrennan@webmd.net)
#   Date Created:    02/15/12
#   Date Modified:   03/23/12
#   Version:         v3.1
#=============================================================================
#   Purpose:     1. Copies IIS Log files
#                2. Runs LogParser.exe scripts against those logs
#                3. Concantenates Logparser output files into a single file.
#                4. Deletes temp and log files
#=============================================================================
#   Last Notes/To Dos:  Listing Files in Logs
#   utlas01l-shr-08:/webmd/apps/webops.webmd.com/htdocs/stats/www.webmd.com
#=============================================================================

#Create Variables
#------------------------------------------------------------------------------
    $rootDrive = "C$"
	#$Hour = (Get-Date).Hour                          #Variable used to get IIS Log TimeStamp
    #$Now = (Get-Date).Hour                           #Variable used to get IIS Log TimeStamp
    $Today = (Get-Date).Date                          #Variable used to get IIS Log TimeStamp
    $PreviousHour = (Get-Date).AddHours(-1).Hour      #Variable used to get IIS Log TimeStamp
    $PreviousHour2 = (Get-Date).AddHours(-2).Hour      #Variable used to get IIS Log TimeStamp
    $dt = Get-Date -format "yyyyMMdd_hhmm"            #TimeStamp for LogParser Output Files
	$TempDir = "c:\LogParserScripts\TempDir"          #Directory to temporarily copy IIS server log files
    $ReportDir = "c:\LogParserScripts\Reports"        #Directory to copy reports
    $LogDir = "c:\LogParserScripts\Logs"              #Directory to copy script log files
    $rptData = "c:\logparserscripts\scripts\ServerApps.csv"
    $LogFile = $LogDir+"\"+$dt+"_LogParserScript.log" #Create the filename for the PS log file
    $script:startTime = get-date                      #Timestampe used for Elapsed Time Fuinction
	$LogparserPath = "C:\Program Files (x86)\Log Parser 2.2\LogParser.exe" #Create Alias for LogParser.exe Start-Process Function
	set-alias logparser $LogparserPath                #Create Alias for LogParser.exe Start-Process Function
	$LPArgs = " -i:W3C"
	$LPArgs += " -o:NAT"
	$LPArgs += " -fileMode:0"
	$LPArgs += " -rtp:-1"
	$LPArgs += " -dQuotes:ON"
	
#Formating Variables for Report
#------------------------------------------------------------------------------
    $crlf   = "`r`n"
    $break  = $crlf * 2
    $string = "*" * 50  
    $Spacer = " " * 14
    $Header = $break + $break + $string + $crlf + $string + $crlf
    $Footer = $crlf + $string + $crlf + $string + $break 
    $Title  = $string+"AGGREGATE IIS LOG REPORTS"+$string
     
#Calculate Elapsed Time
#------------------------------------------------------------------------------
function GetElapsedTime() {
    $runtime = $(get-date) - $script:StartTime
    $retStr = [string]::format("{0} days, {1} hours, {2} minutes, {3}.{4} seconds", `
        $runtime.Days, `
        $runtime.Hours, `
        $runtime.Minutes, `
        $runtime.Seconds, `
        $runtime.Milliseconds)
    $retStr
    }    

# #=============================================================================	
# #Function to append text header to top of report files.
# #=============================================================================	
# function Insert-Content {
    # param ( [String]$Path )
    # process {
        # $( ,$_; Get-Content $LPOutput -ea SilentlyContinue) | Out-File $LPOutput
    # }
# }

#Set Error Checking
#=============================================================================	
    $error.clear()
    $erroractionpreference = "SilentlyContinue"

function MakeLogDir {
	New-Item $TempDir+"\"$AppName -type directory
}
	
#=============================================================================	
# Function to get the Last Hour Log File and Copy it to the TempDir
# NOTE: There are two options, one uses robocopy, the other PS-Copy
#=============================================================================	
function CopyLogs {
        #$items = Get-ChildItem -path $_ | Where-Object {$_.CreationTime.Date -eq $Today -and $_.CreationTime.Hour -eq $PreviousHour2 -and $_.LastWriteTime.Hour -eq $PreviousHour -and $_.name -like "ex*.log"} 
		$items = (Get-ChildItem -path $Logs | Sort-Object name -descending| Where-Object {$_.name -like "ex*.log"})[1] 
		ForEach ($Item in $Items) {
            $LogFile =  $Logs+"\"+$Item
            $Server = $LogFile.SubString(2,15)      
            Write-Output $Server-$Item
            #Copy-Item -path $LogFile -destination $TempDir\$Server-$Item   #Copy Each Log File in $items

            #Copy Log File Using ROBOCOPY
                <#
                $source = $_
                $dest = $TempDir
                $what = $Item
                $whatoptions = @("/COPYALL","/B","/SEC","/MIR")
                $options = @("/R:0","/W:0","/TS","/NC","/NJH","/NJS")
                $cmdArgs = @("$source","$dest",$what,$options)
                .\bin\robocopy @cmdArgs
                Rename-Item  $TempDir\$Item $Server-$Item
                #>
        }  
}

#Start Transcript Log
    Clear-Host
    Start-Transcript -path $logFile


#Get Latest Log Files
#=============================================================================	
Write-Output $CRLF "Getting Lastest LogFiles . . ." $CRLF               #Write Output to Log File    
#$ServerApps = Get-Content c:\LogParserScripts\Scripts\ServerApps.txt    #Get list of server and app directrories from text file
#=============================================================================	

###CURRENT
#Import CSV for ServerApps.csv
$ServerApps = import-csv -path $rptData | sort AppName –Unique
foreach ($AppName in $ServerApps) {
	
	$AppName
	
	}
	Exit
	
foreach ($ServerApp in $ServerApps) {
	$ServerName = $ServerApp.ServerName
	$AppName = $ServerApp.AppName
	$Logs = $ServerApp.LogPath+"\"
	

	
	ForEach ($App in $AppName) {
		New-Item $TempDir+"\"+$AppName -type directory
	}
	
	#CopyLogs
}




#=============================================================================
# Here we setup the Reports Array for our logparser queries
# Format: rptSortOrder, rptName, rptSelectString 
#=============================================================================
$rptArray   =   @()    # Dynamic array definition 
$rptCounter =    $null # Empty key 

$rptCounter ++         # Increase the counter by one 
$rptArray   += ,@(1, 'TOP_20_HITS',          "SELECT TOP 20 cs-uri-stem, COUNT(*) AS Hits INTO $TempDir\$rptCounter.txt FROM $TempDir\*.log GROUP BY cs-uri-stem ORDER BY Hits DESC") # Add report to the array
$rptCounter ++ 
$rptArray   += ,@(2, 'TOP_20_CLIENT_IPs',    "SELECT TOP 20 c-ip, COUNT(*) AS Hits INTO $TempDir\$rptCounter.txt FROM $TempDir\*.log GROUP BY c-ip ORDER BY Hits DESC") #  Add report to the array
$rptCounter ++ 
$rptArray   += ,@(3, 'Top_20_Referrers',     "SELECT TOP 20 cs(Referer), COUNT(*) AS Hits INTO $TempDir\$rptCounter.txt FROM $TempDir\*.log GROUP BY cs(Referer) ORDER BY Hits DESC") #  Add report to the array
$rptCounter ++ 
$rptArray   += ,@(4, 'Top_20_404s',          "SELECT TOP 20 cs-uri-stem, sc-substatus, COUNT(*) AS Hits INTO $TempDir\$rptCounter.txt FROM $TempDir\*.log WHERE sc-status='404' GROUP BY cs-uri-stem, sc-substatus ORDER BY Hits DESC") # Add report to the array
$rptCounter ++ 
$rptArray   += ,@(5, 'Number_of_500_Errors', "SELECT sc-status, COUNT(*) as Hits INTO $TempDir\$rptCounter.txt FROM $TempDir\*.log WHERE sc-status='500' GROUP BY sc-status") #  Add report to the array
$rptCounter ++ 
$rptArray   += ,@(6, 'Top_20_500_Errors',    "SELECT TOP 20 cs-uri-stem, sc-substatus, sc-status, COUNT(*) AS Hits INTO $TempDir\$rptCounter.txt FROM $TempDir\*.log WHERE sc-status='500' GROUP BY cs-uri-stem, sc-substatus, sc-status ORDER BY Hits DESC") #  Add report to the array
$rptCounter ++ 
$rptArray   += ,@(7, 'HTTP_Status_Counts',   "SELECT DISTINCT sc-status AS Status, COUNT(*) AS Hits INTO $TempDir\$rptCounter.txt FROM $TempDir\*.log GROUP BY Status ORDER BY Status ASC") #  Add report to the array

$rptArray = $rptArray | sort-object @{Expression={$_[1]}; Ascending=$true} # Sort array by index 1, the "rptSortOrder" field

#=============================================================================
#Function: Run Start-Process command to execute Lgpaerse.exe queries
#=============================================================================
function ParseLogs {
	$LPOutput = $TempDir+"\"+$rpt[0]+".txt" #Create Unique Name for Logparser output file for InsertContent function
	$rptName = $rpt[1]
	$Arguments = "`""+$rpt[2]+"`""  #Gets the SELECT Quuery string for the logparser query
	$Arguments += $LPArgs
	#$arguments
start-process -NoNewWindow -RedirectStandardOutput $LogFile -Wait -FilePath logparser -ArgumentList @"
$Arguments
"@

	#=============================================================================	
	#Function to append text header to top of report files.
	#=============================================================================	
	function InsertContent {
		param ( [String]$LPOutput )
		process {
			$( ,$_; Get-Content $LPOutput -ea SilentlyContinue) | Out-File $LPOutput
		}
	}
	 #Calls Function to Write a Header into the report
	 #------------------------------------------------------------------------------
	 $Header+$Spacer+$rptName+$Footer | InsertContent $LPOutput 
}

#=============================================================================	
# Loop thru the each array element and run the logparser function
#=============================================================================	
ForEach($rpt in $rptArray)
    {  
    ParseLogs
    }  
  

#=============================================================================	
#Concantinate Reports into one file
#=============================================================================	
Write-Output $CRLF "Concantinating Log Files . . ." $CRLF
$rpts = Get-ChildItem $TempDir -filter "*.txt" # get all txt output files
 
 
#Create New File to concantenate all logparser reports into
#------------------------------------------------------------------------------
Write-Output $CRLF " . . . into merged file:"
$NewFileName = $ReportDir+"\"+$dt+"_Aggregate_IIS_Reports.txt" # Create new file
$LogFiles = Get-ChildItem $TempDir\ -filter "*.log" # Get names of IIS Log Files
New-Item -ItemType file $NewFileName # Create new file
Add-Content $NewFileName $Title$Break 
Add-Content $NewFileName "Server Log Files from ..." 
Add-Content $NewFileName $Today
Add-Content $NewFileName $LogFiles


#Merge all of logparser output reports ($rpts) into $newfilename    
#------------------------------------------------------------------------------
ForEach ($rpt in $rpts) {
		$fullpath = $rpt.fullname
		Write-Output $Spacer $fullpath #Output to log file
		$content = Get-Content $fullpath 
		Add-Content $NewFileName $content | Sort-Object $rpt.fullname
	} 

<#
#Delete IIS Log Files & Temp Files
#------------------------------------------------------------------------------
Write-Output $Break "Deleting Temp Files . . ."
 Get-ChildItem $TempDir\ -include *.log -recurse | ForEach ($_) {
    $_
    Remove-Item $_
 }
 
  Get-ChildItem $TempDir\ -include *.txt -recurse | ForEach ($_) {
  $_
  Remove-Item $_
 }
 #>
 
#Write out the elapsed time to run the script
#------------------------------------------------------------------------------
write-output $Break  #Formating
write-output "Total Elapsed Time: $(GetElapsedTime)"   

#Stop Transcript Log
#------------------------------------------------------------------------------
Write-Output $CRLF   #Formating
Stop-Transcript


