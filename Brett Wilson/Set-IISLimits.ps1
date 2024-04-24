
Function Set-IISLimits {
  <#
  .SYNOPSIS
    Sets some limits for IIS app pools to avoid gobbling of resources. In the current iteration, all app pools are considered. Note that executing this will cause running app pools to recycle, and this may cause excessive resource consumption for a few minutes while the pools restart.

  .PARAMETER CPULimitHeadroom
    Percentage of CPU headroom to leave for other processes. Defaults to 10%, which should be enough to keep a system responsive enough at all times. Increase if you want to leave additional headroom for SQL server for example. The total number of app pools will be divided by 100-headroom to find the total CPU limit for each app pool.

  .PARAMETER CPULimitAction
    Can set to NoAction, KillW3wp, Throttle and ThrottleUnderLoad. Without this, throttling will be disabled by default (NoAction).

  .PARAMETER CPULimitSecs
    Defaults to 5 minutes. After this time is up, limiting will be removed.

  .PARAMETER EnableAffinity
    Set to enable CPU core affinity. Use in concert with -AffinityCoreLimit or -AffinityCoreFree.

  .PARAMETER AffinityCoreLimit
    Use in concert with -EnableAffinity to specify an arbitrary amount of cores to allow IIS to use. Defaults to 4. Mutually-exclusive with -AffinityCoreFree.

  .PARAMETER AffinityCoreFree
    Use in concert with -EnableAffinity to specify cores that IIS will NOT use, based off the current logical core count of the system. Defaults to 4 (cores free). Mutually-exclusive with -AffinityCoreLimit.

  .NOTES
    Author: Brett Wilson
    Date:   February 24, 2021

  #>
  param (
    [int]$CPULimitHeadroom = 10,
    [ValidateSet("NoAction", "KillW3wp", "Throttle", "ThrottleUnderLoad")][string]$CPULimitAction = "NoAction",
    [int]$CPULimitSecs = 5 * 60,
    [switch]$EnableAffinity,
    [int]$AffinityCoreLimit,
    [int]$AffinityCoreFree
  )

  $LogicalCoresPresent = (Get-CimInstance Win32_Processor | Measure-Object -property NumberOfLogicalProcessors -sum).sum

  if ($AffinityCoreLimit -gt $LogicalCoresPresent) {
    throw "-AffinityCoreLimit cannot be greater than the amount of logical cores on the system (currently $LogicalCoresPresent)"
  }
  if ($AffinityCoreLimit -and $AffinityCoreFree) {
    throw "Please use either -AffinityCoreLimit or -AffinityCoreFree, but not both."
  }
  if ($EnableAffinity -and (-not $AffinityCoreLimit -and -not $AffinityCoreFree)) {
    throw "Please specify either -AffinityCoreLimit or -AffinityCoreFree."
  }
  if ($AffinityCoreLimit -gt 32 -and [System.IntPtr]::Size -eq 4) {
    throw "Affinity masks of greater than 32 cores cannot be accomodated on a 32-bit system."
  }
  if ($AffinityCoreFree -ge $LogicalCoresPresent) {
    throw "-AffinityCoreFree must be less than the current amount of logical cores present on the system."
  }

  $THROTTLELIMITMAX = 100000

  $AppPools = Get-IISAppPool
  $LimitPerPool = [math]::Round(($THROTTLELIMITMAX - ($CPULimitHeadroom * 1000)) / ($AppPools | Measure-Object).Count)
  $ResetInterval = "{0:hh}:{0:mm}:{0:ss}" -f (New-Object timespan(0,0,$CPULimitSecs))

  if ($CPULimitAction -ne "NoAction") {
    Write-Host "Setting CPU limit to $($LimitPerPool / 1000)% per pool"
  }

  if ($AffinityCoreFree) {
    $AffinityCoreLimit = $LogicalCoresPresent - $AffinityCoreFree
  }
  if ($EnableAffinity) {
    Write-Host "Limiting IIS App Pools to $AffinityCoreLimit of $LogicalCoresPresent logical cores"
  }

  # smpProcessorAffinityMask is the low-order section of the 64-bit mask and smpProcessorAffinityMask2 is the high-order section
  $AffinityMask = 0..($AffinityCoreLimit-1) | ForEach-Object { 1 }
  $AffinityMask += 0..(64-$AffinityCoreLimit-1) | ForEach-Object { 0 }
  [array]::Reverse($AffinityMask)
  $AffinityHigh = [convert]::ToUInt32(($AffinityMask[0..31] -join ""), 2)
  $AffinityLow = [convert]::ToUInt32(($AffinityMask[32..64] -join ""), 2)

  $AppPools | ForEach-Object { & C:\windows\system32\inetsrv\appcmd.exe set APPPOOL $_.name /cpu.limit:$LimitPerPool /cpu.action:$CPULimitAction /cpu.resetInterval:$ResetInterval /cpu.smpAffinitized:$($EnableAffinity.ToString()) /cpu.smpProcessorAffinityMask:$AffinityLow /cpu.smpProcessorAffinityMask2:$AffinityHigh }

  # IIS 10 affinity fix: https://docs.microsoft.com/en-us/troubleshoot/iis/processor-affinity-not-work
  if ($EnableAffinity) {
    New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\InetInfo\Parameters" -Name "ThreadPoolUseIdealCpu" -Value 0 -PropertyType DWORD -Force | Out-Null
  }
  else {
    New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\InetInfo\Parameters" -Name "ThreadPoolUseIdealCpu" -Value 1 -PropertyType DWORD -Force | Out-Null
  }
}