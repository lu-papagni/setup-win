Import-Module "$PSScriptRoot/Configuration.psm1"

Describe 'Test-ConfigDirectory' {
    It 'returns true for valid directory' {
        $tempDir = Join-Path -Path $env:TEMP -ChildPath (New-Guid)
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $result = Test-ConfigDirectory $tempDir
        Remove-Item -Path $tempDir -Force
        $result | Should -Be $true
    }
    It 'returns false for invalid directory' {
        $invalidPath = Join-Path -Path $env:TEMP -ChildPath (New-Guid)
        $result = Test-ConfigDirectory $invalidPath
        $result | Should -Be $false
    }
}

Describe 'Get-SoftwareConfigNames' {
    It 'returns property names for valid object' {
        $obj = @{One = 1; Two = 2; Three = 3}
        $names = Get-SoftwareConfigNames $obj
        $names | Should -Contain 'One'
        $names | Should -Contain 'Two'
        $names | Should -Contain 'Three'
    }
    It 'returns empty for empty object' {
        $obj = @{}
        $names = Get-SoftwareConfigNames $obj
        $names.Count | Should -Be 0
    }
}

Describe 'Ensure-DestinationDirectory' {
    It 'creates directory when not exists and ShouldProcess is true' {
        $tempDir = Join-Path -Path $env:TEMP -ChildPath (New-Guid)
        $mockPSCmdlet = [pscustomobject]@{ ShouldProcess = { $true } }
        Ensure-DestinationDirectory $tempDir $mockPSCmdlet
        (Test-Path -Path $tempDir -PathType Container) | Should -Be $true
        Remove-Item -Path $tempDir -Force
    }
    It 'does not overwrite existing directory' {
        $tempDir = Join-Path -Path $env:TEMP -ChildPath (New-Guid)
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $mockPSCmdlet = [pscustomobject]@{ ShouldProcess = { $true } }
        Ensure-DestinationDirectory $tempDir $mockPSCmdlet
        (Test-Path -Path $tempDir -PathType Container) | Should -Be $true
        Remove-Item -Path $tempDir -Force
    }
}

Describe 'Get-ItemsToLink' {
    It 'returns matching items' {
        $tempDir = Join-Path -Path $env:TEMP -ChildPath (New-Guid)
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $file1 = Join-Path $tempDir 'foo.txt'
        $file2 = Join-Path $tempDir 'bar.log'
        New-Item -ItemType File -Path $file1 | Out-Null
        New-Item -ItemType File -Path $file2 | Out-Null
        $result = Get-ItemsToLink $tempDir 'foo'
        $result | Should -Contain 'foo.txt'
        Remove-Item -Path $file1, $file2, $tempDir -Force
    }
    It 'returns empty when no matches' {
        $tempDir = Join-Path -Path $env:TEMP -ChildPath (New-Guid)
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $file1 = Join-Path $tempDir 'foo.txt'
        New-Item -ItemType File -Path $file1 | Out-Null
        $result = Get-ItemsToLink $tempDir 'nomatch'
        $result.Count | Should -Be 0
        Remove-Item -Path $file1, $tempDir -Force
    }
}

Describe 'Create-SymbolicLink' {
    It 'creates symbolic link when ShouldProcess is true' {
        $tempDir = Join-Path -Path $env:TEMP -ChildPath (New-Guid)
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $targetFile = Join-Path $tempDir 'target.txt'
        New-Item -ItemType File -Path $targetFile | Out-Null
        $linkFile = Join-Path $tempDir 'link.txt'
        $mockPSCmdlet = [pscustomobject]@{ ShouldProcess = { $true } }
        Create-SymbolicLink 'link.txt' $targetFile $linkFile $mockPSCmdlet
        (Test-Path -Path $linkFile -PathType Leaf) | Should -Be $true
        Remove-Item -Path $targetFile, $linkFile, $tempDir -Force
    }
    It 'does not create link when ShouldProcess is false' {
        $tempDir = Join-Path -Path $env:TEMP -ChildPath (New-Guid)
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $targetFile = Join-Path $tempDir 'target.txt'
        New-Item -ItemType File -Path $targetFile | Out-Null
        $linkFile = Join-Path $tempDir 'link.txt'
        $mockPSCmdlet = [pscustomobject]@{ ShouldProcess = { $false } }
        Create-SymbolicLink 'link.txt' $targetFile $linkFile $mockPSCmdlet
        (Test-Path -Path $linkFile) | Should -Be $false
        Remove-Item -Path $targetFile, $tempDir -Force
    }
}

Describe 'Process-Target' {
    It 'processes valid target' {
        # Integration test: can be implemented with mocks or by checking side effects
        # TODO: Implement with mocks or check created links
    }
    It 'does nothing when no items to link' {
        # Integration test: can be implemented with mocks or by checking no links created
        # TODO: Implement with mocks or check no created links
    }
}

Describe 'Process-SoftwareConfig' {
    It 'processes valid configName' {
        # Integration test: can be implemented with mocks or by checking Process-Target called
        # TODO: Implement with mocks or check side effects
    }
    It 'writes error for invalid configName' {
        $Programs = @{}
        $Path = $env:TEMP
        $mockPSCmdlet = [pscustomobject]@{}
        { Process-SoftwareConfig 'NonExistentConfig' $Programs $Path $mockPSCmdlet } | Should -Throw
    }
}

Describe 'Import-Settings' {
    It 'processes all configs for valid Path and Programs' {
        # Integration test: can be implemented with mocks or by checking Process-SoftwareConfig called
        # TODO: Implement with mocks or check side effects
    }
    It 'writes error for invalid Path' {
        $Programs = @{}
        $invalidPath = Join-Path -Path $env:TEMP -ChildPath (New-Guid)
        { Import-Settings $Programs $invalidPath } | Should -Throw
    }
    It 'writes host message for empty Programs' {
        $Programs = @{}
        $Path = $env:TEMP
        $result = Import-Settings $Programs $Path
        # TODO: Check for host message output
    }
    It 'outputs verbose info when Verbose is set' {
        $Programs = @{TestConfig = @()}
        $Path = $env:TEMP
        $PSBoundParameters = @{Verbose = $true}
        # TODO: Check for verbose output
    }
}
