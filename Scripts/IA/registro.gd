class_name Registro
extends RefCounted

# Bitácora del experimento en CSV, una fila por generación.
#
# Es la materia prima del benchmark cuantitativo que pide el proyecto:
# de aquí salen la velocidad de convergencia, el número de generaciones hasta
# converger, el porcentaje de completitud y la tasa de éxito.
#
# Los archivos quedan en la carpeta de datos de usuario de Godot; en Windows:
#   %APPDATA%\Godot\app_userdata\Genetic Dash OG\ia\

const CARPETA := "user://ia"

# `segundos_sim` es tiempo simulado y `segundos_reloj` tiempo real. Se separan
# porque el entrenamiento puede correr acelerado (x2 a x8): el reloj dice
# cuánto tardó el experimento, pero solo el simulado es comparable entre runs
# hechos a velocidades distintas.
const CABECERA := "generacion,mejor_fitness,fitness_promedio,peor_fitness," \
		+ "completitud_pct,completaron,segundos_gen,segundos_sim,segundos_reloj,delta_pesos"

var ruta := ""

var _archivo: FileAccess
var _t_inicio := 0.0
var _sim_total := 0.0
var _generaciones := 0
var _gen_primera_victoria := -1


func _init(etiqueta: String, config: ConfigIA) -> void:
	DirAccess.make_dir_recursive_absolute(CARPETA)
	ruta = "%s/%s.csv" % [CARPETA, etiqueta]

	_archivo = FileAccess.open(ruta, FileAccess.WRITE)
	if _archivo == null:
		push_error("Registro: no se pudo escribir en %s" % ruta)
		return

	# Los comentarios con '#' documentan la configuración exacta del run, para
	# que cada CSV sea reproducible sin depender de la memoria de nadie.
	_archivo.store_line("# %s" % etiqueta)
	_archivo.store_line("# %s" % config.resumen())
	_archivo.store_line("# config=%s" % JSON.stringify(config.a_dict()))
	_archivo.store_line(CABECERA)
	_archivo.flush()

	_t_inicio = float(Time.get_ticks_msec()) / 1000.0


func registrar(gen: int, fitness: Array, completitud: float, completaron: int,
		segundos_gen: float, delta_pesos: float) -> void:
	if _archivo == null or fitness.is_empty():
		return

	_generaciones = gen
	if completaron > 0 and _gen_primera_victoria < 0:
		_gen_primera_victoria = gen

	var mejor := -INF
	var peor := INF
	var suma := 0.0
	for f in fitness:
		var v := float(f)
		mejor = maxf(mejor, v)
		peor = minf(peor, v)
		suma += v

	_sim_total += segundos_gen
	var reloj := float(Time.get_ticks_msec()) / 1000.0 - _t_inicio
	_archivo.store_line("%d,%.2f,%.2f,%.2f,%.2f,%d,%.3f,%.3f,%.3f,%.5f" % [
		gen, mejor, suma / float(fitness.size()), peor,
		completitud * 100.0, completaron, segundos_gen, _sim_total, reloj, delta_pesos,
	])
	_archivo.flush()


## Generación en la que se completó el nivel por primera vez (-1 si nunca).
func generaciones_hasta_converger() -> int:
	return _gen_primera_victoria


func segundos_transcurridos() -> float:
	return float(Time.get_ticks_msec()) / 1000.0 - _t_inicio


func cerrar() -> void:
	if _archivo == null:
		return
	_archivo.store_line("# generaciones=%d  convergio_en=%d  segundos_sim=%.2f  segundos_reloj=%.2f" % [
		_generaciones, _gen_primera_victoria, _sim_total, segundos_transcurridos(),
	])
	_archivo.flush()
	_archivo.close()
	_archivo = null
