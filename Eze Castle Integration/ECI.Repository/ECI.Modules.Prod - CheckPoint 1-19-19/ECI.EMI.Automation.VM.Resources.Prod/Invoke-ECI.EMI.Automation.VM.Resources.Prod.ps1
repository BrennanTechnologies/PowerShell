cls

$Env = "Prod"
$Environement = "Production" 

$InstanceLocation = "LD5"
#$InstanceLocation = "QTS"

$VMName = "Test-LD5"
$RequestID = "12345"

#Good
$ServerRole = "2016SQL"#,"citrix","dc","file","omsApp"
$gpid = "pjtpa001"#"colch001"#"north021"#"tiede001", "apexf401" ,"etest040"#"ruane001" "wexfo001"


#Bad - No Res Pool
$ServerRole = "2016SQL"
$gpid = "ELEVA401"


#Bad - Get-View		View with Id  '-' was not found on the server(s).
#$ServerRole = "2016SQL"
#$gpid = "ocean401"

#bad  - "No Client Exists with $gpid as a GPID"
#$ServerRole = "sql"
#$gpid = "BALFO401"

#bad - No Client Exists with colch001 as a GPID
#$ServerRole = "2016SQL"
#$gpid = "colch001"

$ServerRole = "2016SQL"
$gpid = "ETEST040"

#####################
### Get vCenter Resources
#####################
    
$vCenterResources = @{
    RequestID        = $RequestID
    InstanceLocation = $InstanceLocation
    ServerRole       = $ServerRole
    GPID             = $GPID
    VMName           = $VMName
}
    
### ECI.ConfigServer.Invoke-ConfigureRoles.ps1
###------------------------------------------------
$File = "ECI.EMI.Automation.VM.Resources"
$FilePath =  "\\eciscripts.file.core.windows.net\clientimplementation\" + $Environement + "\ECI.Modules." + $Env + "\" + $File + "." + $Env + "\" + $File  + "." + $Env + ".ps1"

. ($FilePath) @vCenterResources -Invoke

