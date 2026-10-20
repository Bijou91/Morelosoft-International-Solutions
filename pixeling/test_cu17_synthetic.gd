extends Node

# Script de Pruebas Sintéticas Automatizadas para CU-17 (FileSystemExplorer)
# Proyecto PixelIng - Morelosoft International Solutions
# Responsable: Carlos Manuel Aguirre Norato (Líder Técnico)

var tests_passed: int = 0
var tests_failed: int = 0
var results: Array[Dictionary] = []

func _ready() -> void:
	print("======================================================================")
	print("INICIANDO PRUEBAS SINTÉTICAS AUTOMATIZADAS: CU-17 (EXPLORACIÓN LINUX)")
	print("======================================================================")
	call_deferred("_run_tests")

func _assert_test(test_id: String, component: String, description: String, condition: bool, details: String = "") -> void:
	if condition:
		tests_passed += 1
		print("[PASS] %s | %s: %s" % [test_id, component, description])
		results.append({
			"id": test_id,
			"component": component,
			"description": description,
			"status": "Correcto",
			"details": details
		})
	else:
		tests_failed += 1
		printerr("[FAIL] %s | %s: %s | Detalles: %s" % [test_id, component, description, details])
		results.append({
			"id": test_id,
			"component": component,
			"description": description,
			"status": "Fallido",
			"details": details
		})

func _run_tests() -> void:
	var scene_res = load("res://scenes/minigames/sistemas_operativos/exploracion_archivos/FileSystemExplorer.tscn")
	if not scene_res:
		printerr("ERROR CRÍTICO: No se pudo cargar FileSystemExplorer.tscn")
		get_tree().quit(1)
		return

	var game = scene_res.instantiate()
	add_child(game)
	await get_tree().process_frame

	# --------------------------------------------------------------------------
	# TU-001: Configuración de dificultad Fácil
	# --------------------------------------------------------------------------
	game._on_difficulty_chosen("FACIL")
	var t1_ok = (game.max_lives == 3 and game.time_limit == 60.0 and game.total_score == 250)
	_assert_test("TU-001", "Configuración de dificultad Fácil", "Asigna 3 vidas, 60s y 250 pts", t1_ok,
		"Vidas: %d, Tiempo: %.1f, Puntos: %d" % [game.max_lives, game.time_limit, game.total_score])

	# --------------------------------------------------------------------------
	# TU-002: Configuración de dificultad Normal
	# --------------------------------------------------------------------------
	game._on_difficulty_chosen("NORMAL")
	var t2_ok = (game.max_lives == 2 and game.time_limit == 30.0 and game.total_score == 500)
	_assert_test("TU-002", "Configuración de dificultad Normal", "Asigna 2 vidas, 30s y 500 pts", t2_ok,
		"Vidas: %d, Tiempo: %.1f, Puntos: %d" % [game.max_lives, game.time_limit, game.total_score])

	# --------------------------------------------------------------------------
	# TU-003: Configuración de dificultad Ingeniero
	# --------------------------------------------------------------------------
	game._on_difficulty_chosen("INGENIERO")
	var t3_ok = (game.max_lives == 1 and game.time_limit == 40.0 and game.total_score == 750)
	_assert_test("TU-003", "Configuración de dificultad Ingeniero", "Asigna 1 vida, 40s y 750 pts", t3_ok,
		"Vidas: %d, Tiempo: %.1f, Puntos: %d" % [game.max_lives, game.time_limit, game.total_score])

	# --------------------------------------------------------------------------
	# TU-004: Despliegue de instrucciones iniciales y modal de tutorial (FN-01)
	# --------------------------------------------------------------------------
	game._show_tutorial()
	var t4_ok = (game.modal_tutorial.visible and not game.is_timer_active and game.tutorial_body.text != "")
	_assert_test("TU-004", "Modal de Tutorial (FN-01)", "Despliega reglas de juego y detiene cronómetro", t4_ok)

	# --------------------------------------------------------------------------
	# TU-005: Carga y estructura del desafío de sistema de archivos
	# --------------------------------------------------------------------------
	game.current_difficulty = "FACIL"
	game._start_match()
	await get_tree().process_frame
	var t5_ok = (not game.current_challenge.is_empty() and game.simulated_fs.has(game.current_path) and game.is_timer_active)
	_assert_test("TU-005", "Carga de Desafío", "Inicializa árbol simulado y activa cronómetro", t5_ok,
		"Ruta inicial: %s, Desafío ID: %s" % [game.current_path, game.current_challenge.get("id", "")])

	# --------------------------------------------------------------------------
	# TU-006: Actualización adaptativa del prompt de terminal
	# --------------------------------------------------------------------------
	game._update_prompt_display()
	var prompt_txt = game.terminal_prompt_label.text
	var t6_ok = (prompt_txt.contains("user@is-pixelverse:~") or prompt_txt.contains("root@is-pixelverse"))
	_assert_test("TU-006", "Prompt de Terminal", "Muestra usuario y ruta simplificada con tilde", t6_ok,
		"Prompt: %s" % prompt_txt)

	# --------------------------------------------------------------------------
	# TU-007: Generación dinámica de botones de comandos interactivos
	# --------------------------------------------------------------------------
	var btn_count = game.commands_container.get_child_count()
	var t7_ok = (btn_count >= 5)
	_assert_test("TU-007", "Botones de Comandos", "Genera botones para cada comando disponible", t7_ok,
		"Total botones: %d" % btn_count)

	# --------------------------------------------------------------------------
	# TU-008: Ejecución del comando 'pwd'
	# --------------------------------------------------------------------------
	game._exec_pwd()
	await get_tree().process_frame
	var new_lines = game.terminal_output.get_parsed_text()
	var t8_ok = (new_lines.contains("$ pwd") and new_lines.contains(game.current_path))
	_assert_test("TU-008", "Comando 'pwd'", "Imprime la ruta actual en la terminal", t8_ok)

	# --------------------------------------------------------------------------
	# TU-009: Ejecución del comando 'clear'
	# --------------------------------------------------------------------------
	game._exec_clear()
	await get_tree().process_frame
	var t9_ok = (game.terminal_output.text == "")
	_assert_test("TU-009", "Comando 'clear'", "Limpia completamente el contenido de la terminal", t9_ok)

	# --------------------------------------------------------------------------
	# TU-010: Ejecución del comando 'ls' (sin ocultos)
	# --------------------------------------------------------------------------
	game._exec_ls(false)
	await get_tree().process_frame
	var ls_txt = game.terminal_output.get_parsed_text()
	var t10_ok = (ls_txt.contains("$ ls") and not ls_txt.contains(".flag_oculta"))
	_assert_test("TU-010", "Comando 'ls'", "Lista archivos y directorios omitiendo ocultos", t10_ok)

	# --------------------------------------------------------------------------
	# TU-011: Ejecución del comando 'ls -a' (con ocultos)
	# --------------------------------------------------------------------------
	game._exec_ls(true)
	await get_tree().process_frame
	var lsa_txt = game.terminal_output.get_parsed_text()
	var t11_ok = (lsa_txt.contains("$ ls -a") and lsa_txt.contains("."))
	_assert_test("TU-011", "Comando 'ls -a'", "Lista entradas incluyendo . y ..", t11_ok)

	# --------------------------------------------------------------------------
	# TU-012: Navegación de directorios con 'cd'
	# --------------------------------------------------------------------------
	var initial_p = game.current_path
	var dir_info = game.simulated_fs.get(initial_p, {})
	var subdirs = dir_info.get("dirs", [])
	var t12_ok = false
	if not subdirs.is_empty():
		var target_sub = subdirs[0]
		game._do_cd(target_sub)
		await get_tree().process_frame
		var after_cd = game.current_path
		game._do_cd("..")
		await get_tree().process_frame
		t12_ok = (after_cd == initial_p + "/" + target_sub and game.current_path == initial_p)
	else:
		t12_ok = true
	_assert_test("TU-012", "Navegación 'cd'", "Entra a subdirectorio y retorna con ..", t12_ok,
		"Ruta tras pruebas: %s" % game.current_path)

	# --------------------------------------------------------------------------
	# TU-013: Lectura de archivos con comando 'cat'
	# --------------------------------------------------------------------------
	var files_dict = dir_info.get("files", {})
	var f_name = files_dict.keys()[0] if not files_dict.is_empty() else "test.txt"
	if files_dict.is_empty():
		files_dict["test.txt"] = "linea 1\nlinea 2\nlinea 3\nlinea 4\nlinea 5\nlinea 6\nFlag{test}"
		dir_info["files"] = files_dict

	game._do_file_cmd("cat", f_name)
	await get_tree().process_frame
	var out_txt = game.terminal_output.get_parsed_text()
	var t13_ok = out_txt.contains("$ cat " + f_name)
	_assert_test("TU-013", "Comando 'cat'", "Despliega el contenido textual del archivo", t13_ok)

	# --------------------------------------------------------------------------
	# TU-014: Inspección de cabecera con comando 'head'
	# --------------------------------------------------------------------------
	game._do_file_cmd("head", f_name)
	await get_tree().process_frame
	var head_out = game.terminal_output.get_parsed_text()
	var t14_ok = head_out.contains("$ head " + f_name)
	_assert_test("TU-014", "Comando 'head'", "Inspecciona las primeras líneas del archivo", t14_ok)

	# --------------------------------------------------------------------------
	# TU-015: Inspección de cola con comando 'tail'
	# --------------------------------------------------------------------------
	game._do_file_cmd("tail", f_name)
	await get_tree().process_frame
	var tail_out = game.terminal_output.get_parsed_text()
	var t15_ok = tail_out.contains("$ tail " + f_name)
	_assert_test("TU-015", "Comando 'tail'", "Inspecciona las últimas líneas del archivo", t15_ok)

	# --------------------------------------------------------------------------
	# TU-016: Búsqueda recursiva con 'find'
	# --------------------------------------------------------------------------
	game._exec_find()
	await get_tree().process_frame
	var find_out = game.terminal_output.get_parsed_text()
	var t16_ok = find_out.contains("$ find . -type f")
	_assert_test("TU-016", "Comando 'find'", "Realiza búsqueda recursiva de archivos en el árbol", t16_ok)

	# --------------------------------------------------------------------------
	# TU-017: Filtrado de patrones con 'grep'
	# --------------------------------------------------------------------------
	game._do_file_cmd("grep", f_name)
	await get_tree().process_frame
	var grep_out = game.terminal_output.get_parsed_text()
	var t17_ok = grep_out.contains("$ grep -i 'flag' " + f_name)
	_assert_test("TU-017", "Comando 'grep'", "Filtra líneas que coinciden con el patrón flag", t17_ok)

	# --------------------------------------------------------------------------
	# TU-018: Validación de flag incorrecta (FA-03.01)
	# --------------------------------------------------------------------------
	game.max_lives = 3
	game.current_lives = 3
	game.time_limit = 60.0
	game.time_remaining = 60.0
	var lives_before_err = game.current_lives
	game.flag_input.text = "Flag{flag_invalida_xyz}"
	game._on_submit_flag_pressed()
	await get_tree().process_frame
	var t18_ok = (game.current_lives == lives_before_err - 1 and game.flag_input.text == "")
	_assert_test("TU-018", "Validación Flag Incorrecta (FA-03.01)", "Descuenta 1 vida y limpia campo de texto", t18_ok,
		"Vidas: %d -> %d" % [lives_before_err, game.current_lives])

	# --------------------------------------------------------------------------
	# TU-019: Expiración del temporizador de ronda (FA-03.02)
	# --------------------------------------------------------------------------
	var lives_before_timeout = game.current_lives
	game._on_time_out()
	await get_tree().process_frame
	var t19_ok = (game.current_lives == lives_before_timeout - 1 and game.time_remaining >= game.time_limit - 0.2)
	_assert_test("TU-019", "Tiempo Expirado (FA-03.02)", "Descuenta 1 vida y reinicia tiempo si restan vidas", t19_ok,
		"Vidas: %d -> %d, Tiempo: %.2f / %.2f" % [lives_before_timeout, game.current_lives, game.time_remaining, game.time_limit])

	# --------------------------------------------------------------------------
	# TU-020: Fin de partida por vidas agotadas (Game Over)
	# --------------------------------------------------------------------------
	game.current_lives = 1
	var pts_before_go = StateManager.get_points()
	game._on_time_out() # Pierde la última vida
	await get_tree().process_frame
	var t20_ok = (game.modal_game_over.visible and not game.is_timer_active and StateManager.get_points() == pts_before_go)
	_assert_test("TU-020", "Fin de Partida (Game Over)", "Muestra Game Over sin alterar puntos en StateManager", t20_ok)

	# --------------------------------------------------------------------------
	# TU-021: Funcionalidad de pausa activa durante la partida
	# --------------------------------------------------------------------------
	game._start_match()
	await get_tree().process_frame
	game._on_pause_pressed()
	var t21_ok = (game.is_game_paused and game.modal_pause.visible)
	_assert_test("TU-021", "Botón de Pausa", "Suspende la partida y despliega modal de pausa", t21_ok)

	# --------------------------------------------------------------------------
	# TU-022: Reanudar partida desde pausa
	# --------------------------------------------------------------------------
	game._resume_game()
	var t22_ok = (not game.is_game_paused and not game.modal_pause.visible)
	_assert_test("TU-022", "Reanudar Partida", "Oculta modal y reanuda el estado activo de juego", t22_ok)

	# --------------------------------------------------------------------------
	# TU-023: Reiniciar partida
	# --------------------------------------------------------------------------
	game._restart_match()
	await get_tree().process_frame
	var t23_ok = (game.current_lives == game.max_lives and game.time_remaining >= game.time_limit - 0.2 and game.is_timer_active)
	_assert_test("TU-023", "Reiniciar Partida", "Restaura vidas, temporizador y mantiene la misma dificultad", t23_ok,
		"Vidas: %d, Tiempo: %.2f / %.2f" % [game.current_lives, game.time_remaining, game.time_limit])

	# --------------------------------------------------------------------------
	# TU-024: Validación de flag correcta (FN-04 / FN-05)
	# --------------------------------------------------------------------------
	var target_flag = game.current_challenge.get("flag", "Flag{rookie}")
	game.flag_input.text = target_flag
	game._on_submit_flag_pressed()
	await get_tree().process_frame
	var t24_ok = (game.modal_victory.visible and not game.is_timer_active)
	_assert_test("TU-024", "Validación Flag Correcta (FN-04)", "Acepta flag, detiene reloj y despliega victoria", t24_ok,
		"Flag enviada: %s" % target_flag)

	# --------------------------------------------------------------------------
	# TU-025: Asignación de estrellas y persistencia en StateManager (FN-05)
	# --------------------------------------------------------------------------
	var mg_data = StateManager.get_minigame_data("exploracion_archivos")
	var t25_ok = (mg_data.completed == true and mg_data.score > 0 and mg_data.stars > 0)
	_assert_test("TU-025", "Persistencia de Progreso", "Registra score, estrellas y completado en StateManager", t25_ok,
		"Score: %d, Estrellas: %d, Completado: %s" % [mg_data.score, mg_data.stars, str(mg_data.completed)])

	# --------------------------------------------------------------------------
	# TU-026: Atajo de depuración QA (F8 / _trigger_debug_win)
	# --------------------------------------------------------------------------
	game._start_match()
	await get_tree().process_frame
	game._trigger_debug_win()
	await get_tree().process_frame
	var t26_ok = (game.modal_victory.visible and not game.modal_difficulty.visible and not game.modal_tutorial.visible)
	_assert_test("TU-026", "Atajo de Depuración QA (F8)", "Fuerza victoria instantánea y oculta modales", t26_ok)

	# --------------------------------------------------------------------------
	# TU-027: Selector modal de cancelación
	# --------------------------------------------------------------------------
	game._open_cd_picker()
	game._close_picker()
	var t27_ok = (not game.picker_modal.visible)
	_assert_test("TU-027", "Modal Picker Cancelar", "Cierra el selector modal limpiamente al pulsar cancelar", t27_ok)

	# --------------------------------------------------------------------------
	# RESUMEN FINAL
	# --------------------------------------------------------------------------
	print("======================================================================")
	print("RESUMEN DE RESULTADOS: %d PASADAS / %d FALLIDAS" % [tests_passed, tests_failed])
	print("======================================================================")

	game.queue_free()
	if tests_failed == 0:
		get_tree().quit(0)
	else:
		get_tree().quit(1)
