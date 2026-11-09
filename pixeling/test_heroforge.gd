extends Node

# Script de Pruebas Sintéticas Automatizadas para CU-12 (HeroForge)
# Proyecto PixelIng - Morelosoft International Solutions
# Responsable: Carlos Manuel Aguirre Norato (Líder Técnico & Software Architect)

const HeroForgeData = preload("res://scenes/minigames/programacion/heroforge/HeroForgeData.gd")

var tests_passed: int = 0
var tests_failed: int = 0
var results: Array[Dictionary] = []

func _ready() -> void:
	print("======================================================================")
	print("INICIANDO PRUEBAS SINTÉTICAS AUTOMATIZADAS: CU-12 (HEROFORGE)")
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
	var scene_res = load("res://scenes/minigames/programacion/heroforge/HeroForge.tscn")
	if not scene_res:
		printerr("ERROR CRÍTICO: No se pudo cargar HeroForge.tscn")
		get_tree().quit(1)
		return

	var game = scene_res.instantiate()
	add_child(game)
	await get_tree().process_frame

	# --------------------------------------------------------------------------
	# TU-001: Despliegue de Instrucciones de POO (Paso 1)
	# --------------------------------------------------------------------------
	var t1_ok = (game.screen_start.visible and game.container_instructions.visible and not game.container_difficulty.visible)
	_assert_test("TU-001", "Paso 1: Instrucciones de POO", "Muestra conceptos de Clase, Objeto, Atributos y Métodos", t1_ok)

	# --------------------------------------------------------------------------
	# TU-002: Transición a Selección de Dificultad (Paso 2)
	# --------------------------------------------------------------------------
	game._show_difficulty_step()
	var t2_ok = (not game.container_instructions.visible and game.container_difficulty.visible)
	_assert_test("TU-002", "Paso 2: Selector de Dificultad", "Oculta instrucciones y despliega selector y resumen", t2_ok)

	# --------------------------------------------------------------------------
	# TU-003: Configuración de Dificultad Fácil (3 personajes, 5 vidas, 60s, 300 pts)
	# --------------------------------------------------------------------------
	game._select_difficulty("FACIL")
	var t3_ok = (game.diff_config.characters_count == 3 and game.diff_config.max_lives == 5 and game.diff_config.round_time == 60.0 and game.diff_config.total_score == 300)
	_assert_test("TU-003", "Configuración Fácil", "3 héroes, 5 vidas, 60s, 300 pts", t3_ok,
		"Personajes: %d, Vidas: %d, Tiempo: %.1f, Pts: %d" % [game.diff_config.characters_count, game.diff_config.max_lives, game.diff_config.round_time, game.diff_config.total_score])

	# --------------------------------------------------------------------------
	# TU-004: Configuración de Dificultad Normal (4 personajes, 3 vidas, 45s, 500 pts)
	# --------------------------------------------------------------------------
	game._select_difficulty("NORMAL")
	var t4_ok = (game.diff_config.characters_count == 4 and game.diff_config.max_lives == 3 and game.diff_config.round_time == 45.0 and game.diff_config.total_score == 500)
	_assert_test("TU-004", "Configuración Normal", "4 héroes, 3 vidas, 45s, 500 pts", t4_ok,
		"Personajes: %d, Vidas: %d, Tiempo: %.1f, Pts: %d" % [game.diff_config.characters_count, game.diff_config.max_lives, game.diff_config.round_time, game.diff_config.total_score])

	# --------------------------------------------------------------------------
	# TU-005: Configuración de Dificultad Ingeniero (5 personajes, 1 vida, 30s, 750 pts)
	# --------------------------------------------------------------------------
	game._select_difficulty("INGENIERO")
	var t5_ok = (game.diff_config.characters_count == 5 and game.diff_config.max_lives == 1 and game.diff_config.round_time == 30.0 and game.diff_config.total_score == 750)
	_assert_test("TU-005", "Configuración Ingeniero", "5 héroes, 1 vida, 30s, 750 pts", t5_ok,
		"Personajes: %d, Vidas: %d, Tiempo: %.1f, Pts: %d" % [game.diff_config.characters_count, game.diff_config.max_lives, game.diff_config.round_time, game.diff_config.total_score])

	# --------------------------------------------------------------------------
	# TU-006: FN-01 - Confirmar Inicio de Partida en Normal
	# --------------------------------------------------------------------------
	game._select_difficulty("NORMAL")
	game._on_start_pressed()
	await get_tree().process_frame
	var t6_ok = (game.screen_game.visible and game.current_lives == 3 and game.hero_classes_queue.size() == 4 and game.is_timer_running)
	_assert_test("TU-006", "FN-01: Inicio de Partida", "Despliega mesa de forja con 3 vidas, héroe 1/4 y reloj activo", t6_ok)

	# --------------------------------------------------------------------------
	# TU-007: FN-02 - Carga del Héroe 1 (MagoIgneo) y Banco de 8 Componentes
	# --------------------------------------------------------------------------
	var t7_ok = (game.current_hero.class_name == "MagoIgneo" and game.bank_items.size() == 8)
	_assert_test("TU-007", "FN-02: Carga MagoIgneo", "Carga especificación de clase y 8 componentes en el banco", t7_ok)

	# --------------------------------------------------------------------------
	# TU-008: FA-02.01 - Suspensión de Partida (Pausa y Reanudación)
	# --------------------------------------------------------------------------
	game._on_pause_pressed()
	var t8_a = (game.is_game_paused and game.screen_pause.visible)
	game._on_resume_pressed()
	var t8_b = (not game.is_game_paused and not game.screen_pause.visible)
	_assert_test("TU-008", "FA-02.01: Pausa y Reanudación", "Congela y restaura la actividad de juego", t8_a and t8_b)

	# --------------------------------------------------------------------------
	# TU-009: FA-03.01 - Instanciación con Plantilla Incompleta (sin descontar vidas)
	# --------------------------------------------------------------------------
	var lives_before_incomplete = game.current_lives
	game._on_instantiate_pressed()
	var t9_ok = (game.current_lives == lives_before_incomplete and game.status_banner_lbl.text.contains("Plantilla incompleta"))
	_assert_test("TU-009", "FA-03.01: Plantilla Incompleta", "Muestra advertencia didáctica sin restar vidas", t9_ok)

	# --------------------------------------------------------------------------
	# TU-010: FN-02 - Asignación Interactiva y FA-02.02 - Remoción al Banco
	# --------------------------------------------------------------------------
	var sample_item = game.bank_items[0]
	game._on_component_assigned(sample_item)
	var t10_assigned = game._is_item_assigned(sample_item.id)
	
	if sample_item.type == HeroForgeData.ComponentType.ATTRIBUTE:
		game._on_component_removed("ATTR", 0)
	else:
		game._on_component_removed("METH", 0)
	var t10_removed = (not game._is_item_assigned(sample_item.id))
	_assert_test("TU-010", "FN-02 / FA-02.02: Asignar y Remover", "Asigna al slot correspondiente y permite retirar sin penalización", t10_assigned and t10_removed)

	# --------------------------------------------------------------------------
	# TU-011: FA-04.01 - Clasificación Errónea o Distractor (descuenta 1 vida)
	# --------------------------------------------------------------------------
	var curr_h = game.current_hero
	# Asignamos 1 distractor en atributos y componentes válidos en los demás
	game.assigned_attributes[0] = curr_h.distractor_attributes[0].duplicate()
	game.assigned_attributes[0]["is_correct"] = false
	game.assigned_attributes[0]["expected_section"] = "ATTR"
	game.assigned_attributes[1] = curr_h.target_attributes[1].duplicate()
	game.assigned_attributes[1]["is_correct"] = true
	game.assigned_attributes[1]["expected_section"] = "ATTR"
	game.assigned_methods[0] = curr_h.target_methods[0].duplicate()
	game.assigned_methods[0]["is_correct"] = true
	game.assigned_methods[0]["expected_section"] = "METH"
	game.assigned_methods[1] = curr_h.target_methods[1].duplicate()
	game.assigned_methods[1]["is_correct"] = true
	game.assigned_methods[1]["expected_section"] = "METH"

	game._on_instantiate_pressed()
	var t11_ok = (game.current_lives == 2 and game.status_banner_lbl.text.contains("Error en la Clase"))
	_assert_test("TU-011", "FA-04.01: Penalización por Distractor", "Detecta error en clase y descuenta 1 vida (quedan 2)", t11_ok)

	# --------------------------------------------------------------------------
	# TU-012: FN-05 / FN-06 - Instanciación Exitosa de MagoIgneo
	# --------------------------------------------------------------------------
	game.assigned_attributes[0] = curr_h.target_attributes[0].duplicate()
	game.assigned_attributes[0]["is_correct"] = true
	game.assigned_attributes[0]["expected_section"] = "ATTR"

	game._on_instantiate_pressed()
	await get_tree().process_frame
	var t12_ok = (game.modal_instance_overlay.visible and game.total_score == 125)
	_assert_test("TU-012", "FN-05: Instanciación Exitosa", "Genera objeto, otorga 125 pts y despliega modal del héroe", t12_ok)

	# --------------------------------------------------------------------------
	# TU-013: FN-06 - Avance al Segundo Reto (GuerreroTanque)
	# --------------------------------------------------------------------------
	game._on_next_hero_pressed()
	await get_tree().process_frame
	var t13_ok = (game.current_hero_index == 1 and game.current_hero.class_name == "GuerreroTanque" and not game.modal_instance_overlay.visible)
	_assert_test("TU-013", "FN-06: Siguiente Reto", "Avanza al segundo héroe (GuerreroTanque) cerrando el modal", t13_ok)

	# --------------------------------------------------------------------------
	# TU-014: FA-04.02 - Tiempo Límite de Ronda Agotado
	# --------------------------------------------------------------------------
	game.time_left = 0.05
	game._on_round_timer_timeout()
	var t14_ok = (game.current_lives == 1 and game.time_left == game.round_time)
	_assert_test("TU-014", "FA-04.02: Timeout de Ronda", "Descuenta 1 vida (queda 1) y reinicia el cronómetro del reto", t14_ok)

	# --------------------------------------------------------------------------
	# TU-015: FA-04.03 - Fin de Partida por Agotamiento de Vidas (Game Over)
	# --------------------------------------------------------------------------
	game._lose_life() # Vidas llegan a 0
	game._show_game_over("Prueba de Game Over")
	var t15_ok = (game.screen_game_over.visible and not game.is_timer_running)
	_assert_test("TU-015", "FA-04.03: Game Over", "Despliega pantalla de derrota y detiene el temporizador", t15_ok)

	# --------------------------------------------------------------------------
	# TU-016: FN-07 - Victoria y Persistencia en StateManager
	# --------------------------------------------------------------------------
	game.current_lives = 3
	game.total_score = 500
	game.current_hero_index = 4
	game._handle_victory()
	await get_tree().process_frame

	var saved_data = StateManager.get_minigame_data("heroforge")
	var t16_ok = (game.screen_victory.visible and saved_data.completed and saved_data.score > 0 and saved_data.stars >= 2)
	_assert_test("TU-016", "FN-07: Victoria y Persistencia", "Registra resultado en StateManager y muestra pantalla de victoria", t16_ok,
		"Score guardado: %d, Estrellas: %d, Completado: %s" % [saved_data.score, saved_data.stars, str(saved_data.completed)])

	# --------------------------------------------------------------------------
	# TU-017: Atajo de Depuración QA (F8 / _trigger_debug_win)
	# --------------------------------------------------------------------------
	game.start_game("INGENIERO")
	await get_tree().process_frame
	game._trigger_debug_win()
	await get_tree().process_frame
	var t17_ok = (game.screen_victory.visible and not game.screen_game_over.visible)
	_assert_test("TU-017", "Modo Debug QA (F8)", "Fuerza victoria con 3 estrellas instantáneamente", t17_ok)

	# --------------------------------------------------------------------------
	# RESUMEN FINAL
	# --------------------------------------------------------------------------
	print("======================================================================")
	print("RESUMEN DE PRUEBAS HEROFORGE: %d PASADAS / %d FALLIDAS" % [tests_passed, tests_failed])
	print("======================================================================")

	game.queue_free()
	if tests_failed == 0:
		get_tree().quit(0)
	else:
		get_tree().quit(1)
