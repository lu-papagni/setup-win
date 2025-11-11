BeforeAll {
  $global:OriginalPSModulePath = $env:PSModulePath
  $env:PSModulePath = "$PSScriptRoot;$env:PSModulePath"
  Import-Module Configuration -Force
}

AfterAll {
  $env:PSModulePath = $global:OriginalPSModulePath
}

InModuleScope Configuration {
    Describe 'Test-ConfigDirectory' {
      BeforeEach {
        $tempDir = Join-Path -Path TestDrive: -ChildPath (New-Guid)
      }

      It 'returns true for valid directory' {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $result = Test-ConfigDirectory $tempDir
        $result | Should -Be $true
      }

      It 'returns false for invalid directory' {
        $invalidPath = Join-Path -Path TestDrive: -ChildPath (New-Guid)
        $result = Test-ConfigDirectory $invalidPath
        $result | Should -Be $false
      }
    }
}


InModuleScope Configuration {
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
}


InModuleScope Configuration {
    Describe 'Ensure-DestinationDirectory' {
      BeforeEach {
        $tempDir = Join-Path -Path TestDrive: -ChildPath (New-Guid)
      }

      It 'creates directory when not exists' {
        Ensure-DestinationDirectory $tempDir
        (Test-Path -Path $tempDir -PathType Container) | Should -Be $true
      }
    }
}


InModuleScope Configuration {
    Describe 'Get-ItemsToLink' {
      BeforeEach {
        $tempDir = Join-Path -Path TestDrive: -ChildPath (New-Guid)
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $file1 = Join-Path $tempDir 'foo.txt'
        $file2 = Join-Path $tempDir 'bar.log'
      }

      It 'returns matching items' {
        New-Item -ItemType File -Path $file1 | Out-Null
        New-Item -ItemType File -Path $file2 | Out-Null
        $result = Get-ItemsToLink $tempDir 'foo'
        $result | Should -Contain 'foo.txt'
      }
      It 'returns empty when no matches' {
        New-Item -ItemType File -Path $file1 | Out-Null
        $result = Get-ItemsToLink $tempDir 'nomatch'
        $result.Count | Should -Be 0
      }
    }
}


InModuleScope Configuration {
  Describe 'Create-SymbolicLink' {
    BeforeEach {
      $tempDir = Join-Path -Path TestDrive: -ChildPath (New-Guid)
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $targetFile = Join-Path $tempDir 'target.txt'
        $linkFile = Join-Path $tempDir 'link.txt'
    }

    It 'creates symbolic link when ShouldProcess is true' {
      New-Item -ItemType File -Path $targetFile | Out-Null
        Create-SymbolicLink 'link.txt' $targetFile $linkFile
        (Test-Path -Path $linkFile -PathType Leaf) | Should -Be $true
    }
  }
}


InModuleScope Configuration {
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
}


InModuleScope Configuration {
  Describe 'Process-SoftwareConfig' {
    It 'processes valid configName' {
      # Integration test: can be implemented with mocks or by checking Process-Target called
      # TODO: Implement with mocks or check side effects
    }
      It 'writes error for invalid configName' {
        $Programs = @{}
        $Path = 'TestDrive:'
        $mockPSCmdlet = [pscustomobject]@{}
        { Process-SoftwareConfig 'NonExistentConfig' $Programs $Path $mockPSCmdlet } | Should -Throw
      }
  }
}


InModuleScope Configuration {
  Describe 'Import-Settings' {
    It 'processes all configs for valid Path and Programs' {
      # Integration test: can be implemented with mocks or by checking Process-SoftwareConfig called
      # TODO: Implement with mocks or check side effects
    }
      It 'writes error for invalid Path' {
        $Programs = @{}
        $invalidPath = Join-Path -Path TestDrive: -ChildPath (New-Guid)
        { Import-Settings $Programs $invalidPath } | Should -Throw
      }
      It 'writes host message for empty Programs' {
        $Programs = @{}
        $Path = TestDrive:
        $result = Import-Settings $Programs $Path
        # TODO: Check for host message output
      }
      It 'outputs verbose info when Verbose is set' {
        $Programs = @{TestConfig = @()}
        $Path = TestDrive:
        $PSBoundParameters = @{Verbose = $true}
        # TODO: Check for verbose output
      }
  }
}
