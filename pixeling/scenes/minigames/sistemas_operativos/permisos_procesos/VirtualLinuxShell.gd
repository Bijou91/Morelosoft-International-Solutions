## VirtualLinuxShell.gd - Emulador de Terminal y Entorno GNU/Linux Seguro y Aislado
## CU-18: Practicar a administrar permisos y procesos
## Morelosoft International Solutions - Materia: Sistemas Operativos y Linux
##
## Este simulador opera completamente en memoria (Sandbox aislado).
## NO ejecuta comandos del sistema operativo anfitrión ni accede al disco local.
class_name VirtualLinuxShell extends RefCounted

signal state_changed()
signal risky_action_detected(reason: String)

var current_user: String = "user"
var hostname: String = "is-pixelverse"
var current_path: String = "/home/user"

# Procesos simulados en memoria:
# Array de diccionarios: { "pid": int, "user": String, "cpu": float, "mem": float, "cmd": String, "critical": bool, "target": bool }
var processes: Array = []

# Sistema de archivos simulado en memoria:
# {
#   "/home/user": {
#       "dirs": ["backup"],
#       "files": {
#           "start_server.sh": { "perms": "-rw-r--r--", "owner": "user", "group": "user", "size": 340, "content": "..." }
#       }
#   }
# }
var simulated_fs: Dictionary = {}

# Historial de comandos ingresados
var command_history: Array[String] = []

# Instantánea previa del estado para restaurar en caso de acción riesgosa (FA-04.01)
var _snapshot_processes: Array = []
var _snapshot_fs: Dictionary = {}
var _snapshot_path: String = "/home/user"

func initialize(initial_processes: Array, initial_fs: Dictionary, start_path: String = "/home/user", user_name: String = "user") -> void:
	current_user = user_name
	current_path = start_path
	processes = initial_processes.duplicate(true)
	simulated_fs = initial_fs.duplicate(true)
	command_history.clear()
	_take_snapshot()

## Toma una instantánea del estado para respaldar antes de cada comando
func _take_snapshot() -> void:
	_snapshot_processes = processes.duplicate(true)
	_snapshot_fs = simulated_fs.duplicate(true)
	_snapshot_path = current_path

## Restaura el estado previo tras una acción riesgosa (FA-04.01)
func restore_snapshot() -> void:
	processes = _snapshot_processes.duplicate(true)
	simulated_fs = _snapshot_fs.duplicate(true)
	current_path = _snapshot_path
	state_changed.emit()

## Devuelve el texto del prompt actual (ej. user@is-pixelverse:~$)
func get_prompt_text() -> String:
	var disp: String = current_path
	if current_path == "/home/user":
		disp = "~"
	elif current_path.begins_with("/home/user/"):
		disp = "~/" + current_path.trim_prefix("/home/user/")
	return "%s@%s:%s$ " % [current_user, hostname, disp]

## Ejecuta un comando en la terminal simulada
## Retorna un Dictionary con:
## {
##   "output": String,       # Texto de salida (con formato BBCode)
##   "is_risky": bool,       # True si ejecutó acción peligrosa (FA-04.01)
##   "is_error": bool,       # True si hubo error de comando o sintaxis (FA-03.01)
##   "error_message": String # Motivo del error
## }
func execute_command(cmd_line: String) -> Dictionary:
	var trimmed := cmd_line.strip_edges()
	if trimmed == "":
		return { "output": "", "is_risky": false, "is_error": false, "error_message": "" }

	command_history.append(trimmed)
	_take_snapshot()

	# Soporte para pipes con grep (ej. ps aux | grep miner)
	if "|" in trimmed:
		var pipe_parts := trimmed.split("|", true, 1)
		var left_cmd := pipe_parts[0].strip_edges()
		var right_cmd := pipe_parts[1].strip_edges()
		if right_cmd.begins_with("grep"):
			var grep_args := _parse_tokens(right_cmd)
			var pattern := ""
			for g in grep_args:
				if not g.begins_with("-") and g != "grep":
					pattern = g.trim_prefix("\"").trim_suffix("\"").trim_prefix("'").trim_suffix("'").to_lower()
					break
			var res := execute_command(left_cmd)
			if res.get("is_risky", false) or res.get("is_error", false):
				return res
			var raw_out: String = res.get("output", "")
			var filtered_lines: Array[String] = []
			for line in raw_out.split("\n"):
				if pattern == "" or line.to_lower().contains(pattern) or "user" in line.to_lower():
					filtered_lines.append(line)
			if filtered_lines.is_empty():
				res["output"] = "[color=#888888](Sin coincidencias)[/color]"
			else:
				res["output"] = "\n".join(filtered_lines)
			return res

	# Tokenizar el comando separando por espacios
	var parts: Array[String] = _parse_tokens(trimmed)
	if parts.is_empty():
		return { "output": "", "is_risky": false, "is_error": false, "error_message": "" }

	var binary: String = parts[0].to_lower()
	var args: Array[String] = []
	for i in range(1, parts.size()):
		args.append(parts[i])

	# Soporte para ejecución de scripts (./script.sh o bash script.sh)
	if binary.begins_with("./") or binary == "bash" or binary == "sh":
		var script_name := binary.trim_prefix("./")
		var check_exec := binary.begins_with("./")
		if binary == "bash" or binary == "sh":
			if args.is_empty():
				return { "output": "bash: modo interactivo emulado", "is_risky": false, "is_error": false, "error_message": "" }
			script_name = args[0]
			check_exec = false
		return _cmd_exec_script(script_name, check_exec)

	match binary:
		"ps":
			return _cmd_ps(args)
		"top":
			return _cmd_top(args)
		"kill":
			return _cmd_kill(args)
		"killall":
			return _cmd_killall(args)
		"pkill":
			return _cmd_killall(args)
		"chmod":
			return _cmd_chmod(args)
		"chown":
			return _cmd_chown(args)
		"ls":
			return _cmd_ls(args)
		"pwd":
			return { "output": "[color=#77ff99]" + current_path + "[/color]", "is_risky": false, "is_error": false, "error_message": "" }
		"cd":
			return _cmd_cd(args)
		"cat":
			return _cmd_cat(args)
		"clear":
			return { "output": "__CLEAR__", "is_risky": false, "is_error": false, "error_message": "" }
		"whoami":
			return { "output": current_user, "is_risky": false, "is_error": false, "error_message": "" }
		"id":
			return { "output": "uid=1000(user) gid=1000(user) groups=1000(user),27(sudo)", "is_risky": false, "is_error": false, "error_message": "" }
		"echo":
			return { "output": " ".join(args), "is_risky": false, "is_error": false, "error_message": "" }
		"help", "man":
			return _cmd_help()
		_:
			# FA-03.01: Comando no reconocido o no permitido
			var msg: String = "bash: %s: orden no encontrada. Escribe 'help' para ver los comandos permitidos." % binary
			return {
				"output": "[color=#ff6666]" + msg + "[/color]",
				"is_risky": false,
				"is_error": true,
				"error_message": msg
			}

# ==================== COMANDOS DE PROCESOS ====================

func _cmd_ps(args: Array[String]) -> Dictionary:
	var lines: Array[String] = []
	lines.append("[color=#aaccff]USER       PID  %CPU  %MEM    TIME  COMMAND[/color]")

	var is_aux: bool = false
	for arg in args:
		if "a" in arg or "u" in arg or "x" in arg or "e" in arg or "f" in arg or "-" in arg:
			is_aux = true

	for p in processes:
		# Si no es aux/ef, solo muestra procesos del usuario actual
		if not is_aux and p.get("user", "") != current_user:
			continue

		var p_user: String = str(p.get("user", "user")).rpad(8)
		var p_pid: String = str(p.get("pid", 0)).rpad(5)
		var p_cpu: String = ("%.1f" % float(p.get("cpu", 0.0))).rpad(5)
		var p_mem: String = ("%.1f" % float(p.get("mem", 0.0))).rpad(5)
		var p_cmd: String = str(p.get("cmd", ""))

		var color_tag: String = "#ffffff"
		if p.get("critical", false):
			color_tag = "#77bbff"
		elif p.get("target", false):
			color_tag = "#ff7777" # Resaltado como sospechoso / objetivo

		lines.append("[color=%s]%s  %s  %s  %s  00:00  %s[/color]" % [color_tag, p_user, p_pid, p_cpu, p_mem, p_cmd])

	return { "output": "\n".join(lines), "is_risky": false, "is_error": false, "error_message": "" }

func _cmd_top(_args: Array[String]) -> Dictionary:
	var lines: Array[String] = []
	lines.append("[color=#00e676]top - %s up 2:14, 1 user, load average: 0.85, 0.62, 0.45[/color]" % Time.get_time_string_from_system())
	lines.append("[color=#aaccff]Tareas: %d total, 1 en ejecución, %d durmiendo[/color]" % [processes.size(), processes.size() - 1])
	lines.append("[color=#aaccff]USER       PID  %CPU  %MEM  COMMAND[/color]")

	# Ordenar por CPU descendente para simular top
	var sorted_procs: Array = processes.duplicate(true)
	sorted_procs.sort_custom(func(a, b): return float(a.get("cpu", 0.0)) > float(b.get("cpu", 0.0)))

	for i in range(mini(6, sorted_procs.size())):
		var p: Dictionary = sorted_procs[i]
		var color_tag: String = "#ff5555" if p.get("target", false) else "#ffffff"
		lines.append("[color=%s]%s  %s  %s  %s  %s[/color]" % [
			color_tag,
			str(p.get("user", "user")).rpad(8),
			str(p.get("pid", 0)).rpad(5),
			("%.1f" % float(p.get("cpu", 0.0))).rpad(5),
			("%.1f" % float(p.get("mem", 0.0))).rpad(5),
			str(p.get("cmd", ""))
		])

	return { "output": "\n".join(lines), "is_risky": false, "is_error": false, "error_message": "" }

func _cmd_kill(args: Array[String]) -> Dictionary:
	if args.is_empty():
		return {
			"output": "[color=#ffbb33]kill: uso: kill [-s señal | -n num_señal | -señal] pid ...[/color]\n[color=#888888]Ejemplo: kill 1420 o kill -9 1420[/color]",
			"is_risky": false,
			"is_error": true,
			"error_message": "Sintaxis incorrecta de kill"
		}

	# Extraer señal y PID
	var pid_str: String = ""
	for arg in args:
		if not arg.begins_with("-"):
			pid_str = arg
			break

	if pid_str == "" or not pid_str.is_valid_int():
		return {
			"output": "[color=#ff6666]kill: argumento '%s' inválido. Debe ser un PID numérico.[/color]" % str(args),
			"is_risky": false,
			"is_error": true,
			"error_message": "PID no numérico"
		}

	var target_pid: int = pid_str.to_int()
	var proc_idx: int = -1
	var found_proc: Dictionary = {}

	for i in range(processes.size()):
		if int(processes[i].get("pid", -1)) == target_pid:
			proc_idx = i
			found_proc = processes[i]
			break

	if proc_idx == -1:
		# FA-03.01: Proceso no existe
		var err := "bash: kill: (%d) - No existe el proceso" % target_pid
		return { "output": "[color=#ff6666]" + err + "[/color]", "is_risky": false, "is_error": true, "error_message": err }

	# FA-04.01: Verificar si es un proceso crítico del sistema
	if found_proc.get("critical", false):
		var danger_msg: String = "[⚠️ ALERTA CRÍTICA DEL KERNEL]\nHas intentado terminar un proceso esencial del sistema operativo: '%s' (PID %d).\n¡El sistema se volvió inestable y previno un kernel panic! (-1 Vida)" % [found_proc.get("cmd", ""), target_pid]
		restore_snapshot()
		risky_action_detected.emit(danger_msg)
		return {
			"output": "[color=#ff2222]" + danger_msg + "[/color]",
			"is_risky": true,
			"is_error": false,
			"error_message": "Terminación de proceso crítico"
		}

	# Proceso terminado exitosamente
	var killed_name: String = found_proc.get("cmd", "")
	processes.remove_at(proc_idx)
	state_changed.emit()

	var success_msg := "[color=#33ff77]Proceso [PID %d] '%s' terminado exitosamente.[/color]" % [target_pid, killed_name]
	return { "output": success_msg, "is_risky": false, "is_error": false, "error_message": "" }

func _cmd_killall(args: Array[String]) -> Dictionary:
	if args.is_empty():
		return {
			"output": "[color=#ffbb33]killall: uso: killall [-9] nombre_proceso[/color]",
			"is_risky": false,
			"is_error": true,
			"error_message": "Sintaxis incorrecta de killall"
		}

	var proc_name: String = ""
	for arg in args:
		if not arg.begins_with("-"):
			proc_name = arg.strip_edges()
			break

	if proc_name == "":
		return { "output": "[color=#ff6666]killall: especifica el nombre del proceso.[/color]", "is_risky": false, "is_error": true, "error_message": "Nombre vacío" }

	var matched_indices: Array[int] = []
	var has_critical: bool = false
	var critical_name: String = ""
	var critical_pid: int = 0

	for i in range(processes.size()):
		if processes[i].get("cmd", "").to_lower() == proc_name.to_lower():
			if processes[i].get("critical", false):
				has_critical = true
				critical_name = processes[i].get("cmd", "")
				critical_pid = processes[i].get("pid", 0)
			matched_indices.append(i)

	if matched_indices.is_empty():
		var err := "killall: %s: ningún proceso encontrado" % proc_name
		return { "output": "[color=#ff6666]" + err + "[/color]", "is_risky": false, "is_error": true, "error_message": err }

	# FA-04.01: Si intenta matar un proceso crítico
	if has_critical:
		var danger_msg := "[⚠️ ALERTA CRÍTICA DEL KERNEL]\nHas intentado terminar en masa el proceso protegido '%s' (PID %d).\n¡Se interrumpió la operación para evitar el colapso del sistema! (-1 Vida)" % [critical_name, critical_pid]
		restore_snapshot()
		risky_action_detected.emit(danger_msg)
		return { "output": "[color=#ff2222]" + danger_msg + "[/color]", "is_risky": true, "is_error": false, "error_message": "killall a proceso crítico" }

	# Eliminar de atrás hacia adelante
	matched_indices.reverse()
	for idx in matched_indices:
		processes.remove_at(idx)

	state_changed.emit()
	return {
		"output": "[color=#33ff77]Se terminaron exitosamente %d instancia(s) de '%s'.[/color]" % [matched_indices.size(), proc_name],
		"is_risky": false,
		"is_error": false,
		"error_message": ""
	}

# ==================== COMANDOS DE PERMISOS Y ARCHIVOS ====================

func _cmd_chmod(args: Array[String]) -> Dictionary:
	if args.size() < 2:
		return {
			"output": "[color=#ffbb33]chmod: modo de uso: chmod [OPCIÓN] MODO ARCHIVO...\nEjemplos: chmod 755 script.sh | chmod +x script.sh | chmod 600 clave.pem[/color]",
			"is_risky": false,
			"is_error": true,
			"error_message": "Sintaxis chmod incompleta"
		}

	var mode_arg: String = args[0]
	var file_arg: String = args[1]
	if mode_arg.begins_with("-R") and args.size() >= 3:
		mode_arg = args[1]
		file_arg = args[2]

	var file_info: Dictionary = _resolve_file_entry(file_arg)
	if file_info.is_empty():
		var err := "chmod: no se puede acceder a '%s': No existe el archivo o el directorio" % file_arg
		return { "output": "[color=#ff6666]" + err + "[/color]", "is_risky": false, "is_error": true, "error_message": err }

	# FA-04.01: Comprobación de acciones riesgosas con permisos
	# Ejemplo: darle permisos 777 a un backdoor peligroso, o quitar permisos a carpetas raíz
	var fname: String = file_arg.get_file()
	if fname.contains("backdoor") and (mode_arg == "777" or mode_arg == "+x" or mode_arg == "u+x" or mode_arg == "a+rwx"):
		var danger_msg := "[⚠️ ACCIÓN RIESGOSA]\n¡Has otorgado permisos de ejecución máxima a un script malicioso (%s)!\nEsto compromete por completo la seguridad del servidor. (-1 Vida)" % fname
		restore_snapshot()
		risky_action_detected.emit(danger_msg)
		return { "output": "[color=#ff2222]" + danger_msg + "[/color]", "is_risky": true, "is_error": false, "error_message": "Permiso riesgoso a malware" }

	if mode_arg == "000" and (fname == "bin" or fname == "etc" or fname == "/" or fname == "start_server.sh"):
		var danger_msg := "[⚠️ ACCIÓN RIESGOSA]\n¡Has revocado todos los permisos (000) a un recurso vital del sistema (%s)!\nEl servicio no puede iniciarse. (-1 Vida)" % fname
		restore_snapshot()
		risky_action_detected.emit(danger_msg)
		return { "output": "[color=#ff2222]" + danger_msg + "[/color]", "is_risky": true, "is_error": false, "error_message": "Permisos 000 en archivo vital" }

	# Calcular nueva cadena de permisos (ej. -rwxr-xr-x)
	var new_perms: String = _calculate_permissions(file_info.get("perms", "-rw-r--r--"), mode_arg, file_info.get("is_dir", false))
	if new_perms == "":
		var err := "chmod: modo inválido: '%s'. Usa notación octal (ej. 755, 644, 600) o simbólica (+x, -x, u+w, o-r)." % mode_arg
		return { "output": "[color=#ff6666]" + err + "[/color]", "is_risky": false, "is_error": true, "error_message": err }

	# Aplicar permisos al archivo simulado
	file_info["perms"] = new_perms
	state_changed.emit()

	# En Linux, chmod tiene salida silenciosa por defecto en éxito
	return { "output": "", "is_risky": false, "is_error": false, "error_message": "" }

func _cmd_chown(args: Array[String]) -> Dictionary:
	if args.size() < 2:
		return {
			"output": "[color=#ffbb33]chown: modo de uso: chown [PROPIETARIO][:GRUPO] ARCHIVO...\nEjemplo: chown admin service.conf[/color]",
			"is_risky": false,
			"is_error": true,
			"error_message": "Sintaxis chown incompleta"
		}

	var owner_arg: String = args[0]
	var file_arg: String = args[1]

	var file_info: Dictionary = _resolve_file_entry(file_arg)
	if file_info.is_empty():
		var err := "chown: no se puede acceder a '%s': No existe el archivo o el directorio" % file_arg
		return { "output": "[color=#ff6666]" + err + "[/color]", "is_risky": false, "is_error": true, "error_message": err }

	var new_owner: String = owner_arg
	var new_group: String = ""
	if ":" in owner_arg:
		var spl := owner_arg.split(":")
		new_owner = spl[0]
		if spl.size() > 1:
			new_group = spl[1]
	elif "." in owner_arg:
		var spl := owner_arg.split(".")
		new_owner = spl[0]
		if spl.size() > 1:
			new_group = spl[1]

	file_info["owner"] = new_owner
	if new_group != "":
		file_info["group"] = new_group

	state_changed.emit()
	return { "output": "", "is_risky": false, "is_error": false, "error_message": "" }

func _cmd_ls(args: Array[String]) -> Dictionary:
	var show_long: bool = false
	var show_all: bool = false

	for arg in args:
		if arg.begins_with("-"):
			if "l" in arg:
				show_long = true
			if "a" in arg:
				show_all = true

	var dir_info: Dictionary = simulated_fs.get(current_path, {})
	var dirs: Array = dir_info.get("dirs", [])
	var files: Dictionary = dir_info.get("files", {})

	var lines: Array[String] = []

	if show_long:
		lines.append("[color=#888888]total %d[/color]" % (dirs.size() + files.size() * 4))
		if show_all:
			lines.append("[color=#55aaff]drwxr-xr-x  2 %s %s  4096 Nov 10 04:00 .[/color]" % [current_user, current_user])
			lines.append("[color=#55aaff]drwxr-xr-x  4 root root  4096 Nov 10 03:00 ..[/color]")

		for d in dirs:
			var d_info: Dictionary = simulated_fs.get(current_path + "/" + d, {})
			var d_perms: String = str(d_info.get("perms", "drwxr-xr-x"))
			var d_owner: String = str(d_info.get("owner", current_user)).rpad(8)
			var d_group: String = str(d_info.get("group", current_user)).rpad(8)
			lines.append("[color=#55aaff]%s  2 %s %s  4096 Nov 10 04:00 %s/[/color]" % [d_perms, d_owner, d_group, d])

		for fname in files.keys():
			var f: Dictionary = files[fname]
			var f_perms: String = str(f.get("perms", "-rw-r--r--"))
			var f_owner: String = str(f.get("owner", current_user)).rpad(8)
			var f_group: String = str(f.get("group", current_user)).rpad(8)
			var f_size: String = str(f.get("size", 1024)).lpad(6)

			var color_tag: String = "#ffffff"
			if "x" in f_perms.substr(1, 3):
				color_tag = "#33ff77" # Verde si es ejecutable
			elif f_perms.begins_with("d"):
				color_tag = "#55aaff"

			lines.append("[color=%s]%s  1 %s %s %s Nov 10 04:00 %s[/color]" % [color_tag, f_perms, f_owner, f_group, f_size, fname])

		return { "output": "\n".join(lines), "is_risky": false, "is_error": false, "error_message": "" }
	else:
		var items: Array[String] = []
		if show_all:
			items.append("[color=#55aaff].[/color]")
			items.append("[color=#55aaff]..[/color]")

		for d in dirs:
			items.append("[color=#55aaff]" + d + "/[/color]")

		for fname in files.keys():
			var f: Dictionary = files[fname]
			var perms: String = str(f.get("perms", "-rw-r--r--"))
			if "x" in perms.substr(1, 3):
				items.append("[color=#33ff77]" + fname + "[/color]")
			else:
				items.append("[color=#ffffff]" + fname + "[/color]")

		return { "output": "  ".join(items), "is_risky": false, "is_error": false, "error_message": "" }

func _cmd_cd(args: Array[String]) -> Dictionary:
	if args.is_empty() or args[0] == "~":
		current_path = "/home/user"
		return { "output": "", "is_risky": false, "is_error": false, "error_message": "" }

	var target := args[0]
	if target == "..":
		var parts: Array = current_path.split("/", false)
		if parts.size() > 1:
			parts.pop_back()
			current_path = "/" + "/".join(parts)
		else:
			current_path = "/"
		return { "output": "", "is_risky": false, "is_error": false, "error_message": "" }

	var new_path: String = (current_path + "/" + target) if current_path != "/" else ("/" + target)
	if simulated_fs.has(new_path):
		# Verificar si tiene permiso de ejecución para entrar (x)
		var d_info: Dictionary = simulated_fs[new_path]
		var perms: String = str(d_info.get("perms", "drwxr-xr-x"))
		if not perms.contains("x"):
			var err := "bash: cd: %s: Permiso denegado" % target
			return { "output": "[color=#ff6666]" + err + "[/color]", "is_risky": false, "is_error": true, "error_message": err }

		current_path = new_path
		return { "output": "", "is_risky": false, "is_error": false, "error_message": "" }

	var err := "bash: cd: %s: No existe el archivo o el directorio" % target
	return { "output": "[color=#ff6666]" + err + "[/color]", "is_risky": false, "is_error": true, "error_message": err }

func _cmd_cat(args: Array[String]) -> Dictionary:
	if args.is_empty():
		return { "output": "[color=#ffbb33]cat: uso: cat archivo[/color]", "is_risky": false, "is_error": true, "error_message": "Falta archivo" }

	var fname: String = args[0]
	var file_info: Dictionary = _resolve_file_entry(fname)
	if file_info.is_empty():
		var err := "cat: %s: No existe el archivo o el directorio" % fname
		return { "output": "[color=#ff6666]" + err + "[/color]", "is_risky": false, "is_error": true, "error_message": err }

	var perms: String = str(file_info.get("perms", "-rw-r--r--"))
	if not perms.contains("r"):
		var err := "cat: %s: Permiso denegado" % fname
		return { "output": "[color=#ff6666]" + err + "[/color]", "is_risky": false, "is_error": true, "error_message": err }

	var content: String = str(file_info.get("content", "(archivo vacío)"))
	return { "output": "[color=#dddddd]" + content + "[/color]", "is_risky": false, "is_error": false, "error_message": "" }

func _cmd_exec_script(script_name: String, check_exec_bit: bool) -> Dictionary:
	var file_info: Dictionary = _resolve_file_entry(script_name)
	if file_info.is_empty():
		var err := "bash: ./%s: No existe el archivo o el directorio" % script_name
		return { "output": "[color=#ff6666]" + err + "[/color]", "is_risky": false, "is_error": true, "error_message": err }

	var perms: String = str(file_info.get("perms", "-rw-r--r--"))
	if check_exec_bit and not perms.substr(1, 3).contains("x"):
		var err := "bash: ./%s: Permiso denegado (requiere 'chmod +x %s')" % [script_name, script_name]
		return { "output": "[color=#ff6666]" + err + "[/color]", "is_risky": false, "is_error": true, "error_message": err }

	if script_name.contains("backdoor"):
		var danger_msg := "[⚠️ ACCIÓN RIESGOSA]\n¡Has ejecutado el script malicioso backdoor.sh!\nSe abrió una puerta trasera no autorizada en el servidor. (-1 Vida)"
		restore_snapshot()
		risky_action_detected.emit(danger_msg)
		return { "output": "[color=#ff2222]" + danger_msg + "[/color]", "is_risky": true, "is_error": false, "error_message": "Ejecución de malware" }

	return {
		"output": "[color=#33ff77][+] Ejecutando '%s'...[/color]\n[color=#ffffff]%s[/color]\n[color=#00e676][✓ Script finalizado con código de salida 0][/color]" % [script_name, str(file_info.get("content", ""))],
		"is_risky": false,
		"is_error": false,
		"error_message": ""
	}

func _cmd_help() -> Dictionary:
	var h: Array[String] = [
		"[color=#00e676]=== COMANDOS SIMULADOS DISPONIBLES EN ESTA TERMINAL ===[/color]",
		"• [color=#77ff99]ps aux[/color]    : Lista todos los procesos activos con su PID y uso de CPU.",
		"• [color=#77ff99]top[/color]       : Monitor interactivo de procesos con mayor carga de trabajo.",
		"• [color=#77ff99]kill <PID>[/color] : Termina un proceso por su ID (ej. kill 1420 o kill -9 1420).",
		"• [color=#77ff99]killall <nombre>[/color]: Termina todos los procesos con dicho nombre.",
		"• [color=#77ff99]ls -l[/color]     : Lista detallada de archivos, propietarios y permisos rwx.",
		"• [color=#77ff99]chmod <modo> <arch>[/color]: Cambia permisos en notación octal (755, 600) o simbólica (+x, -x).",
		"• [color=#77ff99]chown <user> <arch>[/color]: Cambia el usuario propietario del archivo.",
		"• [color=#77ff99]cat <arch>[/color]: Lee y muestra el contenido de un archivo.",
		"• [color=#77ff99]pwd / cd / clear[/color]: Navegación y limpieza de pantalla.",
		"[color=#ffcc00]¡CUIDADO! Terminar procesos esenciales del kernel provocará inestabilidad.[/color]"
	]
	return { "output": "\n".join(h), "is_risky": false, "is_error": false, "error_message": "" }

# ==================== UTILIDADES DE PARSEO Y PERMISOS ====================

func _resolve_file_entry(filepath: String) -> Dictionary:
	var dir_info: Dictionary = simulated_fs.get(current_path, {})
	var files: Dictionary = dir_info.get("files", {})

	# Archivo directo en directorio actual
	if files.has(filepath):
		var f: Dictionary = files[filepath]
		f["is_dir"] = false
		return f

	# Carpeta en directorio actual
	var dirs: Array = dir_info.get("dirs", [])
	if dirs.has(filepath):
		var full_d: String = (current_path + "/" + filepath) if current_path != "/" else ("/" + filepath)
		var d_info: Dictionary = simulated_fs.get(full_d, {})
		d_info["is_dir"] = true
		return d_info

	# Ruta absoluta
	if simulated_fs.has(filepath):
		var d_info: Dictionary = simulated_fs[filepath]
		d_info["is_dir"] = true
		return d_info

	return {}

func _calculate_permissions(old_perms: String, mode: String, is_dir: bool) -> String:
	var prefix: String = "d" if is_dir else "-"

	# Notación octal de 3 dígitos (ej. 755, 644, 600, 777, 700)
	if mode.length() == 3 and mode.is_valid_int():
		var u := mode.substr(0, 1).to_int()
		var g := mode.substr(1, 1).to_int()
		var o := mode.substr(2, 1).to_int()
		return prefix + _octal_to_rwx(u) + _octal_to_rwx(g) + _octal_to_rwx(o)

	# Notación simbólica (+x, -x, u+x, u-w, g+w, o-r, etc.)
	var clean_old: String = old_perms
	if clean_old.length() < 10:
		clean_old = prefix + "rw-r--r--"

	var user_part: String = clean_old.substr(1, 3)
	var group_part: String = clean_old.substr(4, 3)
	var other_part: String = clean_old.substr(7, 3)

	match mode:
		"+x", "a+x":
			user_part = _set_bit(user_part, 2, "x")
			group_part = _set_bit(group_part, 2, "x")
			other_part = _set_bit(other_part, 2, "x")
		"-x", "a-x":
			user_part = _set_bit(user_part, 2, "-")
			group_part = _set_bit(group_part, 2, "-")
			other_part = _set_bit(other_part, 2, "-")
		"u+x":
			user_part = _set_bit(user_part, 2, "x")
		"u-x":
			user_part = _set_bit(user_part, 2, "-")
		"u+w":
			user_part = _set_bit(user_part, 1, "w")
		"u-w":
			user_part = _set_bit(user_part, 1, "-")
		"g+w":
			group_part = _set_bit(group_part, 1, "w")
		"g-w":
			group_part = _set_bit(group_part, 1, "-")
		"g+rx", "g+xr":
			group_part = _set_bit(group_part, 0, "r")
			group_part = _set_bit(group_part, 2, "x")
		"g+x":
			group_part = _set_bit(group_part, 2, "x")
		"g-x":
			group_part = _set_bit(group_part, 2, "-")
		"o-r":
			other_part = _set_bit(other_part, 0, "-")
		"o-w":
			other_part = _set_bit(other_part, 1, "-")
		"o-x":
			other_part = _set_bit(other_part, 2, "-")
		"o-rwx", "o-rx", "o-rw":
			other_part = "---"
		"600":
			return prefix + "rw-------"
		"644":
			return prefix + "rw-r--r--"
		"664":
			return prefix + "rw-rw-r--"
		"755":
			return prefix + "rwxr-xr-x"
		"700":
			return prefix + "rwx------"
		"750":
			return prefix + "rwxr-x---"
		"777":
			return prefix + "rwxrwxrwx"
		_:
			return "" # Inválido

	return prefix + user_part + group_part + other_part

func _set_bit(rwx: String, index: int, char_val: String) -> String:
	var chars: PackedStringArray = []
	for i in range(rwx.length()):
		chars.append(rwx.substr(i, 1))
	if index < chars.size():
		chars[index] = char_val
	return "".join(chars)

func _octal_to_rwx(n: int) -> String:
	var r: String = "r" if (n & 4) != 0 else "-"
	var w: String = "w" if (n & 2) != 0 else "-"
	var x: String = "x" if (n & 1) != 0 else "-"
	return r + w + x

func _parse_tokens(line: String) -> Array[String]:
	var tokens: Array[String] = []
	var cur: String = ""
	var in_quotes: bool = false
	var quote_char: String = ""

	for i in range(line.length()):
		var c: String = line.substr(i, 1)
		if (c == "\"" or c == "'") and not in_quotes:
			in_quotes = true
			quote_char = c
		elif in_quotes and c == quote_char:
			in_quotes = false
			quote_char = ""
		elif c == " " and not in_quotes:
			if cur != "":
				tokens.append(cur)
				cur = ""
		else:
			cur += c

	if cur != "":
		tokens.append(cur)

	return tokens
