class_name Matriz
extends RefCounted

# Álgebra matricial mínima para la red neuronal.
# Una matriz es un Array de filas, y cada fila un Array de floats.
#
# Regla de oro: nunca mutar una matriz en sitio. En GDScript los Array son
# tipos por referencia, así que mutar los pesos de un hijo corrompería también
# los del élite del que salió. Todo lo que modifica devuelve copia.


static func crear(filas: int, columnas: int, valor: float = 0.0) -> Array:
	var m: Array = []
	for i in filas:
		var fila: Array = []
		fila.resize(columnas)
		fila.fill(valor)
		m.append(fila)
	return m


static func aleatoria(filas: int, columnas: int, minimo: float = -1.0, maximo: float = 1.0) -> Array:
	var m: Array = []
	for i in filas:
		var fila: Array = []
		for j in columnas:
			fila.append(randf_range(minimo, maximo))
		m.append(fila)
	return m


static func copiar(m: Array) -> Array:
	return m.duplicate(true)


static func multiplicar(a: Array, b: Array) -> Array:
	# a es (n x k), b es (k x p) -> resultado (n x p)
	var n := a.size()
	var k := (a[0] as Array).size()
	var p := (b[0] as Array).size()
	if b.size() != k:
		push_error("Matriz.multiplicar: dimensiones incompatibles (%dx%d) x (%dx%d)" \
				% [n, k, b.size(), p])
		return []

	var res := crear(n, p)
	for i in n:
		var fila_a: Array = a[i]
		var fila_r: Array = res[i]
		for j in p:
			var total := 0.0
			for t in k:
				total += float(fila_a[t]) * float((b[t] as Array)[j])
			fila_r[j] = total
	return res


static func sumar(a: Array, b: Array) -> Array:
	var n := a.size()
	var p := (a[0] as Array).size()
	if b.size() != n or (b[0] as Array).size() != p:
		push_error("Matriz.sumar: dimensiones incompatibles")
		return []

	var res := crear(n, p)
	for i in n:
		for j in p:
			(res[i] as Array)[j] = float((a[i] as Array)[j]) + float((b[i] as Array)[j])
	return res


static func mapear(m: Array, f: Callable) -> Array:
	var res: Array = []
	for fila in m:
		var nueva: Array = []
		for v in fila:
			nueva.append(f.call(float(v)))
		res.append(nueva)
	return res


static func desde_vector(v: Array) -> Array:
	# Convierte [a, b, c] en un vector columna [[a], [b], [c]].
	var m: Array = []
	for valor in v:
		m.append([float(valor)])
	return m


static func aplanar(m: Array) -> Array:
	var plano: Array = []
	for fila in m:
		for v in fila:
			plano.append(float(v))
	return plano


static func desde_plano(plano: Array, desde: int, filas: int, columnas: int) -> Array:
	var m: Array = []
	var k := desde
	for i in filas:
		var fila: Array = []
		for j in columnas:
			fila.append(float(plano[k]))
			k += 1
		m.append(fila)
	return m
