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

function Join-ObjectsRecursive {
  param (
    [Parameter(Mandatory = $true)]
    [psobject]$Source,

    [Parameter(Mandatory = $true)]
    [psobject]$Destination
  )

  $Result = [pscustomobject]@{}

  # Ottieni tutte le proprietà
  $AllProps = @{}
  foreach ($p in $Source.PSObject.Properties) { $AllProps[$p.Name] = $true }
  foreach ($p in $Destination.PSObject.Properties) { $AllProps[$p.Name] = $true }

  foreach ($key in $AllProps.Keys) {
    $sVal = $Source.PSObject.Properties[$key].Value
    $dVal = $Destination.PSObject.Properties[$key].Value

    if ($sVal -is [psobject] -and $dVal -is [psobject] -and
    $sVal.PSObject.TypeNames -contains 'System.Management.Automation.PSCustomObject' -and
    $dVal.PSObject.TypeNames -contains 'System.Management.Automation.PSCustomObject') {
      # Fusione ricorsiva se entrambi sono oggetti personalizzati
      $mergedVal = Join-ObjectsRecursive -Source $sVal -Destination $dVal
      Add-Member -InputObject $Result -MemberType NoteProperty -Name $key -Value $mergedVal
    } elseif ($Source.PSObject.Properties[$key]) {
      # Se la chiave è presente in Source, ha la priorità
      Add-Member -InputObject $Result -MemberType NoteProperty -Name $key -Value $sVal
    } else {
      # Altrimenti usa il valore di Destination
      Add-Member -InputObject $Result -MemberType NoteProperty -Name $key -Value $dVal
    }
  }

  return $Result
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

# Apre il selettore dei file nativo di Windows
# Restituisce il percorso assoluto del file selezionato
function Get-PickedFile {
  param(
    [hashtable[]] $FileTypes,
    [switch] $AllowAny,
    [string] $Dir = $PSScriptRoot,
    [string] $Title
  )

  [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

  $filePicker = New-Object System.Windows.Forms.OpenFileDialog
  [string[]] $filters = @()

  foreach ($entry in $FileTypes) {
    $desc = $entry.Description
    $ext = '*.{0}' -f $entry.Extension
    $filters += $desc, $ext -join '|'
  }

  if ($AllowAny -and $FileTypes.Length -gt 0 -or $FileTypes.Length -eq 0) {
    $filters += 'All Files|*.*'
  }

  $filePicker.Filter = $filters -join '|'
  if ($Dir) { $filePicker.InitialDirectory = Resolve-Path $Dir }
  $filePicker.Title = $Title

  if ($filePicker.ShowDialog() -eq "OK") {
    return Resolve-Path ($filePicker.FileName)
  }

  return $null
}

# Resituisce il percorso assoluto della cartella selezionata
function Get-PickedFolder {
  param(
    [string] $Dir = $PSScriptRoot,
    [string] $Hint
  )

  [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
  $folderPicker = New-Object System.Windows.Forms.FolderBrowserDialog

  if ($Dir) { $folderPicker.SelectedPath = Resolve-Path $Dir }
  $folderPicker.Description = $Hint

  if ($folderPicker.ShowDialog() -eq "OK") {
    return Resolve-Path $folderPicker.SelectedPath
  }

  return $null
}

Export-ModuleMember -Function ConvertTo-HashMap
Export-ModuleMember -Function Test-Compatibility
Export-ModuleMember -Function Get-PickedFile
Export-ModuleMember -Function Get-PickedFolder
Export-ModuleMember -Function Join-ObjectsRecursive
