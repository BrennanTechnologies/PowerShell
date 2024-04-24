

function Get-ShortCutTargets {

    $Path = "$env:USERPROFILE\Desktop"
    $ShortCuts = Get-ChildItem -Path $Path -Filter '*.lnk' #-Include *.lnk -Recurse #-Name
    
    $wShell = New-Object -ComObject WScript.Shell
    
    $Targets = ForEach($Item in $ShortCuts) {
        $S = $wShell.CreateShortcut($Item.FullName)
        $S.TargetPath
    }
    
    $Targets
}

cls
Get-ShortCutTargets