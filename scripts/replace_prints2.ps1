$root = Resolve-Path .
$backupDir = Join-Path $root "print_replacement_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }

Get-ChildItem -Path $root -Recurse -Include *.dart | ForEach-Object {
  $path = $_.FullName
  $text = Get-Content -Path $path -Raw -ErrorAction SilentlyContinue
  if ($null -eq $text) { return }
  if ($text.Contains("print(")) {
    # backup
    $rel = $path.Substring($root.Path.Length).TrimStart('\')
    $bakPath = Join-Path $backupDir ($rel -replace '[\\]','_')
    Copy-Item -Path $path -Destination $bakPath -Force

    # add import if missing
    if (-not ($text.Contains("app_logger.dart"))) {
      $lines = $text -split "\r?\n"
      $lastImport = -1
      for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i].TrimStart().StartsWith("import ")) { $lastImport = $i }
      }
      if ($lastImport -ge 0) {
        if ($lastImport -lt ($lines.Length - 1)) {
          $before = $lines[0..$lastImport]
          $after = $lines[($lastImport + 1)..($lines.Length - 1)]
          $lines = $before + ("import 'package:smart_retail/app/utils/app_logger.dart';") + $after
        } else {
          $lines = $lines + ("import 'package:smart_retail/app/utils/app_logger.dart';")
        }
      } else {
        $lines = @("import 'package:smart_retail/app/utils/app_logger.dart';") + $lines
      }
      $text = $lines -join "`r`n"
    }

    # replace print( with getLogger('app').info(
    $new = [regex]::Replace($text, 'print\(', "getLogger('app').info(")
    if ($new -ne $text) {
      Set-Content -Path $path -Value $new -Encoding UTF8
      Write-Host "Patched: $path"
    }
  }
}
Write-Host 'Done.'
