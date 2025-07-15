param(
  [ValidateNotNullOrEmpty()]
  [string]$Config = "$(Split-Path $MyInvocation.InvocationName)\setup-config.json",

  [ValidateNotNullOrEmpty()]
  [string]$Dotfiles = "$($env:USERPROFILE)\dots-win",

  [switch]$DryRun,
  [string[]]$Only
)

enum SetupAction {
  Install
  Import
}

# Importo moduli
Set-Variable MODULE_PATH -Value (Join-Path -Path (Split-Path $MyInvocation.InvocationName) -ChildPath "Modules") -Option ReadOnly
try {
  Import-Module -Name (Join-Path -Path $MODULE_PATH -ChildPath "Configuration.psm1")
  Import-Module -Name (Join-Path -Path $MODULE_PATH -ChildPath "Installation.psm1")
  Import-Module -Name (Join-Path -Path $MODULE_PATH -ChildPath "Utility.psm1")
  Import-Module -Name (Join-Path -Path $MODULE_PATH -ChildPath "Validation.psm1")
} catch {
  Write-Error 'Caricamento librerie fallito.' -ErrorAction Stop
}

# Esce se powershell non è almeno versione 5.0
Test-Compatibility -ShellVersion 5

# Validazione percorso del file di configurazione
$settingsPath = @{
  User = $Config;
  Default = (Get-ConfigurationPath)
}

while (-not (Test-Path $settingsPath.User)) {
  Write-Warning "File di configurazione inesistente: '$($settingsPath.User)'"
  $selectedPath = Get-PickedFile -FileTypes @{ Description='JSON'; Extension='json' } -Title 'Seleziona file di configurazione'

  if ($selectedPath) {
    $settingsPath.User = $selectedPath
  } else {
    $wantToExit = (Read-Host -Prompt 'Non hai selezionato nulla. Uso configurazione di default? [S/N]') -match '[sSyY]'
    if ($wantToExit) { $settingsPath.User = $settingsPath.Default }
  }
}

if (-not $settingsPath.User) {
  Write-Error "Impossibile trovare file di configurazione" -ErrorAction Stop
}

Write-Host -ForegroundColor Magenta "Configurazione utente: $($settingsPath.User)"

# Lettura e parsing configurazione
try {
  $scriptSettings = Get-Content -Raw (Resolve-Path $settingsPath.User) | ConvertFrom-Json
  $defaultSettings = Get-Content -Raw (Resolve-Path $settingsPath.Default) | ConvertFrom-Json
  $scriptSettings = Join-ObjectsRecursive -Destination $defaultSettings -Source $scriptSettings
  $scriptSettings = ConvertTo-HashMap -Source $scriptSettings
} catch {
  Write-Error $_
  Write-Error 'Errore durante la lettura della configurazione' -ErrorAction Stop
}

# Capisco il sotto-insieme di operazioni che lo script deve compiere 
[SetupAction[]] $selectedFeatures = @()

foreach ($action in $Only) {
  try {
    $selectedFeatures += [SetupAction]($action)
  } catch {
    Write-Error "Impossibile eseguire '$action': azione non riconosciuta."
  }
}

$install = $scriptSettings.installPrograms
$configure = $scriptSettings.configFiles

if ($selectedFeatures.Length -eq 0) {
  if ($install.enabled) { $selectedFeatures += [SetupAction]::Install } 
  if ($configure.enabled) { $selectedFeatures += [SetupAction]::Import } 
}

# Esecuzione
if ([SetupAction]::Install -in $selectedFeatures) {
  Write-Host -ForegroundColor Green "Inizio installazione programmi..."
  Install-Packages `
    -PackageManager $install.packageManager `
    -PackageCollections $install.lists `
    -WhatIf:$DryRun `
    -Verbose:$DryRun
  Write-Host -ForegroundColor Green "Terminato!"
} else {
  Write-Warning "Salto installazione dei pacchetti"
}

if ([SetupAction]::Import -in $selectedFeatures) {
  $dotfilesPath = Resolve-Path $Dotfiles
  Write-Host -ForegroundColor Green "Inizio importazione configurazione..."
  Import-Settings -Programs $configure.programs -Path $dotfilesPath -WhatIf:$DryRun -Verbose:$DryRun
  Write-Host -ForegroundColor Green "Terminato!"
} else {
  Write-Warning "Salto importazione file di configurazione"
}
