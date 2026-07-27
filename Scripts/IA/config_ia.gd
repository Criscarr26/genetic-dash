class_name ConfigIA
extends RefCounted

# Todos los parámetros del experimento en un solo objeto.
#
# Cada campo de aquí es una de las "variables para comparar" del benchmark:
# número de pobladores, tasa de mutación, configuración de peso inicial,
# técnicas de selección/cruce/mutación y técnica de thresholding.

# --- Población ---
var n_bots := 20
var elitismo := 1               ## cuántos mejores pasan intactos a la siguiente gen

# --- Red neuronal ---
var capas_ocultas: Array = [8]  ## [] = red shallow (solo entrada y salida)
var activacion := RedNeuronal.Activacion.RELU
var tecnica_umbral := RedNeuronal.Umbral.FIJO
var umbral := 0.5
var peso_inicial_min := -1.0
var peso_inicial_max := 1.0

# --- Operadores genéticos ---
var metodo_seleccion := Genetico.Seleccion.TORNEO
var metodo_cruce := Genetico.Cruce.UN_PUNTO
var metodo_mutacion := Genetico.Mutacion.GAUSSIANA
var presion := 3                ## K del torneo / del Top-K
var prob_mutacion := 0.15
var magnitud_mutacion := 0.5
var limite_peso := 2.0

# --- Sensores ---
## Una casilla por sensor de Sensores.NOMBRES. Apagar los sensores que no
## aplican al nivel acelera muchísimo la convergencia (recomendación del PDF).
## Vienen todos encendidos: en particular `vel_vertical` es casi obligatorio
## en los tramos de nave, donde volar sin saber si subes o bajas es imposible.
var sensores_activos: Array = [true, true, true, true, true, true, true, true, true]
var rango_h := 600.0            ## alcance horizontal de detección, en píxeles
var rango_v := 400.0            ## alcance vertical de detección, en píxeles

# --- Simulación ---
var semilla := -1               ## -1 = aleatoria; fijarla hace el run reproducible
var max_generaciones := 0       ## 0 = sin límite
var segundos_max_gen := 60.0    ## corta la generación si nadie muere ni gana
var continuar_desde_guardado := true   ## entrenamiento incremental nivel a nivel


func n_sensores_activos() -> int:
	var n := 0
	for activo in sensores_activos:
		if activo:
			n += 1
	return n


## Topología completa de la red: [n_sensores, ...ocultas, 1]
func topologia() -> Array:
	var t: Array = [n_sensores_activos()]
	for c in capas_ocultas:
		if int(c) > 0:
			t.append(int(c))
	t.append(1)
	return t


func duplicar() -> ConfigIA:
	var c := ConfigIA.new()
	c.n_bots = n_bots
	c.elitismo = elitismo
	c.capas_ocultas = capas_ocultas.duplicate()
	c.activacion = activacion
	c.tecnica_umbral = tecnica_umbral
	c.umbral = umbral
	c.peso_inicial_min = peso_inicial_min
	c.peso_inicial_max = peso_inicial_max
	c.metodo_seleccion = metodo_seleccion
	c.metodo_cruce = metodo_cruce
	c.metodo_mutacion = metodo_mutacion
	c.presion = presion
	c.prob_mutacion = prob_mutacion
	c.magnitud_mutacion = magnitud_mutacion
	c.limite_peso = limite_peso
	c.sensores_activos = sensores_activos.duplicate()
	c.rango_h = rango_h
	c.rango_v = rango_v
	c.semilla = semilla
	c.max_generaciones = max_generaciones
	c.segundos_max_gen = segundos_max_gen
	c.continuar_desde_guardado = continuar_desde_guardado
	return c


## Firma corta del experimento, para el HUD y las filas del CSV.
func resumen() -> String:
	return "n=%d  mut=%.2f (%s)  sel=%s(K=%d)  cruce=%s  capas=%s  sensores=%d" % [
		n_bots,
		prob_mutacion,
		Genetico.nombre_mutacion(metodo_mutacion),
		Genetico.nombre_seleccion(metodo_seleccion),
		presion,
		Genetico.nombre_cruce(metodo_cruce),
		str(topologia()),
		n_sensores_activos(),
	]


func a_dict() -> Dictionary:
	return {
		"n_bots": n_bots,
		"elitismo": elitismo,
		"capas_ocultas": capas_ocultas.duplicate(),
		"activacion": int(activacion),
		"tecnica_umbral": int(tecnica_umbral),
		"umbral": umbral,
		"peso_inicial_min": peso_inicial_min,
		"peso_inicial_max": peso_inicial_max,
		"metodo_seleccion": int(metodo_seleccion),
		"metodo_cruce": int(metodo_cruce),
		"metodo_mutacion": int(metodo_mutacion),
		"presion": presion,
		"prob_mutacion": prob_mutacion,
		"magnitud_mutacion": magnitud_mutacion,
		"limite_peso": limite_peso,
		"sensores_activos": sensores_activos.duplicate(),
		"rango_h": rango_h,
		"rango_v": rango_v,
		"semilla": semilla,
	}
