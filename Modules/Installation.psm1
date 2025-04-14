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
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $PackageManager,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]] $PackageList,

    [string] $PackageListPath = "Packages",
    [bool] $Debug = $false
  )

  # Validazione percorso file di installazione
  if (Test-Path $PackageListPath -PathType Container) {
    $PackageListPath = Resolve-Path $PackageListPath
  } else {
    Write-Error "Il percorso ``$PackageListPath`` non è valido."
    return
  }

  # Controllo dell'installazione del package manager
  if ($PackageManager.name -eq $null) {
    Write-Error "Il nome del package manager non è stato definito."
    return
  }

  $cmdInfo = Get-Command $PackageManager.name -ErrorAction SilentlyContinue

  if ($cmdInfo -ne $null -and $cmdInfo.CommandType -eq 'Application') {
    $manager = $cmdInfo.Source

    try {
      # Genero la stringa di parametri per il comando di aggiornamento
      $updateArgs = Parse-PackageManagerArgs -CommandList $PackageManager.actions.update
      $updateCmd = $manager, $updateArgs -join ' '
    } catch {
      Write-Error "Non è stato possibile aggiornare il sistema.", `
                  "CAUSA: errori di sintassi nel comando del package manager."
    }

    if (-not $Debug) {
      Write-Host -ForegroundColor Green "Eseguo aggiornamento di tutti i pacchetti..."
      Invoke-Expression $updateCmd
    } else {
      Write-Host -ForegroundColor Magenta "Avrei eseguito aggiornamento di tutti i pacchetti", `
                                          "CMD: $updateCmd"
    }

    # Installa i pacchetti mancanti
    foreach ($list in $PackageList) {
      $packageList = Join-Path -Path $PackageListPath -ChildPath "$list.json" | Resolve-Path

      if ($packageList -ne $null) {
        try {
          $importArgs = Parse-PackageManagerArgs `
                        -CommandList $PackageManager.actions.import `
                        -Substitute @( "$packageList" )
          $importCmd = $manager, $importArgs -join ' '
        } catch {
          Write-Error "Non è stato possibile importare i pacchetti desiderati.", `
                      "CAUSA: errori di sintassi nel comando del package manager."
        }

        if (-not $Debug) {
          Write-Host -ForegroundColor Green "Installo i pacchetti da '$packageList'"
          Invoke-Expression $importCmd
        } else {
          Write-Host -ForegroundColor Magenta "Avrei installato i pacchetti da '$packageList'"
          Write-Host -ForegroundColor Magenta "CMD: $importCmd"
        }
      } else {
        Write-Error "Impossibile trovare lista di installazione pacchetti."
      }
    }
  } else {
    Write-Error "Impossibile trovare il comando: ", $cmdInfo.Name
  }
}

Export-ModuleMember -Function Install-Packages
