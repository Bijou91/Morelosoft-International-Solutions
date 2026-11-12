# sprites_planning_poker.ps1 - Sprites de Planning Poker (Taberna RPG).
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'PixelArt.psm1') -Force
$dir = Join-Path $PSScriptRoot '..\..\assets\ing_software\planning_poker'
$artDir = 'C:\Users\karol\.gemini\antigravity\brain\5b92e813-8ada-4699-86a6-afde71be419f'
Write-Host "== Sprites Planning Poker =="

# Fondo taberna cuantizado desde imagen IA (180x320 nativo -> 360x640)
$bgSrc = Get-ChildItem -Path $artDir -Filter 'bg_tavern*.jpg' | Select-Object -First 1
if ($bgSrc) {
    Convert-ToPixelBackground $bgSrc.FullName "$dir\bg_tavern.png" 180 320 '01234689efghijk'
}

# HUD de madera con remaches (14x14 nativo -> 28x28, margen 8)
$hud = New-Canvas 14 14
Set-Rect $hud 0 0 14 14 '0'
Set-Rect $hud 1 1 12 12 'h'
Set-Rect $hud 1 1 12 1 'i'; Set-Rect $hud 1 1 1 12 'i'
Set-Rect $hud 1 12 12 1 'g'; Set-Rect $hud 12 1 1 12 'g'
foreach ($p in @(@(2, 2), @(11, 2), @(2, 11), @(11, 11))) { Set-Px $hud $p[0] $p[1] 'd' }
Save-Canvas $hud "$dir\hud_wood_9.png"

# Pergamino de mision (18x18 nativo -> 36x36, margen 10) + sello de cera
$scr = New-Canvas 18 18
Set-Rect $scr 0 0 18 18 '0'
Set-Rect $scr 1 1 16 16 'k'
# Rollos superior e inferior
Set-Rect $scr 1 1 16 2 'j'; Set-Rect $scr 1 3 16 1 'i'
Set-Rect $scr 1 15 16 2 'j'; Set-Rect $scr 1 14 16 1 'i'
# Sombra lateral
Set-Rect $scr 1 4 1 10 'j'; Set-Rect $scr 16 4 1 10 'j'
Save-Canvas $scr "$dir\scroll_9.png"

New-Sprite "$dir\wax_seal.png" @(
    '..000000..',
    '.02222220.',
    '0232222220',
    '0222442220',
    '0224224220',
    '0222442220',
    '0222222110',
    '.02221110.',
    '..000000..'
)

# Mesa redonda de madera con vela y cartas boca abajo (96x34 nativo -> 192x68)
$tbl = New-Canvas 96 34
# Sombra elíptica y tablero de madera
for ($y = 4; $y -lt 32; $y++) {
    $dy = ($y - 17.5) / 13.5
    if ([Math]::Abs($dy) -gt 1) { continue }
    $hw = [int]([Math]::Sqrt(1 - $dy * $dy) * 44)
    for ($x = 48 - $hw; $x -le 48 + $hw; $x++) {
        $edge = ($x -eq 48 - $hw) -or ($x -eq 48 + $hw) -or ($y -eq 4) -or ($y -ge 30)
        if ($edge) { Set-Px $tbl $x $y '0' }
        elseif ($y -ge 28) { Set-Px $tbl $x $y 'g' }
        elseif ($y -le 6) { Set-Px $tbl $x $y 'j' }
        elseif (($y % 5) -eq 0) { Set-Px $tbl $x $y 'g' }
        else { Set-Px $tbl $x $y 'h' }
    }
}
# Patas
Set-Rect $tbl 18 28 5 6 'g'; Set-Rect $tbl 73 28 5 6 'g'
# 3 cartas de tarot boca abajo sobre la mesa (izquierda, centro, derecha)
foreach ($cx in @(22, 44, 66)) {
    Set-Rect $tbl $cx 10 8 11 '0'
    Set-Rect $tbl ($cx + 1) 11 6 9 '1'
    Set-Rect $tbl ($cx + 2) 12 4 7 '4'
    Set-Rect $tbl ($cx + 3) 13 2 5 '1'
}
# Vela encendida al centro-abajo
Set-Rect $tbl 46 21 4 5 'n'; Set-Rect $tbl 45 26 6 2 'd'
Set-Px $tbl 47 19 '4'; Set-Px $tbl 48 19 '3'; Set-Px $tbl 47 20 'c'
Save-Canvas $tbl "$dir\table_round.png"

# 3 aventureros chibi (18x20 nativo -> 36x40): guerrero, mago, picaro
New-Sprite "$dir\party_warrior.png" @(
    '......022220......',
    '.....02333320.....',
    '....00dddddd00....',
    '...0dccccccccd0...',
    '...0dd000000dd0...',
    '...0d0k0kk0k0d0...',
    '...0d0kkkkkk0d0...',
    '....00eeeeee00....',
    '..00dddddddddd00..',
    '.0ddccccccccdddd0.',
    '.0ddeeeeeeeeeedd0.',
    '..00dddddddddd00..',
    '....0hhhhhhhh0....',
    '....0000000000....'
)
New-Sprite "$dir\party_mage.png" @(
    '.......0000.......',
    '......011110......',
    '.....01911110.....',
    '....0191111110....',
    '..00114444441100..',
    '.0111111111111110.',
    '..0000kkkkkk0000..',
    '...0cc0kkkk0cc0...',
    '...0cccccccccc0...',
    '....0cccccccc0....',
    '..00119944991100..',
    '.0111999449991110.',
    '..00111144111100..',
    '....0000000000....'
)
New-Sprite "$dir\party_rogue.png" @(
    '.....00000000.....',
    '....0777777770....',
    '...076777777770...',
    '..07700000000770..',
    '..07005500550070..',
    '..070gkkkkkkg070..',
    '...00gggggggg00...',
    '..00777gggg77700..',
    '.077777ghhg777770.',
    '.07777ghhhhg77770.',
    '..00777777777700..',
    '....0gggggggg0....',
    '....0000000000....'
)

# Marco de carta de tarot (16x20 nativo -> 32x40, margen 9-slice = 8)
# Usamos tonos claros neutros para que se tiñan con el color de cada carta o se usen directo
$card = New-Canvas 16 20
Set-Rect $card 0 0 16 20 '0'
Set-Rect $card 1 1 14 18 '4'
Set-Rect $card 2 2 12 16 'g'
Set-Rect $card 3 3 10 14 'k'
# Adornos de esquina dorados
foreach ($p in @(@(3, 3), @(12, 3), @(3, 16), @(12, 16))) { Set-Px $card $p[0] $p[1] 'i' }
Save-Canvas $card "$dir\card_front_9.png"

$cardP = New-Canvas 16 20
Set-Rect $cardP 0 0 16 20 '0'
Set-Rect $cardP 1 1 14 18 'c'
Set-Rect $cardP 2 2 12 16 'h'
Set-Rect $cardP 3 3 10 14 'j'
Save-Canvas $cardP "$dir\card_front_pressed_9.png"

$cardD = New-Canvas 16 20
Set-Rect $cardD 0 0 16 20 '0'
Set-Rect $cardD 1 1 14 18 'e'
Set-Rect $cardD 2 2 12 16 'f'
Save-Canvas $cardD "$dir\card_front_disabled_9.png"

# Iconos de complejidad Fibonacci (12x12 nativo -> 24x24):
# 1 pluma, 2 daga, 3 escudo, 5 espada, 8 torre, 13 dragon
New-Sprite "$dir\icon_fib_1.png" @(
    '........000.',
    '......00ccc0',
    '.....0ccccc0',
    '....0ccccd0.',
    '...0ccccd0..',
    '..0ccccd0...',
    '.0cccd00....',
    '.0ccd0......',
    '.0cd0.......',
    '0j0.........',
    '00..........',
    '............'
)
New-Sprite "$dir\icon_fib_2.png" @(
    '.....00.....',
    '....0cc0....',
    '....0cd0....',
    '....0cd0....',
    '....0cd0....',
    '....0cd0....',
    '..00444400..',
    '..04333340..',
    '....0hh0....',
    '....0hh0....',
    '....0440....',
    '.....00.....'
)
New-Sprite "$dir\icon_fib_3.png" @(
    '.0000000000.',
    '044444444440',
    '049999aa9940',
    '049999aa9940',
    '049999aa9940',
    '049999aa9940',
    '.04999aa940.',
    '.04999aa940.',
    '..0499aa40..',
    '...049a40...',
    '....0440....',
    '.....00.....'
)
New-Sprite "$dir\icon_fib_5.png" @(
    '.........000',
    '........0cc0',
    '.......0ccd0',
    '......0ccd0.',
    '.....0ccd0..',
    '..000ccd0...',
    '..044cd0....',
    '...04440....',
    '..0hh0440...',
    '.0hh0.00....',
    '0440........',
    '.00.........'
)
New-Sprite "$dir\icon_fib_8.png" @(
    '.00.00.00.00',
    '0dd0dd0dd0d0',
    '0dddddddddd0',
    '.0eeeeeeee0.',
    '.0ddd00ddd0.',
    '.0ddd00ddd0.',
    '.0dddddddd0.',
    '.0eeeeeeee0.',
    '.0ddd00ddd0.',
    '0dddd00dddd0',
    '0dddd00dddd0',
    '000000000000'
)
New-Sprite "$dir\icon_fib_13.png" @(
    '.00......00.',
    '0220.00.0220',
    '023202202320',
    '023224242320',
    '.0222222220.',
    '..00233200..',
    '.0222332220.',
    '023224422320',
    '022024420220',
    '.00.0220.00.',
    '....0220....',
    '...00..00...'
)

Write-Host "Listo Planning Poker."

