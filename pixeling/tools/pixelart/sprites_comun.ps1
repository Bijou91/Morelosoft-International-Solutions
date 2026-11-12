# sprites_comun.ps1 - Sprites compartidos por los minijuegos de Ingenieria de Software.
# Ejecutar desde cualquier carpeta:  powershell -ExecutionPolicy Bypass -File sprites_comun.ps1
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'PixelArt.psm1') -Force
$root = Join-Path $PSScriptRoot '..\..\assets\ing_software\comun'
$hud = Join-Path $root 'hud'
$ui = Join-Path $root 'ui'
Write-Host "== Sprites comunes =="

# ── HUD ──────────────────────────────────────────────────────────────────────
$heart = @(
    '.00...00.',
    '0220.0220',
    '0c2222220',
    '0c2222220',
    '.0222220.',
    '..02220..',
    '...020...',
    '....0....'
)
New-Sprite "$hud\heart_full.png" $heart
New-Sprite "$hud\heart_empty.png" ($heart | ForEach-Object { $_.Replace('2', 'f').Replace('c', 'e') })

New-Sprite "$hud\coin.png" @(
    '..0000..',
    '.044440.',
    '04c44430',
    '04c43430',
    '04c43430',
    '04443330',
    '.033330.',
    '..0000..'
)

$star = @(
    '.....00.....',
    '....0440....',
    '....0c40....',
    '000004400000',
    '0c4444444430',
    '.0c44444430.',
    '..04444430..',
    '..04444430..',
    '.0444004430.',
    '.0440..0330.',
    '000......000',
    '............'
)
New-Sprite "$hud\star_full.png" $star
New-Sprite "$hud\star_empty.png" ($star | ForEach-Object { $_.Replace('4', 'f').Replace('3', 'f').Replace('c', 'e') })

New-Sprite "$hud\hourglass.png" @(
    'hhhhhhh',
    '.0ddd0.',
    '.04440.',
    '..040..',
    '...0...',
    '..0d0..',
    '.0d4d0.',
    '.04440.',
    'hhhhhhh'
)

New-Sprite "$hud\icon_pause.png" @(
    '........',
    '.cc..cc.',
    '.cc..cc.',
    '.cc..cc.',
    '.cc..cc.',
    '.cc..cc.',
    '.cc..cc.',
    '........'
)

New-Sprite "$hud\icon_back.png" @(
    '...c....',
    '..cc....',
    '.ccccccc',
    'cccccccc',
    '.ccccccc',
    '..cc....',
    '...c....',
    '........'
)

# ── Iconos de dificultad ─────────────────────────────────────────────────────
New-Sprite "$ui\diff_facil.png" @(
    '............',
    '.666....666.',
    '65556..65556',
    '655556655556',
    '.6666666666.',
    '.....66.....',
    '.....66.....',
    '.....66.....',
    '...hhhhhh...',
    '..hiiiiiih..',
    '..hiiiiiih..',
    '...hhhhhh...'
)
New-Sprite "$ui\diff_normal.png" @(
    '.....ee.....',
    '..e..dd..e..',
    '.eeddddddee.',
    '..dddddddd..',
    '..ddd00ddd..',
    'eddd0..0ddde',
    'eddd0..0ddde',
    '..ddd00ddd..',
    '..dddddddd..',
    '.eeddddddee.',
    '..e..dd..e..',
    '.....ee.....'
)
New-Sprite "$ui\diff_ingeniero.png" @(
    '............',
    '............',
    '....0000....',
    '...044440...',
    '..0c444440..',
    '.0c44344440.',
    '.0444344440.',
    '.0444344440.',
    '000000000000',
    '044444444440',
    '033333333330',
    '000000000000'
)

# ── Paneles y botones 9-slice (grises: se tiñen con modulate en Godot) ──────
New-BevelPanel "$ui\panel_dark_9.png" 12 '0' 'e' '0' 'f' 1
New-BevelPanel "$ui\btn_normal_9.png" 10 '0' 'c' 'e' 'd' 1
New-BevelPanel "$ui\btn_pressed_9.png" 10 '0' 'e' 'd' 'd' 1
New-BevelPanel "$ui\btn_disabled_9.png" 10 'f' 'e' 'e' 'e' 1
New-BevelPanel "$ui\bar_bg_9.png" 6 '0' 'f' 'f' '0' 1 -NoCorners

Write-Host "Listo."

