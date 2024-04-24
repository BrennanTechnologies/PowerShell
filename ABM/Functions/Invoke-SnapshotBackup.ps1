function Invoke-SnapshotBackup{
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