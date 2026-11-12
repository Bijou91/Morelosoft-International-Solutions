# sprites_lluvia.ps1 - Sprites de Lluvia de Requerimientos (Tormenta en la oficina).
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'PixelArt.psm1') -Force
$dir = Join-Path $PSScriptRoot '..\..\assets\ing_software\lluvia_requerimientos'
$artDir = 'C:\Users\karol\.gemini\antigravity\brain\5b92e813-8ada-4699-86a6-afde71be419f'
Write-Host "== Sprites Lluvia de Requerimientos =="

# Fondo cuantizado desde imagen IA (180x320 nativo -> 360x640 a escala x2)
$bgSrc = Get-ChildItem -Path $artDir -Filter 'bg_storm_city*.jpg' | Select-Object -First 1
if ($bgSrc) {
    Convert-ToPixelBackground $bgSrc.FullName "$dir\bg_storm_city.png" 180 320 '04789abcdef'
}

# Franja de nubes de tormenta (48x18 nativo -> 96x36)
New-Sprite "$dir\clouds_strip.png" @(
    '......000000............00000000..............',
    '....00dddddd00........00dddddddd00............',
    '..00dddddddddd00....00dddddddddddd00...00000..',
    '.0dddddddddddddd0000dddddddddddddddd000ddddd0.',
    '0dddddeeeeeeeeeeddddddeeeeeeeeeeeeeeddddddddd0',
    '0dddeeeeeeeeeeeeeeddeeeeeeeeeeeeeeeeeeddddeee0',
    '0deeeeeeffffffffeeeeeeeeeeffffffffeeeeeeeffff0',
    '.00fffffffffffffffffffffffffffffffffffffffff0.',
    '...00000000000000000000000000000000000000000..'
)

# Gota de lluvia (3x7 nativo -> 6x14)
New-Sprite "$dir\rain_drop.png" @(
    '..b',
    '.bb',
    '.aa',
    'aa.',
    'a..',
    '9..'
)

# Banqueta con charcos (32x16 nativo -> 64x32 tileable)
New-Sprite "$dir\ground_tiles.png" @(
    'cccccccccccccccccccccccccccccccc',
    'ddddddddddddddd0ddddddddddddddd0',
    'eeeeeeeeeeeeeee0eeeeeeeeeeeeeee0',
    'eeeeaaaaeeeeeee0eeeeeeeeeeeeeee0',
    'eeeaabbbaeeeeee0eeeeeeeeeeeeeee0',
    'eeeeaaaaeeeeeee0eeeeeeeeeeeeeee0',
    'fffffffffffffff0fffffffffffffff0',
    '00000000000000000000000000000000',
    'ddddddd0ddddddddddddddd0dddddddd',
    'eeeeeee0eeeeeeeeeeeeeee0eeeeeeee',
    'eeeeeee0eeeeeeeeeeeeeee0eeaaaaee',
    'eeeeeee0eeeeeeeeeeeeeee0eaabbbae',
    'eeeeeee0eeeeeeeeeeeeeee0eeaaaaee',
    'fffffff0fffffffffffffff0ffffffff',
    '00000000000000000000000000000000',
    '00000000000000000000000000000000'
)

# Tarjetas 9-slice: RF (post-it verde con esquina doblada), RNF (bloque naranja), y variantes HC
$rf = New-Canvas 14 14
Set-Rect $rf 0 0 14 14 '0'
Set-Rect $rf 1 1 12 12 '6'
Set-Rect $rf 1 1 12 1 '5'; Set-Rect $rf 1 1 1 12 '5'
Set-Rect $rf 1 12 12 1 '7'; Set-Rect $rf 12 1 1 12 '7'
# Esquina superior derecha doblada
Set-Rect $rf 10 0 4 4 '0'; Set-Rect $rf 10 1 3 3 '5'; Set-Px $rf 13 0 '.'; Set-Px $rf 12 0 '.'; Set-Px $rf 13 1 '.'
Save-Canvas $rf "$dir\card_rf_9.png"

New-BevelPanel "$dir\card_rnf_9.png" 14 '0' '4' '2' '3' 1
New-BevelPanel "$dir\card_rf_hc_9.png" 14 '0' 'p' '0' 'o' 2
New-BevelPanel "$dir\card_rnf_hc_9.png" 14 '0' 'r' '0' 'q' 2

# Iconos de tarjeta: engranaje (RF) y cronómetro (RNF) (10x10 -> 20x20)
New-Sprite "$dir\icon_gear.png" @(
    '....00....',
    '.00.cc.00.',
    '0cc0cc0cc0',
    '.0cccccc0.',
    '0ccc00ccc0',
    '0ccc00ccc0',
    '.0cccccc0.',
    '0cc0cc0cc0',
    '.00.cc.00.',
    '....00....'
)
New-Sprite "$dir\icon_stopwatch.png" @(
    '...0440...',
    '....00....',
    '..000000..',
    '.0cccccc0.',
    '0ccc02ccc0',
    '0ccc0cccc0',
    '0cccccccc0',
    '.0cccccc0.',
    '..000000..',
    '..........'
)

# Caja BACKLOG (45x20 nativo -> 90x40, coincide exacto con CART_WIDTH x CART_HEIGHT)
$crate = New-Canvas 45 20
Set-Rect $crate 0 0 45 20 '0'
Set-Rect $crate 1 1 43 18 'i'
# Marco de madera claro y sombra inferior
Set-Rect $crate 1 1 43 2 'j'; Set-Rect $crate 1 17 43 2 'h'
Set-Rect $crate 1 1 3 18 'j'; Set-Rect $crate 41 1 3 18 'h'
# Listones horizontales y remaches
Set-Rect $crate 4 6 37 1 'h'; Set-Rect $crate 4 13 37 1 'h'
foreach ($rx in @(2, 42)) { foreach ($ry in @(2, 9, 17)) { Set-Px $crate $rx $ry 'g' } }
# Etiqueta central oscura con letras pixel "BACKLOG" (7 letras de 3x5 -> 27 px)
Set-Rect $crate 7 7 31 7 'g'
$lbl = @(
    'jj.jjj.jjj.j.j.j...jjj.jjj',
    'j.j.j.j.j...j.j.j...j.j.j..',
    'jj..jjj.j...jj..j...j.j.j.j',
    'j.j.j.j.j...j.j.j...j.j.j.j',
    'jj..j.j.jjj.j.j.jjj.jjj.jjj'
)
Set-Grid $crate $lbl 9 8
Save-Canvas $crate "$dir\backlog_crate.png"

# Desarrollador chibi (20x18 nativo -> 40x36) con los brazos arriba sosteniendo la caja
$devHead = @(
    '....000000000000....',
    '...0gggggggggggg0...',
    '..0gggggggggggggg0..',
    '..0ggkkkkkkkkkkgg0..',
    '.0f00aa00kk00aa00f0.',
    '.0f0aaaa0000aaaa0f0.',
    '.0f000000kk000000f0.',
    '0ff0kkkkkkkkkkkk0ff0',
    '0ff0kkkk0000kkkk0ff0',
    '.00f0000ffff0000f00.',
    '..0ffffffffffffff0..',
    '..0fffffcffcf0fff0..',
    '...0ffffffffffff0...'
)
$feet0 = @(
    '....099990099990....',
    '....099990099990....',
    '....000000000000....'
)
$feet1 = @(
    '...099990..099990...',
    '...000000..099990...',
    '...........000000...'
)
$feet2 = @(
    '...099990..099990...',
    '...099990..000000...',
    '...000000...........'
)
New-Sprite "$dir\dev_carry_0.png" ($devHead + $feet0)
New-Sprite "$dir\dev_carry_1.png" ($devHead + $feet1)
New-Sprite "$dir\dev_carry_2.png" ($devHead + $feet0)
New-Sprite "$dir\dev_carry_3.png" ($devHead + $feet2)

# FX: chispa de acierto y salpicadura de fallo
New-Sprite "$dir\fx_sparkle.png" @(
    '....4....',
    '....c....',
    '..4.c.4..',
    '...ccc...',
    '4ccccccc4',
    '...ccc...',
    '..4.c.4..',
    '....c....',
    '....4....'
)
New-Sprite "$dir\fx_splash.png" @(
    '.b.......b.',
    '..b..b..b..',
    '...a.b.a...',
    '.aaabbbbaaa',
    'aaaaaaaaaaa'
)

Write-Host "Listo Lluvia."

