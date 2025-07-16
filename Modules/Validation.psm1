Add-Type @'
public enum SetupAction {
  Install,
  Import
}
'@

function Get-ConfigurationPath {
  $searchPaths = @($MyInvocation.PSScriptRoot)

  foreach ($path in $searchPaths) {
    $filePath = Join-Path $path 'setup-config.json' 
    if (Test-Path $filePath) {
      return $filePath
    }
  }

  return $false
}

function Get-CollectionsPath {
  param(
    [object]$CollectionsConfig
  )

  $collections = $CollectionsConfig

  # Se il valore è `true` allora lascio selezionare una directory custom
  if ($collections -eq $true) {
    Write-Host -ForegroundColor Magenta 'Hai scelto di selezionare la collezione in modo interattivo.'
    $collections = Get-PickedFolder -Hint 'Seleziona una collezione valida'

    while (-not $collections) {
      try {
        Write-Error 'Non hai selezionato nulla. Riprovare?' -ErrorAction Inquire
        $collections = Get-PickedFolder -Hint 'Seleziona una collezione valida'
      } catch {
        return $null
      }
    }
  }

  if ($collections -is [string]) {
    return Join-Path $env:USERPROFILE $collections
  }

  if ($collections -is [System.Management.Automation.PathInfo]) {
    return $collections
  }
}

function Get-SelectedActions {
  param(
    [SetupAction[]]$OnlyActions,
    [hashtable]$Settings
  )

  [SetupAction[]] $selectedFeatures = @()

  # Parsing delle azioni specificate
  foreach ($action in $OnlyActions) {
    try {
      $selectedFeatures += [SetupAction]($action)
    } catch {
      Write-Error "Impossibile eseguire '$action': azione non riconosciuta."
    }
  }

  # Se non sono state specificate azioni, usa le configurazioni di default
  if ($selectedFeatures.Length -eq 0) {
    if ($Settings.installPrograms.enabled) { $selectedFeatures += [SetupAction]::Install } 
    if ($Settings.configFiles.enabled) { $selectedFeatures += [SetupAction]::Import } 
  }

  return $selectedFeatures
}

function Get-ValidatedConfigPath {
  param(
    [string]$UserConfigPath,
    [string]$DefaultConfigPath
  )

  $selectedPath = $UserConfigPath
  while (-not $selectedPath -or -not (Test-Path $selectedPath)) {
    Write-Warning "Configurazione '$selectedPath' non valida."
    $selectedPath = Get-PickedFile -FileTypes @{ Description='JSON'; Extension='json' } -Title 'Seleziona file di configurazione'

    if (-not $selectedPath) {
      try {
        Write-Error "Non hai effettuato una selezione. Riprovare?" -ErrorAction Inquire
      } catch {
        return $DefaultConfigPath
      }
    }
  }

  return $selectedPath
}

Export-ModuleMember -Function Get-ConfigurationPath
Export-ModuleMember -Function Get-CollectionsPath
Export-ModuleMember -Function Get-SelectedActions
Export-ModuleMember -Function Get-ValidatedConfigPath
