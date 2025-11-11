function Test-ConfigDirectory {
  param([string]$Path)
  return Test-Path -Path $Path -PathType Container
}


function Get-SoftwareConfigNames {
  param($Programs)
    return $Programs.PSObject.Properties.Name
}

function Ensure-DestinationDirectory {
  param([string]$linkDestinationDir, $PSCmdlet)
    if (-not (Test-Path -PathType Container -Path $linkDestinationDir)) {
      if ($PSCmdlet.ShouldProcess($linkDestinationDir, "Create directory")) {
        New-Item -ItemType Directory -Path $linkDestinationDir
      }
    } else {
      Write-Verbose "The path '$linkDestinationDir' exists, not overwriting."
    }
}

function Get-ItemsToLink {
  param([string]$configAbsolutePath, [string]$targetRegex)
    return Resolve-Path "$configAbsolutePath" |
    Get-ChildItem |
    Where-Object { $_.Name -match "$targetRegex" } |
    Select-Object -ExpandProperty Name
}

function Create-SymbolicLink {
  param([string]$itemName, [string]$itemAbsolutePath, [string]$linkTargetPath, $PSCmdlet)
    Write-Host -ForegroundColor Blue "[${itemName}]: '$itemAbsolutePath' => '$linkTargetPath'"
    if ($PSCmdlet.ShouldProcess($itemName, "Symbolic link")) {
      New-Item -Path $linkTargetPath -Value $itemAbsolutePath -ItemType SymbolicLink -Force
    }
}

function Process-Target {
  param($target, [string]$configAbsolutePath, $PSCmdlet)
    $targetRegex = $target.name
    $linkBasePath = Get-Item -Path ("Env:" + $target.root) | Select-Object -ExpandProperty Value
    $linkDestinationDir = Join-Path $linkBasePath $target.destination
    Ensure-DestinationDirectory $linkDestinationDir $PSCmdlet
    $itemsToBeLinked = Get-ItemsToLink $configAbsolutePath $targetRegex
    Write-Verbose "Objects to link: $itemsToBeLinked"
    foreach ($itemName in $itemsToBeLinked) {
      $itemAbsolutePath = Join-Path -Path $configAbsolutePath -ChildPath $itemName | Resolve-Path
        $linkTargetPath = Join-Path -Path $linkDestinationDir -ChildPath $itemName
        Create-SymbolicLink $itemName $itemAbsolutePath $linkTargetPath $PSCmdlet
    }
}

function Process-SoftwareConfig {
  param([string]$configName, $Programs, [string]$Path, $PSCmdlet)
    $configAbsolutePath = Join-Path -Path $Path -ChildPath $configName | Resolve-Path
    if (Test-Path -Path $configAbsolutePath -PathType Container) {
      $targetList = $Programs.$configName
        foreach ($target in $targetList) {
          Process-Target $target $configAbsolutePath $PSCmdlet
        }
    } else {
      Write-Error "Unable to find settings for '$configName'"
    }
}


function Import-Settings {
  [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        $Programs,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
        )

      if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        $Programs | Format-Table -AutoSize
      }
  Write-Verbose "Configuration path: $Path"

    if (-not (Test-ConfigDirectory $Path)) {
      Write-Error "'$Path' is not a valid directory!"
      return
    }

  Write-Verbose ("Keys of `$Programs: ", (ConvertTo-Json $Programs.PSObject.Properties.Name) -join ' ')
    $softwareConfigDirNames = Get-SoftwareConfigNames $Programs

    if ($softwareConfigDirNames.Length -eq 0) {
      Write-Host -ForegroundColor Magenta 'No configuration to import.'
        return
    }

  foreach ($configName in $softwareConfigDirNames) {
    Process-SoftwareConfig $configName $Programs $Path $PSCmdlet
  }
}


Export-ModuleMember -Function Import-Settings
