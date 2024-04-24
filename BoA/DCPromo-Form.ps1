<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Untitled
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$DCPromo                         = New-Object system.Windows.Forms.Form
#$DCPromo.ClientSize              = '400,507'
$DCPromo.text                    = "DC Promo"
$DCPromo.TopMost                 = $true

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 160
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(180,71)
$TextBox1.Font                   = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$action                          = New-Object system.Windows.Forms.Label
$action.text                     = "Action: "
$action.AutoSize                 = $true
$action.width                    = 25
$action.height                   = 10
$action.location                 = New-Object System.Drawing.Point(12,35)
$action.Font                     = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$action.ForeColor                = [System.Drawing.Color]::Blue

$actionListBox                   = New-Object system.Windows.Forms.ListBox
$actionListBox.text              = "listBox"
$actionListBox.width             = 80
$actionListBox.height            = 30
$actionListBox.location          = New-Object System.Drawing.Point(180,26)

$targetDCFQDN                    = New-Object system.Windows.Forms.Label
$targetDCFQDN.text               = "Target DC FQDN: "
$targetDCFQDN.AutoSize           = $true
$targetDCFQDN.width              = 25
$targetDCFQDN.height             = 10
$targetDCFQDN.location           = New-Object System.Drawing.Point(12,73)
$targetDCFQDN.Font               = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$targetDCFQDN.ForeColor          = [System.Drawing.Color]::Blue

$TextBox2                        = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline              = $false
$TextBox2.width                  = 164
$TextBox2.height                 = 20
$TextBox2.location               = New-Object System.Drawing.Point(180,104)
$TextBox2.Font                   = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$targetDCSite                    = New-Object system.Windows.Forms.Label
$targetDCSite.text               = "Target DC Site: "
$targetDCSite.AutoSize           = $true
$targetDCSite.width              = 25
$targetDCSite.height             = 10
$targetDCSite.location           = New-Object System.Drawing.Point(12,108)
$targetDCSite.Font               = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$targetDCSite.ForeColor          = [System.Drawing.Color]::Blue

$EnableGC                        = New-Object system.Windows.Forms.CheckBox
$EnableGC.text                   = "Enable GC"
$EnableGC.AutoSize               = $false
$EnableGC.width                  = 95
$EnableGC.height                 = 20
$EnableGC.location               = New-Object System.Drawing.Point(180,139)
$EnableGC.Font                   = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$EnableGC.ForeColor              = [System.Drawing.Color]::Blue

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Submit"
$Button1.width                   = 60
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(113,460)
$Button1.Font                    = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.text                    = "Cancel"
$Button2.width                   = 60
$Button2.height                  = 30
$Button2.location                = New-Object System.Drawing.Point(202,460)
$Button2.Font                    = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$InstallPCNS                     = New-Object system.Windows.Forms.CheckBox
$InstallPCNS.text                = "Install PCNS"
$InstallPCNS.AutoSize            = $false
$InstallPCNS.width               = 95
$InstallPCNS.height              = 20
$InstallPCNS.location            = New-Object System.Drawing.Point(180,164)
$InstallPCNS.Font                = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$InstallPCNS.ForeColor           = [System.Drawing.Color]::Blue

$TextBox3                        = New-Object system.Windows.Forms.TextBox
$TextBox3.multiline              = $false
$TextBox3.width                  = 157
$TextBox3.height                 = 20
$TextBox3.location               = New-Object System.Drawing.Point(180,186)
$TextBox3.Font                   = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$DPMBackup                       = New-Object system.Windows.Forms.Label
$DPMBackup.text                  = "DPM Backup: "
$DPMBackup.AutoSize              = $true
$DPMBackup.width                 = 25
$DPMBackup.height                = 10
$DPMBackup.location              = New-Object System.Drawing.Point(12,187)
$DPMBackup.Font                  = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$DPMBackup.ForeColor             = [System.Drawing.Color]::Blue

$TextBox4                        = New-Object system.Windows.Forms.TextBox
$TextBox4.multiline              = $false
$TextBox4.width                  = 157
$TextBox4.height                 = 20
$TextBox4.location               = New-Object System.Drawing.Point(180,214)
$TextBox4.Font                   = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$DCPromoSite                     = New-Object system.Windows.Forms.Label
$DCPromoSite.text                = "DC Promo Site: "
$DCPromoSite.AutoSize            = $true
$DCPromoSite.width               = 25
$DCPromoSite.height              = 10
$DCPromoSite.location            = New-Object System.Drawing.Point(12,216)
$DCPromoSite.Font                = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$DCPromoSite.ForeColor           = [System.Drawing.Color]::Blue

$InstallSystemStateBackup        = New-Object system.Windows.Forms.CheckBox
$InstallSystemStateBackup.text   = "Install System State Backup"
$InstallSystemStateBackup.AutoSize  = $false
$InstallSystemStateBackup.width  = 95
$InstallSystemStateBackup.height  = 20
$InstallSystemStateBackup.location  = New-Object System.Drawing.Point(180,247)
$InstallSystemStateBackup.Font   = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$InstallSystemStateBackup.ForeColor  = [System.Drawing.Color]::Blue

$sourceDCFQDNjh                  = New-Object system.Windows.Forms.TextBox
$sourceDCFQDNjh.multiline        = $false
$sourceDCFQDNjh.width            = 100
$sourceDCFQDNjh.height           = 20
$sourceDCFQDNjh.location         = New-Object System.Drawing.Point(180,275)
$sourceDCFQDNjh.Font             = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Source DC FQDN: "
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(12,278)
$Label1.Font                     = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$Label1.ForeColor                = [System.Drawing.Color]::Blue

$sourceDCOriginalState           = New-Object system.Windows.Forms.Label
$sourceDCOriginalState.text      = "Source DC Original State: "
$sourceDCOriginalState.AutoSize  = $true
$sourceDCOriginalState.width     = 25
$sourceDCOriginalState.height    = 10
$sourceDCOriginalState.location  = New-Object System.Drawing.Point(12,308)
$sourceDCOriginalState.Font      = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$sourceDCOriginalState.ForeColor  = [System.Drawing.Color]::Blue

$TextBox5                        = New-Object system.Windows.Forms.TextBox
$TextBox5.multiline              = $false
$TextBox5.width                  = 100
$TextBox5.height                 = 20
$TextBox5.location               = New-Object System.Drawing.Point(180,306)
$TextBox5.Font                   = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$IFMPromo                        = New-Object system.Windows.Forms.CheckBox
$IFMPromo.text                   = "IFM Promo"
$IFMPromo.AutoSize               = $false
$IFMPromo.width                  = 95
$IFMPromo.height                 = 20
$IFMPromo.location               = New-Object System.Drawing.Point(180,341)
$IFMPromo.Font                   = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$IFMPromo.ForeColor              = [System.Drawing.Color]::Blue

$TextBox6                        = New-Object system.Windows.Forms.TextBox
$TextBox6.multiline              = $false
$TextBox6.width                  = 100
$TextBox6.height                 = 20
$TextBox6.location               = New-Object System.Drawing.Point(180,365)
$TextBox6.Font                   = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$RMFECollection                  = New-Object system.Windows.Forms.Label
$RMFECollection.text             = "RMFE Collection: "
$RMFECollection.AutoSize         = $true
$RMFECollection.width            = 25
$RMFECollection.height           = 10
$RMFECollection.location         = New-Object System.Drawing.Point(12,365)
$RMFECollection.Font             = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RMFECollection.ForeColor        = [System.Drawing.Color]::Blue

$sourceADDNS                     = New-Object system.Windows.Forms.Label
$sourceADDNS.text                = "Source ADDNS: "
$sourceADDNS.AutoSize            = $true
$sourceADDNS.width               = 25
$sourceADDNS.height              = 10
$sourceADDNS.location            = New-Object System.Drawing.Point(12,399)
$sourceADDNS.Font                = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$sourceADDNS.ForeColor           = [System.Drawing.Color]::Blue

$TextBox7                        = New-Object system.Windows.Forms.TextBox
$TextBox7.multiline              = $false
$TextBox7.width                  = 100
$TextBox7.height                 = 20
$TextBox7.location               = New-Object System.Drawing.Point(180,399)
$TextBox7.Font                   = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$DCPromo.controls.AddRange(@($TextBox1,$action,$actionListBox,$targetDCFQDN,$TextBox2,$targetDCSite,$EnableGC,$Button1,$Button2,$InstallPCNS,$TextBox3,$DPMBackup,$TextBox4,$DCPromoSite,$InstallSystemStateBackup,$sourceDCFQDNjh,$Label1,$sourceDCOriginalState,$TextBox5,$IFMPromo,$TextBox6,$RMFECollection,$sourceADDNS,$TextBox7))


