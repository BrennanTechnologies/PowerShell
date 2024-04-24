

#Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" -recurse 

#$DeviceEnroller = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" -recurse | Where-Object { $_ -like 'DeviceEnroller' }
$DeviceEnroller = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" -recurse | Where-Object { $_ -match 'AlertListener' }
if ($DeviceEnroller.Count -gt 0) {
    Write-LogInfo -Message "DeviceEnroller: $($DeviceEnroller)" #FirstScheduleTimestamp
    Function GetRegDate ($path, $key) {
        function GVl ($ar) {
            return [uint32]('0x' + (($ar | ForEach-Object ToString X2) -join ''))
        }
        #$ar = 
        Write-Host "Path: $path" -ForegroundColor yellow
        Write-Host "Key: $key" -ForegroundColor yellow
        #Get-ItemPropertyValue $path $key 
        exit
        [array]::reverse($ar)
        $time = New-Object DateTime (GVl $ar[14..15]), (GVl $ar[12..13]), (GVl $ar[8..9]), (GVl $ar[6..7]), (GVl $ar[4..5]), (GVl $ar[2..3]), (GVl $ar[0..1])
        return $time
    }
    #$KeyName = 'DeviceEnroller' 
    $KeyName = 'AlertListener'

    Write-Host "Searching for DeviceEnroller... $KeyName"
    [array]$RegKey = (@(Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" -Recurse | Where-Object { $_.PSChildName -like $KeyName }))
    Write-Host " $KeyName.Count: " $RegKey.Count -ForegroundColor Yellow


    #$KeyName = "FirstScheduleTimestamp"
    $KeyName = "AlertListenerClassID"
    if ($RegKey.Count -gt 0) {
        foreach ($Key in $RegKey) {

            $RegPath = $($RegKey.name).TrimStart("HKEY_LOCAL_MACHINE") 

            $RegPath = "HKLM:\$RegPath"
            Write-Host "RegPath: " $RegPath -ForegroundColor Magenta
            Write-Host "KeyName: " $KeyName -ForegroundColor Magenta
            Get-ItemPropertyValue $RegPath $KeyName 
        }
        #Get-ItemPropertyValue -Path $RegPath -Name $KeyName

        $RegKey = (@(Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" -recurse | Where-Object { $_.PSChildName -like 'DeviceEnroller' }))
        $RegPath = $($RegKey.name).TrimStart("HKEY_LOCAL_MACHINE")
        $RegDate = GetRegDate HKLM:\$RegPath "FirstScheduleTimestamp"
        $DeviceEnrolmentDate = Get-Date $RegDate
        $DeviceEnrolmentDate


        exit
        #$RegDate = GetRegDate HKLM:\$RegPath "FirstScheduleTimestamp"
        $RegDate = GetRegDate "HKLM:\$RegPath" $KeyName
            
            
        Write-Host "RegDate: $RegDate" -ForegroundColor Magenta
        #GetRegDate HKLM:\$RegPath $KeyName -ErrorAction SilentlyContinue
           

        #$RegDate = GetRegDate HKLM:\$RegPath $KeyName
        #$DeviceEnrolmentDate = Get-Date $RegDate
        #$DeviceEnrolmentDate

        #$RegKey.name
        #$RegKey | Select-Object -Property PSChildName #, PSPath, Name, Value, Property, PropertyType, PSChildName, PSProvider, PSCustomObject, PSIsContainer, PSParentPath, PSPath, PSDrive, PSProvider, PSIsContainer, PSParentPath, PSChildName, PSProvider, P
        #$RegPath = $($RegKey.name).TrimStart("HKEY_LOCAL_MACHINE")
        #$RegDate = GetRegDate HKLM:\$RegPath "FirstScheduleTimestamp"
        #$RegDate = GetRegDate HKLM:\$RegPath "AlertListenerClassID"
            
            
        #Get-Date $RegDate
            
    }
    #$RegKey | Select-Object -Property $PSChildName | FL
    <#
        

        #>
}
    


#HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\1E05DD5D-A022-46C5-963C-B20DE341170F\AlertListener
#Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" -recurse | Where-Object { $_ -match 'AlertListener' }
exit
$Enrollments = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" -recurse 
    

foreach ($Enrollment in $Enrollments) {
    #Write-LogInfo -Message $Enrollment #.PSChildName
    $Enrollment
    #$Enrollment.PSChildName #.TrimStart("HKEY_LOCAL_MACHINE")
} ; exit 

