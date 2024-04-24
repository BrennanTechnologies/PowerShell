<#
.SYNOPSIS
Get VM's and associated Server Tags from VMWare.

.DESCRIPTION
Get VM's and associated Server Tags from VMWare.

.PARAMETER VMNameFilter
[string] -- Filter used by Get-VM -Name $vmNameFilter.

.PARAMETER IncludeTagCategory
[array]  -- Array of Server Tag Assignments to Include.

.PARAMETER ExcludeTagName
[array] -- Array of Server Tag Assignments to Exclude.

.PARAMETER ServerRecordAge
# of Days until servers show up in the report.

.EXAMPLE
$ServerParams = @{
    VMNameFilter       = $VMNameFilter
    IncludeTagCategory = $IncludeTagCategory 
    ExcludeTagName     = $ExcludeTagName
    ServerRecordAge    = $ServerRecordAge
}
Get-ServerTagAssignments @serverParams

.OUTPUTS
[PSCustomObject]$ServerTags

#>

function Get-ServerTagAssignments {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [array]$VMNameFilter
        ,
        [Parameter(Mandatory = $true)]
        [array]$IncludeTagCategory
        ,
        [Parameter(Mandatory = $true)]
        [array]$ExcludeTagName
        ,
        [Parameter(Mandatory = $true)]
        [array]$ServerRecordAge
    ) 
    Begin {
        Write-Log -LogString "Start : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray
    }
    Process {
        try {
            ### Get VM's from VMWare.
            ###---------------------------------------------
            $VMServers = VMware.VimAutomation.Core\Get-VM -Name $VMNameFilter | Sort-Object -Property Name
            $VMServers | %{Write-Host "Server: " $_.Name -ForegroundColor DarkCyan}
            Write-Log -LogString ("Total Server Count: " + $VMServers.Count) -LogLevel Output -LogObject $VeeamReportLog
        } 
        catch {
            $ErrMsg = "ERROR: Getting VM -" + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message
            Write-Log -LogString $ErrMsg -LogLevel Warning -LogObject $VeeamReportLog
        }
        ### Get VM Tags Assignments from VMWare.
        ###---------------------------------------------
        $ServerTags = @()
        foreach ($Server in $VMServers){
            Write-Host "Getting Server Tag: " $($Server.Name) -ForegroundColor DarkCyan

            ### Get Server vCenter Location.
            ###---------------------------------------------
            $VCenter = $( (Get-VM $Server.Name).Uid.Split(":")[0].Split("@")[1] )

            ### Get VM Tags Assignments.
            ###---------------------------------------------
            try {
                $Tag = Get-TagAssignment -Entity $Server -Server $vCenter -Verbose -ErrorAction Stop | Select-Object -ExpandProperty tag
                if( $null -eq $Tag ){
                    ### Catch Servers with No Tags.
                    ###------------------------------
                    $Tag = New-Object PSObject -Property @{ Name =  "No Tag"; Category = "No Tag"}
                }
            } 
            catch {
                ### Catch Server Tag Errors - "Not Found".
                ###---------------------------------------------
                ###  - Get-TagAssignment com.vmware.vapi.std.errors.unauthenticated {'messages': [com.vmware.vapi.std.localizable_message {'id': vapi.method.authentication.required, 'default_message': This method requires authentication., 'args': []}], 'data':}
                ###  - This Error generates the message "The given key was not present in the dictionary."
                ###  - $Tag = New-Object PSObject -Property @{ Category =  ($global:Error[0].Exception.Message).Split("`t")[3]; Name = "NA"; Entity = $server} #<-- The given key was not present in the dictionary.
                
                $Tag = New-Object PSObject -Property @{ Category =  "Not Found"; Name = "Not Found"; Entity = $server}
                $ErrMsg = "ERROR: Getting Tag - " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message
                Write-Log -LogString $ErrMsg -LogLevel Warning -LogObject $VeeamReportLog
            }
            ### Filter Include & Exclude Tags.
            ###---------------------------------------------
            [bool]$ReportServer = if( `
                (( $IncludeTagCategory -Contains $Tag.Category ) -OR  ( $Tag.Category -Like  $IncludeTagCategory )) `
                    -AND  `
                (( $ExcludeTagName -NotContains  $Tag.Name )     -OR  ( $Tag.Name -Like  $IncludeTagName )) `
            )
            {
                $Object = [PSCustomObject]@{
                    vCenter      = $(($vCenter.Split(".")[0]).SubString(0,2).ToUpper())
                    ServerName   = $Server.Name
                    TagCategory  = $Tag.Category
                    TagName      = $Tag.Name
                }
                $ServerTags += $Object
            }
        }
    }
    End {
        if($DeveloperMode){Write-Log -LogString "End   : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray}
        return $ServerTags
    }
}