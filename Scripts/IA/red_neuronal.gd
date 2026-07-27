class_name RedNeuronal
extends RefCounted

# El "cerebro" de cada bot: una red densa hacia adelante.
#
#   entrada (sensores) -> [capas ocultas: ReLU] -> salida (sigmoide) -> ¿saltar?
#
# Los pesos NO se entrenan por descenso de gradiente: los optimiza el algoritmo
# genético de genetico.gd. Esta clase solo evalúa, clona y serializa.

## Función de activación de las capas ocultas.
enum Activacion { RELU, TANH }

## Cómo se convierte la salida continua en la acción binaria "saltar".
enum Umbral {
	FIJO,        ## salta si salida > umbral (0.5 por defecto)
	ESTOCASTICO, ## salta con probabilidad igual a la salida
}

var capas: Array = []   ## p. ej. [6, 8, 1]
var pesos: Array = []   ## una matriz (capas[i] x capas[i-1]) por capa
var sesgos: Array = []  ## un vector columna (capas[i] x 1) por capa

var activacion: Activacion = Activacion.RELU
var tecnica_umbral: Umbral = Umbral.FIJO
var umbral := 0.5

## Última salida evaluada. Solo para el HUD de depuración.
var ultima_salida := 0.0


func _init(tamanos: Array = []) -> void:
	if not tamanos.is_empty():
		inicializar(tamanos)


## Crea pesos y sesgos aleatorios para la topología dada.
func inicializar(tamanos: Array, minimo: float = -1.0, maximo: float = 1.0) -> void:
	capas = []
	for t in tamanos:
		capas.append(int(t))
	pesos = []
	sesgos = []
	for i in range(1, capas.size()):
		pesos.append(Matriz.aleatoria(capas[i], capas[i - 1], minimo, maximo))
		sesgos.append(Matriz.aleatoria(capas[i], 1, minimo, maximo))


## Propagación hacia adelante. `entradas` son los sensores ya normalizados.
func evaluar(entradas: Array) -> float:
	if pesos.is_empty() or entradas.is_empty():
		return 0.0
	if entradas.size() != capas[0]:
		push_error("RedNeuronal: esperaba %d entradas y recibió %d" \
				% [capas[0], entradas.size()])
		return 0.0

	var a := Matriz.desde_vector(entradas)
	var ultima := pesos.size() - 1
	for i in pesos.size():
		var z := Matriz.sumar(Matriz.multiplicar(pesos[i], a), sesgos[i])
		# La capa de salida siempre usa sigmoide para dejar el valor en (0,1);
		# las ocultas usan la activación configurada.
		a = _sigmoide(z) if i == ultima else _activar_oculta(z)

	ultima_salida = float((a[0] as Array)[0])
	return ultima_salida


## Convierte la salida de la red en la acción del juego.
func decidir(entradas: Array) -> bool:
	var y := evaluar(entradas)
	if tecnica_umbral == Umbral.ESTOCASTICO:
		return randf() < y
	return y > umbral


func clonar() -> RedNeuronal:
	var copia := RedNeuronal.new()
	copia.capas = capas.duplicate()
	copia.pesos = Matriz.copiar(pesos)
	copia.sesgos = Matriz.copiar(sesgos)
	copia.activacion = activacion
	copia.tecnica_umbral = tecnica_umbral
	copia.umbral = umbral
	return copia


# --- Vista plana (la usa el cruce del algoritmo genético) --------------------

## Todos los pesos y sesgos en un solo vector, para poder cortarlo y recombinarlo.
func aplanar() -> Array:
	var plano: Array = []
	for m in pesos:
		plano.append_array(Matriz.aplanar(m))
	for m in sesgos:
		plano.append_array(Matriz.aplanar(m))
	return plano


## Inversa de aplanar(): reconstruye las matrices respetando la topología.
func cargar_plano(plano: Array) -> void:
	var k := 0
	for i in pesos.size():
		var filas: int = capas[i + 1]
		var columnas: int = capas[i]
		pesos[i] = Matriz.desde_plano(plano, k, filas, columnas)
		k += filas * columnas
	for i in sesgos.size():
		var filas: int = capas[i + 1]
		sesgos[i] = Matriz.desde_plano(plano, k, filas, 1)
		k += filas


func n_genes() -> int:
	var total := 0
	for i in range(1, capas.size()):
		total += capas[i] * capas[i - 1] + capas[i]
	return total


# --- Persistencia (entrenamiento incremental nivel a nivel) ------------------

func a_dict() -> Dictionary:
	return {
		"capas": capas.duplicate(),
		"pesos": Matriz.copiar(pesos),
		"sesgos": Matriz.copiar(sesgos),
		"activacion": int(activacion),
		"umbral": umbral,
		"tecnica_umbral": int(tecnica_umbral),
	}


static func desde_dict(d: Dictionary) -> RedNeuronal:
	var red := RedNeuronal.new()
	# JSON no distingue enteros de flotantes: sin este casteo las capas
	# vuelven como [8.0, 8.0, 1.0] y nunca coinciden con la topología pedida,
	# así que el entrenamiento incremental descartaría siempre el gen guardado.
	red.capas = []
	for c in d.get("capas", []) as Array:
		red.capas.append(int(c))
	red.pesos = Matriz.copiar(d.get("pesos", []))
	red.sesgos = Matriz.copiar(d.get("sesgos", []))
	red.activacion = int(d.get("activacion", Activacion.RELU)) as Activacion
	red.umbral = float(d.get("umbral", 0.5))
	red.tecnica_umbral = int(d.get("tecnica_umbral", Umbral.FIJO)) as Umbral
	return red


# --- Activaciones -----------------------------------------------------------

func _activar_oculta(z: Array) -> Array:
	if activacion == Activacion.TANH:
		return Matriz.mapear(z, func(v: float) -> float: return tanh(v))
	return Matriz.mapear(z, func(v: float) -> float: return maxf(0.0, v))


func _sigmoide(z: Array) -> Array:
	return Matriz.mapear(z, func(v: float) -> float: return 1.0 / (1.0 + exp(-v)))
