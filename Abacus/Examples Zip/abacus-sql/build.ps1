Param (
    $Settings = $( Get-Content .\settings.json | ConvertFrom-Json).Settings
)
Begin {
    Import-Module Abacus-Logging -Force
    $BuildLog = $(Start-Log -LogPath "$($Settings.Artifacts)\Build.log" -ScriptName 'build.ps1' -AttachToExistingLog True -Audit False -Global False)
}
Process {
    task Clean {
        If ( Test-Path -Path $($Settings.Artifacts) ) {
            Write-Log -LogString "Removing old artifacts from previous builds..." -LogLevel Output -LogObject $BuildLog
            Remove-Item "$($Settings.Artifacts)/*" -Recurse -Force
        }
    }

    task Build {
        Write-Log -LogString "Writing Environment Variables to Log..." -LogLevel Output -LogObject $BuildLog
        Write-Log -LogString $(Get-ChildItem Env: | Select Name, Value | ConvertTo-Json) -LogLevel Output -LogObject $BuildLog
        Write-Log -LogString "----------------------------------------------------" -LogLevel Output -LogObject $BuildLog

        Write-Log -LogString "Attempting to create Artifacts directory if not present." -LogLevel Output -LogObject $BuildLog
        New-Item -Type Directory -Path $($Settings.Artifacts) -Force

        Write-Log -LogString "Checking PSModule dependencies..." -LogLevel Output -LogObject $BuildLog
        ForEach ( $Dependency in $($Settings.Dependencies) ) {
            Write-Log -LogString "Action Copy: [Repo: '$($Dependency.Name)' | Branch: '$($Dependency.Branch)' | Server: '$($Settings.JenkinsServer)']" -LogLevel Output -LogObject $BuildLog
            Copy-Item -Path "\\$($Settings.JenkinsServer)\$($Settings.JenkinsRepoShare)\$($Dependency.Branch)\$($Dependency.Name)" -Destination '.\Artifacts' -Force -Verbose -Recurse
        }
        $BuildNumber = $(Get-ChildItem env:'Build_Number').Value
        New-Item -Type File -Path "$($Settings.Artifacts)\BuildNumber"
        Set-Content -Path "$($Settings.Artifacts)\BuildNumber" -Value $BuildNumber
    }

    task Test {
        # Run Tests
        If ($Settings.Tests.Count -ge 1) {
            ForEach ( $Dependency in $($Settings.Dependencies.Name) ) {
                If ($Dependency -ne 'PSTestReport') {
                    Write-Log -LogString "Importing $Dependency from the Artifacts directory." -LogLevel Output -LogObject $BuildLog
                    Import-Module -Name ".\Artifacts\$Dependency" -Force
                }
            }

            Write-Log -LogString "Importing Pester for Build tests." -LogLevel Output -LogObject $BuildLog
            Import-Module Pester

            Write-Log -LogString "Importing the module for testing..." -LogLevel Output -LogObject $BuildLog
            Import-Module .\$($Settings.ProjectName)

            Write-Log -LogString "Executing Tests..." -LogLevel Output -LogObject $BuildLog
            $TestResults = Invoke-Pester -Script $($Settings.Tests) `
                -OutputFile "$($Settings.Artifacts)\PesterResults.xml" `
                -OutputFormat NUnitXml `
                -CodeCoverage $($Settings.Tests) `
                -PassThru
            $TestResults | ConvertTo-Json -Depth 5 | Out-File "$($Settings.Artifacts)\PesterResults.json"

            $BuildNumber = Get-Content -Path "$($Settings.Artifacts)\BuildNumber"
            & .\$($Settings.Artifacts)\PSTestReport\Invoke-PSTestReport.ps1 -PesterFile "$($Settings.Artifacts)\PesterResults.json" `
                -BuildNumber $BuildNumber `
                -GitRepo $($Settings.GitRepo) `
                -GitRepoURL $($Settings.GitRepoUrl) `
                -CiURL $($Settings.CiURL) `
                -ShowHitCommands $True `
                -Compliance ".$($Settings.Compliance)" `
                -OutputDir $($Settings.Artifacts)

        }
        Else {
            Write-Host "No tests were included in the settings file."
        }
    }

    task WrapArtifacts {
        Write-Log -LogString "Compressing Archive of resulting Artifacts." -LogLevel Output -LogObject $BuildLog
        Compress-Archive -Path "$($Settings.Artifacts)/*" `
            -DestinationPath "$($Settings.Artifacts)/$($Settings.ProjectName).Artifacts.zip" `
            -CompressionLevel Optimal
    }

    task UploadArtifacts {
        $BuildNumber = $(Get-ChildItem ENV:Build_Number).Value
        Write-Log -LogString "Uploading Artifacts to archive - \\$($Settings.JenkinsServer)\$($Settings.JenkinsArtifactShare)\$($Settings.ProjectName)\$BuildNumber" -LogLevel Output -LogObject $BuildLog

        New-Item -Type Directory `
            -Path "\\$($Settings.JenkinsServer)\$($Settings.JenkinsArtifactShare)\$($Settings.ProjectName)\$BuildNumber" `
            -Force `
            -ErrorAction SilentlyContinue

        Copy-Item -Path "$($Settings.Artifacts)/$($Settings.ProjectName).Artifacts.zip" `
            -Destination "\\$($Settings.JenkinsServer)\$($Settings.JenkinsArtifactShare)\$($Settings.ProjectName)\$BuildNumber" `
            -Force `
            -Verbose `
            -Recurse
    }

    task ConfirmTestsPassed {
        If ($Settings.Tests.Count -ge 1) {
            Write-Log -LogString "Calculating Build results based on tests..." -LogLevel Output -LogObject $BuildLog
            [XML]$Xml = Get-Content (Join-Path $($Settings.Artifacts) "PesterResults.xml")

            $FailedTestCount = $Xml."test-results".failures
            Write-Log -LogString "Tests Failed: $($Xml."test-results".failures)/$($Xml."test-results".Total)" -LogLevel Output -LogObject $BuildLog

            $Json = Get-Content (Join-Path $Settings.Artifacts "PesterResults.json") | ConvertFrom-Json
            $overallCoverage = [Math]::Floor(
                ($json.CodeCoverage.NumberOfCommandsExecuted / $json.CodeCoverage.NumberOfCommandsAnalyzed) * 100
            )

            If ($OverallCoverage -ge $Settings.Compliance) {
                Write-Log -LogString "Test coverage passed: Overall: $($OverAllCoverage)%   /   Setting: $($Settings.Compliance)%" -LogLevel Output -LogObject $BuildLog
            }
            Else {
                Write-Log -LogString "Test coverage failed: Overall: $($OverAllCoverage)%   /   Setting: $($Settings.Compliance)%" -LogLevel Output -LogObject $BuildLog
            }

            assert($FailedTestCount -eq 0) (
                'Failed "{0}" unit tests.' -f $FailedTestCount
            )

            assert($OverallCoverage -ge $Settings.Compliance) (
                'A Code Coverage of "{0}" is above the not build requirement of "{1}"' -f $overallCoverage,
                $Settings.Compliance
            )
        }
    }

    task Publish {
        $branch = $(git show -s --pretty=%d HEAD).split("/")[1].replace(")","")
        Write-Log -LogString "Publishing Build to $branch - \\$($Settings.JenkinsServer)\$($Settings.JenkinsRepoShare)\$branch\$($Settings.ProjectName)" -LogLevel Output -LogObject $BuildLog
        Robocopy.exe /Z /E /PURGE ".\$($Settings.ProjectName)" "\\$($Settings.JenkinsServer)\$($Settings.JenkinsRepoShare)\$branch\$($Settings.ProjectName)" | Out-String -OutVariable RoboCopyOutput
    }
}

