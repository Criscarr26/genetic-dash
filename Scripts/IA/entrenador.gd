class_name Entrenador
extends Node2D

# Orquesta el aprendizaje por refuerzo: lanza una población de bots sobre el
# nivel, espera a que todos mueran o lleguen a la meta, los ordena por fitness
# y construye la siguiente generación con selección, cruce y mutación.
#
# Ciclo de una generación:
#   lanzar N bots -> viven -> mueren/ganan -> evaluar -> evolucionar -> repetir
#
# El fitness es la distancia recorrida en el nivel, como pide el proyecto, más
# un bono por completarlo que premia además haber tardado poco.

const ESCENA_BOT := preload("res://Objetos/jugador.tscn")
const CARPETA_GENES := "user://ia"

## Cuánto vale completar el nivel, en píxeles equivalentes.
const BONO_VICTORIA := 2000.0

## Pasos de física por segundo con los que se diseñó el juego. Acelerar la
## simulación sin respetarlo cambia el comportamiento: `Engine.time_scale`
## multiplica el delta de cada paso, así que a x8 el cubo avanza 56 px por
## paso en vez de 7 y atraviesa obstáculos que a x1 lo matarían. Por eso la
## aceleración sube también los ticks, dejando el delta por paso intacto.
const TICKS_BASE := 60

signal generacion_terminada(numero: int, mejor_fitness: float)
signal entrenamiento_terminado


## Acelera la simulación conservando la física: más pasos por segundo real,
## cada uno con el mismo delta de 1/60 que en el juego normal.
static func fijar_velocidad(factor: float) -> void:
	var v: float = maxf(1.0, factor)
	Engine.physics_ticks_per_second = int(round(float(TICKS_BASE) * v))
	Engine.max_physics_steps_per_frame = maxi(8, int(ceil(v)) * 8)
	Engine.time_scale = v


static func restaurar_velocidad() -> void:
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = TICKS_BASE
	Engine.max_physics_steps_per_frame = 8

## Nombre con el que se guardan el CSV y el gen. Si se deja vacío se usa el
## del nivel; el modo por lotes lo fija para poder distinguir configuraciones.
var etiqueta_run := ""

## En modo evaluación no hay evolución: se corre una sola generación con una
## población ya entrenada y se mide cuántos completan el nivel. Es lo que
## produce el "porcentaje de completitud" y la "tasa de éxito en validación"
## del benchmark, sobre un nivel que el agente no usó para entrenar.
var modo_evaluacion := false

## Población fija con la que arrancar (evaluación, o semilla explícita).
var poblacion_forzada: Array = []

var config: ConfigIA
var nivel: Node2D
var etiqueta := "nivel"

var generacion := 0
var poblacion: Array = []   ## Array[RedNeuronal] que corre esta generación
var genes: Array = []       ## resultados de la generación: {red, fitness, ...}
var bots: Array = []        ## nodos vivos ahora mismo

var mejor_fitness_historico := -INF
var mejor_red_historica: RedNeuronal = null
var mejor_completitud := 0.0
var generaciones_completadas := 0

var _inicio_x := 0.0
var _meta_x := 0.0
var _spawn := Vector2.ZERO
var _camara: Camera2D
var _hud: Label
var _registro: Registro
var _t_gen := 0.0
var _pesos_previos: Array = []
var _terminado := false


func iniciar(cfg: ConfigIA, escena_nivel: Node2D, nombre_nivel: String) -> void:
	config = cfg
	nivel = escena_nivel
	etiqueta = nombre_nivel

	if config.semilla >= 0:
		seed(config.semilla)

	_preparar_nivel()
	_crear_hud()
	var nombre_csv := etiqueta_run if etiqueta_run != "" \
			else "%s_%d" % [etiqueta, Time.get_unix_time_from_system()]
	_registro = Registro.new(nombre_csv, config)
	_crear_poblacion_inicial()
	_lanzar_generacion()


# --- Preparación ------------------------------------------------------------

func _preparar_nivel() -> void:
	# El nivel trae un jugador humano colocado en el punto de salida: se le
	# roba la posición y la cámara, y luego se retira de la escena.
	var humano := nivel.get_node_or_null("Jugador")
	if humano != null:
		_spawn = humano.position
		var cam := humano.get_node_or_null("Camera2D") as Camera2D
		if cam != null:
			humano.remove_child(cam)
			nivel.add_child(cam)
			cam.position = _spawn
			cam.make_current()
			_camara = cam
		humano.queue_free()
	else:
		_spawn = Vector2(224, 568)

	_inicio_x = _spawn.x

	# La meta define el 100% de completitud del nivel.
	var meta := nivel.get_node_or_null("PortalMeta")
	if meta != null:
		_meta_x = meta.position.x
	else:
		# Sin portal de meta, se toma el objeto más lejano como final.
		for hijo in nivel.get_children():
			if hijo is Node2D:
				_meta_x = maxf(_meta_x, (hijo as Node2D).position.x)
	_meta_x = maxf(_meta_x, _inicio_x + 1.0)

	if nivel.has_method("activar_modo_ia"):
		nivel.activar_modo_ia()


func _crear_poblacion_inicial() -> void:
	poblacion.clear()
	var topologia := config.topologia()

	# Evaluación (o semilla explícita): se corre exactamente esta población.
	if not poblacion_forzada.is_empty():
		for red in poblacion_forzada:
			poblacion.append((red as RedNeuronal).clonar())
		config.n_bots = poblacion.size()
		return

	# Entrenamiento incremental: si hay una red guardada compatible, la
	# población arranca de ella en vez de arrancar de ruido.
	var semilla_red := _cargar_gen_guardado()
	if semilla_red != null:
		mejor_red_historica = semilla_red
		poblacion.append(semilla_red.clonar())
		while poblacion.size() < config.n_bots:
			poblacion.append(Genetico.mutar(semilla_red, config.metodo_mutacion,
					config.prob_mutacion, config.magnitud_mutacion, config.limite_peso))
		return

	for i in config.n_bots:
		var red := RedNeuronal.new()
		red.inicializar(topologia, config.peso_inicial_min, config.peso_inicial_max)
		red.activacion = config.activacion
		red.tecnica_umbral = config.tecnica_umbral
		red.umbral = config.umbral
		poblacion.append(red)


# --- Ciclo de generaciones --------------------------------------------------

func _lanzar_generacion() -> void:
	genes.clear()
	bots.clear()
	_t_gen = 0.0
	_reiniciar_objetos()

	for i in poblacion.size():
		var bot := ESCENA_BOT.instantiate() as Jugador
		# Un desfase mínimo evita que 20 cubos idénticos se solapen en un píxel.
		bot.position = _spawn + Vector2(0.0, -float(i % 4) * 2.0)
		nivel.add_child(bot)

		bot.piloto = Jugador.Piloto.IA
		bot.auto_reiniciar = false
		bot.silencioso = i != 0
		bot.red = poblacion[i]
		bot.red.activacion = config.activacion
		bot.red.tecnica_umbral = config.tecnica_umbral
		bot.red.umbral = config.umbral
		bot.tenir(Color.WHITE if i == 0 else Color.from_hsv(randf(), 0.75, 1.0, 0.85))

		bot.sensores.configurar(config.sensores_activos, config.rango_h, config.rango_v)
		# Solo el élite dibuja sus rayos: con 20 bots la pantalla sería ilegible.
		bot.sensores.dibujar = i == 0

		bot.murio.connect(_on_bot_termino.bind(false))
		bot.gano.connect(_on_bot_termino.bind(true))
		bots.append(bot)


func _on_bot_termino(bot: Jugador, completo: bool) -> void:
	bots.erase(bot)
	genes.append({
		"red": bot.red,
		"fitness": _fitness(bot, completo),
		"distancia": bot.distancia_maxima - _inicio_x,
		"completo": completo,
		"tiempo": bot.tiempo_vivo,
	})
	bot.queue_free()

	if bots.is_empty():
		# El último bot suele morir dentro de un callback de colisión, y ahí la
		# física está resolviendo consultas: crear los cuerpos de la siguiente
		# generación en ese momento revienta el servidor 2D. Se difiere al
		# final del frame, cuando ya es seguro tocar la escena.
		_evolucionar.call_deferred()


func _fitness(bot: Jugador, completo: bool) -> float:
	var distancia := bot.distancia_maxima - _inicio_x
	if not completo:
		return distancia
	# Completar vale el largo del nivel más un bono que decae con el tiempo,
	# así entre dos bots que ganan gana el más rápido.
	return distancia + BONO_VICTORIA - bot.tiempo_vivo * 10.0


func _evolucionar() -> void:
	if genes.is_empty():
		return

	genes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["fitness"]) > float(b["fitness"]))

	var mejor: Dictionary = genes[0]
	var completaron := 0
	var lista_fitness: Array = []
	for g in genes:
		lista_fitness.append(float(g["fitness"]))
		if bool(g["completo"]):
			completaron += 1

	var completitud: float = clampf(
			float(mejor["distancia"]) / (_meta_x - _inicio_x), 0.0, 1.0)
	mejor_completitud = maxf(mejor_completitud, completitud)
	if completaron > 0:
		generaciones_completadas += 1

	# El mejor histórico nunca se pierde, aunque esta generación haya salido mal.
	if float(mejor["fitness"]) > mejor_fitness_historico:
		mejor_fitness_historico = float(mejor["fitness"])
		mejor_red_historica = (mejor["red"] as RedNeuronal).clonar()
		_guardar_gen()

	var delta := _delta_pesos(mejor_red_historica)
	_registro.registrar(generacion, lista_fitness, completitud, completaron, _t_gen, delta)
	generacion_terminada.emit(generacion, float(mejor["fitness"]))

	# En evaluación no se evoluciona: una sola pasada y se reporta.
	if modo_evaluacion:
		_guardar_evaluacion(completaron, completitud)
		_terminar()
		return

	generacion += 1
	if config.max_generaciones > 0 and generacion >= config.max_generaciones:
		_terminar()
		return

	_construir_siguiente_generacion()
	_lanzar_generacion()


func _construir_siguiente_generacion() -> void:
	var nueva: Array = []

	# Elitismo: los mejores pasan intactos. Sin esto, una mutación desafortunada
	# puede borrar en una generación todo lo aprendido en cincuenta.
	nueva.append(mejor_red_historica.clonar())
	for i in range(1, mini(config.elitismo, genes.size())):
		nueva.append((genes[i]["red"] as RedNeuronal).clonar())

	while nueva.size() < config.n_bots:
		var padre_a := Genetico.seleccionar(genes, config.metodo_seleccion, config.presion)
		var padre_b := Genetico.seleccionar(genes, config.metodo_seleccion, config.presion)
		var hijo := Genetico.cruzar(
				padre_a["red"] as RedNeuronal,
				padre_b["red"] as RedNeuronal,
				config.metodo_cruce)
		nueva.append(Genetico.mutar(hijo, config.metodo_mutacion,
				config.prob_mutacion, config.magnitud_mutacion, config.limite_peso))

	poblacion = nueva


## Distancia euclídea media entre los pesos del élite actual y el anterior.
## Es la "velocidad de convergencia de w" del benchmark: tiende a 0 al converger.
func _delta_pesos(red: RedNeuronal) -> float:
	if red == null:
		return 0.0
	var actuales := red.aplanar()
	if _pesos_previos.size() != actuales.size():
		_pesos_previos = actuales
		return 0.0

	var suma := 0.0
	for i in actuales.size():
		var d := float(actuales[i]) - float(_pesos_previos[i])
		suma += d * d
	_pesos_previos = actuales
	return sqrt(suma) / maxf(1.0, float(actuales.size()))


func _reiniciar_objetos() -> void:
	# Orbes y portales guardan estado por intento; hay que limpiarlo entre
	# generaciones o la segunda tanda correría un nivel distinto a la primera.
	for nodo in nivel.find_children("*", "Area2D", true, false):
		if nodo.has_method("reiniciar"):
			nodo.reiniciar()


func _terminar() -> void:
	if _terminado:
		return
	_terminado = true
	if not modo_evaluacion:
		_guardar_poblacion()
	_registro.cerrar()
	_actualizar_hud()
	entrenamiento_terminado.emit()


# --- Bucle de cada frame ----------------------------------------------------

func _physics_process(delta: float) -> void:
	if _terminado:
		return

	_t_gen += delta

	# Corte de seguridad: si nadie muere ni gana (por ejemplo un bot que vuela
	# indefinidamente fuera del nivel), la generación se cierra por tiempo.
	if config.segundos_max_gen > 0.0 and _t_gen > config.segundos_max_gen:
		for bot in bots.duplicate():
			if is_instance_valid(bot):
				bot.morir()

	_seguir_lider()
	_actualizar_hud()


func _seguir_lider() -> void:
	if _camara == null:
		return
	var lider: Jugador = null
	for bot in bots:
		if is_instance_valid(bot) and (lider == null or bot.position.x > lider.position.x):
			lider = bot
	if lider != null:
		_camara.global_position = lider.global_position


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo:
		match (evento as InputEventKey).physical_keycode:
			KEY_1:
				fijar_velocidad(1.0)
			KEY_2:
				fijar_velocidad(2.0)
			KEY_3:
				fijar_velocidad(4.0)
			KEY_4:
				fijar_velocidad(8.0)
			KEY_ESCAPE:
				restaurar_velocidad()
				_terminar()
				get_tree().change_scene_to_file("res://Escenas/MenuIA.tscn")


# --- HUD --------------------------------------------------------------------

func _crear_hud() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)

	var fondo := ColorRect.new()
	fondo.color = Color(0.0, 0.0, 0.0, 0.45)
	fondo.position = Vector2(8, 8)
	fondo.size = Vector2(430, 168)
	capa.add_child(fondo)

	_hud = Label.new()
	_hud.position = Vector2(20, 16)
	_hud.add_theme_font_size_override("font_size", 15)
	capa.add_child(_hud)


func _actualizar_hud() -> void:
	if _hud == null:
		return

	var texto := "Generación %d" % generacion
	if config.max_generaciones > 0:
		texto += " / %d" % config.max_generaciones
	texto += "     Vivos %d/%d\n" % [bots.size(), config.n_bots]
	texto += "Mejor histórico: %.0f px  (%.1f%% del nivel)\n" % [
		maxf(mejor_fitness_historico, 0.0), mejor_completitud * 100.0,
	]
	texto += "Generaciones con victoria: %d\n" % generaciones_completadas
	texto += "%s\n" % config.resumen()
	texto += "Sensores: %s\n" % ", ".join(_nombres_sensores())
	texto += "[1-4] velocidad x%d    [Esc] salir" % int(Engine.time_scale)
	if _terminado:
		texto += "\nENTRENAMIENTO TERMINADO — CSV en %s" % _registro.ruta
	_hud.text = texto


func _nombres_sensores() -> Array:
	var ns: Array = []
	for i in Sensores.N_SENSORES:
		if i < config.sensores_activos.size() and config.sensores_activos[i]:
			ns.append(Sensores.NOMBRES[i])
	return ns


# --- Persistencia de genes --------------------------------------------------

func ruta_gen() -> String:
	# En modo por lotes cada configuración guarda su propio gen; si no, varias
	# corridas del mismo nivel se pisarían el archivo entre ellas.
	var nombre := etiqueta_run if etiqueta_run != "" else etiqueta
	return "%s/mejor_%s.json" % [CARPETA_GENES, nombre]


func _guardar_gen() -> void:
	DirAccess.make_dir_recursive_absolute(CARPETA_GENES)
	var archivo := FileAccess.open(ruta_gen(), FileAccess.WRITE)
	if archivo == null:
		return
	archivo.store_string(JSON.stringify({
		"nivel": etiqueta,
		"generacion": generacion,
		"fitness": mejor_fitness_historico,
		"completitud": mejor_completitud,
		"sensores_activos": config.sensores_activos,
		"red": mejor_red_historica.a_dict(),
	}, "\t"))
	archivo.close()


func ruta_poblacion() -> String:
	var nombre := etiqueta_run if etiqueta_run != "" else etiqueta
	return "%s/poblacion_%s.json" % [CARPETA_GENES, nombre]


## Guarda todas las redes de la última generación. La validación necesita la
## población completa, no solo al campeón: la tasa de éxito se mide como qué
## fracción de los agentes entrenados completa un nivel que no entrenaron.
func _guardar_poblacion() -> void:
	if genes.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(CARPETA_GENES)
	var archivo := FileAccess.open(ruta_poblacion(), FileAccess.WRITE)
	if archivo == null:
		return

	var redes: Array = []
	for g in genes:
		redes.append((g["red"] as RedNeuronal).a_dict())
	archivo.store_string(JSON.stringify({
		"nivel": etiqueta,
		"generacion": generacion,
		"sensores_activos": config.sensores_activos,
		"redes": redes,
	}, "\t"))
	archivo.close()


## Lee un archivo de población (o de gen único) y devuelve las redes.
static func cargar_redes(ruta: String) -> Array:
	if not FileAccess.file_exists(ruta):
		push_error("No existe %s" % ruta)
		return []
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return []
	var datos = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if typeof(datos) != TYPE_DICTIONARY:
		return []

	var redes: Array = []
	if datos.has("redes"):
		for d in datos["redes"] as Array:
			redes.append(RedNeuronal.desde_dict(d))
	elif datos.has("red"):
		redes.append(RedNeuronal.desde_dict(datos["red"]))
	return redes


func _guardar_evaluacion(completaron: int, completitud: float) -> void:
	var total := maxi(1, genes.size())
	var distancias: Array = []
	var completitudes: Array = []
	for g in genes:
		var d := float(g["distancia"])
		distancias.append(d)
		completitudes.append(clampf(d / (_meta_x - _inicio_x), 0.0, 1.0))

	var suma := 0.0
	for c in completitudes:
		suma += float(c)

	DirAccess.make_dir_recursive_absolute(CARPETA_GENES)
	var nombre := etiqueta_run if etiqueta_run != "" else etiqueta
	var archivo := FileAccess.open("%s/eval_%s.csv" % [CARPETA_GENES, nombre], FileAccess.WRITE)
	if archivo == null:
		return
	archivo.store_line("agentes,completaron,tasa_exito_pct,completitud_mejor_pct,completitud_media_pct")
	archivo.store_line("%d,%d,%.2f,%.2f,%.2f" % [
		total, completaron,
		100.0 * float(completaron) / float(total),
		completitud * 100.0,
		100.0 * suma / float(total),
	])
	archivo.close()


func _cargar_gen_guardado() -> RedNeuronal:
	if not config.continuar_desde_guardado:
		return null

	var ruta: String = EstadoIA.ruta_semilla if EstadoIA.ruta_semilla != "" else ruta_gen()
	if not FileAccess.file_exists(ruta):
		return null

	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return null
	var datos = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if typeof(datos) != TYPE_DICTIONARY or not datos.has("red"):
		return null

	var red := RedNeuronal.desde_dict(datos["red"])
	# Una red entrenada con otra topología (otros sensores u otras capas) no
	# sirve como punto de partida: sus pesos no significan lo mismo.
	if red.capas != config.topologia():
		push_warning("Entrenador: el gen guardado tiene topología %s y la configuración pide %s; se ignora." \
				% [str(red.capas), str(config.topologia())])
		return null

	red.activacion = config.activacion
	red.tecnica_umbral = config.tecnica_umbral
	red.umbral = config.umbral
	return red
