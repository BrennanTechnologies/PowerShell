cls

### Parameters from Portal
###-----------------------------------

$Env = "Prod"

$ServerMgmtOperation = "vCPU"
$ServerMgmtValue     = "4"

$ServerMgmtOperation = "vMemory"
$ServerMgmtValue     = "16"

$ServerMgmtOperation = "vDisk"
$ServerMgmtValue     = "$SwapFileVolume,$SwapFileVolumeSize"

$ServerMgmtOperation = "PowerState"
$ServerMgmtValue     = "PowerOff"

$ServerMgmtOperation = "PowerState"
$ServerMgmtValue     = "PowerOn"



$ServerMgmtValue     = "PowerOff"
#$ServerMgmtValue     = "PowerOn"

#$VMName = "ETEST040_Test-LD5-06wiX" # Bad
$VMName = "ETEST040_Test-LD5-QqhDy" # Good/On
#$VMName = "ETEST040_QA-Test" # Good/Off


$vCenter = "ld5vc.eci.cloud"
$VMUUID = "421e8f66-e26c-1449-5a58-6cf4f2c89160"
$VMMoRef = "VirtualMachine-vm-12375"


$VMUUID = "421e8f66-e26c-1449-5a58-6cf4f2c89160"
$VMMoRef = "VirtualMachine-vm-12375"




$ServerMgmt = @{
    ServerMgmtOperation = $ServerMgmtOperation
    ServerMgmtValue     = $ServerMgmtValue
    VMName              = $VMName
    vCenter             = $vCenter
    VMUUID              = $VMUUID
    VMMoRef             = $VMMoRef
}

. 'c:\scripts\ServerMgmt\Invoke-ServerMgmt.ps1' @ServerMgmt
   




