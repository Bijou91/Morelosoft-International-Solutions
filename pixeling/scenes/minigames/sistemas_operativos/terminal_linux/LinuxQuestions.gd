## LinuxQuestions.gd - Banco de preguntas pedagógicas para CU-16: Linux Command
## Morelosoft International Solutions - Materia: Sistemas Operativos y Linux
class_name LinuxQuestions extends RefCounted

const QUESTIONS := {
	"FACIL": [
		{
			"command": "pwd",
			"situation": "¿Cuál comando imprime la ruta absoluta del directorio donde te encuentras ubicado actualmente?",
			"distractors": ["cd", "ls", "whoami", "dir", "path"],
			"feedback_correct": "¡Excelente! 'pwd' (Print Working Directory) muestra tu ubicación actual en el árbol de directorios.",
			"feedback_wrong": "No es correcto. El comando 'pwd' muestra el directorio de trabajo actual (Print Working Directory)."
		},
		{
			"command": "ls",
			"situation": "Necesitas listar y visualizar los archivos y carpetas contenidos en el directorio actual. ¿Qué comando utilizas?",
			"distractors": ["cat", "pwd", "show", "dir", "tree"],
			"feedback_correct": "¡Muy bien! 'ls' (List) enumera los archivos y subdirectorios del directorio actual.",
			"feedback_wrong": "Recuerda que 'ls' es el comando estándar para listar contenidos de un directorio."
		},
		{
			"command": "cd",
			"situation": "¿Qué comando te permite cambiar de directorio y navegar hacia otra carpeta del sistema?",
			"distractors": ["mv", "goto", "pwd", "mkdir", "jump"],
			"feedback_correct": "¡Correcto! 'cd' (Change Directory) te traslada a otra ruta del sistema de archivos.",
			"feedback_wrong": "Incorrecto. 'cd' (Change Directory) es el comando para desplazarte entre carpetas."
		},
		{
			"command": "clear",
			"situation": "La terminal está llena de texto y comandos previos. ¿Qué comando limpia la pantalla de la consola?",
			"distractors": ["clean", "cls", "reset", "erase", "exit"],
			"feedback_correct": "¡Exacto! 'clear' limpia visualmente la pantalla de la terminal sin borrar tu historial.",
			"feedback_wrong": "Incorrecto. En sistemas Unix/Linux se utiliza 'clear' para limpiar el contenido visible de la terminal."
		},
		{
			"command": "mkdir",
			"situation": "Quieres crear una nueva carpeta llamada 'proyectos'. ¿Cuál comando permite crear un nuevo directorio?",
			"distractors": ["touch", "newdir", "md", "create", "make"],
			"feedback_correct": "¡Bien hecho! 'mkdir' (Make Directory) crea uno o varios nuevos directorios.",
			"feedback_wrong": "Incorrecto. Para crear carpetas o directorios se emplea 'mkdir' (Make Directory)."
		},
		{
			"command": "touch",
			"situation": "Deseas crear un archivo vacío llamado 'notas.txt' de forma rápida. ¿Qué comando debes ejecutar?",
			"distractors": ["mkdir", "cat", "new", "nano", "echo"],
			"feedback_correct": "¡Acertaste! 'touch' crea archivos vacíos de manera inmediata o actualiza su marca temporal.",
			"feedback_wrong": "Para crear un archivo en blanco rápidamente sin abrir un editor, se utiliza 'touch'."
		},
		{
			"command": "cat",
			"situation": "Quieres ver el contenido completo de un archivo de texto directamente en la pantalla de la terminal. ¿Qué comando usas?",
			"distractors": ["touch", "ls", "read", "view", "open"],
			"feedback_correct": "¡Correcto! 'cat' (Concatenate) muestra el contenido de archivos en la salida estándar de la terminal.",
			"feedback_wrong": "El comando 'cat' permite concatenar y mostrar el contenido de archivos de texto en pantalla."
		}
	],
	"NORMAL": [
		{
			"command": "cp",
			"situation": "Necesitas hacer una copia de seguridad del archivo 'codigo.c' hacia 'codigo_backup.c'. ¿Qué comando ejecutas?",
			"distractors": ["mv", "rm", "clone", "duplicate", "ln"],
			"feedback_correct": "¡Exacto! 'cp' (Copy) copia archivos y directorios manteniendo intacto el original.",
			"feedback_wrong": "Para duplicar o respaldar archivos sin mover el original, se utiliza 'cp'."
		},
		{
			"command": "mv",
			"situation": "Quieres mover un archivo a otra carpeta o cambiarle el nombre a 'tarea_final.txt'. ¿Qué comando utilizas?",
			"distractors": ["cp", "rename", "transfer", "rm", "shift"],
			"feedback_correct": "¡Muy bien! 'mv' (Move) traslada archivos de ubicación y también sirve para renombrarlos.",
			"feedback_wrong": "Recuerda que en Linux 'mv' sirve tanto para mover como para renombrar archivos."
		},
		{
			"command": "rm",
			"situation": "¿Qué comando elimina de forma definitiva un archivo del sistema de archivos?",
			"distractors": ["del", "mv", "erase", "trash", "rmdir"],
			"feedback_correct": "¡Correcto! 'rm' (Remove) elimina archivos permanentemente. ¡Úsalo con precaución!",
			"feedback_wrong": "El comando para borrar archivos en Linux es 'rm' (Remove)."
		},
		{
			"command": "ls -l",
			"situation": "¿Qué comando y opción lista los archivos con formato largo, mostrando permisos, propietario, tamaño y fecha?",
			"distractors": ["ls -a", "ls", "dir /w", "ls -all", "stat"],
			"feedback_correct": "¡Excelente! 'ls -l' (Long format) lista detalles completos de permisos y atributos.",
			"feedback_wrong": "La opción '-l' con 'ls' es la encargada del formato de listado largo y detallado."
		},
		{
			"command": "ls -a",
			"situation": "Hay archivos de configuración ocultos que empiezan con un punto (.) y no se ven. ¿Cómo listas todos los archivos?",
			"distractors": ["ls -l", "ls -h", "show -hidden", "dir -all", "ls -x"],
			"feedback_correct": "¡Acertaste! 'ls -a' (All) muestra todos los archivos, incluyendo los ocultos que inician con '.'",
			"feedback_wrong": "Para visualizar archivos ocultos en Linux debes usar 'ls -a' (All)."
		},
		{
			"command": "cd ..",
			"situation": "Estás dentro de '/home/usuario/descargas' y quieres retroceder al directorio superior ('/home/usuario'). ¿Qué comando ejecutas?",
			"distractors": ["cd ~", "cd /", "cd -", "back", "up"],
			"feedback_correct": "¡Muy bien! 'cd ..' navega al directorio padre inmediatamente superior.",
			"feedback_wrong": "Dos puntos '..' representan el directorio padre en rutas de Unix/Linux."
		},
		{
			"command": "cd ~",
			"situation": "Sin importar en qué carpeta estés navegando, ¿cuál comando te regresa directo al directorio personal (home) de tu usuario?",
			"distractors": ["cd ..", "cd /", "home", "cd root", "pwd"],
			"feedback_correct": "¡Exacto! 'cd ~' (o simplemente 'cd') te transporta de inmediato a tu directorio personal.",
			"feedback_wrong": "La tilde de la eñe '~' representa el directorio home del usuario actual."
		},
		{
			"command": "head",
			"situation": "Tienes un archivo de 10,000 líneas y solo quieres inspeccionar las primeras 10 líneas. ¿Qué comando utilizas?",
			"distractors": ["tail", "cat", "first", "top", "less"],
			"feedback_correct": "¡Bien hecho! 'head' muestra por defecto las primeras 10 líneas de cualquier archivo.",
			"feedback_wrong": "El comando para ver la cabecera (primeras líneas) de un archivo es 'head'."
		},
		{
			"command": "tail",
			"situation": "Un archivo de bitácora (log) sigue creciendo y necesitas ver sus últimas líneas. ¿Qué comando utilizas?",
			"distractors": ["head", "less", "last", "bottom", "cat"],
			"feedback_correct": "¡Correcto! 'tail' muestra el final de un archivo, ideal para monitorizar logs.",
			"feedback_wrong": "Para observar las últimas líneas de un archivo se emplea 'tail'."
		},
		{
			"command": "less",
			"situation": "Deseas leer un archivo de texto largo página por página permitiendo avanzar y retroceder con el teclado. ¿Qué visor usas?",
			"distractors": ["cat", "head", "tail", "nano", "view"],
			"feedback_correct": "¡Perfecto! 'less' es un paginador interactivo que permite navegar archivos hacia adelante y atrás.",
			"feedback_wrong": "'less' es el paginador moderno recomendado para inspeccionar archivos extensos sin cargarlos enteros."
		},
		{
			"command": "man",
			"situation": "¿Qué comando te permite consultar el manual oficial y la documentación de ayuda de cualquier herramienta en Linux?",
			"distractors": ["help", "info", "guide", "doc", "whatis"],
			"feedback_correct": "¡Excelente! 'man' (Manual) despliega la documentación oficial y parámetros de un comando.",
			"feedback_wrong": "Para leer el manual oficial de un comando en la consola se ejecuta 'man <comando>'."
		}
	],
	"INGENIERO": [
		{
			"command": "grep",
			"situation": "En un proyecto con miles de archivos, necesitas buscar todas las líneas que contengan la palabra 'ERROR_FATAL'. ¿Qué comando usas?",
			"distractors": ["find", "search", "lookup", "locate", "filter"],
			"feedback_correct": "¡Gran acierto! 'grep' busca patrones de texto y expresiones regulares dentro de archivos.",
			"feedback_wrong": "Para buscar texto o expresiones regulares dentro del contenido de archivos se usa 'grep'."
		},
		{
			"command": "find",
			"situation": "Necesitas rastrear en todo el disco duro archivos que tengan extensión '.conf' por su nombre. ¿Qué comando utilizas?",
			"distractors": ["grep", "locate", "whereis", "which", "ls"],
			"feedback_correct": "¡Correcto! 'find' busca archivos y carpetas en el árbol de directorios según nombre, tamaño o fecha.",
			"feedback_wrong": "'find' es la herramienta para localizar archivos por sus atributos en el sistema."
		},
		{
			"command": "chmod",
			"situation": "Un script de bash no tiene permisos de ejecución y necesitas otorgarle permisos (ej. 'chmod +x script.sh'). ¿Qué comando es?",
			"distractors": ["chown", "chgrp", "sudo", "permit", "passwd"],
			"feedback_correct": "¡Exacto! 'chmod' (Change Mode) modifica los permisos de lectura, escritura y ejecución (rwx).",
			"feedback_wrong": "El comando para alterar los permisos de acceso de un archivo es 'chmod'."
		},
		{
			"command": "sudo",
			"situation": "Debes instalar un paquete del sistema que requiere privilegios de superusuario (root). ¿Qué comando antepones?",
			"distractors": ["root", "admin", "su", "exec", "runas"],
			"feedback_correct": "¡Muy bien! 'sudo' (Superuser Do) ejecuta órdenes con privilegios de seguridad administrativos.",
			"feedback_wrong": "'sudo' permite a usuarios autorizados ejecutar comandos con privilegios elevados de superusuario."
		},
		{
			"command": "ps",
			"situation": "¿Qué comando toma una instantánea de los procesos activos que se están ejecutando en tu sesión actual?",
			"distractors": ["top", "tasklist", "proc", "jobs", "kill"],
			"feedback_correct": "¡Correcto! 'ps' (Process Status) informa el estado de los procesos actuales y sus PID.",
			"feedback_wrong": "'ps' muestra el estado estático de los procesos activos en el sistema."
		},
		{
			"command": "top",
			"situation": "Quieres monitorizar en tiempo real el uso de CPU, memoria RAM y procesos que consumen recursos de forma dinámica. ¿Qué comando ejecutas?",
			"distractors": ["ps", "htop", "monitor", "perf", "sysinfo"],
			"feedback_correct": "¡Acertaste! 'top' proporciona una vista interactiva en tiempo real del rendimiento del procesador y memoria.",
			"feedback_wrong": "'top' es la utilidad nativa en tiempo real para supervisar recursos y procesos."
		},
		{
			"command": "kill",
			"situation": "Un proceso en segundo plano se ha congelado con el PID 4321. ¿Qué comando envías para terminarlo o matarlo?",
			"distractors": ["stop", "terminate", "exit", "close", "end"],
			"feedback_correct": "¡Excelente! 'kill' envía señales a procesos (por defecto SIGTERM) para finalizar su ejecución.",
			"feedback_wrong": "Para detener o forzar la terminación de un proceso por su PID se utiliza 'kill'."
		},
		{
			"command": "wc",
			"situation": "Necesitas saber con exactitud el número de líneas, palabras y bytes que componen un archivo de texto. ¿Qué comando usas?",
			"distractors": ["count", "len", "size", "stat", "lines"],
			"feedback_correct": "¡Bien hecho! 'wc' (Word Count) cuenta las líneas (-l), palabras (-w) y caracteres/bytes de archivos.",
			"feedback_wrong": "'wc' (Word Count) calcula el conteo de líneas, palabras y bytes en archivos de texto."
		},
		{
			"command": "sort",
			"situation": "Tienes una lista desordenada de nombres de alumnos y requieres ordenarlos alfabéticamente en la consola. ¿Qué comando utilizas?",
			"distractors": ["order", "uniq", "arrange", "index", "rank"],
			"feedback_correct": "¡Exacto! 'sort' ordena líneas de archivos de texto o entradas de datos alfabética o numéricamente.",
			"feedback_wrong": "Para ordenar información de texto en Linux se utiliza 'sort'."
		},
		{
			"command": "uniq",
			"situation": "Tras ordenar una lista de registros, deseas filtrar y omitir las líneas que están duplicadas de manera consecutiva. ¿Qué comando empleas?",
			"distractors": ["sort", "distinct", "filter", "clean", "dedup"],
			"feedback_correct": "¡Acertaste! 'uniq' filtra y reporta u omite líneas repetidas adyacentes.",
			"feedback_wrong": "'uniq' elimina líneas duplicadas consecutivas en un flujo de datos ordenado."
		},
		{
			"command": "history",
			"situation": "No recuerdas la sintaxis exacta de un comando complejo que tecleaste hace unos minutos. ¿Qué comando lista los comandos ingresados previamente?",
			"distractors": ["log", "past", "prev", "recent", "recall"],
			"feedback_correct": "¡Perfecto! 'history' despliega la lista con numeración de todos los comandos ejecutados en tu sesión de shell.",
			"feedback_wrong": "Para consultar el registro cronológico de comandos escritos en la terminal se usa 'history'."
		}
	]
}

## Retorna 5 preguntas barajadas según la dificultad
static func get_round_questions(difficulty: String) -> Array[Dictionary]:
	var key: String = difficulty.to_upper()
	if not QUESTIONS.has(key):
		key = "NORMAL"

	var pool: Array = QUESTIONS[key].duplicate(true)
	pool.shuffle()
	
	var round_questions: Array[Dictionary] = []
	var count: int = mini(5, pool.size())
	for i in range(count):
		round_questions.append(pool[i])

	return round_questions
