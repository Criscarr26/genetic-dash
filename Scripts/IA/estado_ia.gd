extends Node

# Autoload `EstadoIA`: lo poco que tiene que sobrevivir a un cambio de escena
# entre el menú de configuración y la pantalla de entrenamiento.

## Configuración del experimento que se va a correr.
var config: ConfigIA = ConfigIA.new()

## Nivel sobre el que se entrena.
var ruta_nivel := "res://Escenas/Nivel1.tscn"

## Gen guardado que se usa como población inicial ("" = empezar de cero o
## desde el mejor del propio nivel). Es la pieza del entrenamiento incremental:
## el ganador del nivel 1 se convierte en la semilla del nivel 2.
var ruta_semilla := ""


## Nombre corto del nivel, usado para nombrar CSV y genes guardados.
func etiqueta_nivel() -> String:
	return ruta_nivel.get_file().get_basename()


## Genes disponibles en disco, para el desplegable de semilla del menú.
func genes_guardados() -> Array:
	var rutas: Array = []
	var dir := DirAccess.open(Entrenador.CARPETA_GENES)
	if dir == null:
		return rutas
	for archivo in dir.get_files():
		if archivo.begins_with("mejor_") and archivo.ends_with(".json"):
			rutas.append("%s/%s" % [Entrenador.CARPETA_GENES, archivo])
	rutas.sort()
	return rutas
