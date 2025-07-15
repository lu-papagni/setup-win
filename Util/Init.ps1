[CmdletBinding(SupportsShouldProcess = $true)]
param (
  [ValidateNotNullOrEmpty()]
  [string] $Branch = 'main'
)

$github = "https://github.com/lu-papagni/{0}/archive/{1}.zip"
$zipSuffix = "-$Branch"
$dotfiles = @{ Name='dots-win'; Dest='~' }
$setup = @{ Name='setup-win'; Dest='~/Documents/Repository' }

foreach ($repo in $dotfiles, $setup) {
  $zipFile = Join-Path $env:TEMP "$($repo.Name).zip"
  $outDest = Resolve-Path $repo.Dest
  $repoAddress = ($github -f $repo.Name, $Branch)


  if ($PSCmdlet.ShouldProcess($repoAddress, "Download della repository")) {
    Invoke-RestMethod -Uri $repoAddress -OutFile $zipFile -ErrorAction Stop
  }

  if ($PSCmdlet.ShouldProcess($zipFile, "Estrazione archivio")) {
    Expand-Archive -LiteralPath $zipFile -DestinationPath $outDest
    rm $zipFile
  }

  $extractedDir = (Join-Path $outDest -ChildPath "$($repo.Name)$zipSuffix")
  if ($PSCmdlet.ShouldProcess($extractedDir, "Ridenominazione directory estratta")) {
    mv $extractedDir ($extractedDir -replace $zipSuffix, '')
  }
}

Write-Host -ForegroundColor Green 'Tutto pronto per iniziare!'

if ($PSCmdlet.ShouldProcess("Conferma di avvio")) {
  $shouldRunSetup = Read-Host -Prompt 'Avviare la configurazione del sistema? [S/N]'
} else {
  $shouldRunSetup = 's'
}

if ($shouldRunSetup -match '[sSyY]') {
  $setupDest = Join-Path $setup.Dest $setup.Name
  $script = Join-Path $setupDest 'Setup.ps1'

  $dotfilesDest = Join-Path $dotfiles.Dest $dotfiles.Name
  $configuration = Join-Path $dotfilesDest 'setup-config.json'

  if ($PSCmdlet.ShouldProcess(@($script, $configuration) -join ';', "Risoluzione percorso assoluto")) {
    $script, $configuration = Resolve-Path $script, $configuration -ErrorAction Stop
  }

  $scriptArgs = '-NoProfile', $script, '-Config', $configuration, '-Dotfiles', $dotfilesDest

  if ($PSCmdlet.ShouldProcess($scriptArgs, "Avvio processo di installazione come amministratore")) {
    Write-Host -ForegroundColor Green 'Inizio installazione.'
    Start-Process powershell.exe -Verb runas -ArgumentList $scriptArgs
  }
}
