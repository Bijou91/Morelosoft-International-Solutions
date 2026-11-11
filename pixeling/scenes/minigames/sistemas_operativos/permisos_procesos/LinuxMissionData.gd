## LinuxMissionData.gd - Catálogo de Misiones y Evaluador de Objetivos para CU-18
## Morelosoft International Solutions - Sistemas Operativos y Linux
class_name LinuxMissionData extends RefCounted

const MISSIONS := {
	"FACIL": [
		{
			"id": "facil_servidor_web",
			"title": "Misión 1: Servidor Web Estudiantil en Riesgo",
			"situation": "¡El servidor web estudiantil está bloqueado! Un proceso 'miner_rogue' satura el CPU. Además, el script de arranque 'start_server.sh' no tiene permisos de ejecución, y el archivo 'server.conf' está expuesto a otros usuarios.",
			"prompt_user": "user@is-pixelverse:~$",
			"initial_path": "/home/user",
			"initial_processes": [
				{ "pid": 1, "user": "root", "cpu": 0.0, "mem": 0.1, "cmd": "systemd", "critical": true },
				{ "pid": 2, "user": "root", "cpu": 0.0, "mem": 0.0, "cmd": "kthreadd", "critical": true },
				{ "pid": 105, "user": "root", "cpu": 0.0, "mem": 0.2, "cmd": "sshd", "critical": true },
				{ "pid": 210, "user": "user", "cpu": 0.0, "mem": 0.3, "cmd": "bash", "critical": false },
				{ "pid": 842, "user": "user", "cpu": 94.2, "mem": 12.5, "cmd": "miner_rogue", "target": true },
				{ "pid": 901, "user": "www-data", "cpu": 0.1, "mem": 1.1, "cmd": "nginx", "critical": false }
			],
			"initial_fs": {
				"/home/user": {
					"dirs": [],
					"perms": "drwxr-xr-x",
					"owner": "user",
					"group": "user",
					"files": {
						"start_server.sh": {
							"perms": "-rw-r--r--",
							"owner": "user",
							"group": "user",
							"size": 340,
							"content": "#!/bin/bash\necho 'Iniciando servidor Nginx de la UAZ en puerto 8080...'"
						},
						"server.conf": {
							"perms": "-rw-r--r--",
							"owner": "user",
							"group": "user",
							"size": 180,
							"content": "PORT=8080\nDB_PASS=uaz_pixel_2026\nDEBUG=false"
						},
						"readme.txt": {
							"perms": "-rw-r--r--",
							"owner": "user",
							"group": "user",
							"size": 95,
							"content": "Usa 'ps aux' para revisar procesos y 'chmod' para configurar permisos."
						}
					}
				}
			},
			"objectives": [
				{
					"id": "obj_kill_miner",
					"desc": "Terminar el proceso malicioso 'miner_rogue' (kill <PID> o killall miner_rogue)",
					"type": "process_killed",
					"target": "miner_rogue"
				},
				{
					"id": "obj_chmod_exec",
					"desc": "Dar permisos de ejecución a 'start_server.sh' (chmod +x start_server.sh)",
					"type": "file_executable",
					"target": "start_server.sh"
				},
				{
					"id": "obj_protect_conf",
					"desc": "Restringir lectura a otros en 'server.conf' (chmod 600 o chmod o-r server.conf)",
					"type": "file_no_other_read",
					"target": "server.conf"
				}
			]
		},
		{
			"id": "facil_bucle_infinito",
			"title": "Misión 2: Script en Bucle Infinito y Despliegue",
			"situation": "Un script de pruebas 'loop_leak' quedó atascado consumiendo memoria. El archivo de entorno 'database.env' es legible por todos los usuarios y el script 'deploy.sh' no se puede ejecutar.",
			"prompt_user": "user@is-pixelverse:~$",
			"initial_path": "/home/user",
			"initial_processes": [
				{ "pid": 1, "user": "root", "cpu": 0.0, "mem": 0.1, "cmd": "systemd", "critical": true },
				{ "pid": 2, "user": "root", "cpu": 0.0, "mem": 0.0, "cmd": "kthreadd", "critical": true },
				{ "pid": 105, "user": "root", "cpu": 0.0, "mem": 0.2, "cmd": "sshd", "critical": true },
				{ "pid": 350, "user": "user", "cpu": 88.5, "mem": 30.1, "cmd": "loop_leak", "target": true },
				{ "pid": 412, "user": "user", "cpu": 0.0, "mem": 0.3, "cmd": "bash", "critical": false }
			],
			"initial_fs": {
				"/home/user": {
					"dirs": [],
					"perms": "drwxr-xr-x",
					"owner": "user",
					"group": "user",
					"files": {
						"deploy.sh": {
							"perms": "-rw-r--r--",
							"owner": "user",
							"group": "user",
							"size": 420,
							"content": "#!/bin/bash\necho 'Desplegando versión 1.2...'"
						},
						"database.env": {
							"perms": "-rw-rw-rw-",
							"owner": "user",
							"group": "user",
							"size": 210,
							"content": "DB_HOST=127.0.0.1\nDB_PASS=PixelIngSecretKey"
						},
						"notas.txt": {
							"perms": "-rw-r--r--",
							"owner": "user",
							"group": "user",
							"size": 80,
							"content": "Ajusta permisos con chmod y elimina el proceso con kill."
						}
					}
				}
			},
			"objectives": [
				{
					"id": "obj_kill_loop",
					"desc": "Detener el proceso 'loop_leak' (PID 350)",
					"type": "process_killed",
					"target": "loop_leak"
				},
				{
					"id": "obj_chmod_deploy",
					"desc": "Otorgar permisos de ejecución a 'deploy.sh' (chmod +x deploy.sh)",
					"type": "file_executable",
					"target": "deploy.sh"
				},
				{
					"id": "obj_protect_env",
					"desc": "Restringir permisos de 'database.env' para 'otros' (chmod 600 database.env)",
					"type": "file_no_other_read",
					"target": "database.env"
				}
			]
		}
	],
	"NORMAL": [
		{
			"id": "normal_fuga_bd",
			"title": "Misión: Intrusión y Fuga en Base de Datos",
			"situation": "¡Alerta en la base de datos central! Un proceso espía 'spy_daemon' intercepta puertos y un proceso 'db_leak' tiene fuga de memoria. Además, 'db_secret.key' tiene permisos 777 y el directorio 'backup/' no tiene permisos de ejecución para el grupo.",
			"prompt_user": "user@is-pixelverse:~$",
			"initial_path": "/home/user",
			"initial_processes": [
				{ "pid": 1, "user": "root", "cpu": 0.0, "mem": 0.1, "cmd": "systemd", "critical": true },
				{ "pid": 2, "user": "root", "cpu": 0.0, "mem": 0.0, "cmd": "kthreadd", "critical": true },
				{ "pid": 102, "user": "root", "cpu": 0.0, "mem": 0.2, "cmd": "sshd", "critical": true },
				{ "pid": 1420, "user": "mysql", "cpu": 72.1, "mem": 18.2, "cmd": "db_leak", "target": true },
				{ "pid": 1550, "user": "user", "cpu": 45.0, "mem": 5.4, "cmd": "spy_daemon", "target": true },
				{ "pid": 1600, "user": "postgres", "cpu": 0.2, "mem": 2.1, "cmd": "postgres", "critical": false }
			],
			"initial_fs": {
				"/home/user": {
					"dirs": ["backup"],
					"perms": "drwxr-xr-x",
					"owner": "user",
					"group": "user",
					"files": {
						"db_secret.key": {
							"perms": "-rwxrwxrwx",
							"owner": "user",
							"group": "user",
							"size": 512,
							"content": "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0...\n-----END RSA PRIVATE KEY-----"
						},
						"db_monitor.sh": {
							"perms": "-rwxr-xr-x",
							"owner": "user",
							"group": "user",
							"size": 600,
							"content": "#!/bin/bash\nps aux | grep mysql"
						}
					}
				},
				"/home/user/backup": {
					"dirs": [],
					"perms": "drwx---r-x",
					"owner": "user",
					"group": "staff",
					"files": {}
				}
			},
			"objectives": [
				{
					"id": "obj_kill_spy",
					"desc": "Terminar el proceso espía 'spy_daemon' (PID 1550)",
					"type": "process_killed",
					"target": "spy_daemon"
				},
				{
					"id": "obj_kill_leak",
					"desc": "Detener el proceso con fuga 'db_leak' (PID 1420)",
					"type": "process_killed",
					"target": "db_leak"
				},
				{
					"id": "obj_protect_key",
					"desc": "Asegurar 'db_secret.key' asignando permisos solo al dueño (chmod 600 db_secret.key)",
					"type": "file_no_other_read",
					"target": "db_secret.key"
				},
				{
					"id": "obj_backup_exec",
					"desc": "Otorgar permisos de ejecución al grupo en 'backup/' (chmod 750 backup o chmod g+rx backup)",
					"type": "file_group_exec",
					"target": "backup"
				}
			]
		}
	],
	"INGENIERO": [
		{
			"id": "ing_auditoria_cluster",
			"title": "Misión: Auditoría y Desinfección de Producción",
			"situation": "¡Ataque crítico en el cluster de producción UAZ! Un bot descontrolado 'crypto_bot' satura la CPU. Un backdoor 'backdoor.sh' tiene permisos de ejecución, el archivo 'syslog.log' no permite escribir eventos y 'service.conf' tiene como dueño a 'guest' en vez de 'admin'.",
			"prompt_user": "user@is-pixelverse:~$",
			"initial_path": "/home/user",
			"initial_processes": [
				{ "pid": 1, "user": "root", "cpu": 0.0, "mem": 0.1, "cmd": "systemd", "critical": true },
				{ "pid": 2, "user": "root", "cpu": 0.0, "mem": 0.0, "cmd": "kthreadd", "critical": true },
				{ "pid": 88, "user": "root", "cpu": 0.0, "mem": 0.1, "cmd": "cron", "critical": true },
				{ "pid": 201, "user": "root", "cpu": 0.1, "mem": 0.4, "cmd": "auth_service", "critical": true },
				{ "pid": 2890, "user": "user", "cpu": 99.8, "mem": 24.3, "cmd": "crypto_bot", "target": true }
			],
			"initial_fs": {
				"/home/user": {
					"dirs": [],
					"perms": "drwxr-xr-x",
					"owner": "user",
					"group": "user",
					"files": {
						"backdoor.sh": {
							"perms": "-rwxr-xr-x",
							"owner": "user",
							"group": "user",
							"size": 1024,
							"content": "#!/bin/bash\n# MALICIOUS PAYLOAD"
						},
						"syslog.log": {
							"perms": "-r--------",
							"owner": "user",
							"group": "adm",
							"size": 4096,
							"content": "[SYSTEM EVENT LOGS]"
						},
						"service.conf": {
							"perms": "-rw-r--r--",
							"owner": "guest",
							"group": "guest",
							"size": 320,
							"content": "SERVER_MODE=production\nADMIN=true"
						}
					}
				}
			},
			"objectives": [
				{
					"id": "obj_kill_crypto",
					"desc": "Eliminar el proceso voraz 'crypto_bot' (kill -9 2890 o kill 2890)",
					"type": "process_killed",
					"target": "crypto_bot"
				},
				{
					"id": "obj_revoke_backdoor",
					"desc": "Revocar permisos de ejecución a 'backdoor.sh' (chmod -x backdoor.sh)",
					"type": "file_not_executable",
					"target": "backdoor.sh"
				},
				{
					"id": "obj_write_syslog",
					"desc": "Habilitar permisos de escritura en 'syslog.log' (chmod 664 syslog.log o chmod u+w)",
					"type": "file_writable",
					"target": "syslog.log"
				},
				{
					"id": "obj_chown_admin",
					"desc": "Cambiar propietario de 'service.conf' a 'admin' (chown admin service.conf)",
					"type": "file_owner",
					"target": "service.conf",
					"expected": "admin"
				}
			]
		}
	]
}

static func get_random_mission(difficulty: String) -> Dictionary:
	var list: Array = MISSIONS.get(difficulty.to_upper(), MISSIONS["FACIL"])
	if list.is_empty():
		return MISSIONS["FACIL"][0]
	return list[randi() % list.size()]

## Evalúa la lista de objetivos contra el estado actual del shell simulado
## Retorna un Array[bool] del mismo tamaño con el estado de cumplimiento de cada objetivo
static func evaluate_objectives(shell: VirtualLinuxShell, objectives: Array) -> Array[bool]:
	var results: Array[bool] = []
	for obj in objectives:
		var ok: bool = false
		var o_type: String = obj.get("type", "")
		var target: String = obj.get("target", "")

		match o_type:
			"process_killed":
				# Verdadero si ningún proceso activo tiene el nombre target
				var found := false
				for p in shell.processes:
					if str(p.get("cmd", "")).to_lower() == target.to_lower():
						found = true
						break
				ok = not found

			"file_executable":
				# Verdadero si el archivo tiene 'x' en permisos de propietario (índice 3 de -rwxr-xr-x)
				var f_info := shell._resolve_file_entry(target)
				if not f_info.is_empty():
					var perms: String = str(f_info.get("perms", ""))
					if perms.length() >= 4 and perms.substr(3, 1) == "x":
						ok = true

			"file_not_executable":
				# Verdadero si ni el propietario, ni el grupo, ni otros tienen 'x'
				var f_info := shell._resolve_file_entry(target)
				if not f_info.is_empty():
					var perms: String = str(f_info.get("perms", ""))
					ok = not perms.contains("x")

			"file_no_other_read":
				# Verdadero si 'otros' no tienen permiso de lectura ('-' en índice 7) y tampoco escritura
				var f_info := shell._resolve_file_entry(target)
				if not f_info.is_empty():
					var perms: String = str(f_info.get("perms", ""))
					if perms.length() >= 10:
						var other_part := perms.substr(7, 3)
						# Si 'otros' no pueden leer ni escribir
						if not other_part.contains("r") and not other_part.contains("w"):
							ok = true

			"file_group_exec":
				# Verdadero si el grupo tiene permiso 'x' (índice 6 de drwxr-x---)
				var f_info := shell._resolve_file_entry(target)
				if not f_info.is_empty():
					var perms: String = str(f_info.get("perms", ""))
					if perms.length() >= 7 and perms.substr(6, 1) == "x":
						ok = true

			"file_writable":
				# Verdadero si el dueño o grupo tiene permiso de escritura 'w'
				var f_info := shell._resolve_file_entry(target)
				if not f_info.is_empty():
					var perms: String = str(f_info.get("perms", ""))
					if perms.length() >= 3 and perms.substr(2, 1) == "w":
						ok = true

			"file_owner":
				# Verdadero si el propietario coincide con expected
				var expected_owner: String = str(obj.get("expected", "admin"))
				var f_info := shell._resolve_file_entry(target)
				if not f_info.is_empty():
					if str(f_info.get("owner", "")) == expected_owner:
						ok = true

		results.append(ok)

	return results

