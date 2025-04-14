param(
  [string]$Config = "setup-config.json",
  [switch]$DryRun
)

# Importo moduli
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "Modules"
Import-Module -Name (Join-Path -Path $modulePath -ChildPath "Configuration.psm1")
Import-Module -Name (Join-Path -Path $modulePath -ChildPath "Installation.psm1")
Import-Module -Name (Join-Path -Path $modulePath -ChildPath "Utility.psm1")

# Esce se powershell non è almeno versione 5.0
Test-Compatibility -ShellVersion 5

# Solo powershell 7:
# $scriptSettings = Get-Content -Raw "$Config" | ConvertFrom-Json -AsHashTable
$scriptSettings = Get-Content -Raw "$Config" | ConvertFrom-Json
$scriptSettings = Convert-JsonObject -Source $scriptSettings
$install = $scriptSettings.installPrograms
$configure = $scriptSettings.configFiles

if ($install.enabled) {
  Write-Host -ForegroundColor Green "Inizio installazione programmi..."
  Install-Packages -PackageManager $install.packageManager -PackageList $install.lists -WhatIf:$DryRun
  Write-Host -ForegroundColor Green "Terminato!"
} else {
  Write-Warning "Salto installazione dei pacchetti"
}

if ($configure.enabled) {
  $confDir = Resolve-Path $Config | Split-Path -Parent
  Write-Host -ForegroundColor Green "Inizio importazione configurazione..."
  Import-Settings -Programs $configure.programs -ConfigPath $confDir -WhatIf:$DryRun
  Write-Host -ForegroundColor Green "Terminato!"
} else {
  Write-Warning "Salto importazione file di configurazione"
}
