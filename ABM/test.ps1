$Process_Name = (Get-Item $PSCommandPath ).Basename -replace "_"," "
$Process_Name
exit
Split-Path (Split-Path $PSCommandPath -Parent) -Parent

Split-Path $PSCommandPath -Parent
exit

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
  $Logfile = "C:\Users\brenn\OneDrive\Documents\__Repo\PowerShell\ABM\logfile.txt"
  LogLine "Test" 10 50


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
    #$ErrorPrint = $ErrorDescription[$ReturnValue]
    #Add-content $Logfile -value "${NowStamp} | ${ErrorPrint}"
    Logline "${ErrorPrint}" 0 0
    }
  }
  LogResult "Processing FDMEE Load Rulewith " '1'