## HeroForgeData.gd - Catálogo de Clases, Objetos, Atributos y Métodos para CU-12
## Morelosoft International Solutions - Materia: Introducción a la Programación (Aula 101)
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico & Software Architect)
class_name HeroForgeData
extends RefCounted

## Tipos de componentes de POO
enum ComponentType {
	ATTRIBUTE,
	METHOD
}

## Catálogo completo de 7 clases divididas por tiers de dificultad:
## • FACIL: 1 Atributo y 1 Método muy obvios y directos para principiantes.
## • NORMAL: 2 Atributos y 2 Métodos técnicos e intermedios.
## • INGENIERO: 3 Atributos y 3 Métodos con mayor nivel de abstracción y rigor científico/ingenieril.
const HERO_CLASSES: Array[Dictionary] = [
	{
		"id": "mago_igneo",
		"class_name": "MagoIgneo",
		"title": "Mago Ígneo",
		"badge_color": Color("ff5722"), # Naranja fuego
		"avatar_symbol": "🧙‍♂️🔥",
		"tiers": {
			"FACIL": {
				"concept": "Especialista arcano en fuego elemental. Conjura y proyecta llamas directas.",
				"target_attributes": [
					{ "id": "attr_f_elem", "text": "elemento = \"Fuego\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Elemento primordial que rige su magia" }
				],
				"target_methods": [
					{ "id": "meth_f_lanzar", "text": "lanzar_fuego()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Proyecta fuego directamente al objetivo" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_f_agua", "text": "elemento = \"Agua\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Elemento de agua" },
					{ "id": "d_attr_f_planta", "text": "elemento = \"Planta\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Elemento de planta" }
				],
				"distractor_methods": [
					{ "id": "d_meth_f_agua", "text": "lanzar_agua()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Lanza agua" },
					{ "id": "d_meth_f_roca", "text": "lanzar_rocas()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Lanza rocas" }
				],
				"instance_lore": "¡MagoIgneo() instanciado!\n• Atributo: elemento='Fuego'\n• Método: lanzar_fuego()"
			},
			"NORMAL": {
				"concept": "Especialista arcano en piromancia. Canaliza energía ígnea para conjurar esferas ardientes y levantar muros de llamas defensivos.",
				"target_attributes": [
					{ "id": "attr_n_elem", "text": "elemento_magico = \"Fuego\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Elemento primordial de piromancia" },
					{ "id": "attr_n_flama", "text": "temperatura_flama = 1500", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Calor de sus conjuros en grados Celsius" }
				],
				"target_methods": [
					{ "id": "meth_n_bola", "text": "lanzar_bola_fuego()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Proyecta un orbe ardiente destructivo" },
					{ "id": "meth_n_muro", "text": "invocar_muro_llamas()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Crea una barrera de llamas defensiva" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_n_hielo", "text": "elemento_magico = \"Hielo\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Elemento criogénico" },
					{ "id": "d_attr_n_blindaje", "text": "grosor_blindaje = \"50mm Acero\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Blindaje de tanque" }
				],
				"distractor_methods": [
					{ "id": "d_meth_n_chorro", "text": "disparar_chorro_agua()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Chorro de agua elemental" },
					{ "id": "d_meth_n_escudo", "text": "bloquear_con_escudo()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Defensa física con escudo" }
				],
				"instance_lore": "¡MagoIgneo() instanciado!\n• Atributos: elemento_magico='Fuego', temperatura_flama=1500\n• Métodos: lanzar_bola_fuego(), invocar_muro_llamas()"
			},
			"INGENIERO": {
				"concept": "Especialista avanzado en termodinámica arcana. Regula reacciones exotérmicas, densidad de flujo calorífico y disipación de gradientes térmicos.",
				"target_attributes": [
					{ "id": "attr_i_entalpia", "text": "entalpia_reaccion = \"Exotermica\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Liberación energética por combustión" },
					{ "id": "attr_i_densidad", "text": "densidad_flujo_calor = 4800", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Transferencia de calor superficial" },
					{ "id": "attr_i_resistencia", "text": "resistencia_termica = 2500", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Tolerancia a gradientes extremos" }
				],
				"target_methods": [
					{ "id": "meth_i_disipar", "text": "disipar_gradiente_calor()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Gestión activa de disipación térmica" },
					{ "id": "meth_i_sobrecargar", "text": "sobrecargar_nucleo_termico()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Excitación masiva del núcleo calorífico" },
					{ "id": "meth_i_propagar", "text": "propagar_onda_termica()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Emisión radial de ondas calóricas" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_i_clock", "text": "frecuencia_clock_ghz = 4.2", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Electrónica digital" },
					{ "id": "d_attr_i_rigidez", "text": "rigidez_estructural_kpa = 950", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Mecánica estructural" },
					{ "id": "d_attr_i_viscosidad", "text": "viscosidad_fluido_poise = 1.8", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Reología de fluidos químicos" }
				],
				"distractor_methods": [
					{ "id": "d_meth_i_ancho", "text": "remodular_ancho_banda()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Telecomunicaciones de red" },
					{ "id": "d_meth_i_presurizar", "text": "presurizar_tanque_vacio()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Ingeniería aeroespacial" },
					{ "id": "d_meth_i_retroceso", "text": "compensar_retroceso_mecanico()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Cinemática de artillería" }
				],
				"instance_lore": "¡MagoIgneo() instanciado a nivel Ingeniero!\n• Atributos: entalpia_reaccion='Exotermica', densidad_flujo_calor=4800, resistencia_termica=2500\n• Métodos: disipar_gradiente_calor(), sobrecargar_nucleo_termico(), propagar_onda_termica()"
			}
		}
	},
	{
		"id": "guerrero_tanque",
		"class_name": "GuerreroTanque",
		"title": "Guerrero Acorazado",
		"badge_color": Color("3f51b5"), # Azul acero
		"avatar_symbol": "🛡️⚔️",
		"tiers": {
			"FACIL": {
				"concept": "Luchador de primera línea con escudo de hierro. Bloquea ataques enemigos cara a cara.",
				"target_attributes": [
					{ "id": "attr_f_escudo", "text": "escudo = \"Hierro\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Material de su escudo protector" }
				],
				"target_methods": [
					{ "id": "meth_f_bloquear", "text": "bloquear()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Levanta el escudo para detener impactos" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_f_papel", "text": "escudo = \"Papel\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Material inservible" },
					{ "id": "d_attr_f_arco", "text": "arma = \"Arco Madera\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Arma de tirador" }
				],
				"distractor_methods": [
					{ "id": "d_meth_f_disparo", "text": "disparar_arco()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Dispara flecha" },
					{ "id": "d_meth_f_volar", "text": "volar_espacio()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Vuela en nave" }
				],
				"instance_lore": "¡GuerreroTanque() instanciado!\n• Atributo: escudo='Hierro'\n• Método: bloquear()"
			},
			"NORMAL": {
				"concept": "Baluarte defensivo de primera línea. Porta armadura pesada de placas de acero y un escudo colosal para bloquear y embestir rivales.",
				"target_attributes": [
					{ "id": "attr_n_armadura", "text": "grosor_armadura = \"Placas Acero\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Blindaje metálico pesado" },
					{ "id": "attr_n_escudo_res", "text": "resistencia_escudo = 800", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Capacidad de absorción de impactos" }
				],
				"target_methods": [
					{ "id": "meth_n_bloquear_esc", "text": "bloquear_con_escudo()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Mitiga daño frontal con escudo" },
					{ "id": "meth_n_embestir", "text": "embestir_con_hombrera()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Carga pesada con la armadura" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_n_sigilo", "text": "sigilo_camuflaje = \"Capa Sombra\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Camuflaje de arquero" },
					{ "id": "d_attr_n_iones", "text": "combustible_iones = \"Xenón\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Combustible aeroespacial" }
				],
				"distractor_methods": [
					{ "id": "d_meth_n_flecha", "text": "disparar_flecha_silente()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Ataque con arco" },
					{ "id": "d_meth_n_hiper", "text": "activar_salto_hiperespacio()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Salto espacial" }
				],
				"instance_lore": "¡GuerreroTanque() instanciado!\n• Atributos: grosor_armadura='Placas Acero', resistencia_escudo=800\n• Métodos: bloquear_con_escudo(), embestir_con_hombrera()"
			},
			"INGENIERO": {
				"concept": "Especialista en cinética de impactos y resistencia estructural de materiales. Modula elasticidad, inercia de masa y redirección vectorial de fuerzas mecánicas.",
				"target_attributes": [
					{ "id": "attr_i_modulo", "text": "modulo_elasticidad_gpa = 210", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Rigidez de absorción del acero" },
					{ "id": "attr_i_mitigacion", "text": "coeficiente_mitigacion = 0.85", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Reducción porcentual de momentum cinético" },
					{ "id": "attr_i_masa", "text": "masa_inercial_kg = 180", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Inercia corporal contra derribos" }
				],
				"target_methods": [
					{ "id": "meth_i_absorber", "text": "absorber_impulso_cinetico()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Disipa vectores de fuerza recibidos" },
					{ "id": "meth_i_afianzar", "text": "afianzar_centro_gravedad()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Baja postura para anclar estabilidad" },
					{ "id": "meth_i_redireccionar", "text": "redireccionar_vector_fuerza()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Desvía la trayectoria de choques" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_i_laser", "text": "longitud_onda_laser_nm = 532", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Óptica láser" },
					{ "id": "d_attr_i_refraccion", "text": "indice_refraccion = 1.02", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Índice de refracción óptica" },
					{ "id": "d_attr_i_ph", "text": "potencial_hidrogeno_ph = 6.8", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Acidez de solución química" }
				],
				"distractor_methods": [
					{ "id": "d_meth_i_catalizar", "text": "catalizar_reaccion_exotermica()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Reacción química de alquimista" },
					{ "id": "d_meth_i_hash", "text": "auditar_integridad_hash()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Criptografía de hacker" },
					{ "id": "d_meth_i_eco", "text": "suprimir_eco_sonoro()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Acústica de arquero sigiloso" }
				],
				"instance_lore": "¡GuerreroTanque() instanciado a nivel Ingeniero!\n• Atributos: modulo_elasticidad_gpa=210, coeficiente_mitigacion=0.85, masa_inercial_kg=180\n• Métodos: absorber_impulso_cinetico(), afianzar_centro_gravedad(), redireccionar_vector_fuerza()"
			}
		}
	},
	{
		"id": "arquero_sombra",
		"class_name": "ArqueroSombra",
		"title": "Arquero Sombrío",
		"badge_color": Color("4caf50"), # Verde sombra
		"avatar_symbol": "🏹🌑",
		"tiers": {
			"FACIL": {
				"concept": "Tirador a distancia con arco y flechas. Dispara proyectiles y caza desde lejos.",
				"target_attributes": [
					{ "id": "attr_f_arma", "text": "arma = \"Arco\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Arma balística de proyectiles" }
				],
				"target_methods": [
					{ "id": "meth_f_disparar", "text": "disparar_flecha()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Dispara flecha hacia el objetivo" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_f_varita", "text": "arma = \"Varita\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Instrumento de mago" },
					{ "id": "d_attr_f_soplete", "text": "herramienta = \"Soplete\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Herramienta de robot" }
				],
				"distractor_methods": [
					{ "id": "d_meth_f_mago", "text": "lanzar_fuego()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Conjuro de fuego" },
					{ "id": "d_meth_f_curar", "text": "curar_aliado()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Habilidad curativa" }
				],
				"instance_lore": "¡ArqueroSombra() instanciado!\n• Atributo: arma='Arco'\n• Método: disparar_flecha()"
			},
			"NORMAL": {
				"concept": "Tirador táctico a larga distancia y maestro del sigilo. Utiliza arco de gran tensión y una capa de camuflaje para ocultarse en las sombras.",
				"target_attributes": [
					{ "id": "attr_n_tension", "text": "tension_arco_libras = 70", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Potencia de tracción del arco" },
					{ "id": "attr_n_camuflaje", "text": "camuflaje = \"Capa de Sombras\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Vestimenta para fundirse en penumbra" }
				],
				"target_methods": [
					{ "id": "meth_n_flecha_sil", "text": "disparar_flecha_silente()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Disparo certero sin alertar enemigos" },
					{ "id": "meth_n_ocultar", "text": "ocultarse_en_sombras()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Reduce visibilidad a cero" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_n_bateria", "text": "carga_bateria = \"98% Litio\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Batería de robot" },
					{ "id": "d_attr_n_sulfuro", "text": "reactivo_base = \"Sulfuro Puro\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Química de alquimista" }
				],
				"distractor_methods": [
					{ "id": "d_meth_n_soldar", "text": "soldar_circuito_impreso()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Soldadura electrónica" },
					{ "id": "d_meth_n_destilar", "text": "destilar_pocion_curativa()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Destilación química" }
				],
				"instance_lore": "¡ArqueroSombra() instanciado!\n• Atributos: tension_arco_libras=70, camuflaje='Capa de Sombras'\n• Métodos: disparar_flecha_silente(), ocultarse_en_sombras()"
			},
			"INGENIERO": {
				"concept": "Especialista en aerodinámica balística y reducción de firmas espectrales. Modula sección de radar, coeficiente de arrastre y atenuación acústica.",
				"target_attributes": [
					{ "id": "attr_i_rcs", "text": "seccion_radar_rcs_db = -45.0", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Baja detectabilidad electromagnética" },
					{ "id": "attr_i_vsalida", "text": "velocidad_salida_ms = 92.0", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Velocidad de boca del proyectil" },
					{ "id": "attr_i_arrastre", "text": "coeficiente_arrastre = 0.28", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Resistencia del aire en trayectoria" }
				],
				"target_methods": [
					{ "id": "meth_i_optica", "text": "minimizar_firma_optica()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Absorción espectral en rango visible" },
					{ "id": "meth_i_parabola", "text": "calcular_parabola_balistica()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Compensación de viento y gravedad" },
					{ "id": "meth_i_eco", "text": "suprimir_eco_sonoro()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Amortiguación de decibeles de disparo" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_i_amperaje", "text": "consumo_amperaje_ma = 450", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Consumo de circuito robótico" },
					{ "id": "d_attr_i_deltav", "text": "delta_v_total_ms = 12500", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Maniobra orbital de nave" },
					{ "id": "d_attr_i_presur", "text": "presurizacion_kpa = 101.3", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Presión de cabina espacial" }
				],
				"distractor_methods": [
					{ "id": "d_meth_i_pid", "text": "cerrar_bucle_control_pid()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Control mecatrónico" },
					{ "id": "d_meth_i_precip", "text": "precipitar_fase_solida()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Filtro químico de alquimista" },
					{ "id": "d_meth_i_tunel", "text": "enrutar_trafico_tunel()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "VPN de hacker" }
				],
				"instance_lore": "¡ArqueroSombra() instanciado a nivel Ingeniero!\n• Atributos: seccion_radar_rcs_db=-45.0, velocidad_salida_ms=92.0, coeficiente_arrastre=0.28\n• Métodos: minimizar_firma_optica(), calcular_parabola_balistica(), suprimir_eco_sonoro()"
			}
		}
	},
	{
		"id": "robot_reparador",
		"class_name": "RobotReparador",
		"title": "Androide Mecatrónico",
		"badge_color": Color("00bcd4"), # Cian cibernético
		"avatar_symbol": "🤖🔧",
		"tiers": {
			"FACIL": {
				"concept": "Autómata electromecánico de asistencia. Arregla y repara cosas rotas.",
				"target_attributes": [
					{ "id": "attr_f_tipo_rob", "text": "tipo = \"Robot\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Naturaleza mecánica del ser" }
				],
				"target_methods": [
					{ "id": "meth_f_reparar", "text": "reparar()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Repara maquinaria descompuesta" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_f_caballo", "text": "tipo = \"Caballo\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Animal biológico" },
					{ "id": "d_attr_f_arbusto", "text": "tipo = \"Arbusto\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Elemento vegetal" }
				],
				"distractor_methods": [
					{ "id": "d_meth_f_morder", "text": "morder()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Acción animal" },
					{ "id": "d_meth_f_florecer", "text": "florecer()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Acción botánica" }
				],
				"instance_lore": "¡RobotReparador() instanciado!\n• Atributo: tipo='Robot'\n• Método: reparar()"
			},
			"NORMAL": {
				"concept": "Autómata cibernético de ingeniería electromecánica. Funciona con batería de litio recargable y cuenta con soplete láser para soldar circuitos impresos.",
				"target_attributes": [
					{ "id": "attr_n_bateria", "text": "carga_bateria = \"98% Litio\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Almacenamiento electroquímico de energía" },
					{ "id": "attr_n_herramienta", "text": "herramienta_brazo = \"Soplete Láser\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Instrumento térmico de precisión" }
				],
				"target_methods": [
					{ "id": "meth_n_soldar", "text": "soldar_circuito_impreso()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Repara pistas y componentes electrónicos" },
					{ "id": "meth_n_diag", "text": "ejecutar_autodiagnostico()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Escanea memoria y sensores" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_n_espada", "text": "filo_espada = \"Doble Filo\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Espada de combate" },
					{ "id": "d_attr_n_viento", "text": "elemento_magico = \"Viento\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Hechicería mística" }
				],
				"distractor_methods": [
					{ "id": "d_meth_n_tormenta", "text": "conjurar_tormenta_fuego()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Hechizo arcano" },
					{ "id": "d_meth_n_disparo", "text": "disparar_flecha_silente()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Habilidad de tirador" }
				],
				"instance_lore": "¡RobotReparador() instanciado!\n• Atributos: carga_bateria='98% Litio', herramienta_brazo='Soplete Láser'\n• Métodos: soldar_circuito_impreso(), ejecutar_autodiagnostico()"
			},
			"INGENIERO": {
				"concept": "Sistema robótico avanzado de servocontrol y telemetría de actuadores. Gestiona grados de libertad, control PID en lazo cerrado y reacondicionamiento de buses.",
				"target_attributes": [
					{ "id": "attr_i_grados", "text": "grados_libertad_brazo = 6", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Cinemática articular del manipulador" },
					{ "id": "attr_i_muestreo", "text": "frecuencia_muestreo_hz = 1000", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Ciclo de escaneo en bus de control" },
					{ "id": "attr_i_potencia", "text": "potencia_consumo_watts = 350", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Demanda de energía de los motores" }
				],
				"target_methods": [
					{ "id": "meth_i_pid", "text": "cerrar_bucle_control_pid()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Ajuste proactivo de posición articular" },
					{ "id": "meth_i_calibrar", "text": "calibrar_sensores_posicion()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Puesta a cero de encoders absolutos" },
					{ "id": "meth_i_buses", "text": "reparar_buses_interconexion()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Restaura continuidad en enlaces CAN" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_i_entalpia", "text": "entalpia_reaccion = \"Exotermica\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Termoquímica" },
					{ "id": "d_attr_i_curvatura", "text": "curvatura_espacio_tiempo = 0.05", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Astrofísica espacial" },
					{ "id": "d_attr_i_clave", "text": "entropia_clave_bits = 256", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Criptografía digital" }
				],
				"distractor_methods": [
					{ "id": "d_meth_i_hohmann", "text": "ejecutar_transferencia_hohmann()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Órbitas astronáuticas" },
					{ "id": "d_meth_i_payload", "text": "desplegar_payload_remoto()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Inyección de software" },
					{ "id": "d_meth_i_emulsion", "text": "estabilizar_emulsion_coloidal()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Bioquímica medicinal" }
				],
				"instance_lore": "¡RobotReparador() instanciado a nivel Ingeniero!\n• Atributos: grados_libertad_brazo=6, frecuencia_muestreo_hz=1000, potencia_consumo_watts=350\n• Métodos: cerrar_bucle_control_pid(), calibrar_sensores_posicion(), reparar_buses_interconexion()"
			}
		}
	},
	{
		"id": "nave_exploradora",
		"class_name": "NaveExploradora",
		"title": "Astronave Espacial",
		"badge_color": Color("9c27b0"), # Púrpura cósmico
		"avatar_symbol": "🚀🌌",
		"tiers": {
			"FACIL": {
				"concept": "Vehículo espacial para volar entre planetas y estrellas en el espacio.",
				"target_attributes": [
					{ "id": "attr_f_vehic", "text": "vehiculo = \"Nave\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Tipo de transporte estelar" }
				],
				"target_methods": [
					{ "id": "meth_f_volar", "text": "volar_espacio()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Vuela a través del cosmos" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_f_bici", "text": "vehiculo = \"Bicicleta\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Transporte de pedales" },
					{ "id": "d_attr_f_carreta", "text": "vehiculo = \"Carreta\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Vehículo de tracción animal" }
				],
				"distractor_methods": [
					{ "id": "d_meth_f_pedalear", "text": "pedalear()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Acción terrestre" },
					{ "id": "d_meth_f_remendar", "text": "remendar_vela()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Acción náutica antigua" }
				],
				"instance_lore": "¡NaveExploradora() instanciada!\n• Atributo: vehiculo='Nave'\n• Método: volar_espacio()"
			},
			"NORMAL": {
				"concept": "Sonda cósmica interestelar diseñada para el vacío estelar. Equipada con motor de iones, escudos deflectores y capacidad de salto al hiperespacio.",
				"target_attributes": [
					{ "id": "attr_n_propulsion", "text": "propulsion = \"Motor de Iones\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Acelerador iónico para desplazamiento cósmico" },
					{ "id": "attr_n_escudo", "text": "escudo_deflector = \"Antimateria\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Campo de dispersión de radiación" }
				],
				"target_methods": [
					{ "id": "meth_n_salto", "text": "activar_salto_hiperespacio()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Curva el tejido espacial para viajar" },
					{ "id": "meth_n_escanear", "text": "escanear_orbita_planetaria()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Analiza geología de cuerpos celestes" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_n_fuerza", "text": "fuerza_muscular = 150", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Propiedad de ser orgánico" },
					{ "id": "d_attr_n_arco_t", "text": "tension_arco_libras = 70", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Propiedad de arquero" }
				],
				"distractor_methods": [
					{ "id": "d_meth_n_meditar", "text": "meditar_para_recuperar_mana()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Práctica mística" },
					{ "id": "d_meth_n_bloquear", "text": "bloquear_con_escudo()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Bloqueo físico de infantería" }
				],
				"instance_lore": "¡NaveExploradora() instanciada!\n• Atributos: propulsion='Motor de Iones', escudo_deflector='Antimateria'\n• Métodos: activar_salto_hiperespacio(), escanear_orbita_planetaria()"
			},
			"INGENIERO": {
				"concept": "Plataforma aeroespacial de astrodinámica y navegación orbital. Regula impulso específico, presupuesto de Delta-V y triangulación estelar relativista.",
				"target_attributes": [
					{ "id": "attr_i_isp", "text": "impulso_especifico_seg = 3200", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Eficiencia de empuje del propelente" },
					{ "id": "attr_i_deltav", "text": "delta_v_total_ms = 12500", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Capacidad de maniobra orbital total" },
					{ "id": "attr_i_estanca", "text": "presurizacion_estanca_kpa = 101.3", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Soporte de atmósfera interna estanca" }
				],
				"target_methods": [
					{ "id": "meth_i_hohmann", "text": "ejecutar_transferencia_hohmann()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Transición orbital elíptica de menor energía" },
					{ "id": "meth_i_radiador", "text": "desplegar_radiadores_termicos()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Disipación de calor por radiación al vacío" },
					{ "id": "meth_i_triangular", "text": "triangular_posicion_estelar()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Orientación astronáutica mediante púlsares" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_i_mitig", "text": "coeficiente_mitigacion = 0.85", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Mecánica de choques de blindaje" },
					{ "id": "d_attr_i_ph", "text": "potencial_hidrogeno_ph = 6.8", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Química de soluciones" },
					{ "id": "d_attr_i_cidr", "text": "mascara_subred_cidr = \"/24\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Topología lógica de redes" }
				],
				"distractor_methods": [
					{ "id": "d_meth_i_hash", "text": "auditar_integridad_hash()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Criptografía de software" },
					{ "id": "d_meth_i_catal", "text": "catalizar_reaccion_exotermica()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Reacción química de laboratorio" },
					{ "id": "d_meth_i_impulso", "text": "absorber_impulso_cinetico()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Absorción mecánica de tanques" }
				],
				"instance_lore": "¡NaveExploradora() instanciada a nivel Ingeniero!\n• Atributos: impulso_especifico_seg=3200, delta_v_total_ms=12500, presurizacion_estanca_kpa=101.3\n• Métodos: ejecutar_transferencia_hohmann(), desplegar_radiadores_termicos(), triangular_posicion_estelar()"
			}
		}
	},
	{
		"id": "alquimista_pociones",
		"class_name": "AlquimistaPociones",
		"title": "Boticario Alquimista",
		"badge_color": Color("009688"), # Verde azulado / teal
		"avatar_symbol": "🧪🌿",
		"tiers": {
			"FACIL": {
				"concept": "Elaborador de elixires mágicos. Mezcla pociones en frascos para sanar.",
				"target_attributes": [
					{ "id": "attr_f_frasco", "text": "frasco = \"Pocion\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Contenedor de brebaje medicinal" }
				],
				"target_methods": [
					{ "id": "meth_f_mezclar", "text": "mezclar_pocion()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Combina ingredientes en el frasco" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_f_bat", "text": "frasco = \"Bateria\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Pila de robot" },
					{ "id": "d_attr_f_coh", "text": "frasco = \"Cohete\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Vehículo cósmico" }
				],
				"distractor_methods": [
					{ "id": "d_meth_f_recarg", "text": "recargar_energia()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Recarga de robots" },
					{ "id": "d_meth_f_despeg", "text": "despegar()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Despegue espacial" }
				],
				"instance_lore": "¡AlquimistaPociones() instanciado!\n• Atributo: frasco='Pocion'\n• Método: mezclar_pocion()"
			},
			"NORMAL": {
				"concept": "Científico boticario y químico de laboratorio. Manipula reactivos puros de sulfuro en matraces para destilar pociones curativas y analizar compuestos medicinales.",
				"target_attributes": [
					{ "id": "attr_n_reactivo", "text": "reactivo_base = \"Sulfuro Puro\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Compuesto mineral base de destilación" },
					{ "id": "attr_n_pureza", "text": "pureza_elixir_pct = 99.5", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Grado porcentual de refinamiento" }
				],
				"target_methods": [
					{ "id": "meth_n_destilar", "text": "destilar_pocion_curativa()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Hierve y condensa para crear medicina" },
					{ "id": "meth_n_analizar", "text": "analizar_reactivo_quimico()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Examina propiedades moleculares" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_n_prop", "text": "propulsion = \"Motor de Iones\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Motor de nave espacial" },
					{ "id": "d_attr_n_placas", "text": "grosor_armadura = \"Placas Acero\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Placas de tanque acorazado" }
				],
				"distractor_methods": [
					{ "id": "d_meth_n_bola", "text": "lanzar_bola_fuego()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Hechizo de piromancia" },
					{ "id": "d_meth_n_fw", "text": "descifrar_cortafuegos()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Hacking de redes" }
				],
				"instance_lore": "¡AlquimistaPociones() instanciado!\n• Atributos: reactivo_base='Sulfuro Puro', pureza_elixir_pct=99.5\n• Métodos: destilar_pocion_curativa(), analizar_reactivo_quimico()"
			},
			"INGENIERO": {
				"concept": "Especialista en síntesis estequiométrica, catálisis en equilibrio termodinámico y estabilización de suspensiones coloidales en fase acuosa.",
				"target_attributes": [
					{ "id": "attr_i_eq", "text": "constante_equilibrio = 1.45", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Afinidad de la reacción de síntesis" },
					{ "id": "attr_i_ph", "text": "potencial_hidrogeno_ph = 6.8", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Balance iónico del principio activo" },
					{ "id": "attr_i_molar", "text": "molaridad_solucion = 2.5", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Concentración molar estequiométrica" }
				],
				"target_methods": [
					{ "id": "meth_i_cat", "text": "catalizar_reaccion_exotermica()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Acelera cinética química con reactivo" },
					{ "id": "meth_i_prec", "text": "precipitar_fase_solida()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Aísla solutos cristalinos por decantación" },
					{ "id": "meth_i_emul", "text": "estabilizar_emulsion_coloidal()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Garantiza dispersión homogénea del fármaco" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_i_sock", "text": "conteo_sockets_abiertos = 128", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Comunicaciones de red de hacker" },
					{ "id": "d_attr_i_art", "text": "grados_libertad_brazo = 6", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Cinemática robótica" },
					{ "id": "d_attr_i_vel", "text": "velocidad_salida_ms = 92.0", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Balística de proyectil" }
				],
				"distractor_methods": [
					{ "id": "d_meth_i_rad", "text": "desplegar_radiadores_termicos()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Enfriamiento espacial" },
					{ "id": "d_meth_i_calib", "text": "calibrar_sensores_posicion()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Calibración de transductores" },
					{ "id": "d_meth_i_hash", "text": "auditar_integridad_hash()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Verificación criptográfica" }
				],
				"instance_lore": "¡AlquimistaPociones() instanciado a nivel Ingeniero!\n• Atributos: constante_equilibrio=1.45, potencial_hidrogeno_ph=6.8, molaridad_solucion=2.5\n• Métodos: catalizar_reaccion_exotermica(), precipitar_fase_solida(), estabilizar_emulsion_coloidal()"
			}
		}
	},
	{
		"id": "hacker_ciberespacio",
		"class_name": "HackerCiberespacio",
		"title": "Especialista Ciberespacial",
		"badge_color": Color("10b981"), # Verde esmeralda terminal
		"avatar_symbol": "💻🕶️",
		"tiers": {
			"FACIL": {
				"concept": "Genio informático frente a su computadora. Escribe comandos y hackea sistemas.",
				"target_attributes": [
					{ "id": "attr_f_equipo", "text": "equipo = \"Computadora\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Herramienta digital de trabajo" }
				],
				"target_methods": [
					{ "id": "meth_f_hack", "text": "hackear_sistema()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Accede remotamente al sistema" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_f_espada", "text": "arma = \"Espada\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Arma medieval" },
					{ "id": "d_attr_f_escudo", "text": "equipo = \"Escudo\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Defensa física" }
				],
				"distractor_methods": [
					{ "id": "d_meth_f_flecha", "text": "disparar_flecha()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Ataque con flecha" },
					{ "id": "d_meth_f_golpe", "text": "bloquear_con_escudo()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Bloqueo corporal" }
				],
				"instance_lore": "¡HackerCiberespacio() instanciado!\n• Atributo: equipo='Computadora'\n• Método: hackear_sistema()"
			},
			"NORMAL": {
				"concept": "Especialista informático en seguridad digital y redes. Utiliza proxies remotos y cifrado criptográfico AES-256 para auditar y descifrar cortafuegos corporativos.",
				"target_attributes": [
					{ "id": "attr_n_proxy", "text": "ip_proxy_nodo = \"192.168.1.77\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Dirección IP virtual de anonimato" },
					{ "id": "attr_n_cifrado", "text": "algoritmo_cifrado = \"AES-256\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Criptografía estándar de protección" }
				],
				"target_methods": [
					{ "id": "meth_n_fw", "text": "descifrar_cortafuegos()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Vulnera reglas de filtrado de firewall" },
					{ "id": "meth_n_payload", "text": "desplegar_payload_remoto()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Transmite paquete binario al destino" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_n_arco", "text": "tension_arco_libras = 70", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Propiedad de arco de caza" },
					{ "id": "d_attr_n_flama", "text": "temperatura_flama = 1500", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Calor de piromancia" }
				],
				"distractor_methods": [
					{ "id": "d_meth_n_embestir", "text": "embestir_con_hombrera()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Impacto corporal de tanque" },
					{ "id": "d_meth_n_salto", "text": "activar_salto_hiperespacio()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Navegación espacial" }
				],
				"instance_lore": "¡HackerCiberespacio() instanciado!\n• Atributos: ip_proxy_nodo='192.168.1.77', algoritmo_cifrado='AES-256'\n• Métodos: descifrar_cortafuegos(), desplegar_payload_remoto()"
			},
			"INGENIERO": {
				"concept": "Arquitecto de ciberseguridad y auditoría criptográfica de sockets. Audita entropía de claves, enrutamiento en túneles IPsec y vectores de desbordamiento de memoria.",
				"target_attributes": [
					{ "id": "attr_i_entropia", "text": "entropia_clave_bits = 256", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Aleatoriedad de clave criptográfica" },
					{ "id": "attr_i_cidr", "text": "mascara_subred_cidr = \"/24\"", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Segmentación lógica de subred" },
					{ "id": "attr_i_sockets", "text": "conteo_sockets_abiertos = 128", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Conexiones TCP concurrentes activas" }
				],
				"target_methods": [
					{ "id": "meth_i_hash", "text": "auditar_integridad_hash()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Comprobación de firmas SHA" },
					{ "id": "meth_i_tunel", "text": "enrutar_trafico_tunel()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Encapsulamiento cifrado punto a punto" },
					{ "id": "meth_i_overflow", "text": "analizar_vector_desbordamiento()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Auditoría de colapso de stack/heap" }
				],
				"distractor_attributes": [
					{ "id": "d_attr_i_calor", "text": "densidad_flujo_calor = 4800", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Termodinámica de piromante" },
					{ "id": "d_attr_i_mol", "text": "molaridad_solucion = 2.5", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Química de alquimista" },
					{ "id": "d_attr_i_isp", "text": "impulso_especifico_seg = 3200", "type": ComponentType.ATTRIBUTE, "expected_section": "ATTR", "desc": "Propulsión espacial" }
				],
				"distractor_methods": [
					{ "id": "d_meth_i_pign", "text": "sobrecargar_nucleo_termico()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Sobrecarga de calor de piromante" },
					{ "id": "d_meth_i_triang", "text": "triangular_posicion_estelar()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Navegación espacial" },
					{ "id": "d_meth_i_prec", "text": "precipitar_fase_solida()", "type": ComponentType.METHOD, "expected_section": "METH", "desc": "Purificación química" }
				],
				"instance_lore": "¡HackerCiberespacio() instanciado a nivel Ingeniero!\n• Atributos: entropia_clave_bits=256, mascara_subred_cidr='/24', conteo_sockets_abiertos=128\n• Métodos: auditar_integridad_hash(), enrutar_trafico_tunel(), analizar_vector_desbordamiento()"
			}
		}
	}
]

## Configuración y parámetros por dificultad según Diagrama de Secuencia CU-12
## Las clases se seleccionan y barajan aleatoriamente SIN REPETICIÓN en cada partida
static func get_difficulty_config(difficulty: String) -> Dictionary:
	var required_count: int = 4
	var required_slots: int = 2
	var max_lives: int = 3
	var round_time: float = 45.0
	var total_score: int = 500
	var points_per_char: int = 125
	var stars: int = 2
	var diff_name: String = "Normal"
	var diff_key: String = "NORMAL"

	match difficulty.to_upper():
		"FACIL":
			diff_name = "Fácil"
			diff_key = "FACIL"
			required_count = 3
			required_slots = 1   # 1 Atributo y 1 Método por personaje
			max_lives = 5        # 5 vidas según especificación
			round_time = 60.0     # 60s por personaje según especificación
			total_score = 300    # 300 pts totales (100 pts/personaje)
			points_per_char = 100
			stars = 1
		"INGENIERO":
			diff_name = "Ingeniero"
			diff_key = "INGENIERO"
			required_count = 5
			required_slots = 3   # 3 Atributos y 3 Métodos por personaje
			max_lives = 1        # 1 vida según especificación
			round_time = 30.0     # 30s por personaje según especificación
			total_score = 750    # 750 pts totales (150 pts/personaje)
			points_per_char = 150
			stars = 3
		_: # NORMAL por defecto
			diff_name = "Normal"
			diff_key = "NORMAL"
			required_count = 4
			required_slots = 2   # 2 Atributos y 2 Métodos por personaje
			max_lives = 3        # 3 vidas según especificación
			round_time = 45.0     # 45s por personaje según especificación
			total_score = 500    # 500 pts totales (125 pts/personaje)
			points_per_char = 125
			stars = 2

	var randomized_classes: Array[Dictionary] = pick_random_classes(required_count)

	return {
		"name": diff_name,
		"difficulty_key": diff_key,
		"characters_count": required_count,
		"required_slots": required_slots,
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

## Genera los componentes del banco divididos en Atributos (izquierda) y Métodos (derecha)
## según la dificultad seleccionada
static func generate_bank_for_hero(hero_data: Dictionary, difficulty_key: String = "NORMAL") -> Dictionary:
	var diff: String = difficulty_key.to_upper()
	if not hero_data.tiers.has(diff):
		diff = "NORMAL"
	var tier_data: Dictionary = hero_data.tiers[diff]

	# Atributos (Lado Izquierdo)
	var attr_items: Array[Dictionary] = []
	for a in tier_data.target_attributes:
		var item: Dictionary = a.duplicate()
		item["is_correct"] = true
		item["expected_section"] = "ATTR"
		item["hero_id"] = hero_data.id
		attr_items.append(item)
	for da in tier_data.distractor_attributes:
		var item: Dictionary = da.duplicate()
		item["is_correct"] = false
		item["expected_section"] = "ATTR"
		item["hero_id"] = hero_data.id
		attr_items.append(item)
	attr_items.shuffle()

	# Métodos (Lado Derecho)
	var meth_items: Array[Dictionary] = []
	for m in tier_data.target_methods:
		var item: Dictionary = m.duplicate()
		item["is_correct"] = true
		item["expected_section"] = "METH"
		item["hero_id"] = hero_data.id
		meth_items.append(item)
	for dm in tier_data.distractor_methods:
		var item: Dictionary = dm.duplicate()
		item["is_correct"] = false
		item["expected_section"] = "METH"
		item["hero_id"] = hero_data.id
		meth_items.append(item)
	meth_items.shuffle()

	# Lista unificada y mezclada de componentes (para que el alumno elija la sección correcta)
	var mixed_items: Array[Dictionary] = []
	mixed_items.append_array(attr_items)
	mixed_items.append_array(meth_items)
	mixed_items.shuffle()

	return {
		"attributes": attr_items,
		"methods": meth_items,
		"all_components": mixed_items,
		"tier_data": tier_data
	}
