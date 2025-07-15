function Import-Settings {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    $Programs,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $Path
  )

  Write-Verbose ("Lista programmi:", (ConvertTo-Json $Programs) -join ' ')
  Write-Verbose "Percorso configurazione: $Path"

  # Validazione directory configurazione
  if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Error "'$Path' non è una directory valida!"
    return
  }

  Write-Verbose ("Chiavi di `$Programs: ", (ConvertTo-Json $Programs.PSObject.Properties.Name) -join ' ')

  $programDirNames = $Programs.PSObject.Properties.Name

  # per ogni programma
  foreach ($program in $programDirNames) {
    $programSrcDir = (Join-Path -Path $Path -ChildPath $program | Resolve-Path)

    if (Test-Path -Path $programSrcDir -PathType Container) {
      $targetList = $Programs.$program

      # Write-Verbose "Lista programmi: $targetList"

      # per ogni regola
      foreach ($target in $targetList) {
        $fileRegex = $target.name
        $absRootDir = Get-Item -Path ("Env:\" + $target.root) | Select-Object -ExpandProperty Value
        $linkDestDir = Join-Path $absRootDir $target.destination

        # crea la cartella se non esiste
        if (-not (Test-Path -PathType Container -Path $linkDestDir)) {
          if ($PSCmdlet.ShouldProcess($linkDestDir, "Creazione directory")) {
            New-Item -ItemType Directory -Path $linkDestDir
          }
        } else {
          Write-Verbose "Il percorso '$linkDestDir' esiste, non lo sovrascrivo."
        }

        # ottieni nomi file
        $targetFiles = Resolve-Path "$programSrcDir" `
          | Get-ChildItem `
          | Where-Object { $_.Name -match "$fileRegex" } `
          | Select-Object -ExpandProperty Name

        Write-Verbose "File da linkare: $targetFiles"

        # per ogni nome file che corrisponde alla regola
        foreach ($fileName in $targetFiles) {
          $programAbsPath = Join-Path -Path $programSrcDir -ChildPath $fileName | Resolve-Path 
          $linkTargetPath = Join-Path -Path $linkDestDir -ChildPath $fileName

          Write-Host -ForegroundColor Blue "[${fileName}]: '$programAbsPath' => '$linkTargetPath'"

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
