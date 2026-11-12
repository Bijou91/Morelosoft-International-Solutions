# PixelArt.psm1 — Pipeline de generación de sprites pixel art para PixelIng.
# Uso: Import-Module .\PixelArt.psm1 ; New-Sprite -Out "ruta.png" -Rows @("..0..", ".000.")
# Cada carácter de las filas se traduce a un color de la paleta (ver $script:Palette).
# '.' o ' ' = transparente. No requiere Python ni Node: solo PowerShell + System.Drawing.
# Responsable: Karol Christopher Espino Galicia

Add-Type -AssemblyName System.Drawing

# ── Paleta "Sweetie-16 extendida" ─────────────────────────────────────────────
# 0-f: Sweetie-16 original (GrafxKid). g-n: extensión para madera, pergamino y pizarrón
# (Sweetie-16 no incluye cafés); coinciden con COL_WOOD / COL_BOARD / COL_CHALK del código.
$script:Palette = [ordered]@{
    '0' = '1a1c2c'; '1' = '5d275d'; '2' = 'b13e53'; '3' = 'ef7d57'
    '4' = 'ffcd75'; '5' = 'a7f070'; '6' = '38b764'; '7' = '257179'
    '8' = '29366f'; '9' = '3b5dc9'; 'a' = '41a6f6'; 'b' = '73eff7'
    'c' = 'f4f4f4'; 'd' = '94b0c2'; 'e' = '566c86'; 'f' = '333c57'
    'g' = '3b2416'; 'h' = '6b4226'; 'i' = '9c6b3c'; 'j' = 'd9a066'
    'k' = 'eedbb0'; 'l' = '1f3b2d'; 'm' = '2e5a43'; 'n' = 'e8e6d9'
    # Alto contraste (Okabe-Ito), solo para variantes _hc
    'o' = '0072b2'; 'p' = '56b4e9'; 'q' = 'd55e00'; 'r' = 'e69f00'
}

function Get-PaletteColor([char]$key) {
    $k = [string]$key
    if ($k -eq '.' -or $k -eq ' ') { return [System.Drawing.Color]::FromArgb(0, 0, 0, 0) }
    if (-not $script:Palette.Contains($k)) { throw "Caracter de paleta desconocido: '$k'" }
    $hex = $script:Palette[$k]
    return [System.Drawing.Color]::FromArgb(255,
        [Convert]::ToInt32($hex.Substring(0, 2), 16),
        [Convert]::ToInt32($hex.Substring(2, 2), 16),
        [Convert]::ToInt32($hex.Substring(4, 2), 16))
}

function Get-PaletteHexList { return @($script:Palette.Values) }

# Crea un lienzo transparente
function New-Canvas([int]$W, [int]$H) {
    $bmp = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $H; $y++) { for ($x = 0; $x -lt $W; $x++) { $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0)) } }
    return $bmp
}

# Dibuja una cuadrícula de caracteres sobre el lienzo en (OX, OY)
function Set-Grid($Bmp, [string[]]$Rows, [int]$OX = 0, [int]$OY = 0) {
    for ($y = 0; $y -lt $Rows.Count; $y++) {
        $row = $Rows[$y]
        for ($x = 0; $x -lt $row.Length; $x++) {
            $ch = $row[$x]
            if ($ch -eq '.' -or $ch -eq ' ') { continue }
            $px = $OX + $x; $py = $OY + $y
            if ($px -ge 0 -and $py -ge 0 -and $px -lt $Bmp.Width -and $py -lt $Bmp.Height) {
                $Bmp.SetPixel($px, $py, (Get-PaletteColor $ch))
            }
        }
    }
}

# Rectángulo relleno con un carácter de paleta
function Set-Rect($Bmp, [int]$X, [int]$Y, [int]$W, [int]$H, [char]$C) {
    $col = Get-PaletteColor $C
    for ($j = $Y; $j -lt $Y + $H; $j++) { for ($i = $X; $i -lt $X + $W; $i++) {
        if ($i -ge 0 -and $j -ge 0 -and $i -lt $Bmp.Width -and $j -lt $Bmp.Height) { $Bmp.SetPixel($i, $j, $col) } } }
}

function Set-Px($Bmp, [int]$X, [int]$Y, [char]$C) {
    if ($X -ge 0 -and $Y -ge 0 -and $X -lt $Bmp.Width -and $Y -lt $Bmp.Height) { $Bmp.SetPixel($X, $Y, (Get-PaletteColor $C)) }
}

# Escala de exportación: cada píxel de arte se guarda como NxN píxeles de textura.
# Con 2, los sprites se usan en Godot a tamaño natural y se ven "chunky" a 360x640.
$script:ExportScale = 2
function Set-ExportScale([int]$Factor) { $script:ExportScale = $Factor }

function Save-Canvas($Bmp, [string]$Out, [int]$Scale = 0) {
    if ($Scale -le 0) { $Scale = $script:ExportScale }
    $dir = Split-Path -Parent $Out
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if ($Scale -gt 1) {
        $big = New-Object System.Drawing.Bitmap ($Bmp.Width * $Scale), ($Bmp.Height * $Scale), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        for ($y = 0; $y -lt $Bmp.Height; $y++) { for ($x = 0; $x -lt $Bmp.Width; $x++) {
            $c = $Bmp.GetPixel($x, $y)
            for ($j = 0; $j -lt $Scale; $j++) { for ($i = 0; $i -lt $Scale; $i++) { $big.SetPixel($x * $Scale + $i, $y * $Scale + $j, $c) } }
        } }
        $Bmp.Dispose()
        $Bmp = $big
    }
    $Bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
    $Bmp.Dispose()
    Write-Host "  OK $Out"
}

# Sprite completo a partir de filas de texto (todas las filas se rellenan al ancho máximo)
function New-Sprite([string]$Out, [string[]]$Rows) {
    $rows2 = @($Rows | Where-Object { $_ -ne $null })
    $w = ($rows2 | Measure-Object -Property Length -Maximum).Maximum
    $bmp = New-Canvas $w $rows2.Count
    Set-Grid $bmp $rows2
    Save-Canvas $bmp $Out
}

# Convierte un here-string multilínea en arreglo de filas (ignora líneas vacías al inicio/fin)
function ConvertTo-Rows([string]$Text) {
    return @(($Text -split "`r?`n") | ForEach-Object { $_.TrimEnd() } | Where-Object { $_.Length -gt 0 })
}

# Panel 9-slice genérico: borde exterior, borde interior (bisel claro/oscuro) y relleno.
#   Size: lado del cuadrado; Outline/Light/Dark/Fill: caracteres de paleta
function New-BevelPanel([string]$Out, [int]$Size, [char]$Outline, [char]$Light, [char]$Dark, [char]$Fill, [int]$Bevel = 1, [switch]$NoCorners) {
    $bmp = New-Canvas $Size $Size
    Set-Rect $bmp 0 0 $Size $Size $Outline
    Set-Rect $bmp 1 1 ($Size - 2) ($Size - 2) $Fill
    for ($b = 0; $b -lt $Bevel; $b++) {
        Set-Rect $bmp 1 (1 + $b) ($Size - 2) 1 $Light            # arriba
        Set-Rect $bmp (1 + $b) 1 1 ($Size - 2) $Light            # izquierda
        Set-Rect $bmp 1 ($Size - 2 - $b) ($Size - 2) 1 $Dark     # abajo
        Set-Rect $bmp ($Size - 2 - $b) 1 1 ($Size - 2) $Dark     # derecha
    }
    if (-not $NoCorners) {
        # Esquinas recortadas (look pixel redondeado)
        $m = $Size - 1
        foreach ($p in @(@(0, 0), @($m, 0), @(0, $m), @($m, $m))) {
            $bmp.SetPixel($p[0], $p[1], [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        }
    }
    Save-Canvas $bmp $Out
}

# Reduce una imagen grande (p. ej. generada con IA) a resolución nativa y la cuantiza a la paleta.
function Convert-ToPixelBackground([string]$In, [string]$Out, [int]$W, [int]$H, [string]$Keys = '0123456789abcdefghijklmn') {
    $src = [System.Drawing.Image]::FromFile($In)
    # Recorte centrado al aspecto objetivo
    $targetAspect = $W / $H
    $srcAspect = $src.Width / $src.Height
    if ($srcAspect -gt $targetAspect) { $cw = [int]($src.Height * $targetAspect); $ch = $src.Height; $cx = [int](($src.Width - $cw) / 2); $cy = 0 }
    else { $cw = $src.Width; $ch = [int]($src.Width / $targetAspect); $cx = 0; $cy = [int](($src.Height - $ch) / 2) }
    $small = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($small)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($src, (New-Object System.Drawing.Rectangle 0, 0, $W, $H), $cx, $cy, $cw, $ch, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose(); $src.Dispose()
    $pal = @($Keys.ToCharArray() | ForEach-Object { Get-PaletteColor $_ })
    for ($y = 0; $y -lt $H; $y++) { for ($x = 0; $x -lt $W; $x++) {
        $c = $small.GetPixel($x, $y)
        $best = $pal[0]; $bd = [double]::MaxValue
        foreach ($p in $pal) {
            # Distancia ponderada por percepción (aprox. "redmean")
            $rm = ($c.R + $p.R) / 2.0
            $dr = $c.R - $p.R; $dg = $c.G - $p.G; $db = $c.B - $p.B
            $d = (2 + $rm / 256) * $dr * $dr + 4 * $dg * $dg + (2 + (255 - $rm) / 256) * $db * $db
            if ($d -lt $bd) { $bd = $d; $best = $p }
        }
        $small.SetPixel($x, $y, $best)
    } }
    Save-Canvas $small $Out
}

# Verifica que un PNG use solo colores de la paleta (o transparencia total)
function Test-PaletteCompliance([string]$Path) {
    $allowed = @{}
    foreach ($h in (Get-PaletteHexList)) { $allowed[$h.ToLower()] = $true }
    $bmp = [System.Drawing.Bitmap]::FromFile($Path)
    $bad = 0
    for ($y = 0; $y -lt $bmp.Height; $y++) { for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.A -eq 0) { continue }
        $hex = ('{0:x2}{1:x2}{2:x2}' -f $c.R, $c.G, $c.B)
        if ($c.A -ne 255 -or -not $allowed.ContainsKey($hex)) { $bad++ }
    } }
    $bmp.Dispose()
    return $bad
}

# Hoja de previsualización: todos los PNG de una carpeta (recursivo) ampliados sobre fondo oscuro.
function New-PreviewSheet([string]$Dir, [string]$Out, [int]$Zoom = 3, [int]$MaxW = 1200) {
    $files = Get-ChildItem -Path $Dir -Filter *.png -Recurse | Sort-Object FullName
    $imgs = @(); foreach ($f in $files) { $imgs += [System.Drawing.Image]::FromFile($f.FullName) }
    $pad = 12; $x = $pad; $y = $pad; $rowH = 0; $places = @()
    foreach ($im in $imgs) {
        $w = $im.Width * $Zoom; $h = $im.Height * $Zoom
        if ($w -gt $MaxW - 2 * $pad) { $z = [Math]::Max(1, [int][Math]::Floor(($MaxW - 2 * $pad) / $im.Width)); $w = $im.Width * $z; $h = $im.Height * $z }
        if ($x + $w + $pad -gt $MaxW) { $x = $pad; $y += $rowH + $pad; $rowH = 0 }
        $places += , @($im, $x, $y, $w, $h); $x += $w + $pad; if ($h -gt $rowH) { $rowH = $h }
    }
    $H = $y + $rowH + $pad
    $sheet = New-Object System.Drawing.Bitmap $MaxW, $H
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear([System.Drawing.Color]::FromArgb(255, 0x26, 0x2b, 0x44))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    foreach ($p in $places) { $g.DrawImage($p[0], (New-Object System.Drawing.Rectangle $p[1], $p[2], $p[3], $p[4])) }
    $g.Dispose(); foreach ($im in $imgs) { $im.Dispose() }
    $sheet.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $sheet.Dispose()
    Write-Host "  Preview: $Out"
}

Export-ModuleMember -Function New-PreviewSheet, Set-ExportScale, New-Canvas, Set-Grid, Set-Rect, Set-Px, Save-Canvas, New-Sprite, ConvertTo-Rows, New-BevelPanel, Convert-ToPixelBackground, Test-PaletteCompliance, Get-PaletteColor, Get-PaletteHexList
