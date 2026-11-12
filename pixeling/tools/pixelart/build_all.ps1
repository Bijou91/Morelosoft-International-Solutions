# build_all.ps1 - Regenera todos los sprites de Ingenieria de Software y sus hojas de preview.
# Uso:  powershell -ExecutionPolicy Bypass -File pixeling\tools\pixelart\build_all.ps1 [-PreviewDir <carpeta>] [-Only comun,lluvia,...]
param([string]$PreviewDir = '', [string[]]$Only = @())
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'PixelArt.psm1') -Force
$assets = Join-Path $PSScriptRoot '..\..\assets\ing_software'
$jobs = [ordered]@{
    'comun'          = @('sprites_comun.ps1', 'comun')
    'lluvia'         = @('sprites_lluvia.ps1', 'lluvia_requerimientos')
    'include_extend' = @('sprites_include_extend.ps1', 'include_extend')
    'planning_poker' = @('sprites_planning_poker.ps1', 'planning_poker')
}
foreach ($k in $jobs.Keys) {
    if ($Only.Count -gt 0 -and $Only -notcontains $k) { continue }
    $script = Join-Path $PSScriptRoot $jobs[$k][0]
    if (-not (Test-Path $script)) { continue }
    & $script
    if ($PreviewDir) {
        New-Item -ItemType Directory -Force -Path $PreviewDir | Out-Null
        New-PreviewSheet (Join-Path $assets $jobs[$k][1]) (Join-Path $PreviewDir "preview_$k.png") 3 900
    }
}

# Validación de paleta
$bad = 0
foreach ($f in Get-ChildItem $assets -Filter *.png -Recurse) {
    $n = Test-PaletteCompliance $f.FullName
    if ($n -gt 0) { Write-Host "  [PALETA] $($f.Name): $n pixeles fuera de paleta"; $bad++ }
}
Write-Host "Validacion de paleta: $bad archivo(s) con colores fuera de paleta."

