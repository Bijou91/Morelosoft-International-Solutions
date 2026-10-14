## DataDropQuestions.gd - Banco de datos y generador de pares para CU-11 DataDrop
## Morelosoft International Solutions - Materia: Introducción a la Programación (Aula 101)
## Tipos de variables: int, float, string, bool, char, list
## Trazabilidad estricta con TSP_Morelosoft_EspecificacionCUs_v2.docx
extends RefCounted

const ALL_TYPES: Array[Dictionary] = [
	{ "type": "int", "label": "int\n(Entero)", "color": Color("00e5ff") },
	{ "type": "float", "label": "float\n(Decimal)", "color": Color("76ff03") },
	{ "type": "string", "label": "string\n(Cadena)", "color": Color("ffea00") },
	{ "type": "bool", "label": "bool\n(Booleano)", "color": Color("ff3366") },
	{ "type": "char", "label": "char\n(Carácter)", "color": Color("d500f9") },
	{ "type": "list", "label": "list\n(Lista)", "color": Color("ff6d00") }
]

const EASY_ITEMS: Array[Dictionary] = [
	{ "literal": "42", "type": "int", "desc": "Entero positivo" },
	{ "literal": "100", "type": "int", "desc": "Entero positivo" },
	{ "literal": "7", "type": "int", "desc": "Entero positivo" },
	{ "literal": "0", "type": "int", "desc": "Cero entero" },
	{ "literal": "3.14", "type": "float", "desc": "Punto flotante" },
	{ "literal": "0.5", "type": "float", "desc": "Fracción decimal" },
	{ "literal": "9.99", "type": "float", "desc": "Decimal estándar" },
	{ "literal": "\"Hola\"", "type": "string", "desc": "Texto entre comillas dobles" },
	{ "literal": "\"UAZ\"", "type": "string", "desc": "Cadena de texto" },
	{ "literal": "\"Pixel\"", "type": "string", "desc": "Cadena alfanumérica" },
	{ "literal": "True", "type": "bool", "desc": "Valor de verdad booleano" },
	{ "literal": "False", "type": "bool", "desc": "Valor de falsedad booleano" },
	{ "literal": "'a'", "type": "char", "desc": "Carácter único entre comillas simples" },
	{ "literal": "'Z'", "type": "char", "desc": "Carácter único mayúscula" },
	{ "literal": "'#'", "type": "char", "desc": "Símbolo como carácter único" },
	{ "literal": "[1, 2, 3]", "type": "list", "desc": "Lista de enteros entre corchetes" },
	{ "literal": "[\"a\", \"b\"]", "type": "list", "desc": "Lista de cadenas" },
	{ "literal": "[0, 1]", "type": "list", "desc": "Lista de dos elementos" }
]

const NORMAL_ITEMS: Array[Dictionary] = [
	{ "literal": "123", "type": "int", "desc": "Entero numérico directo" },
	{ "literal": "-15", "type": "int", "desc": "Entero negativo" },
	{ "literal": "8080", "type": "int", "desc": "Entero numérico" },
	{ "literal": "0.0", "type": "float", "desc": "Cero con decimal explícito" },
	{ "literal": "5.0", "type": "float", "desc": "Número entero con punto flotante" },
	{ "literal": "-2.5", "type": "float", "desc": "Flotante negativo" },
	{ "literal": "3.1416", "type": "float", "desc": "Flotante de precisión" },
	{ "literal": "\"123\"", "type": "string", "desc": "Dígitos entre comillas (texto)" },
	{ "literal": "\"True\"", "type": "string", "desc": "Palabra True entre comillas (texto)" },
	{ "literal": "\"3.14\"", "type": "string", "desc": "Decimal entre comillas (texto)" },
	{ "literal": "\"x\"", "type": "string", "desc": "Cadena de texto con comillas dobles" },
	{ "literal": "True", "type": "bool", "desc": "Booleano literal verdadero" },
	{ "literal": "False", "type": "bool", "desc": "Booleano literal falso" },
	{ "literal": "'1'", "type": "char", "desc": "Dígito entre comillas simples (char)" },
	{ "literal": "'x'", "type": "char", "desc": "Letra entre comillas simples (char)" },
	{ "literal": "'@'", "type": "char", "desc": "Símbolo entre comillas simples (char)" },
	{ "literal": "' '", "type": "char", "desc": "Espacio como carácter (char)" },
	{ "literal": "[]", "type": "list", "desc": "Lista vacía entre corchetes" },
	{ "literal": "[123]", "type": "list", "desc": "Lista con un entero" },
	{ "literal": "[True, False]", "type": "list", "desc": "Lista de booleanos" }
]

const INGENIERO_ITEMS: Array[Dictionary] = [
	{ "literal": "-9999", "type": "int", "desc": "Entero negativo grande" },
	{ "literal": "404", "type": "int", "desc": "Código numérico entero" },
	{ "literal": "-1", "type": "int", "desc": "Entero negativo" },
	{ "literal": "1e-3", "type": "float", "desc": "Notación científica (0.001)" },
	{ "literal": "2.5e2", "type": "float", "desc": "Notación científica (250.0)" },
	{ "literal": "-0.007", "type": "float", "desc": "Flotante negativo pequeño" },
	{ "literal": "-10.0", "type": "float", "desc": "Punto flotante negativo" },
	{ "literal": "\"\"", "type": "string", "desc": "Cadena de texto vacía" },
	{ "literal": "\" \"", "type": "string", "desc": "Cadena con un espacio" },
	{ "literal": "\"False\"", "type": "string", "desc": "False textual entre comillas" },
	{ "literal": "\"[1, 2]\"", "type": "string", "desc": "Lista dentro de comillas (texto)" },
	{ "literal": "\"-42\"", "type": "string", "desc": "Entero dentro de comillas (texto)" },
	{ "literal": "True", "type": "bool", "desc": "Booleano literal verdadero" },
	{ "literal": "False", "type": "bool", "desc": "Booleano literal falso" },
	{ "literal": "'\\n'", "type": "char", "desc": "Salto de línea como carácter" },
	{ "literal": "'\\t'", "type": "char", "desc": "Tabulador como carácter" },
	{ "literal": "'0'", "type": "char", "desc": "Cero como carácter simple" },
	{ "literal": "'\"'", "type": "char", "desc": "Comilla doble como carácter simple" },
	{ "literal": "[[]]", "type": "list", "desc": "Lista que contiene una lista vacía" },
	{ "literal": "[1, \"a\", True]", "type": "list", "desc": "Lista heterogénea" },
	{ "literal": "[-5, 0]", "type": "list", "desc": "Lista de enteros con negativo" },
	{ "literal": "[\"1\", \"2\"]", "type": "list", "desc": "Lista de cadenas" }
]

## Configuración y parámetros por dificultad según TSP_Morelosoft_EspecificacionCUs_v2.docx
static func get_difficulty_config(difficulty: String) -> Dictionary:
	match difficulty.to_upper():
		"FACIL":
			return {
				"name": "Fácil",
				"pairs_count": 4,
				"max_lives": 5,      # 5 vidas según especificación
				"time_limit": 60.0,   # 60 segundos según especificación
				"base_score": 300,   # 300 puntos según especificación
				"pool": EASY_ITEMS
			}
		"INGENIERO":
			return {
				"name": "Ingeniero",
				"pairs_count": 8,
				"max_lives": 1,      # 1 vida según especificación
				"time_limit": 15.0,   # 15 segundos según especificación
				"base_score": 765,   # 765 puntos según especificación
				"pool": INGENIERO_ITEMS
			}
		_: # NORMAL por defecto
			return {
				"name": "Normal",
				"pairs_count": 6,
				"max_lives": 3,      # 3 vidas según especificación
				"time_limit": 30.0,   # 30 segundos según especificación
				"base_score": 520,   # 520 puntos según especificación
				"pool": NORMAL_ITEMS
			}

## Genera un conjunto equilibrado de pares de prueba
static func generate_round_pairs(difficulty: String) -> Array[Dictionary]:
	var config := get_difficulty_config(difficulty)
	var pool: Array[Dictionary] = config.pool.duplicate()
	pool.shuffle()

	var count: int = config.pairs_count
	var all_type_names: Array[String] = ["int", "float", "string", "bool", "char", "list"]
	all_type_names.shuffle()

	var selected: Array[Dictionary] = []

	# 1. Asegurar variedad de tipos en la ronda
	for req_type in all_type_names:
		if selected.size() >= count:
			break
		for item in pool:
			if item.type == req_type and not selected.has(item):
				selected.append(item.duplicate())
				break

	# 2. Rellenar hasta el total de pares requerido
	for item in pool:
		if selected.size() >= count:
			break
		if not selected.has(item):
			selected.append(item.duplicate())

	# 3. Barajar el orden final para la columna izquierda
	selected.shuffle()
	return selected
