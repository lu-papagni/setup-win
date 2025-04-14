# Helper per Powershell 5.x dove la funzione `ConvertFrom-Json`
# non aveva ancora implementato questa conversione
function ConvertTo-HashMap {
  param($Source = $null)

  if ($Source -eq $null) {
    Write-Error "Non posso mappare un oggetto nullo."
    return
  }

  $settingsHashMap = @{}

  foreach ($key in $Source.PSObject.Properties.Name) {
    $settingsHashMap[$key] = $Source.$key
  }

  return $settingsHashMap
}

function Test-Compatibility {
  param([int]$ShellVersion)

  $hostVersion = Get-Host | Select-Object -ExpandProperty Version
  Write-Host -ForegroundColor Magenta "Versione PowerShell rilevata: $hostVersion"

  if ($Host.Version.Major -lt $ShellVersion) {
    Write-Host -ForegroundColor Red "Versione di PowerShell incompatibile!"
    Write-Host -ForegroundColor Red "Versione minima richiesta: $ShellVersion"
    Write-Host -ForegroundColor Cyan "Prova ad installare PowerShell $ShellVersion con ``winget install Microsoft.PowerShell``"

    exit 1
  }
}

Export-ModuleMember -Function ConvertTo-HashMap
Export-ModuleMember -Function Test-Compatibility
