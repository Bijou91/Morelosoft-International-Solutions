# sprites_include_extend.ps1 - Sprites de Include o Extend (Pizarron UML).
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'PixelArt.psm1') -Force
$dir = Join-Path $PSScriptRoot '..\..\assets\ing_software\include_extend'
$artDir = 'C:\Users\karol\.gemini\antigravity\brain\5b92e813-8ada-4699-86a6-afde71be419f'
Write-Host "== Sprites Include / Extend =="

# Fondo muro de aula cuantizado desde imagen IA (180x320 nativo -> 360x640)
$bgSrc = Get-ChildItem -Path $artDir -Filter 'bg_classroom_wall*.jpg' | Select-Object -First 1
if ($bgSrc) {
    Convert-ToPixelBackground $bgSrc.FullName "$dir\bg_classroom_wall.png" 180 320 '0189efgh'
}

# Pizarron verde con marco grueso de madera (20x20 nativo -> 40x40, margen 9-slice = 12)
$board = New-Canvas 20 20
Set-Rect $board 0 0 20 20 '0'
Set-Rect $board 1 1 18 18 'h'
Set-Rect $board 1 1 18 1 'j'; Set-Rect $board 1 1 1 18 'j'
Set-Rect $board 1 18 18 1 'g'; Set-Rect $board 18 1 1 18 'g'
Set-Rect $board 3 3 14 14 'g'
Set-Rect $board 4 4 12 12 'l'
# Ligero brillo de gis en la pizarra
Set-Px $board 5 5 'm'; Set-Px $board 6 5 'm'; Set-Px $board 5 6 'm'
Save-Canvas $board "$dir\chalkboard_9.png"

# Repisa inferior con gises y borrador (64x8 nativo -> 128x16)
$tray = New-Canvas 64 8
Set-Rect $tray 0 4 64 4 '0'
Set-Rect $tray 1 4 62 1 'j'
Set-Rect $tray 1 5 62 2 'h'
# Gises (blanco, amarillo, azul) y borrador de fieltro
Set-Rect $tray 10 2 6 2 'n'; Set-Rect $tray 18 2 5 2 '4'; Set-Rect $tray 26 2 5 2 'b'
Set-Rect $tray 44 0 12 4 '0'; Set-Rect $tray 45 1 10 1 'j'; Set-Rect $tray 45 2 10 2 'f'
Save-Canvas $tray "$dir\chalk_tray.png"

# Elipse/capsula de gis para caso de uso (24x16 nativo -> 48x32, 9-slice margen = 12)
New-Sprite "$dir\uc_oval_9.png" @(
    '....nnnnnnnnnnnnnnnn....',
    '..nnnnnnnnnnnnnnnnnnnn..',
    '.nnnmmmmmmmmmmmmmmmmnnn.',
    '.nnmmmmmmmmmmmmmmmmmmnn.',
    'nnmmmmmmmmmmmmmmmmmmmmnn',
    'nnmmmmmmmmmmmmmmmmmmmmnn',
    'nnmmmmmmmmmmmmmmmmmmmmnn',
    'nnmmmmmmmmmmmmmmmmmmmmnn',
    'nnmmmmmmmmmmmmmmmmmmmmnn',
    'nnmmmmmmmmmmmmmmmmmmmmnn',
    'nnmmmmmmmmmmmmmmmmmmmmnn',
    'nnmmmmmmmmmmmmmmmmmmmmnn',
    '.nnmmmmmmmmmmmmmmmmmmnn.',
    '.nnnmmmmmmmmmmmmmmmmnnn.',
    '..nnnnnnnnnnnnnnnnnnnn..',
    '....nnnnnnnnnnnnnnnn....'
)

# Actor UML stickman en gis (14x24 nativo -> 28x48)
New-Sprite "$dir\chalk_actor.png" @(
    '....nnnnnn....',
    '...nn....nn...',
    '..nn......nn..',
    '..nn......nn..',
    '..nn......nn..',
    '...nn....nn...',
    '....nnnnnn....',
    '......nn......',
    '......nn......',
    '.nnnnnnnnnnnn.',
    '.nnnnnnnnnnnn.',
    '......nn......',
    '......nn......',
    '......nn......',
    '......nn......',
    '.....nnnn.....',
    '....nn..nn....',
    '...nn....nn...',
    '..nn......nn..',
    '..nn......nn..',
    '.nn........nn.',
    '..............',
    'nn.nnn.nnn.nn.',
    'n..n...n.n.n..'
)

# Nota de papel para la Regla de Negocio (14x14 nativo -> 28x28, margen 8)
$note = New-Canvas 14 14
Set-Rect $note 0 0 14 14 '0'
Set-Rect $note 1 1 12 12 'k'
Set-Rect $note 1 1 12 2 'j'
Set-Rect $note 1 12 12 1 'j'
# Chincheta roja arriba al centro
Set-Rect $note 6 0 2 2 '2'; Set-Px $note 6 0 '3'
Save-Canvas $note "$dir\paper_note_9.png"

# Globo de dialogo blanco (14x14 nativo -> 28x28, margen 8)
New-BevelPanel "$dir\speech_bubble_9.png" 14 '0' 'c' 'd' 'c' 1

# Buho profesor (24x24 nativo -> 48x48) en 3 expresiones: neutral, happy, sad
$owlTop = @(
    '......000000000000......',
    '....00ffffffffffff00....',
    '..00000000000000000000..',
    '....00ffffffffffff00..4.',
    '....0h000000000000h0..4.',
    '...0hhhiiiiiiiiiiihh0.4.',
    '..0hh00000ii00000ihhh0..',
    '..0h0ccccc00ccccc0hhh0..'
)
$eyesNeutral = @(
    '..0h0cc00c00c00cc0hhh0..',
    '..0h0cc00c00c00cc0hhh0..',
    '..0h0ccccc00ccccc0hhh0..'
)
$eyesHappy = @(
    '..0h0c000c00c000c0hhh0..',
    '..0h00c..0000..c00hhh0..',
    '..0h0ccccc00ccccc0hhh0..'
)
$eyesSad = @(
    '..0h000ccc00ccc000hhh0..',
    '..0h0cc00c00c00cc0hhh0..',
    '..0h0cccccbbccccc0hhh0..'
)
$owlBottom = @(
    '..0hh000004400000hhhh0..',
    '..0hhhhhh4334hhhhhhhh0..',
    '.0hhhhjjjj44jjjjhhhhhh0.',
    '.0hhhjjjjjjjjjjjjhhhhh0.',
    '0hhhhjjhjjjjjjhjjhhhhhh0',
    '0hhhhjjjjjhjjjjjjhhhhhh0',
    '0hhhhjjhjjjjjjhjjhhhhhh0',
    '.0hhhjjjjjjjjjjjjhhhhh0.',
    '.0hhhhjjjjjjjjjjhhhhhh0.',
    '..0hhhhhhhhhhhhhhhhhh0..',
    '...000004400004400000...',
    '.......0440..0440.......',
    '.......0000..0000.......'
)
New-Sprite "$dir\owl_neutral.png" ($owlTop + $eyesNeutral + $owlBottom)
New-Sprite "$dir\owl_happy.png"   ($owlTop + $eyesHappy   + $owlBottom)
New-Sprite "$dir\owl_sad.png"     ($owlTop + $eyesSad     + $owlBottom)

# Botones sello INCLUDE (azul) y EXTEND (morado) + iconos claros de alto contraste
New-BevelPanel "$dir\btn_include_normal_9.png"  14 '0' 'b' '8' '9' 2
New-BevelPanel "$dir\btn_include_pressed_9.png" 14 '0' '8' '9' '8' 2
New-BevelPanel "$dir\btn_extend_normal_9.png"   14 '0' '3' '0' '1' 2
New-BevelPanel "$dir\btn_extend_pressed_9.png"  14 '0' '0' '1' '1' 2

# Eslabon de cadena (14x14 -> 28x28)
New-Sprite "$dir\icon_link.png" @(
    '.......00000..',
    '......0ccccc0.',
    '.....0cc000cc0',
    '....0cc0...0c0',
    '...000c0..0cc0',
    '..0ccccc00cc0.',
    '.0cc000cccc0..',
    '.0c0..0c000...',
    '0cc0...0cc0...',
    '0cc000cc0.....',
    '.0ccccc0......',
    '..00000.......'
)

# Pieza de rompecabezas en blanco/amarillo claro para maximo contraste sobre morado
New-Sprite "$dir\icon_puzzle.png" @(
    '.....0000.....',
    '....0cccc0....',
    '....0cccc0....',
    '.00000cc00000.',
    '0cccccccccccc0',
    '0cccccccccccc0',
    '0cc00cccccccc0',
    '0cc00cccccccc0',
    '0cccccccccccc0',
    '0cccccccccccc0',
    '.000000000000.'
)

Write-Host "Listo Include/Extend."

