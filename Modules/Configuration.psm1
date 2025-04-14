function Import-Settings {
  param(
    $Programs,
    [string]$ConfigPath = '.',
    [bool]$Debug = $false
  )

  if ($Debug) {
    Write-Host -ForegroundColor Magenta "Contenuto di '`$Programs' = "
    ConvertTo-Json $Programs | Write-Host -ForegroundColor Magenta
    Write-Host -ForegroundColor Magenta "Contenuto di '`$ConfigPath' = "
    Write-Host -ForegroundColor Magenta $ConfigPath
  }

  # Validazione directory configurazione
  if (-not (Test-Path -Path $ConfigPath -PathType Container)) {
    Write-Error "'$ConfigPath' non è una directory valida!"
    return
  }

  # Validazione lista programmi
  if ($Programs -eq $null) {
    Write-Error "Errore nella configurazione!"
    return
  }

  if ($Debug) {
    Write-Host -ForegroundColor Magenta "`$Programs = ", $Programs
    Write-Host -ForegroundColor Magenta "`$Programs.PSObject.Properties.Name = ", $Programs.PSObject.Properties.Name
  }

  $programDirNames = $Programs.PSObject.Properties.Name

  # per ogni programma
  foreach ($program in $programDirNames) {
    $programSrcDir = (Join-Path -Path $ConfigPath -ChildPath $program | Resolve-Path)

    if (Test-Path -Path $programSrcDir -PathType Container) {
      $targetList = $Programs.$program

      if ($Debug) {
        Write-Host -ForegroundColor Magenta "`$targetList = ", $targetList
      }

      # per ogni regola
      foreach ($target in $targetList) {
        $fileRegex = $target.name
        $absRootDir = Get-Item -Path ("Env:\" + $target.root) | Select-Object -ExpandProperty Value
        $linkDestDir = Join-Path $absRootDir $target.destination

        # crea la cartella se non esiste
        if (-not (Test-Path -PathType Container -Path $linkDestDir)) {
          if (-not $Debug) {
            New-Item -ItemType Directory -Path "$linkDestDir"
          } else {
            Write-Host -ForegroundColor Magenta "DEBUG: Avrei creato la directory '$linkDestDir'"
          }
        } else {
          Write-Warning "Il percorso '$linkDestDir' esiste, non lo sovrascrivo."
        }

        # ottieni nomi file
        $targetFiles = Resolve-Path "$programSrcDir" `
          | Get-ChildItem `
          | Where-Object { $_.Name -match "$fileRegex" } `
          | Select-Object -ExpandProperty Name

        if ($Debug) {
          Write-Host -ForegroundColor Magenta "`$targetFiles = ", $targetFiles
        }

        # per ogni nome file che corrisponde alla regola
        foreach ($fileName in $targetFiles) {
          $programAbsPath = Resolve-Path "$programSrcDir\$fileName"

          if (-not $Debug) {
            New-Item `
              -Path "$linkDestDir\$fileName" `
              -Value "$programAbsPath" `
              -ItemType SymbolicLink `
              -Force
          } else {
            Write-Host -ForegroundColor Magenta "DEBUG: Avrei linkato '$programAbsPath' a '$linkDestDir\$fileName'"
            Write-Host -ForegroundColor Magenta ("DEBUG: `$linkDestDir = '$absRootDir' + '" + $target.destination + "'")
          }
        }
      }
    } else {
      Write-Error "Impossibile trovare le impostazioni di '$program'"
    }
  }
}

Export-ModuleMember -Function Import-Settings
