$root = Resolve-Path .
$backupDir = Join-Path $root "print_replacement_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }

Get-ChildItem -Path $root -Recurse -Include *.dart | ForEach-Object {
  $path = $_.FullName
  $text = Get-Content -Path $path -Raw -ErrorAction SilentlyContinue
  if ($null -eq $text) { return }
  if ($text -match "print\(") {
    # backup
    $rel = $path.Substring($root.Path.Length).TrimStart('\')
    $bakPath = Join-Path $backupDir ($rel -replace '[\\]','_')
    Copy-Item -Path $path -Destination $bakPath -Force

    # add import if missing
    if ($text -notmatch "app_logger.dart") {
      $text = [regex]::Replace($text, "((?:import\s+['\"].+?['\"];\r?\n)+)", "$1import 'package:smart_retail/app/utils/app_logger.dart';`r`n", 1)
    }

    # replace print( with logger info
    $new = $text -replace 'print\\(', "getLogger('app').info("
    if ($new -ne $text) {
      Set-Content -Path $path -Value $new -Encoding UTF8
      Write-Host "Patched: $path"
    }
  }
}
Write-Host 'Done.'
