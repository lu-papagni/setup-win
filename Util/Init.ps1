[CmdletBinding(SupportsShouldProcess = $true)]
param (
  [ValidateNotNullOrEmpty()]
  [string] $DotsBranch = 'main',

  [ValidateNotNullOrEmpty()]
  [string] $SetupBranch = 'main'
)

$github = "https://github.com/lu-papagni/{0}/archive/{1}.zip"
$dotfiles = @{
  Name='dots-win';
  Dest='~';
  Branch=$DotsBranch;
  RenameFolder='.dots-win'
}
$setup = @{
  Name='setup-win';
  Dest='~/Documents/Repository';
  Branch=$SetupBranch;
  RenameFolder='setup-win'
}

foreach ($repo in $dotfiles, $setup) {
  $zipFile = Join-Path $env:TEMP "$($repo.Name).zip"
  $outDest = $repo.Dest
  $repoAddress = ($github -f $repo.Name, $repo.Branch)
  $zipSuffix = "-$($repo.Branch)"

  if ($PSCmdlet.ShouldProcess($repoAddress, "Download della repository")) {
    Invoke-RestMethod -Uri $repoAddress -OutFile $zipFile -ErrorAction Stop
  }

  if ($PSCmdlet.ShouldProcess($zipFile, "Estrazione archivio")) {
    Expand-Archive -LiteralPath $zipFile -DestinationPath $outDest
    rm $zipFile
  }

  $extractedDir = (Join-Path $outDest -ChildPath "$($repo.Name)$zipSuffix")
  if ($PSCmdlet.ShouldProcess($extractedDir, "Ridenominazione directory estratta")) {
    if ($repo.RenameFolder) {
      mv $extractedDir (Join-Path (Split-Path -Parent $extractedDir) $repo.RenameFolder)
    }
  }
}

Write-Host -ForegroundColor Green 'Tutto pronto per iniziare!'

if ($PSCmdlet.ShouldProcess("Conferma di avvio")) {
  $shouldRunSetup = Read-Host -Prompt 'Avviare la configurazione del sistema? [S/N]'
} else {
  $shouldRunSetup = 's'
}

if ($shouldRunSetup -match '[sSyY]') {
  if ($setup.RenameFolder) {
    $setupPath = Join-Path $setup.Dest $setup.RenameFolder
  } else {
    $setupPath = Join-Path $setup.Dest $setup.Name
  }
  $script = Join-Path $setupPath 'Setup.ps1'

  if ($dotfiles.RenameFolder) {
    $dotfilesPath = Join-Path $dotfiles.Dest $dotfiles.RenameFolder
  } else {
    $dotfilesPath = Join-Path $dotfiles.Dest $dotfiles.Name
  }
  $configuration = Join-Path $dotfilesPath 'setup-config.json'

  if ($PSCmdlet.ShouldProcess(@($script, $configuration) -join ';', "Risoluzione percorso assoluto")) {
    $script, $configuration = Resolve-Path $script, $configuration -ErrorAction Stop
  }

  $scriptArgs = '-NoProfile', $script, '-Config', $configuration, '-Dotfiles', $dotfilesPath

  if ($PSCmdlet.ShouldProcess($scriptArgs, "Avvio processo di installazione come amministratore")) {
    Write-Host -ForegroundColor Green 'Inizio installazione.'
    Start-Process powershell.exe -Verb runas -ArgumentList $scriptArgs
  }
}
