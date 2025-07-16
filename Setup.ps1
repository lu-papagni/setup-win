param(
  [ValidateNotNullOrEmpty()]
  [string]$Config = "$(Split-Path $MyInvocation.InvocationName)\setup-config.json",

  [ValidateNotNullOrEmpty()]
  [string]$Dotfiles = "$($env:USERPROFILE)\dots-win",

  [switch]$DryRun,
  [string[]]$Only
)

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

$settingsPath = @{
  User = $Config;
  Default = (Get-ConfigurationPath)
}

# Validazione percorso del file di configurazione
$settingsPath.User = Get-ValidatedConfigPath -UserConfigPath $settingsPath.User -DefaultConfigPath $settingsPath.Default

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

$selectedFeatures = Get-SelectedActions -OnlyActions $Only -Settings $scriptSettings

$install = $scriptSettings.installPrograms
$configure = $scriptSettings.configFiles

# Installazione pacchetti
if ([SetupAction]::Install -in $selectedFeatures) {
  $arguments = @{
    PackageManager=$install.packageManager;
    PackageCollections=$install.collections.get;
    WhatIf=$DryRun;
    Verbose=$DryRun
  }

  $collections = Get-CollectionsPath $install.collections.path
  if ($collections) { $arguments.CollectionsPath = $collections }

  Write-Host -ForegroundColor Green "Inizio installazione programmi..."
  Install-Packages @arguments
  Write-Host -ForegroundColor Green "Terminato!"
} else {
  Write-Warning "Salto installazione dei pacchetti"
}

# Importazione dei file di configurazione
if ([SetupAction]::Import -in $selectedFeatures) {
  $dotfilesPath = Resolve-Path $Dotfiles
  Write-Host -ForegroundColor Green "Inizio importazione configurazione..."
  Import-Settings -Programs $configure.programs -Path $dotfilesPath -WhatIf:$DryRun -Verbose:$DryRun
  Write-Host -ForegroundColor Green "Terminato!"
} else {
  Write-Warning "Salto importazione file di configurazione"
}
