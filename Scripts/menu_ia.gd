extends Control

# Menú del modo IA: cada control de esta pantalla es una de las variables que
# el proyecto pide comparar en el benchmark. La interfaz se construye por
# código para que agregar una variable nueva sea una línea, no editar la escena.

const NIVELES := [
	{"nombre": "Entrenamiento — Nivel 1 (Primeros Pasos)", "ruta": "res://Escenas/Nivel1.tscn"},
	{"nombre": "Entrenamiento — Nivel 2 (Salto Alto)", "ruta": "res://Escenas/Nivel2.tscn"},
	{"nombre": "Entrenamiento — Nivel 3 (Vuelo Final)", "ruta": "res://Escenas/Nivel3.tscn"},
	{"nombre": "Validación — Fácil A", "ruta": "res://Escenas/ValFacil1.tscn"},
	{"nombre": "Validación — Fácil B", "ruta": "res://Escenas/ValFacil2.tscn"},
	{"nombre": "Validación — Media A", "ruta": "res://Escenas/ValMedio1.tscn"},
	{"nombre": "Validación — Media B", "ruta": "res://Escenas/ValMedio2.tscn"},
	{"nombre": "Validación — Media-Alta A", "ruta": "res://Escenas/ValMedioAlto1.tscn"},
	{"nombre": "Validación — Media-Alta B", "ruta": "res://Escenas/ValMedioAlto2.tscn"},
	{"nombre": "Validación — Avanzado", "ruta": "res://Escenas/ValAvanzado.tscn"},
]

const AYUDA_SENSORES := [
	"distancia horizontal a la próxima púa",
	"distancia horizontal al próximo bloque",
	"distancia al techo (clave en modo nave)",
	"distancia al borde del suelo (abismo)",
	"distancia horizontal al próximo trampolín",
	"¿está pisando el suelo?",
	"¿tiene una orbe disponible ahora?",
	"¿va en modo nave?",
	"velocidad vertical actual",
]

var _nivel: OptionButton
var _semilla_gen: OptionButton
var _n_bots: SpinBox
var _elitismo: SpinBox
var _capas: LineEdit
var _activacion: OptionButton
var _seleccion: OptionButton
var _presion: SpinBox
var _cruce: OptionButton
var _mutacion: OptionButton
var _prob_mut: SpinBox
var _mag_mut: SpinBox
var _limite: SpinBox
var _peso_min: SpinBox
var _peso_max: SpinBox
var _umbral_tecnica: OptionButton
var _umbral_valor: SpinBox
var _rango_h: SpinBox
var _rango_v: SpinBox
var _semilla_rng: SpinBox
var _max_gen: SpinBox
var _seg_max: SpinBox
var _sensores: Array = []

var _rutas_semilla: Array = []


func _ready() -> void:
	_construir()
	_volcar_config(EstadoIA.config)


# --- Construcción de la interfaz --------------------------------------------

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.06, 0.16)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var raiz := MarginContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("margin_left", 28)
	raiz.add_theme_constant_override("margin_right", 28)
	raiz.add_theme_constant_override("margin_top", 18)
	raiz.add_theme_constant_override("margin_bottom", 18)
	add_child(raiz)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	raiz.add_child(columna)

	var titulo := Label.new()
	titulo.text = "MODO IA — Configuración del experimento"
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	columna.add_child(titulo)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(scroll)

	var cuerpo := VBoxContainer.new()
	cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 6)
	scroll.add_child(cuerpo)

	_seccion(cuerpo, "Escenario")
	var g1 := _grid(cuerpo)
	_nivel = _opciones(g1, "Nivel", NIVELES.map(func(n: Dictionary) -> String: return n["nombre"]))
	_semilla_gen = _opciones(g1, "Población inicial", _opciones_semilla())

	_seccion(cuerpo, "Población")
	var g2 := _grid(cuerpo)
	_n_bots = _numero(g2, "Número de pobladores", 2, 200, 1)
	_elitismo = _numero(g2, "Élites que pasan intactos", 1, 20, 1)
	_max_gen = _numero(g2, "Máx. generaciones (0 = sin límite)", 0, 5000, 1)
	_seg_max = _numero(g2, "Segundos máx. por generación", 5, 600, 1)
	_semilla_rng = _numero(g2, "Semilla aleatoria (-1 = libre)", -1, 999999, 1)

	_seccion(cuerpo, "Red neuronal")
	var g3 := _grid(cuerpo)
	_capas = _texto(g3, "Capas ocultas", "vacío = shallow;  8  ;  12,8")
	_activacion = _opciones(g3, "Activación oculta", ["ReLU", "Tanh"])
	_umbral_tecnica = _opciones(g3, "Thresholding", ["Fijo", "Estocástico"])
	_umbral_valor = _numero(g3, "Umbral de activación", 0.0, 1.0, 0.05)
	_peso_min = _numero(g3, "Peso inicial mínimo", -5.0, 5.0, 0.1)
	_peso_max = _numero(g3, "Peso inicial máximo", -5.0, 5.0, 0.1)

	_seccion(cuerpo, "Algoritmo genético")
	var g4 := _grid(cuerpo)
	_seleccion = _opciones(g4, "Técnica de selección", ["Top-K", "Torneo", "Ruleta", "Rango"])
	_presion = _numero(g4, "Presión selectiva (K)", 1, 50, 1)
	_cruce = _opciones(g4, "Técnica de cruce", ["Ninguno", "Un punto", "Uniforme", "Aritmético"])
	_mutacion = _opciones(g4, "Técnica de mutación", ["Uniforme", "Gaussiana", "Reemplazo"])
	_prob_mut = _numero(g4, "Probabilidad de mutación", 0.0, 1.0, 0.01)
	_mag_mut = _numero(g4, "Magnitud de mutación", 0.01, 3.0, 0.05)
	_limite = _numero(g4, "Límite (clipping) de peso", 0.5, 10.0, 0.5)

	_seccion(cuerpo, "Sensores")
	var nota := Label.new()
	nota.text = "Apagar los sensores que el nivel no usa acelera mucho la convergencia."
	nota.add_theme_font_size_override("font_size", 13)
	nota.modulate = Color(1, 1, 1, 0.65)
	cuerpo.add_child(nota)

	var g5 := _grid(cuerpo)
	_sensores.clear()
	for i in Sensores.N_SENSORES:
		var casilla := CheckBox.new()
		casilla.text = Sensores.NOMBRES[i]
		g5.add_child(casilla)
		var ayuda := Label.new()
		ayuda.text = AYUDA_SENSORES[i]
		ayuda.add_theme_font_size_override("font_size", 13)
		ayuda.modulate = Color(1, 1, 1, 0.6)
		g5.add_child(ayuda)
		_sensores.append(casilla)

	var g6 := _grid(cuerpo)
	_rango_h = _numero(g6, "Rango de detección horizontal (px)", 100, 2000, 25)
	_rango_v = _numero(g6, "Rango de detección vertical (px)", 100, 2000, 25)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	columna.add_child(botones)

	var entrenar := Button.new()
	entrenar.text = "Entrenar"
	entrenar.custom_minimum_size = Vector2(200, 46)
	entrenar.add_theme_font_size_override("font_size", 20)
	entrenar.pressed.connect(_on_entrenar)
	botones.add_child(entrenar)

	var restablecer := Button.new()
	restablecer.text = "Valores por defecto"
	restablecer.custom_minimum_size = Vector2(200, 46)
	restablecer.pressed.connect(func() -> void: _volcar_config(ConfigIA.new()))
	botones.add_child(restablecer)

	var volver := Button.new()
	volver.text = "Volver al menú"
	volver.custom_minimum_size = Vector2(200, 46)
	volver.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://Escenas/Menu.tscn"))
	botones.add_child(volver)


func _seccion(padre: Control, texto: String) -> void:
	var separador := HSeparator.new()
	padre.add_child(separador)
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", 19)
	etiqueta.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
	padre.add_child(etiqueta)


func _grid(padre: Control) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 18)
	g.add_theme_constant_override("v_separation", 6)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(g)
	return g


func _etiqueta(padre: GridContainer, texto: String) -> void:
	var l := Label.new()
	l.text = texto
	l.custom_minimum_size = Vector2(330, 0)
	padre.add_child(l)


func _numero(padre: GridContainer, texto: String, minimo: float, maximo: float,
		paso: float) -> SpinBox:
	_etiqueta(padre, texto)
	var s := SpinBox.new()
	s.min_value = minimo
	s.max_value = maximo
	s.step = paso
	s.custom_minimum_size = Vector2(180, 0)
	padre.add_child(s)
	return s


func _opciones(padre: GridContainer, texto: String, items: Array) -> OptionButton:
	_etiqueta(padre, texto)
	var o := OptionButton.new()
	for item in items:
		o.add_item(str(item))
	o.custom_minimum_size = Vector2(320, 0)
	padre.add_child(o)
	return o


func _texto(padre: GridContainer, etiqueta: String, pista: String) -> LineEdit:
	_etiqueta(padre, etiqueta)
	var e := LineEdit.new()
	e.placeholder_text = pista
	e.custom_minimum_size = Vector2(320, 0)
	padre.add_child(e)
	return e


func _opciones_semilla() -> Array:
	_rutas_semilla = ["", "auto"]
	var items: Array = [
		"Aleatoria (empezar de cero)",
		"Mejor guardado de este nivel",
	]
	for ruta in EstadoIA.genes_guardados():
		_rutas_semilla.append(ruta)
		items.append("Gen de %s" % ruta.get_file().get_basename().replace("mejor_", ""))
	return items


# --- Configuración <-> interfaz ---------------------------------------------

func _volcar_config(c: ConfigIA) -> void:
	_n_bots.value = c.n_bots
	_elitismo.value = c.elitismo
	_max_gen.value = c.max_generaciones
	_seg_max.value = c.segundos_max_gen
	_semilla_rng.value = c.semilla
	_capas.text = ",".join(c.capas_ocultas.map(func(v: Variant) -> String: return str(int(v))))
	_activacion.selected = int(c.activacion)
	_umbral_tecnica.selected = int(c.tecnica_umbral)
	_umbral_valor.value = c.umbral
	_peso_min.value = c.peso_inicial_min
	_peso_max.value = c.peso_inicial_max
	_seleccion.selected = int(c.metodo_seleccion)
	_presion.value = c.presion
	_cruce.selected = int(c.metodo_cruce)
	_mutacion.selected = int(c.metodo_mutacion)
	_prob_mut.value = c.prob_mutacion
	_mag_mut.value = c.magnitud_mutacion
	_limite.value = c.limite_peso
	_rango_h.value = c.rango_h
	_rango_v.value = c.rango_v
	for i in _sensores.size():
		_sensores[i].button_pressed = i < c.sensores_activos.size() and bool(c.sensores_activos[i])


func _leer_config() -> ConfigIA:
	var c := ConfigIA.new()
	c.n_bots = int(_n_bots.value)
	c.elitismo = int(_elitismo.value)
	c.max_generaciones = int(_max_gen.value)
	c.segundos_max_gen = float(_seg_max.value)
	c.semilla = int(_semilla_rng.value)
	c.capas_ocultas = _leer_capas()
	c.activacion = _activacion.selected as RedNeuronal.Activacion
	c.tecnica_umbral = _umbral_tecnica.selected as RedNeuronal.Umbral
	c.umbral = float(_umbral_valor.value)
	c.peso_inicial_min = float(_peso_min.value)
	c.peso_inicial_max = float(_peso_max.value)
	c.metodo_seleccion = _seleccion.selected as Genetico.Seleccion
	c.metodo_cruce = _cruce.selected as Genetico.Cruce
	c.metodo_mutacion = _mutacion.selected as Genetico.Mutacion
	c.presion = int(_presion.value)
	c.prob_mutacion = float(_prob_mut.value)
	c.magnitud_mutacion = float(_mag_mut.value)
	c.limite_peso = float(_limite.value)
	c.rango_h = float(_rango_h.value)
	c.rango_v = float(_rango_v.value)

	var mascara: Array = []
	for casilla in _sensores:
		mascara.append(casilla.button_pressed)
	c.sensores_activos = mascara
	return c


func _leer_capas() -> Array:
	var capas: Array = []
	for pieza in _capas.text.split(",", false):
		var n := int(pieza.strip_edges())
		if n > 0:
			capas.append(n)
	return capas


func _on_entrenar() -> void:
	var config := _leer_config()
	if config.n_sensores_activos() == 0:
		_avisar("Hay que dejar al menos un sensor encendido: sin entradas la red no puede decidir nada.")
		return
	if config.peso_inicial_min > config.peso_inicial_max:
		_avisar("El peso inicial mínimo no puede ser mayor que el máximo.")
		return

	EstadoIA.config = config
	EstadoIA.ruta_nivel = NIVELES[_nivel.selected]["ruta"]

	var opcion: String = str(_rutas_semilla[_semilla_gen.selected])
	config.continuar_desde_guardado = opcion != ""
	EstadoIA.ruta_semilla = "" if opcion == "auto" else opcion

	get_tree().change_scene_to_file("res://Escenas/Entrenar.tscn")


func _avisar(mensaje: String) -> void:
	var dialogo := AcceptDialog.new()
	dialogo.dialog_text = mensaje
	dialogo.title = "Configuración incompleta"
	add_child(dialogo)
	dialogo.popup_centered()
	dialogo.confirmed.connect(dialogo.queue_free)
	dialogo.canceled.connect(dialogo.queue_free)
