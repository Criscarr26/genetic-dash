class_name Genetico
extends RefCounted

# Operadores del algoritmo genético: selección, cruce y mutación.
#
# Todo son funciones estáticas puras sobre "individuos", diccionarios con la
# forma {red: RedNeuronal, fitness: float, ...}. El entrenador es quien arma la
# población y decide qué operador usar; aquí solo vive la mecánica.
#
# El proyecto pide comparar varios operadores en el benchmark, por eso hay más
# de uno de cada tipo y se eligen por enum desde la configuración.

## Cómo se eligen los padres de la siguiente generación.
enum Seleccion {
	TOP_K,   ## se sortea entre los K mejores (presión = K)
	TORNEO,  ## K al azar compiten, gana el de mayor fitness
	RULETA,  ## probabilidad proporcional al fitness
	RANGO,   ## proporcional al puesto, no al fitness ("suavizada")
}

## Cómo se combinan dos padres para producir un hijo.
enum Cruce {
	NINGUNO,     ## clona al primer padre (comportamiento del demo de clase)
	UN_PUNTO,    ## un corte en el vector de genes
	UNIFORME,    ## gen a gen, cara o cruz
	ARITMETICO,  ## promedio ponderado de ambos padres
}

## Cómo se perturban los genes del hijo.
enum Mutacion {
	UNIFORME,   ## suma ruido uniforme en (-magnitud, magnitud)
	GAUSSIANA,  ## suma ruido normal con desviación = magnitud
	REEMPLAZO,  ## descarta el gen y sortea uno nuevo
}


# --- Selección --------------------------------------------------------------

## Devuelve un individuo de `poblacion`, que debe venir ordenada por fitness
## descendente. `presion` es el K de TOP_K y el tamaño del torneo.
static func seleccionar(poblacion: Array, metodo: Seleccion, presion: int = 3) -> Dictionary:
	if poblacion.is_empty():
		return {}

	match metodo:
		Seleccion.TOP_K:
			var k: int = clampi(presion, 1, poblacion.size())
			return poblacion[randi_range(0, k - 1)]

		Seleccion.TORNEO:
			var k: int = clampi(presion, 1, poblacion.size())
			var mejor: Dictionary = poblacion[randi_range(0, poblacion.size() - 1)]
			for i in k - 1:
				var rival: Dictionary = poblacion[randi_range(0, poblacion.size() - 1)]
				if float(rival["fitness"]) > float(mejor["fitness"]):
					mejor = rival
			return mejor

		Seleccion.RULETA:
			# Se desplaza el fitness para que nunca sea negativo, si no los
			# individuos malos podrían recibir probabilidad negativa.
			var minimo := INF
			for ind in poblacion:
				minimo = minf(minimo, float(ind["fitness"]))
			var desplazamiento: float = maxf(0.0, -minimo) + 1.0

			var total := 0.0
			for ind in poblacion:
				total += float(ind["fitness"]) + desplazamiento

			var tirada := randf() * total
			var acumulado := 0.0
			for ind in poblacion:
				acumulado += float(ind["fitness"]) + desplazamiento
				if acumulado >= tirada:
					return ind
			return poblacion[poblacion.size() - 1]

		Seleccion.RANGO:
			# El primero pesa n, el segundo n-1, etc. Es más suave que la ruleta
			# cuando un individuo se dispara en fitness y aplasta a los demás.
			var n := poblacion.size()
			var total_rangos := float(n * (n + 1)) / 2.0
			var tirada := randf() * total_rangos
			var acumulado := 0.0
			for i in n:
				acumulado += float(n - i)
				if acumulado >= tirada:
					return poblacion[i]
			return poblacion[n - 1]

	return poblacion[0]


static func nombre_seleccion(metodo: Seleccion) -> String:
	match metodo:
		Seleccion.TOP_K: return "Top-K"
		Seleccion.TORNEO: return "Torneo"
		Seleccion.RULETA: return "Ruleta"
		Seleccion.RANGO: return "Rango"
	return "?"


# --- Cruce ------------------------------------------------------------------

## Combina dos redes y devuelve una nueva. No toca a los padres.
static func cruzar(padre_a: RedNeuronal, padre_b: RedNeuronal, metodo: Cruce) -> RedNeuronal:
	var hijo := padre_a.clonar()
	if metodo == Cruce.NINGUNO or padre_b == null:
		return hijo

	var genes_a := padre_a.aplanar()
	var genes_b := padre_b.aplanar()
	if genes_a.size() != genes_b.size():
		# Topologías distintas: no hay cruce posible, se hereda del primero.
		return hijo

	var genes: Array = []
	match metodo:
		Cruce.UN_PUNTO:
			var corte := randi_range(1, genes_a.size() - 1)
			genes = genes_a.slice(0, corte)
			genes.append_array(genes_b.slice(corte))

		Cruce.UNIFORME:
			for i in genes_a.size():
				genes.append(genes_a[i] if randf() < 0.5 else genes_b[i])

		Cruce.ARITMETICO:
			var alfa := randf()
			for i in genes_a.size():
				genes.append(alfa * float(genes_a[i]) + (1.0 - alfa) * float(genes_b[i]))

	hijo.cargar_plano(genes)
	return hijo


static func nombre_cruce(metodo: Cruce) -> String:
	match metodo:
		Cruce.NINGUNO: return "Ninguno"
		Cruce.UN_PUNTO: return "Un punto"
		Cruce.UNIFORME: return "Uniforme"
		Cruce.ARITMETICO: return "Aritmético"
	return "?"


# --- Mutación ---------------------------------------------------------------

## Devuelve una copia mutada de `red`. `probabilidad` va de 0 a 1 y se evalúa
## gen a gen; `limite` recorta los pesos para que no exploten.
static func mutar(red: RedNeuronal, metodo: Mutacion, probabilidad: float,
		magnitud: float, limite: float) -> RedNeuronal:
	var copia := red.clonar()
	var genes := copia.aplanar()

	for i in genes.size():
		if randf() >= probabilidad:
			continue
		var v := float(genes[i])
		match metodo:
			Mutacion.UNIFORME:
				v += randf_range(-magnitud, magnitud)
			Mutacion.GAUSSIANA:
				v += randfn(0.0, magnitud)
			Mutacion.REEMPLAZO:
				v = randf_range(-limite, limite)
		genes[i] = clampf(v, -limite, limite)

	copia.cargar_plano(genes)
	return copia


static func nombre_mutacion(metodo: Mutacion) -> String:
	match metodo:
		Mutacion.UNIFORME: return "Uniforme"
		Mutacion.GAUSSIANA: return "Gaussiana"
		Mutacion.REEMPLAZO: return "Reemplazo"
	return "?"
