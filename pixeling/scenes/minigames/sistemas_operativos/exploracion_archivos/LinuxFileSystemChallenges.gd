## LinuxFileSystemChallenges.gd - Banco de desafíos de exploración para CU-17
## Morelosoft International Solutions - Sistemas Operativos y Linux
class_name LinuxFileSystemChallenges extends RefCounted

const CHALLENGES := {
	"FACIL": [
		{
			"id": "facil_1",
			"situation": "Un alumno novato dejó una flag guardada en un archivo de texto dentro de una de las carpetas de su sesión. Explora el sistema con 'ls', entra a la carpeta con 'cd' y lee el archivo con 'cat'.",
			"available_commands": ["ls", "cd", "cat", "pwd", "clear"],
			"prompt_user": "user@is-pixelverse:~$",
			"initial_path": "/home/user",
			"flag": "Flag{rookie}",
			"files": {
				"/home/user": {
					"dirs": ["documentos", "descargas"],
					"files": {"leeme.txt": "Bienvenido al sistema. Revisa la carpeta documentos."}
				},
				"/home/user/documentos": {
					"dirs": [],
					"files": {"secreto.txt": "¡Felicidades! Tu flag es: Flag{rookie}"}
				},
				"/home/user/descargas": {
					"dirs": [],
					"files": {"instalador.sh": "# Script vacío"}
				}
			}
		},
		{
			"id": "facil_2",
			"situation": "El docente de SO guardó una clave de acceso en una subcarpeta de proyectos. Localiza el archivo de texto y revisa su interior.",
			"available_commands": ["ls", "cd", "cat", "pwd", "clear"],
			"prompt_user": "user@is-pixelverse:~$",
			"initial_path": "/home/user",
			"flag": "Flag{cat}",
			"files": {
				"/home/user": {
					"dirs": ["proyectos", "publico"],
					"files": {"notas.txt": "Revisa los proyectos de la materia."}
				},
				"/home/user/proyectos": {
					"dirs": [],
					"files": {"flag.txt": "Flag{cat}"}
				},
				"/home/user/publico": {
					"dirs": [],
					"files": {"aviso.txt": "Aquí no hay nada interesante."}
				}
			}
		}
	],
	"NORMAL": [
		{
			"id": "normal_1",
			"situation": "La flag fue escondida en un archivo oculto o de respaldo en los directorios de usuario. Necesitas usar 'ls -a' para ver elementos ocultos o 'head'/'tail' para inspeccionar archivos largos.",
			"available_commands": ["ls", "ls -a", "cd", "cat", "head", "tail", "pwd", "clear"],
			"prompt_user": "user@is-pixelverse:~$",
			"initial_path": "/home/user",
			"flag": "Flag{hidden}",
			"files": {
				"/home/user": {
					"dirs": ["tareas", ".config"],
					"files": {
						".flag_oculta.txt": "¡Excelente ojo! La flag es: Flag{hidden}",
						"historial.log": "Registro del sistema:\nlinea 1\nlinea 2\nlinea 3\nlinea 4\nlinea 5\nlinea 6\nlinea 7\nlinea 8\nlinea 9\nlinea 10\nlinea 11"
					}
				},
				"/home/user/tareas": {
					"dirs": [],
					"files": {"tarea1.c": "// Codigo de C"}
				},
				"/home/user/.config": {
					"dirs": [],
					"files": {"settings.conf": "config=1"}
				}
			}
		},
		{
			"id": "normal_2",
			"situation": "Un archivo de bitácora muy largo en '/home/user/logs_backup' contiene la flag registrada al final de los eventos del servidor. Usa 'cd', 'ls' y 'tail' para extraerla.",
			"available_commands": ["ls", "ls -a", "cd", "cat", "head", "tail", "pwd", "clear"],
			"prompt_user": "user@is-pixelverse:~$",
			"initial_path": "/home/user",
			"flag": "Flag{tail}",
			"files": {
				"/home/user": {
					"dirs": ["logs_backup"],
					"files": {"pista.txt": "La flag está en logs_backup/server.log al final del archivo."}
				},
				"/home/user/logs_backup": {
					"dirs": [],
					"files": {
						"server.log": "Evento 1: Servidor iniciado\nEvento 2: Conexión aceptada\nEvento 3: Autenticación exitosa\nEvento 4: Servicio activo\nEvento 5: Flag registrada: Flag{tail}"
					}
				}
			}
		}
	],
	"INGENIERO": [
		{
			"id": "ingeniero_1",
			"situation": "Nivel Auditor de Seguridad: Hay múltiples directorios con archivos de configuración y logs del sistema. Usa 'find' para localizar archivos o 'grep' para filtrar la palabra FLAG directamente entre las líneas.",
			"available_commands": ["ls", "ls -a", "cd", "cat", "grep", "find", "pwd", "clear"],
			"prompt_user": "root@is-pixelverse:/#",
			"initial_path": "/etc",
			"flag": "Flag{grep}",
			"files": {
				"/etc": {
					"dirs": ["security", "network"],
					"files": {
						"motd": "Bienvenido al nodo central.\nUsa grep en security/access.log para hallar la flag.",
						"hosts": "127.0.0.1 localhost"
					}
				},
				"/etc/security": {
					"dirs": [],
					"files": {
						"access.log": "INFO: user admin ok\nWARN: failed attempt\nKEY: token=4819\nFLAG: Encontraste la flag definitiva -> Flag{grep}\nDEBUG: finished dump"
					}
				},
				"/etc/network": {
					"dirs": [],
					"files": {"interfaces": "auto eth0"}
				}
			}
		},
		{
			"id": "ingeniero_2",
			"situation": "Un hacker dejó la flag fragmentada dentro de la estructura '/var'. Encuentra el archivo con 'find' o usa 'grep' sobre los registros de auditoría.",
			"available_commands": ["ls", "ls -a", "cd", "cat", "grep", "find", "pwd", "clear"],
			"prompt_user": "root@is-pixelverse:/#",
			"initial_path": "/var",
			"flag": "Flag{find}",
			"files": {
				"/var": {
					"dirs": ["audit", "crash"],
					"files": {"info.txt": "Busca archivos en /var/audit."}
				},
				"/var/audit": {
					"dirs": [],
					"files": {
						"flag_secured.txt": "Permisos verificados. Flag{find}",
						"sysdump.bin": "DUMP_EMPTY"
					}
				},
				"/var/crash": {
					"dirs": [],
					"files": {}
				}
			}
		}
	]
}

static func get_random_challenge(difficulty: String) -> Dictionary:
	var list: Array = CHALLENGES.get(difficulty, CHALLENGES["FACIL"])
	if list.is_empty():
		return CHALLENGES["FACIL"][0]
	var copy: Array = list.duplicate()
	copy.shuffle()
	return copy[0]
