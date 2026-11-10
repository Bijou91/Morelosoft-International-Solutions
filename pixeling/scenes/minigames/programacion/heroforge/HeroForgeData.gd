## HeroForgeData.gd - Catálogo de Clases, Objetos, Atributos y Métodos para CU-12
## Morelosoft International Solutions - Materia: Introducción a la Programación (Aula 101)
## Basado en prototipos didácticos y especificación formal de Casos de Uso
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico & Software Architect)
class_name HeroForgeData
extends RefCounted

## Tipos de componentes de POO
enum ComponentType {
	ATTRIBUTE,
	METHOD
}

## Catálogo completo de clases para la forja de héroes (Abstracciones específicas e inequívocas)
const HERO_CLASSES: Array[Dictionary] = [
	{
		"id": "mago_igneo",
		"class_name": "MagoIgneo",
		"title": "Mago Ígneo",
		"concept": "Especialista arcano en piromancia. Canaliza energía de fuego para conjurar esferas ardientes y levantar muros de llamas defensivos.",
		"badge_color": Color("ff5722"), # Naranja fuego
		"avatar_symbol": "🧙‍♂️🔥",
		"target_attributes": [
			{
				"id": "attr_elemento_fuego",
				"text": "elemento_magico = \"Fuego\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Elemento primordial que rige su magia de fuego"
			},
			{
				"id": "attr_temp_flama",
				"text": "temperatura_flama = 1500",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Intensidad calorífica de sus conjuros en grados Celsius"
			}
		],
		"target_methods": [
			{
				"id": "meth_lanzar_bola_fuego",
				"text": "lanzar_bola_fuego()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Proyecta un orbe llameante a gran distancia"
			},
			{
				"id": "meth_invocar_muro_llamas",
				"text": "invocar_muro_llamas()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Crea una barrera ígnea que calcina proyectiles"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_hielo",
				"text": "elemento_magico = \"Hielo\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Elemento criogénico incompatible con magia ígnea"
			},
			{
				"id": "dist_attr_blindaje",
				"text": "grosor_blindaje = \"50mm Acero\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Propiedad física de armadura pesada de tanque"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_chorro_agua",
				"text": "disparar_chorro_agua()",
				"type": ComponentType.METHOD,
				"desc": "Acción elemental acuática opuesta a piromancia"
			},
			{
				"id": "dist_meth_bloquear_escudo",
				"text": "bloquear_con_escudo()",
				"type": ComponentType.METHOD,
				"desc": "Acción física de defensa con escudo no arcana"
			}
		],
		"instance_lore": "¡Objeto instanciado: MagoIgneo() en memoria!\n• Atributos: elemento_magico='Fuego', temperatura_flama=1500\n• Métodos activos: lanzar_bola_fuego(), invocar_muro_llamas()\nEl hechicero arcano está listo para el combate."
	},
	{
		"id": "guerrero_tanque",
		"class_name": "GuerreroTanque",
		"title": "Guerrero Acorazado",
		"concept": "Baluarte defensivo de primera línea. Porta armadura pesada de placas de acero y un escudo colosal para bloquear impactos y embestir rivales.",
		"badge_color": Color("3f51b5"), # Azul acero
		"avatar_symbol": "🛡️⚔️",
		"target_attributes": [
			{
				"id": "attr_grosor_armadura",
				"text": "grosor_armadura = \"Placas Acero\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Blindaje pesado de aleación metálica"
			},
			{
				"id": "attr_resistencia_escudo",
				"text": "resistencia_escudo = 800",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Puntos de impacto que resiste el escudo baluarte"
			}
		],
		"target_methods": [
			{
				"id": "meth_bloquear_con_escudo",
				"text": "bloquear_con_escudo()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Mitiga daño frontal levantando el escudo hercúleo"
			},
			{
				"id": "meth_embestir_hombrera",
				"text": "embestir_con_hombrera()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Carga pesada con la armadura para aturdir al enemigo"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_sigilo",
				"text": "sigilo_camuflaje = \"Capa Sombra\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Propiedad de arquero incompatible con armadura pesada"
			},
			{
				"id": "dist_attr_combustible",
				"text": "combustible_iones = \"Xenón\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Propiedad de propulsión de una astronave cósmica"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_flecha_silente",
				"text": "disparar_flecha_silente()",
				"type": ComponentType.METHOD,
				"desc": "Ataque a distancia con arco ajeno a un combatiente cuerpo a cuerpo"
			},
			{
				"id": "dist_meth_hechizo",
				"text": "lanzar_bola_fuego()",
				"type": ComponentType.METHOD,
				"desc": "Conjuro arcano ajeno a combatientes puramente físicos"
			}
		],
		"instance_lore": "¡Objeto instanciado: GuerreroTanque() en memoria!\n• Atributos: grosor_armadura='Placas Acero', resistencia_escudo=800\n• Métodos activos: bloquear_con_escudo(), embestir_con_hombrera()\nLa línea frontal defensiva ha sido consolidada."
	},
	{
		"id": "arquero_sombra",
		"class_name": "ArqueroSombra",
		"title": "Arquero Sombrío",
		"concept": "Tirador táctico a larga distancia y maestro del sigilo. Utiliza un arco compuesto de gran tensión y una capa de camuflaje para ocultarse en las sombras.",
		"badge_color": Color("4caf50"), # Verde sombra
		"avatar_symbol": "🏹🌑",
		"target_attributes": [
			{
				"id": "attr_tension_arco",
				"text": "tension_arco_libras = 70",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Potencia de tracción de la cuerda del arco de precisión"
			},
			{
				"id": "attr_camuflaje",
				"text": "camuflaje = \"Capa de Sombras\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Vestimenta especial para fundirse en la oscuridad"
			}
		],
		"target_methods": [
			{
				"id": "meth_disparar_flecha",
				"text": "disparar_flecha_silente()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Disparo de proyectil certero sin alertar a los rivales"
			},
			{
				"id": "meth_ocultarse",
				"text": "ocultarse_en_sombras()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Activa el camuflaje reduciendo visibilidad a cero"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_bateria",
				"text": "carga_bateria = \"98% Litio\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Fuente de energía de un robot electrónico"
			},
			{
				"id": "dist_attr_reactivo",
				"text": "reactivo_base = \"Sulfuro Puro\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Insumo químico de laboratorio de un alquimista"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_soldar",
				"text": "soldar_circuito_impreso()",
				"type": ComponentType.METHOD,
				"desc": "Trabajo de ingeniería electrónica ajeno a un cazador silente"
			},
			{
				"id": "dist_meth_hiperespacio",
				"text": "activar_salto_hiperespacio()",
				"type": ComponentType.METHOD,
				"desc": "Maniobra estelar propia de una astronave"
			}
		],
		"instance_lore": "¡Objeto instanciado: ArqueroSombra() en memoria!\n• Atributos: tension_arco_libras=70, camuflaje='Capa de Sombras'\n• Métodos activos: disparar_flecha_silente(), ocultarse_en_sombras()\nEl tirador vigila silenciosamente desde la penumbra."
	},
	{
		"id": "robot_reparador",
		"class_name": "RobotReparador",
		"title": "Androide Mecatrónico",
		"concept": "Autómata cibernético de ingeniería electromecánica. Funciona con batería de litio recargable y cuenta con soplete láser para soldar circuitos impresos.",
		"badge_color": Color("00bcd4"), # Cian cibernético
		"avatar_symbol": "🤖🔧",
		"target_attributes": [
			{
				"id": "attr_bateria",
				"text": "carga_bateria = \"98% Litio\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Almacenamiento electroquímico de energía de la unidad"
			},
			{
				"id": "attr_herramienta",
				"text": "herramienta_brazo = \"Soplete Láser\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Instrumento térmico de precisión montado en su brazo"
			}
		],
		"target_methods": [
			{
				"id": "meth_soldar",
				"text": "soldar_circuito_impreso()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Repara pistas electrónicas y componentes microelectrónicos"
			},
			{
				"id": "meth_diagnostico",
				"text": "ejecutar_autodiagnostico()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Escanea integridad de memoria y sensores en busca de fallas"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_espada",
				"text": "filo_espada = \"Doble Filo\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Atributo de arma blanca de combate medieval"
			},
			{
				"id": "dist_attr_magia",
				"text": "elemento_magico = \"Viento\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Energía mística no aplicable a hardware electrónico"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_tormenta",
				"text": "conjurar_tormenta_fuego()",
				"type": ComponentType.METHOD,
				"desc": "Hechizo arcano ajeno a firmware de mantenimiento"
			},
			{
				"id": "dist_meth_disparo",
				"text": "disparar_flecha_silente()",
				"type": ComponentType.METHOD,
				"desc": "Habilidad de arquería ajena a robots de servicio técnico"
			}
		],
		"instance_lore": "¡Objeto instanciado: RobotReparador() en memoria!\n• Atributos: carga_bateria='98% Litio', herramienta_brazo='Soplete Láser'\n• Métodos activos: soldar_circuito_impreso(), ejecutar_autodiagnostico()\nSubrutinas de diagnóstico y mantenimiento en línea."
	},
	{
		"id": "nave_exploradora",
		"class_name": "NaveExploradora",
		"title": "Astronave Espacial",
		"concept": "Sonda cósmica interestelar diseñada para el vacío estelar. Equipada con motor de iones, escudos deflectores y capacidad de salto al hiperespacio.",
		"badge_color": Color("9c27b0"), # Púrpura cósmico
		"avatar_symbol": "🚀🌌",
		"target_attributes": [
			{
				"id": "attr_propulsion",
				"text": "propulsion = \"Motor de Iones\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Acelerador iónico para desplazamiento cósmico"
			},
			{
				"id": "attr_escudos",
				"text": "escudo_deflector = \"Antimateria\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Campo de dispersión contra micrometeoritos y radiación espacial"
			}
		],
		"target_methods": [
			{
				"id": "meth_hiperespacio",
				"text": "activar_salto_hiperespacio()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Curva el tejido espacial para viajar entre sistemas estelares"
			},
			{
				"id": "meth_escanear_planeta",
				"text": "escanear_orbita_planetaria()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Analiza geología y atmósfera de cuerpos celestes desde órbita"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_musculo",
				"text": "fuerza_muscular = 150",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Propiedad biológica orgánica inaplicable a una astronave"
			},
			{
				"id": "dist_attr_cuerda",
				"text": "tension_arco_libras = 70",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Propiedad mecánica de arco de caza"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_meditar",
				"text": "meditar_para_recuperar_mana()",
				"type": ComponentType.METHOD,
				"desc": "Práctica mística espiritual de magos"
			},
			{
				"id": "dist_meth_escudo",
				"text": "bloquear_con_escudo()",
				"type": ComponentType.METHOD,
				"desc": "Técnica de combate cuerpo a cuerpo con escudo medieval"
			}
		],
		"instance_lore": "¡Objeto instanciado: NaveExploradora() en memoria!\n• Atributos: propulsion='Motor de Iones', escudo_deflector='Antimateria'\n• Métodos activos: activar_salto_hiperespacio(), escanear_orbita_planetaria()\nSistemas de navegación cósmica listos para el despegue."
	},
	{
		"id": "alquimista_pociones",
		"class_name": "AlquimistaPociones",
		"title": "Boticario Alquimista",
		"concept": "Científico boticario y químico de laboratorio. Manipula reactivos puros de sulfuro en matraces para destilar pociones curativas y analizar compuestos medicinales.",
		"badge_color": Color("009688"), # Verde azulado / teal
		"avatar_symbol": "🧪🌿",
		"target_attributes": [
			{
				"id": "attr_reactivo",
				"text": "reactivo_base = \"Sulfuro Puro\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Compuesto mineral base para la destilación en matraces"
			},
			{
				"id": "attr_pureza",
				"text": "pureza_elixir_pct = 99.5",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Grado de refinamiento químico porcentual de la mezcla"
			}
		],
		"target_methods": [
			{
				"id": "meth_destilar",
				"text": "destilar_pocion_curativa()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Hierve y condensa reactivos para fabricar un elixir de salud"
			},
			{
				"id": "meth_analizar",
				"text": "analizar_reactivo_quimico()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Examina propiedades moleculares del espécimen de laboratorio"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_motor",
				"text": "propulsion = \"Motor de Iones\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Mecanismo aeroespacial incompatible con cristalería boticaria"
			},
			{
				"id": "dist_attr_blindaje_metal",
				"text": "grosor_armadura = \"Placas Acero\"",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Equipo de blindaje físico de infantería pesada"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_fuego_alquimia",
				"text": "lanzar_bola_fuego()",
				"type": ComponentType.METHOD,
				"desc": "Poder de hechicero destructivo no metódico ni medicinal"
			},
			{
				"id": "dist_meth_firewall",
				"text": "descifrar_cortafuegos()",
				"type": ComponentType.METHOD,
				"desc": "Operación de redes informáticas ajena a la química"
			}
		],
		"instance_lore": "¡Objeto instanciado: AlquimistaPociones() en memoria!\n• Atributos: reactivo_base='Sulfuro Puro', pureza_elixir_pct=99.5\n• Métodos activos: destilar_pocion_curativa(), analizar_reactivo_quimico()\nElixires medicinales destilados y listos para distribución."
	},
	{
		"id": "hacker_ciberespacio",
		"class_name": "HackerCiberespacio",
		"title": "Especialista Ciberespacial",
		"concept": "Especialista informático en seguridad digital y redes. Utiliza proxies remotos y cifrado criptográfico AES-256 para auditar y descifrar cortafuegos corporativos.",
		"badge_color": Color("10b981"), # Verde esmeralda terminal
		"avatar_symbol": "💻🕶️",
		"target_attributes": [
			{
				"id": "attr_proxy",
				"text": "ip_proxy_nodo = \"192.168.1.77\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Dirección IP virtual para anonimizar la conexión en red"
			},
			{
				"id": "attr_cifrado",
				"text": "algoritmo_cifrado = \"AES-256\"",
				"type": ComponentType.ATTRIBUTE,
				"expected_section": "ATTR",
				"desc": "Estándar de criptografía para proteger los paquetes de datos"
			}
		],
		"target_methods": [
			{
				"id": "meth_descifrar",
				"text": "descifrar_cortafuegos()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Vulnera y audita las reglas de filtrado del firewall de red"
			},
			{
				"id": "meth_payload",
				"text": "desplegar_payload_remoto()",
				"type": ComponentType.METHOD,
				"expected_section": "METH",
				"desc": "Transmite paquete binario estructurado al servidor de destino"
			}
		],
		"distractor_attributes": [
			{
				"id": "dist_attr_flecha_hacker",
				"text": "tension_arco_libras = 70",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Propiedad de arquería física, ajena al software"
			},
			{
				"id": "dist_attr_flama_hacker",
				"text": "temperatura_flama = 1500",
				"type": ComponentType.ATTRIBUTE,
				"desc": "Calor ígneo arcano ajeno a sistemas digitales"
			}
		],
		"distractor_methods": [
			{
				"id": "dist_meth_embestir_hacker",
				"text": "embestir_con_hombrera()",
				"type": ComponentType.METHOD,
				"desc": "Ataque físico de impacto corporal ajeno al ciberespacio"
			},
			{
				"id": "dist_meth_hiper_hacker",
				"text": "activar_salto_hiperespacio()",
				"type": ComponentType.METHOD,
				"desc": "Navegación espacial de astronaves ajena a computadoras"
			}
		],
		"instance_lore": "¡Objeto instanciado: HackerCiberespacio() en memoria!\n• Atributos: ip_proxy_nodo='192.168.1.77', algoritmo_cifrado='AES-256'\n• Métodos activos: descifrar_cortafuegos(), desplegar_payload_remoto()\nAcceso concedido al mainframe: protocolos auditados exitosamente."
	}
]

## Configuración y parámetros por dificultad según Diagrama de Secuencia CU-12
## Las clases se seleccionan y barajan aleatoriamente SIN REPETICIÓN en cada partida
static func get_difficulty_config(difficulty: String) -> Dictionary:
	var required_count: int = 4
	var max_lives: int = 3
	var round_time: float = 45.0
	var total_score: int = 500
	var points_per_char: int = 125
	var stars: int = 2
	var diff_name: String = "Normal"

	match difficulty.to_upper():
		"FACIL":
			diff_name = "Fácil"
			required_count = 3
			max_lives = 5        # 5 vidas según especificación
			round_time = 60.0     # 60s por personaje según especificación
			total_score = 300    # 300 pts totales (100 pts/personaje)
			points_per_char = 100
			stars = 1
		"INGENIERO":
			diff_name = "Ingeniero"
			required_count = 5
			max_lives = 1        # 1 vida según especificación
			round_time = 30.0     # 30s por personaje según especificación
			total_score = 750    # 750 pts totales (150 pts/personaje)
			points_per_char = 150
			stars = 3
		_: # NORMAL por defecto
			diff_name = "Normal"
			required_count = 4
			max_lives = 3        # 3 vidas según especificación
			round_time = 45.0     # 45s por personaje según especificación
			total_score = 500    # 500 pts totales (125 pts/personaje)
			points_per_char = 125
			stars = 2

	# Selección aleatoria sin repetición del catálogo de clases disponibles
	var randomized_classes: Array[Dictionary] = pick_random_classes(required_count)

	return {
		"name": diff_name,
		"characters_count": required_count,
		"max_lives": max_lives,
		"round_time": round_time,
		"total_score": total_score,
		"points_per_char": points_per_char,
		"stars": stars,
		"classes": randomized_classes
	}

## Selecciona N clases únicas de forma aleatoria (Fisher-Yates shuffle sin repetición)
static func pick_random_classes(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = HERO_CLASSES.duplicate()
	pool.shuffle()
	var selected: Array[Dictionary] = []
	var limit: int = mini(count, pool.size())
	for i in range(limit):
		selected.append(pool[i])
	return selected

## Genera el banco de 8 componentes mezclados para la ronda del personaje dado
static func generate_bank_for_hero(hero_data: Dictionary) -> Array[Dictionary]:
	var bank: Array[Dictionary] = []
	
	# 2 Atributos correctos de la clase
	for attr in hero_data.target_attributes:
		var item: Dictionary = attr.duplicate()
		item["is_correct"] = true
		item["hero_id"] = hero_data.id
		bank.append(item)
		
	# 2 Métodos correctos de la clase
	for meth in hero_data.target_methods:
		var item: Dictionary = meth.duplicate()
		item["is_correct"] = true
		item["hero_id"] = hero_data.id
		bank.append(item)
		
	# 2 Distractores de Atributo
	for dist_attr in hero_data.distractor_attributes:
		var item: Dictionary = dist_attr.duplicate()
		item["is_correct"] = false
		item["expected_section"] = "ATTR"
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
