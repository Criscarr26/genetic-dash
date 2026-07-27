extends Node2D

# Pantalla de entrenamiento: instancia el nivel elegido y le monta encima el
# entrenador. El nivel no sabe nada de la IA; así cualquier nivel nuevo
# (incluidos los siete de validación) sirve para entrenar sin tocarlo.
#
# También acepta parámetros por línea de comandos para correr tandas del
# benchmark sin pasar por el menú. Todo lo que va después de `--` se lee como
# pares clave=valor:
#
#   godot --headless --path . res://Escenas/Entrenar.tscn -- \
#         nivel=1 generaciones=80 velocidad=8 sensores=111111111 etiqueta=run_a
#
# Claves admitidas: nivel, etiqueta, generaciones, velocidad, bots, elitismo,
# capas, sensores, mutacion, magnitud, limite, seleccion, cruce, tipo_mutacion,
# presion, umbral, tipo_umbral, activacion, rango_h, rango_v, semilla,
# incremental, segundos_max.

const NIVELES := {
	# Niveles de entrenamiento
	"1": "res://Escenas/Nivel1.tscn",
	"2": "res://Escenas/Nivel2.tscn",
	"3": "res://Escenas/Nivel3.tscn",
	# Niveles de validación: mismas mecánicas que su pareja de entrenamiento,
	# trazado distinto. El agente no entrena en ellos.
	"f1": "res://Escenas/ValFacil1.tscn",
	"f2": "res://Escenas/ValFacil2.tscn",
	"m1": "res://Escenas/ValMedio1.tscn",
	"m2": "res://Escenas/ValMedio2.tscn",
	"ma1": "res://Escenas/ValMedioAlto1.tscn",
	"ma2": "res://Escenas/ValMedioAlto2.tscn",
	"av": "res://Escenas/ValAvanzado.tscn",
}

## Velocidad de simulación pedida por línea de comandos.
var _velocidad := 1.0
## En modo por lotes el proceso se cierra solo al terminar.
var _por_lotes := false
var _etiqueta_run := ""
## Ruta de una población o gen guardado con el que evaluar (modo validación).
var _ruta_evaluar := ""


func _ready() -> void:
	_leer_argumentos()

	var escena := load(EstadoIA.ruta_nivel) as PackedScene
	if escena == null:
		push_error("Entrenar: no se pudo cargar %s" % EstadoIA.ruta_nivel)
		get_tree().change_scene_to_file("res://Escenas/MenuIA.tscn")
		return

	var nivel := escena.instantiate() as Node2D
	add_child(nivel)

	var entrenador := Entrenador.new()
	entrenador.name = "Entrenador"
	entrenador.etiqueta_run = _etiqueta_run
	if _ruta_evaluar != "":
		var redes := Entrenador.cargar_redes(_ruta_evaluar)
		if redes.is_empty():
			push_error("Entrenar: no se pudieron cargar redes de %s" % _ruta_evaluar)
			get_tree().quit(1)
			return
		entrenador.modo_evaluacion = true
		entrenador.poblacion_forzada = redes
		# La validación corre la red tal cual quedó: sin evolución y sin
		# heredar nada del disco.
		EstadoIA.config.continuar_desde_guardado = false
		EstadoIA.config.max_generaciones = 1
	add_child(entrenador)
	entrenador.entrenamiento_terminado.connect(_on_terminado)
	entrenador.iniciar(EstadoIA.config, nivel, EstadoIA.etiqueta_nivel())

	Entrenador.fijar_velocidad(_velocidad)


func _on_terminado() -> void:
	if _por_lotes:
		# El CSV ya se cerró en el entrenador; solo queda salir con código 0.
		get_tree().quit(0)


func _exit_tree() -> void:
	# Si se sale con la simulación acelerada, el menú quedaría corriendo a x8.
	Entrenador.restaurar_velocidad()


# --- Modo por lotes ---------------------------------------------------------

func _leer_argumentos() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		return

	_por_lotes = true
	var c := EstadoIA.config
	for arg in args:
		# allow_empty debe ir en true: con false, un argumento como "capas="
		# (red shallow, sin capas ocultas) se descarta en silencio y la corrida
		# usa la topología por defecto sin avisar.
		var partes := String(arg).split("=", true, 1)
		if partes.size() != 2:
			push_warning("Entrenar: argumento ignorado '%s' (se espera clave=valor)" % arg)
			continue
		var clave := partes[0].strip_edges()
		var valor := partes[1].strip_edges()

		match clave:
			"nivel":
				if NIVELES.has(valor):
					EstadoIA.ruta_nivel = NIVELES[valor]
				else:
					EstadoIA.ruta_nivel = valor
			"etiqueta":
				_etiqueta_run = valor
			"evaluar":
				# Ruta a poblacion_*.json o mejor_*.json. Activa la validación.
				_ruta_evaluar = valor if valor.begins_with("user://") \
						else "%s/%s" % [Entrenador.CARPETA_GENES, valor]
			"velocidad":
				_velocidad = maxf(1.0, float(valor))
			"generaciones":
				c.max_generaciones = int(valor)
			"bots":
				c.n_bots = int(valor)
			"elitismo":
				c.elitismo = int(valor)
			"capas":
				c.capas_ocultas = _leer_capas(valor)
			"sensores":
				c.sensores_activos = _leer_sensores(valor)
			"mutacion":
				c.prob_mutacion = float(valor)
			"magnitud":
				c.magnitud_mutacion = float(valor)
			"limite":
				c.limite_peso = float(valor)
			"peso_min":
				c.peso_inicial_min = float(valor)
			"peso_max":
				c.peso_inicial_max = float(valor)
			"seleccion":
				c.metodo_seleccion = int(valor) as Genetico.Seleccion
			"cruce":
				c.metodo_cruce = int(valor) as Genetico.Cruce
			"tipo_mutacion":
				c.metodo_mutacion = int(valor) as Genetico.Mutacion
			"presion":
				c.presion = int(valor)
			"umbral":
				c.umbral = float(valor)
			"tipo_umbral":
				c.tecnica_umbral = int(valor) as RedNeuronal.Umbral
			"activacion":
				c.activacion = int(valor) as RedNeuronal.Activacion
			"rango_h":
				c.rango_h = float(valor)
			"rango_v":
				c.rango_v = float(valor)
			"semilla":
				c.semilla = int(valor)
			"segundos_max":
				c.segundos_max_gen = float(valor)
			"incremental":
				c.continuar_desde_guardado = valor != "0"
			"semilla_gen":
				# Entrenamiento incremental: arrancar del campeón de otro nivel.
				c.continuar_desde_guardado = true
				EstadoIA.ruta_semilla = valor if valor.begins_with("user://") \
						else "%s/%s" % [Entrenador.CARPETA_GENES, valor]
			_:
				push_warning("Entrenar: clave desconocida '%s'" % clave)

	if c.max_generaciones <= 0:
		push_warning("Entrenar: modo por lotes sin 'generaciones=N'; el proceso no se cerrará solo.")


func _leer_capas(texto: String) -> Array:
	var capas: Array = []
	for pieza in texto.split(",", false):
		var n := int(pieza.strip_edges())
		if n > 0:
			capas.append(n)
	return capas


## Acepta "111111111" (una casilla por sensor) o "0,1,3" (índices encendidos).
func _leer_sensores(texto: String) -> Array:
	var mascara: Array = []
	mascara.resize(Sensores.N_SENSORES)
	mascara.fill(false)

	if texto.contains(","):
		for pieza in texto.split(",", false):
			var i := int(pieza.strip_edges())
			if i >= 0 and i < Sensores.N_SENSORES:
				mascara[i] = true
		return mascara

	for i in mini(texto.length(), Sensores.N_SENSORES):
		mascara[i] = texto[i] == "1"
	return mascara
