function SetupScheduledTasks {
Christopher Brennan (HCL Technologies Corporate Ser) <v-cbrennan@microsoft.com>
​
You
​
function SetupScheduledTasks {

    Write-Host "Setting up scheduled tasks"

    if (!(Test-Path -PathType Container $CustomizationScriptsDir)) {

        New-Item -Path $CustomizationScriptsDir -ItemType Directory

    }

 

    if (!(Test-Path -PathType Leaf "$($CustomizationScriptsDir)\$($LockFile)")) {

        New-Item -Path "$($CustomizationScriptsDir)\$($LockFile)" -ItemType File

    }

 

    if (!(Test-Path -PathType Leaf "$($CustomizationScriptsDir)\$($RunAsUserScript)")) {

        Copy-Item "./$($RunAsUserScript)" -Destination $CustomizationScriptsDir

    }

 

    if (!(Test-Path -PathType Leaf "$($CustomizationScriptsDir)\$($CleanupScript)")) {

        Copy-Item "./$($CleanupScript)" -Destination $CustomizationScriptsDir

    }

 

    ### CB: Copy Config File

    #if (!(Test-Path -PathType Leaf "$($CustomizationScriptsDir)\$($ConfigurationFile)")) {

    #Copy-Item "./$($ConfigurationFile)" -Destination $CustomizationScriptsDir

    #}

 

    # Reference: https://learn.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-objects

    $ShedService = New-Object -comobject "Schedule.Service"

    $ShedService.Connect()

 

    # Schedule the cleanup script to run every minute as SYSTEM

    $Task = $ShedService.NewTask(0)

    $Task.RegistrationInfo.Description = "Dev Box Customizations Cleanup"

    $Task.Settings.Enabled = $true

    $Task.Settings.AllowDemandStart = $false

 

    $Trigger = $Task.Triggers.Create(9)

    $Trigger.Enabled = $true

    $Trigger.Repetition.Interval = "PT1M"

 

    $Action = $Task.Actions.Create(0)

    $Action.Path = "PowerShell.exe"

    $Action.Arguments = "Set-ExecutionPolicy Bypass -Scope Process -Force; $($CustomizationScriptsDir)\$($CleanupScript)"

 

    $TaskFolder = $ShedService.GetFolder("\")

    $TaskFolder.RegisterTaskDefinition("$($CleanupTask)", $Task , 6, "NT AUTHORITY\SYSTEM", $null, 5)

 

    # Schedule the script to be run in the user context on login

    $Task = $ShedService.NewTask(0)

    $Task.RegistrationInfo.Description = "Dev Box Customizations"

    $Task.Settings.Enabled = $true

    $Task.Settings.AllowDemandStart = $false

    $Task.Principal.RunLevel = 1

 

    $Trigger = $Task.Triggers.Create(9)

    $Trigger.Enabled = $true

 

    $Action = $Task.Actions.Create(0)

    $Action.Path = "C:\Program Files\PowerShell\7\pwsh.exe"

    $Action.Arguments = "-MTA -Command $($CustomizationScriptsDir)\$($RunAsUserScript)"

 

    $TaskFolder = $ShedService.GetFolder("\")

    $TaskFolder.RegisterTaskDefinition("$($RunAsUserTask)", $Task , 6, "Users", $null, 4)

    Write-Host "Done setting up scheduled tasks"

}

 

