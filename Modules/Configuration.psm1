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

  # Nomi delle cartelle corrispondenti ai nomi dei software di cui si vuole importare la configurazione
  $softwareConfigDirNames = $Programs.PSObject.Properties.Name

  if ($softwareConfigDirNames.Length -eq 0) {
    Write-Host -ForegroundColor Magenta 'Nessuna configurazione da importare.'
  }

  foreach ($configName in $softwareConfigDirNames) {
    $configAbsolutePath = Join-Path -Path $Path -ChildPath $configName | Resolve-Path

    if (Test-Path -Path $configAbsolutePath -PathType Container) {
      $targetList = $Programs.$configName

      # Per ogni bersaglio indicato per un certo software
      # trovo gli elementi che corrispondono all'espressione regolare fornita e la destinazione ad essi associata
      foreach ($target in $targetList) {
        $targetRegex = $target.name
        $linkBasePath = Get-Item -Path ("Env:\" + $target.root) | Select-Object -ExpandProperty Value
        $linkDestinationDir = Join-Path $linkBasePath $target.destination

        # Creo la cartella di destinazione se non esiste
        if (-not (Test-Path -PathType Container -Path $linkDestinationDir)) {
          if ($PSCmdlet.ShouldProcess($linkDestinationDir, "Creazione directory")) {
            New-Item -ItemType Directory -Path $linkDestinationDir
          }
        } else {
          Write-Verbose "Il percorso '$linkDestinationDir' esiste, non lo sovrascrivo."
        }

        # Ottengo i nomi degli oggetti
        $itemsToBeLinked = Resolve-Path "$configAbsolutePath" `
          | Get-ChildItem `
          | Where-Object { $_.Name -match "$targetRegex" } `
          | Select-Object -ExpandProperty Name

        Write-Verbose "Oggetti da linkare: $itemsToBeLinked"

        # Collegamento simbolico degli oggetti trovati
        foreach ($itemName in $itemsToBeLinked) {
          $itemAbsolutePath = Join-Path -Path $configAbsolutePath -ChildPath $itemName | Resolve-Path 
          $linkTargetPath = Join-Path -Path $linkDestinationDir -ChildPath $itemName

          Write-Host -ForegroundColor Blue "[${itemName}]: '$itemAbsolutePath' => '$linkTargetPath'"

          if ($PSCmdlet.ShouldProcess($itemName, "Collegamento simbolico")) {
            New-Item -Path $linkTargetPath -Value $itemAbsolutePath -ItemType SymbolicLink -Force
          }
        }
      }
    } else {
      Write-Error "Impossibile trovare le impostazioni di '$configName'"
    }
  }
}

Export-ModuleMember -Function Import-Settings
