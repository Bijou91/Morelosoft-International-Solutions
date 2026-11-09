## HeroForgeData.gd - Catálogo de Clases, Objetos, Atributos y Métodos para CU-12
## Morelosoft International Solutions - Materia: Introducción a la Programación (Aula 101)
## Basado en prototipos iniciales (HeroForge.png) y especificación formal de Casos de Uso
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico & Software Architect)
class_name HeroForgeData
extends RefCounted

## Tipos de componentes de POO
enum ComponentType {
	ATTRIBUTE,
	METHOD
}

## Catálogo completo de clases para la forja de héroes
const HERO_CLASSES: Array[Dictionary] = [
	{
		"id": "mago_igneo",
		"class_name": "MagoIgneo",
		"title": "Mago Ígneo",
		"concept": "Especialista arcano en piromancia. Domina el elemento Fuego y combate a pie lanzando hechizos.",
		"badge_color": Color("ff5722"), # Naranja fuego
		"avatar_symbol": "🧙‍♂️🔥",
		"target_attributes": [
			{
				"id": "attr_fuego",
				"text": "elemento = \"Fuego\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Define la naturaleza elemental del mago"
			},
			{
				"id": "attr_mana",
				"text": "mana_max = 120",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Capacidad máxima de energía arcana"
			}
		],
		"target_methods": [
			{
				"id": "meth_lanzar_fuego",
				"text": "lanzar_fuego()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Proyecta una bola de fuego destructiva"
			},
			{
				"id": "meth_recibir_dano",
				"text": "recibir_dano()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Procesa y descuenta puntos de vida al ser impactado"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_agua",
				"text": "elemento = \"Agua\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Distractor elemental incompatible con piromancia"
			},
			{
				"id": "dist_attr_blindaje",
				"text": "blindaje = \"Pesado\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Distractor de clase tanquista no propio de un mago"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_lanzar_agua",
				"text": "lanzar_agua()",
				"type": ComponentType.METHOD,
				"desc": "Distractor elemental opuesto a la clase ígnea"
			},
			{
				"id": "dist_meth_volar",
				"text": "volar()",
				"type": ComponentType.METHOD,
				"desc": "Distractor de movilidad incompatible con hechicero terrestre"
			}
		],
		"instance_lore": "¡Objeto instanciado: MagoIgneo() en memoria!\n• Atributos: elemento='Fuego', mana_max=120\n• Métodos activos: lanzar_fuego(), recibir_dano()\nEl hechicero está listo para el combate arcano."
	},
	{
		"id": "guerrero_tanque",
		"class_name": "GuerreroTanque",
		"title": "Guerrero Acorazado",
		"concept": "Defensor de primera línea con armadura pesada. Protege aliados y resiste impactos masivos.",
		"badge_color": Color("3f51b5"), # Azul acero
		"avatar_symbol": "🛡️⚔️",
		"target_attributes": [
			{
				"id": "attr_blindaje",
				"text": "blindaje = \"Placas de Acero\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Protección física de alto calibre"
			},
			{
				"id": "attr_salud",
				"text": "puntos_salud = 300",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Reserva masiva de puntos de vitalidad"
			}
		],
		"target_methods": [
			{
				"id": "meth_bloquear",
				"text": "bloquear_escudo()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Levanta el baluarte para mitigar el 80% del daño"
			},
			{
				"id": "meth_provocar",
				"text": "provocar_enemigo()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Atrae la atención de los rivales hacia sí mismo"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_sigilo",
				"text": "sigilo_porcentaje = 95",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Distractor propio de un pícaro o arquero"
			},
			{
				"id": "dist_attr_flechas",
				"text": "flechas_carcaj = 30",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Distractor de proyectiles no acorde a un tanque cuerpo a cuerpo"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_esconderse",
				"text": "esconderse_en_sombras()",
				"type": ComponentType.METHOD,
				"desc": "Habilidad de sigilo incompatible con armadura pesada"
			},
			{
				"id": "dist_meth_teletransportar",
				"text": "teletransportar()",
				"type": ComponentType.METHOD,
				"desc": "Hechizo arcano no correspondiente a un guerrero físico"
			}
		],
		"instance_lore": "¡Objeto instanciado: GuerreroTanque() en memoria!\n• Atributos: blindaje='Placas de Acero', puntos_salud=300\n• Métodos activos: bloquear_escudo(), provocar_enemigo()\nLa vanguardia defensiva ha sido consolidada."
	},
	{
		"id": "arquero_sombra",
		"class_name": "ArqueroSombra",
		"title": "Arquero Sombrío",
		"concept": "Tirador táctico de larga distancia. Se oculta en el entorno y efectúa ataques críticos certeros.",
		"badge_color": Color("4caf50"), # Verde bosque / sigilo
		"avatar_symbol": "🏹🌑",
		"target_attributes": [
			{
				"id": "attr_alcance",
				"text": "alcance_arco = 80",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Rango máximo efectivo de los disparos"
			},
			{
				"id": "attr_sigilo",
				"text": "nivel_sigilo = \"Alto\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Capacidad de camuflarse en el entorno"
			}
		],
		"target_methods": [
			{
				"id": "meth_disparar",
				"text": "disparar_flecha()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Lanza proyectil cinético con alta probabilidad de crítico"
			},
			{
				"id": "meth_camuflar",
				"text": "camuflarse()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Se vuelve invisible para los enemigos durante 5 segundos"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_combustible",
				"text": "combustible = 100",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Atributo de maquinaria, no de un ser biológico"
			},
			{
				"id": "dist_attr_oxigeno",
				"text": "tanque_oxigeno = 50",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Atributo de astronave o buzo, distractor"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_embestir",
				"text": "embestir_tanque()",
				"type": ComponentType.METHOD,
				"desc": "Ataque pesado incompatible con tirador ágil"
			},
			{
				"id": "dist_meth_reparar",
				"text": "reparar_motor()",
				"type": ComponentType.METHOD,
				"desc": "Habilidad mecánica ajena a la clase exploradora"
			}
		],
		"instance_lore": "¡Objeto instanciado: ArqueroSombra() en memoria!\n• Atributos: alcance_arco=80, nivel_sigilo='Alto'\n• Métodos activos: disparar_flecha(), camuflarse()\nEl explorador vigila el campo desde la penumbra."
	},
	{
		"id": "robot_reparador",
		"class_name": "RobotReparador",
		"title": "Androide Mecatrónico",
		"concept": "Unidad cibernética autónoma programada para dar soporte técnico y restaurar maquinaria.",
		"badge_color": Color("00bcd4"), # Cian cibernético
		"avatar_symbol": "🤖🔧",
		"target_attributes": [
			{
				"id": "attr_bateria",
				"text": "bateria_porcentaje = 100",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Nivel de energía interna almacenada"
			},
			{
				"id": "attr_so",
				"text": "sistema_operativo = \"Linux\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Kernel seguro que gestiona sus subrutinas"
			}
		],
		"target_methods": [
			{
				"id": "meth_soldar",
				"text": "soldar_circuito()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Repara pistas electrónicas y componentes dañados"
			},
			{
				"id": "meth_recargar",
				"text": "recargar_bateria()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Conecta a la red eléctrica para recuperar energía"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_rayo",
				"text": "elemento = \"Rayo\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Atributo de hechicería elemental, no cibernético"
			},
			{
				"id": "dist_attr_magia",
				"text": "fuerza_magica = 70",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Estadística mágica inaplicable a hardware robótico"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_fantasma",
				"text": "invocar_fantasma()",
				"type": ComponentType.METHOD,
				"desc": "Hechizo nigromántico incompatible con software"
			},
			{
				"id": "dist_meth_opera",
				"text": "cantar_opera()",
				"type": ComponentType.METHOD,
				"desc": "Función lúdica sin utilidad en tareas de mantenimiento"
			}
		],
		"instance_lore": "¡Objeto instanciado: RobotReparador() en memoria!\n• Atributos: bateria_porcentaje=100, sistema_operativo='Linux'\n• Métodos activos: soldar_circuito(), recargar_bateria()\nSubrutinas de diagnóstico y mantenimiento en línea."
	},
	{
		"id": "nave_exploradora",
		"class_name": "NaveExploradora",
		"title": "Vehículo Espacial",
		"concept": "Sonda espacial interestelar tripulada para cartografiar planetas y navegar galaxias.",
		"badge_color": Color("9c27b0"), # Púrpura espacial
		"avatar_symbol": "🚀🌌",
		"target_attributes": [
			{
				"id": "attr_propulsion",
				"text": "propulsion = \"Motor de Iones\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Sistema de aceleración para el vacío espacial"
			},
			{
				"id": "attr_escudos",
				"text": "escudos_termicos = 100",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Defensa contra radiación estelar y reentrada atmosférica"
			}
		],
		"target_methods": [
			{
				"id": "meth_hiperespacio",
				"text": "activar_hiperespacio()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Acelera más allá de la velocidad de la luz"
			},
			{
				"id": "meth_escanear",
				"text": "escanear_planeta()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Obtiene telemetría geológica y biológica del astro"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_caballos",
				"text": "caballos_fuerza = 150",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Medida para motores de combustión terrestre"
			},
			{
				"id": "dist_attr_espada",
				"text": "filo_espada = 90",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Atributo de arma blanca medieval, no de nave espacial"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_submarino",
				"text": "nadar_submarino()",
				"type": ComponentType.METHOD,
				"desc": "Acción náutica submarina ajena a una nave orbital"
			},
			{
				"id": "dist_meth_hierba",
				"text": "cortar_hierba()",
				"type": ComponentType.METHOD,
				"desc": "Acción doméstica incompatible con navegación interestelar"
			}
		],
		"instance_lore": "¡Objeto instanciado: NaveExploradora() en memoria!\n• Atributos: propulsion='Motor de Iones', escudos_termicos=100\n• Métodos activos: activar_hiperespacio(), escanear_planeta()\nSistemas de astronavegación listos para el despegue."
	}
]

## Configuración y parámetros por dificultad según Diagrama de Secuencia CU-12
static func get_difficulty_config(difficulty: String) -> Dictionary:
	match difficulty.to_upper():
		"FACIL":
			return {
				"name": "Fácil",
				"characters_count": 3,
				"max_lives": 5,        # 5 vidas según especificación
				"round_time": 60.0,     # 60s por personaje según especificación
				"total_score": 300,    # 300 pts totales (100 pts/personaje)
				"points_per_char": 100,
				"stars": 1,
				"classes": HERO_CLASSES.slice(0, 3)
			}
		"INGENIERO":
			return {
				"name": "Ingeniero",
				"characters_count": 5,
				"max_lives": 1,        # 1 vida según especificación
				"round_time": 30.0,     # 30s por personaje según especificación
				"total_score": 750,    # 750 pts totales (150 pts/personaje)
				"points_per_char": 150,
				"stars": 3,
				"classes": HERO_CLASSES.slice(0, 5)
			}
		_: # NORMAL por defecto
			return {
				"name": "Normal",
				"characters_count": 4,
				"max_lives": 3,        # 3 vidas según especificación
				"round_time": 45.0,     # 45s por personaje según especificación
				"total_score": 500,    # 500 pts totales (125 pts/personaje)
				"points_per_char": 125,
				"stars": 2,
				"classes": HERO_CLASSES.slice(0, 4)
			}

## Genera el banco de 8 componentes mezclados para la ronda del personaje dado
static func generate_bank_for_hero(hero_data: Dictionary) -> Array[Dictionary]:
	var bank: Array[Dictionary] = []
	
	# 2 Atributos correctos
	for attr in hero_data.target_attributes:
		var item: Dictionary = attr.duplicate()
		item["is_correct"] = true
		item["hero_id"] = hero_data.id
		bank.append(item)
		
	# 2 Métodos correctos
	for meth in hero_data.target_methods:
		var item: Dictionary = meth.duplicate()
		item["is_correct"] = true
		item["hero_id"] = hero_data.id
		bank.append(item)
		
	# 2 Distractores de Atributo
	for dist_attr in hero_data.distractor_attributes:
		var item: Dictionary = dist_attr.duplicate()
		item["is_correct"] = false
		item["expected_section"] = "ATTR" # Para validar si lo colocan en la sección incorrecta
		item["hero_id"] = hero_data.id
		bank.append(item)
		
	# 2 Distractores de Método
	for dist_meth in hero_data.distractor_methods:
		var item: Dictionary = dist_meth.duplicate()
		item["is_correct"] = false
		item["expected_section"] = "METH"
		item["hero_id"] = hero_data.id
		bank.append(item)
		
	bank.shuffle()
	return bank
