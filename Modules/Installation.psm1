function Install-Packages {
  param(
    [string]$PackageManager = "winget",
    [string[]]$PackageList,
    [string]$Path = (Resolve-Path "Packages"),
    [bool]$Debug = $false
  )

  $cmdInfo = Get-Command $PackageManager -ErrorAction SilentlyContinue

  if ($cmdInfo -ne $null -and $cmdInfo.CommandType -eq 'Application') {
    $manager = $cmdInfo.Source

    switch ($cmdInfo.Name) {
      'winget.exe' {

        # aggiorna tutti i pacchetti già presenti
        $installCmd = "$manager upgrade --all --accept-package-agreements"

        if (-not $Debug) {
          Write-Host -ForegroundColor Green "Eseguo aggiornamento di tutti i pacchetti..."
          Invoke-Expression $installCmd
        } else {
          Write-Host -ForegroundColor Magenta "Avrei eseguito aggiornamento di tutti i pacchetti"
          Write-Host -ForegroundColor Magenta "CMD = '$installCmd'"
        }

        # installa i pacchetti mancanti
        foreach ($list in $PackageList) {
          $listFile = "$Path\$list.json"

          if (Test-Path -Path "$listFile" -PathType Leaf) {
            $installList = "$manager import -i $listFile --accept-package-agreements"

            if (-not $Debug) {
              Write-Host -ForegroundColor Green "Installo i pacchetti da '$listFile'"
              Invoke-Expression $installList
            } else {
              Write-Host -ForegroundColor Magenta "Avrei installato i pacchetti da '$listFile'"
              Write-Host -ForegroundColor Magenta "CMD = '$installList'"
            }
          } else {
            Write-Error "Impossibile trovare il backup di winget"
          }
        }

        break
      }

      default {
        Write-Error "Package manager non supportato: " + $cmdInfo.Name
      }
    }

  } else {
    Write-Error "Impossibile trovare il comando: " + $cmdInfo.Name
  }
}

Export-ModuleMember -Function Install-Packages
