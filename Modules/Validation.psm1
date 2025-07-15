function Get-ConfigurationPath {
  $searchPaths = @($MyInvocation.PSScriptRoot)

  foreach ($path in $searchPaths) {
    $filePath = Join-Path $path 'setup-config.json' 
    if (Test-Path $filePath) {
      return $filePath
    }
  }

  return $false
}

Export-ModuleMember -Function Get-ConfigurationPath
