# A partire da una lista di stringhe, sostituisce le variabili e
# restituisce una nuova stringa ottenuta dalla concatenazione degli
# elementi della lista
function Parse-PackageManagerArgs {
  param(
    [string[]] $CommandList,
    [string[]] $Substitute
  )

  # Cerco variabili tra i parametri e le sostituisco con i valori forniti
  for ($i=0; $i -lt $CommandList.Count; $i+=1) {
    $param = $CommandList[$i]

    # Controllo se un parametro è una variabile, ovvero se corrisponde
    # ad un numero tra `${}`
    if ($param -like '${?}') {
      $paramIndex = [int]($param -replace '[${}]')    # Ottengo indice
      $CommandList[$i] = $Substitute[$paramIndex]
    }
  }

  return ($CommandList -join ' ')
}

function Install-Packages {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $PackageManager,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]] $PackageCollections,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $CollectionType,

    [ValidateNotNullOrEmpty()]
    [string] $CollectionsPath = "$($MyInvocation.PSScriptRoot)\Packages"
  )

  # Validazione percorso file di installazione
  if (Test-Path $CollectionsPath -PathType Container) {
    $CollectionsPath = Resolve-Path $CollectionsPath
  } else {
    $CollectionsPath = "$($MyInvocation.PSScriptRoot)\Packages"
    Write-Error "Percorso '$CollectionsPath' non valido. Continuare con il percorso di default?" -ErrorAction Inquire
  }

  Write-Verbose "Collezioni individuate in: '$CollectionsPath'"

  # Controllo dell'installazione del package manager
  if ($PackageManager.name -eq $null) {
    Write-Error "Il nome del package manager non è stato definito."
    return
  }

  $cmdInfo = Get-Command $PackageManager.name -ErrorAction SilentlyContinue

  # Se il package manager è eseguibile
  if ($cmdInfo -ne $null -and $cmdInfo.CommandType -eq 'Application') {
    $manager = $cmdInfo.Source

    try {
      # Genero la stringa di parametri per il comando di aggiornamento
      $updateArgs = Parse-PackageManagerArgs -CommandList $PackageManager.actions.update
      $updateCmd = $manager, $updateArgs -join ' '
    } catch {
      Write-Error ("Non è stato possibile aggiornare il sistema." + `
                  "CAUSA: errori di sintassi nel comando del package manager.")
    }

    if ($PSCmdlet.ShouldProcess($updateCmd, "Aggiornamento pacchetti")) {
      Invoke-Expression $updateCmd
    }

    if ($PackageCollections.Length -eq 0) {
      Write-Host -ForegroundColor Magenta 'Nessun nuovo pacchetto da installare.'
    }

    # Installa i pacchetti mancanti
    foreach ($collectionName in $PackageCollections) {
      try {
        $collectionFile = Join-Path -Path $CollectionsPath -ChildPath "$collectionName.$CollectionType" 
        $collectionFullPath = $collectionFile | Resolve-Path -ErrorAction Stop
      } catch {
        Write-Error "Impossibile trovare la lista '$collectionName' in $(Split-Path $collectionFile)"
        continue
      }

      if ($collectionFullPath -ne $null) {
        Write-Verbose "Trovata lista: '$collectionFullPath'"

        try {
          $importArgs = Parse-PackageManagerArgs `
                        -CommandList $PackageManager.actions.import `
                        -Substitute @( "$collectionFullPath" )
          $importCmd = $manager, $importArgs -join ' '
        } catch {
          Write-Error ("Non è stato possibile importare i pacchetti desiderati." + `
                      "CAUSA: errori di sintassi nel comando del package manager.")
        }

        if ($PSCmdlet.ShouldProcess($importCmd, "Installazione pacchetti")) {
          Invoke-Expression $importCmd
        }
      } else {
        Write-Error "Impossibile trovare lista di installazione pacchetti."
      }
    }
  } else {
    Write-Error ("Package manager non trovato: " + $PackageManager.Name)
  }
}

Export-ModuleMember -Function Install-Packages
