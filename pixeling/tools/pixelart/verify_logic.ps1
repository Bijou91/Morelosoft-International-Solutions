# verify_logic.ps1 - Comprueba que las funciones de logica de los 3 minijuegos de
# Ingenieria de Software son byte-a-byte identicas a las de git HEAD.
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-FuncBodies([string]$Text) {
    $map = @{}
    $lines = $Text -split "`r?`n"
    $curName = $null; $buf = New-Object System.Collections.Generic.List[string]
    foreach ($ln in $lines) {
        if ($ln -match '^func\s+([A-Za-z0-9_]+)\s*\(') {
            if ($curName) { $map[$curName] = (($buf -join "`n").TrimEnd()) }
            $curName = $Matches[1]; $buf.Clear(); $buf.Add($ln)
        } elseif ($curName) {
            if ($ln -match '^(const |var |enum |signal |@export|# \S{10,})') {
                $map[$curName] = (($buf -join "`n").TrimEnd()); $curName = $null; $buf.Clear()
            } else { $buf.Add($ln) }
        }
    }
    if ($curName) { $map[$curName] = (($buf -join "`n").TrimEnd()) }
    return $map
}

# Funciones únicamente visuales permitidas a cambiar (según el plan de implementación §0)
$visualAllowed = @(
    '_build_ui', '_build_top_hud', '_build_timer_bar', '_build_global_timer',
    '_build_game_area', '_build_controls_hud', '_build_board', '_build_owl_section',
    '_build_answer_buttons', '_build_tavern_party', '_build_cards_section',
    '_build_overlay_difficulty', '_build_overlay_instructions', '_build_overlay_pause',
    '_build_overlay_game_over', '_build_overlay_victory',
    '_make_stylebox', '_make_pixel_box', '_make_label', '_make_button', '_make_badge',
    '_make_use_case_oval', '_make_card_button', '_make_req_stylebox',
    '_create_overlay', '_apply_accessibility_mode', '_spawn_requirement',
    '_update_hud', '_update_timer_bar',
    # Navegación de pantallas pre-partida (Instrucciones <-> Dificultad, acordado con el usuario)
    '_show_difficulty_selector', '_on_difficulty_selected', '_on_start_pressed',
    'stats_sync_stars', '_sync_owl_with_buttons', 'bsb_has_light_bg'
)

$targets = @(
    'pixeling/scenes/minigames/ing_software/lluvia_requerimientos/LluviaReqs.gd',
    'pixeling/scenes/minigames/ing_software/include_extend/IncludeExtend.gd',
    'pixeling/scenes/minigames/ing_software/planning_poker/PlanningPoker.gd'
)

$diffs = 0
foreach ($rel in $targets) {
    $headTxt = (git show "HEAD:$rel") -join "`n"
    $curTxt = [IO.File]::ReadAllText((Join-Path (Get-Location) $rel))
    $headFuncs = Get-FuncBodies $headTxt
    $curFuncs = Get-FuncBodies $curTxt
    $checked = 0
    foreach ($fn in $headFuncs.Keys) {
        if ($visualAllowed -contains $fn) { continue }
        $checked++
        if (-not $curFuncs.ContainsKey($fn)) {
            Write-Host "  [FALTA] $rel :: $fn"; $diffs++; continue
        }
        if ($headFuncs[$fn] -ne $curFuncs[$fn]) {
            Write-Host "  [CAMBIO EN LOGICA] $rel :: $fn"; $diffs++
        }
    }
    Write-Host "OK $rel : $checked funciones de logica verificadas sin cambios."
}
if ($diffs -gt 0) { throw "Se detectaron $diffs diferencia(s) en funciones de logica." }
Write-Host "Resultado: 0 diferencias en funciones de logica."

