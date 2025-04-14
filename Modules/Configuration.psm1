function Import-Settings {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    [ValidateNotNullOrEmpty()]
    $Programs,

    [string] $ConfigPath = (Resolve-Path '.'),
  )

  $PSCmdlet.ShouldProcess((ConvertTo-Json $Programs), "Visualizzazione lista programmi")
  $PSCmdlet.ShouldProcess($ConfigPath, "Visualizzazione percorso di configurazione")

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

  $PSCmdlet.ShouldProcess($Programs.PSObject.Properties.Name, "Visualizzazione chiavi di `$Programs")

  $programDirNames = $Programs.PSObject.Properties.Name

  # per ogni programma
  foreach ($program in $programDirNames) {
    $programSrcDir = (Join-Path -Path $ConfigPath -ChildPath $program | Resolve-Path)

    if (Test-Path -Path $programSrcDir -PathType Container) {
      $targetList = $Programs.$program
      $PSCmdlet.ShouldProcess($targetList, "Visualizzazione lista programmi")

      # per ogni regola
      foreach ($target in $targetList) {
        $fileRegex = $target.name
        $absRootDir = Get-Item -Path ("Env:\" + $target.root) | Select-Object -ExpandProperty Value
        $linkDestDir = Join-Path $absRootDir $target.destination

        # crea la cartella se non esiste
        if (-not (Test-Path -PathType Container -Path $linkDestDir)) {
          if ($PSCmdlet.ShouldProcess($linkDestDir, "Creazione directory")) {
            New-Item -ItemType Directory -Path "$linkDestDir"
          }
        } else {
          Write-Warning "Il percorso '$linkDestDir' esiste, non lo sovrascrivo."
        }

        # ottieni nomi file
        $targetFiles = Resolve-Path "$programSrcDir" `
          | Get-ChildItem `
          | Where-Object { $_.Name -match "$fileRegex" } `
          | Select-Object -ExpandProperty Name

        $PSCmdlet.ShouldProcess($targetFiles, "Visualizzazione file da linkare")

        # per ogni nome file che corrisponde alla regola
        foreach ($fileName in $targetFiles) {
          $programAbsPath = Join-Path -Path $programSrcDir -ChildPath $fileName | Resolve-Path 
          $linkTargetPath = Join-Path -Path $linkDestDir -ChildPath $fileName | Resolve-Path 

          $PSCmdlet.ShouldProcess($programAbsPath, "Visualizzazione percorso sorgente")
          $PSCmdlet.ShouldProcess($linkTargetPath, "Visualizzazione percorso destinazione")

          if ($PSCmdlet.ShouldProcess($fileName, "Collegamento simbolico")) {
            New-Item -Path $linkTargetPath -Value $programAbsPath -ItemType SymbolicLink -Force
          }
        }
      }
    } else {
      Write-Error "Impossibile trovare le impostazioni di '$program'"
    }
  }
}

Export-ModuleMember -Function Import-Settings
