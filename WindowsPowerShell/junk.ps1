$disks = Get-Disk | Sort Number
# 83..89 = S..Y
$letters = 83..89 | ForEach-Object { [char]$_ }
$count = 0
$label = "datadisk"

for($index = 2; $index -lt $disks.Count; $index++) {
    $driveLetter = $letters[$count].ToString()
    if ($disks[$index].partitionstyle -eq 'raw') {
        $disks[$index] | Initialize-Disk -PartitionStyle MBR -PassThru |
            New-Partition -UseMaximumSize -DriveLetter $driveLetter |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel "$label.$count" -Confirm:$false -Force
    } else {
        $disks[$index] | Get-Partition | Set-Partition -NewDriveLetter $driveLetter
    }
    $count++
}