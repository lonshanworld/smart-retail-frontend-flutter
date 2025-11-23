# Fix all DialogUtils calls that have extra parameters

$files = Get-ChildItem -Recurse lib -Filter *.dart

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    
    # Remove snackPosition parameter
    $content = $content -replace ',\s*snackPosition:\s*SnackPosition\.\w+', ''
    
    # Remove backgroundColor parameter
    $content = $content -replace ',\s*backgroundColor:\s*Colors\.\w+', ''
    
    # Remove colorText parameter  
    $content = $content -replace ',\s*colorText:\s*Colors\.\w+', ''
    
    # Remove duration parameter
    $content = $content -replace ',\s*duration:\s*(?:const\s+)?Duration\([^)]+\)', ''
    
    # Remove titleStyle parameter
    $content = $content -replace ',\s*titleStyle:\s*const\s+TextStyle\([^)]+\)', ''
    
    # Clean up trailing commas before closing parentheses
    $content = $content -replace ',\s*\)', ')'
    
    if ($content -ne $original) {
        Set-Content $file.FullName -Value $content -NoNewline
        Write-Host "✓ $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`n✅ All files processed!" -ForegroundColor Cyan
