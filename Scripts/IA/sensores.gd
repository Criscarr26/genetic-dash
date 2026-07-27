class_name Sensores
extends Node2D

# Los "ojos" del bot: convierte el estado del mundo en un vector de números
# entre 0 y 1, que es lo único que ve la red neuronal.
#
# Todas las distancias se normalizan invertidas: 1.0 significa "lo tengo
# encima" y 0.0 "no hay nada dentro del rango". Así el peso de la neurona
# se interpreta directo como urgencia, y la red arranca en un régimen sano
# sin necesidad de normalizar por lotes.

## Capas de física del proyecto (ver README de la carpeta IA).
const CAPA_MUNDO := 1      ## bloques y suelo
const CAPA_PUA := 4        ## púas
const CAPA_ORBE := 8       ## orbes de doble salto
const CAPA_TRAMPOLIN := 16 ## trampolines

const NOMBRES := [
	"dist_pua",         # 0
	"dist_bloque",      # 1
	"dist_techo",       # 2
	"dist_abismo",      # 3
	"dist_trampolin",   # 4
	"en_suelo",         # 5
	"orbe_disponible",  # 6
	"modo_nave",        # 7
	"vel_vertical",     # 8
]

const N_SENSORES := 9

## Separación entre sondeos del sensor de abismo, en píxeles.
const PASO_ABISMO := 32.0
## Profundidad a la que se busca suelo bajo el jugador.
const PROFUNDIDAD_ABISMO := 600.0
## Altura del rayo horizontal respecto al centro del jugador (cerca de los pies).
const ALTURA_RAYO := 20.0

var rango_h := 600.0
var rango_v := 400.0
var mascara: Array = []   ## qué sensores están activos

## Valores crudos (en píxeles / booleanos) para el HUD de depuración.
var crudos: Array = []
## Valores normalizados de los 9 sensores, activos o no.
var valores: Array = []
## Se dibujan las líneas de detección solo para el bot que lleva la corona.
var dibujar := false

var _cuerpo: CharacterBody2D
var _impactos: Array = []  ## puntos globales donde pegó cada rayo, para _draw


func _ready() -> void:
	_cuerpo = get_parent() as CharacterBody2D
	valores.resize(N_SENSORES)
	valores.fill(0.0)
	crudos.resize(N_SENSORES)
	crudos.fill(0.0)
	_impactos.resize(5)
	_impactos.fill(null)
	if mascara.is_empty():
		mascara.resize(N_SENSORES)
		mascara.fill(true)


func configurar(mascara_sensores: Array, alcance_h: float, alcance_v: float) -> void:
	mascara = mascara_sensores.duplicate()
	rango_h = alcance_h
	rango_v = alcance_v


## Recalcula los 9 sensores. Debe llamarse desde _physics_process.
func actualizar() -> void:
	if _cuerpo == null:
		return

	var origen := _cuerpo.global_position + Vector2(0.0, ALTURA_RAYO)

	# 0-1-4: qué hay delante (púa, bloque, trampolín)
	var d_pua := _distancia_horizontal(origen, CAPA_PUA, true)
	var d_bloque := _distancia_horizontal(origen, CAPA_MUNDO, false)
	var d_trampolin := _distancia_horizontal(origen, CAPA_TRAMPOLIN, true)

	# 2: qué hay encima (techo de bloques, clave en modo nave)
	var d_techo := _distancia_vertical(_cuerpo.global_position)

	# 3: dónde se acaba el suelo
	var d_abismo := _distancia_abismo()

	crudos[0] = d_pua
	crudos[1] = d_bloque
	crudos[2] = d_techo
	crudos[3] = d_abismo
	crudos[4] = d_trampolin
	crudos[5] = 1.0 if _cuerpo.is_on_floor() else 0.0
	crudos[6] = 1.0 if _orbe_disponible() else 0.0
	crudos[7] = 1.0 if _cuerpo.modo_nave else 0.0
	crudos[8] = _cuerpo.velocity.y

	valores[0] = _normalizar(d_pua, rango_h)
	valores[1] = _normalizar(d_bloque, rango_h)
	valores[2] = _normalizar(d_techo, rango_v)
	valores[3] = _normalizar(d_abismo, rango_h)
	valores[4] = _normalizar(d_trampolin, rango_h)
	valores[5] = crudos[5]
	valores[6] = crudos[6]
	valores[7] = crudos[7]
	# La velocidad vertical se lleva a [0,1] con 0.5 = quieto.
	valores[8] = clampf(_cuerpo.velocity.y / 1000.0, -1.0, 1.0) * 0.5 + 0.5

	if dibujar:
		queue_redraw()


## Vector de entrada de la red: solo los sensores activos, en orden.
func leer() -> Array:
	var entradas: Array = []
	for i in N_SENSORES:
		if i < mascara.size() and mascara[i]:
			entradas.append(valores[i])
	return entradas


## Nombres de los sensores activos, para el HUD.
func nombres_activos() -> Array:
	var ns: Array = []
	for i in N_SENSORES:
		if i < mascara.size() and mascara[i]:
			ns.append(NOMBRES[i])
	return ns


# --- Rayos ------------------------------------------------------------------

func _consultar(desde: Vector2, hasta: Vector2, capa: int, areas: bool) -> Dictionary:
	var espacio := get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(desde, hasta, capa)
	params.collide_with_areas = areas
	params.collide_with_bodies = not areas
	params.exclude = [_cuerpo.get_rid()]
	return espacio.intersect_ray(params)


func _distancia_horizontal(origen: Vector2, capa: int, areas: bool) -> float:
	var destino := origen + Vector2(rango_h, 0.0)
	var golpe := _consultar(origen, destino, capa, areas)
	var indice := 0
	if capa == CAPA_MUNDO:
		indice = 1
	elif capa == CAPA_TRAMPOLIN:
		indice = 4

	if golpe.is_empty():
		_impactos[indice] = null
		return rango_h

	var punto: Vector2 = golpe["position"]
	_impactos[indice] = punto
	return absf(punto.x - origen.x)


func _distancia_vertical(origen: Vector2) -> float:
	var destino := origen + Vector2(0.0, -rango_v)
	var golpe := _consultar(origen, destino, CAPA_MUNDO, false)
	if golpe.is_empty():
		_impactos[2] = null
		return rango_v

	var punto: Vector2 = golpe["position"]
	_impactos[2] = punto
	return absf(punto.y - origen.y)


## Avanza en pasos hacia adelante y devuelve la primera x sin suelo debajo.
func _distancia_abismo() -> float:
	var base := _cuerpo.global_position
	var d := PASO_ABISMO
	while d < rango_h:
		var desde := base + Vector2(d, 0.0)
		var hasta := desde + Vector2(0.0, PROFUNDIDAD_ABISMO)
		if _consultar(desde, hasta, CAPA_MUNDO, false).is_empty():
			_impactos[3] = desde
			return d
		d += PASO_ABISMO

	_impactos[3] = null
	return rango_h


func _orbe_disponible() -> bool:
	var orbe: Area2D = _cuerpo.orbe_actual
	if orbe == null or not is_instance_valid(orbe):
		return false
	return orbe.disponible(_cuerpo)


static func _normalizar(distancia: float, rango: float) -> float:
	if rango <= 0.0:
		return 0.0
	return 1.0 - clampf(distancia, 0.0, rango) / rango


# --- Depuración -------------------------------------------------------------

const COLORES_RAYO := [
	Color(1.0, 0.25, 0.25),  # púa
	Color(0.35, 0.7, 1.0),   # bloque
	Color(0.7, 0.4, 1.0),    # techo
	Color(1.0, 0.8, 0.2),    # abismo
	Color(0.3, 1.0, 0.5),    # trampolín
]


func _draw() -> void:
	if not dibujar or _cuerpo == null:
		return

	var origen := _cuerpo.global_position + Vector2(0.0, ALTURA_RAYO)
	for i in _impactos.size():
		if i < mascara.size() and not mascara[i]:
			continue
		var punto = _impactos[i]
		if punto == null:
			continue
		var desde := origen
		if i == 2:
			desde = _cuerpo.global_position
		elif i == 3:
			desde = _cuerpo.global_position
		draw_line(to_local(desde), to_local(punto as Vector2), COLORES_RAYO[i], 2.0)
