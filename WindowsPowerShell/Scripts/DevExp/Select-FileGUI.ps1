function Select-FileGUI {
    param (
        [Parameter(Mandatory=$true)]$title,
        [Parameter(Mandatory=$true)]$directory,
        [Parameter(Mandatory=$false)]$fileName,
        [Parameter(Mandatory=$false)]$logFile
    )

    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $objForm = New-Object System.Windows.Forms.OpenFileDialog
    $objForm.ShowHelp = "true"
    $objForm.Title = $title
    $objForm.InitialDirectory = $directory
    $objForm.FileName = $fileName
    $objForm.CheckFileExists = $true
    $show = $objForm.ShowDialog()
    if ($show -eq "OK") {
        Return $objForm.FileName
    }
    else {
        Write-ScreenAndLog -cat "ERROR" -msg "Operation cancelled by user." -logFile $logFile
    }
}

$csvPath = Select-FileGUI -title "Select your csv file with host info" -directory "C:\" 
$csvPath
exit
$csvInput = Import-Csv -Path $csvPath
$csvInput | GM

