class_name Jugador
extends CharacterBody2D

# El mismo script maneja al humano y a los bots del entrenador.
# Lo único que cambia entre uno y otro es de dónde sale la decisión de saltar
# (`_quiere_saltar`) y quién decide qué pasa después de morir.

signal murio(quien)
signal gano(quien)

const SPEED := 420.0            # velocidad horizontal constante (px/s)
const JUMP_VELOCITY := -640.0   # impulso del salto normal
const FUERZA_ORBE := -640.0     # impulso de la orbe amarilla
const EMPUJE_NAVE := 3200.0     # aceleración hacia arriba al mantener presionado en modo nave
const VEL_MAX_NAVE := 420.0     # velocidad vertical máxima de la nave
const LIMITE_CAIDA := 950.0     # si el jugador cae por debajo de esta Y, muere

## Quién decide los saltos de este jugador.
enum Piloto { HUMANO, IA }

var piloto: Piloto = Piloto.HUMANO
var red: RedNeuronal = null     # solo en modo IA
var auto_reiniciar := true      # el humano recarga la escena al morir; los bots no
var silencioso := false         # con 20 bots en pantalla solo suena el élite

var modo_nave := false
var orbe_actual: Area2D = null  # orbe que el jugador está tocando ahora mismo
var muerto := false
var nivel_completado := false

# Métricas que lee el entrenador para calcular el fitness.
var distancia_maxima := 0.0
var tiempo_vivo := 0.0

@onready var sprite_cubo: Sprite2D = $Sprite2D
@onready var sprite_nave: Sprite2D = $SpriteNave
@onready var snd_salto: AudioStreamPlayer = $SndSalto
@onready var snd_muerte: AudioStreamPlayer = $SndMuerte
@onready var snd_orbe: AudioStreamPlayer = $SndOrbe
@onready var particulas_muerte: CPUParticles2D = $ParticulasMuerte
@onready var sensores: Sensores = $Sensores


func _ready() -> void:
	distancia_maxima = position.x


func _physics_process(delta: float) -> void:
	if muerto or nivel_completado:
		return

	tiempo_vivo += delta

	# Los sensores se leen antes de decidir: la red actúa sobre el estado actual.
	if piloto == Piloto.IA or sensores.dibujar:
		sensores.actualizar()

	# Se consulta una sola vez por frame; evaluar la red dos veces sería
	# gastar el doble de CPU y además desincronizar el umbral estocástico.
	var salta := _quiere_saltar()

	if modo_nave:
		_fisica_nave(delta, salta)
	else:
		_fisica_cubo(delta, salta)

	velocity.x = SPEED
	move_and_slide()

	distancia_maxima = maxf(distancia_maxima, position.x)

	# Choques mortales contra bloques sólidos:
	# de frente (pared) siempre mata; el techo solo mata en modo cubo.
	for i in get_slide_collision_count():
		var normal := get_slide_collision(i).get_normal()
		if normal.x < -0.7:
			morir()
			return
		if not modo_nave and normal.y > 0.7:
			morir()
			return

	# Caída al vacío.
	if position.y > LIMITE_CAIDA:
		morir()


## De dónde sale la orden de saltar. El humano usa el teclado o el ratón;
## el bot, la salida de su red neuronal.
func _quiere_saltar() -> bool:
	if piloto == Piloto.IA:
		if red == null:
			return false
		return red.decidir(sensores.leer())
	return Input.is_action_pressed("jump")


func _fisica_cubo(delta: float, salta: bool) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		# El cubo gira en el aire, como en Geometry Dash.
		sprite_cubo.rotation += TAU * 1.2 * delta
	else:
		# Al aterrizar, el cubo se endereza al ángulo recto más cercano.
		sprite_cubo.rotation = roundf(sprite_cubo.rotation / (TAU / 4.0)) * (TAU / 4.0)

	if salta:
		# velocity.y >= -1 evita pisar el impulso del trampolín (-1050)
		# cuando el jugador mantiene presionado el salto.
		if is_on_floor() and velocity.y >= -1.0:
			velocity.y = JUMP_VELOCITY
			_sonar(snd_salto)
		elif orbe_actual != null and is_instance_valid(orbe_actual) \
				and orbe_actual.disponible(self):
			# Doble salto en el aire gracias a la orbe.
			velocity.y = FUERZA_ORBE
			orbe_actual.usar(self)
			_sonar(snd_orbe)


func _fisica_nave(delta: float, salta: bool) -> void:
	if salta:
		velocity.y -= EMPUJE_NAVE * delta
	velocity += get_gravity() * delta
	velocity.y = clampf(velocity.y, -VEL_MAX_NAVE, VEL_MAX_NAVE)
	# La nave se inclina según sube o baja.
	sprite_nave.rotation = velocity.y / 1400.0


func activar_nave(activa: bool) -> void:
	modo_nave = activa
	sprite_nave.visible = activa
	sprite_cubo.visible = not activa
	sprite_cubo.rotation = 0.0
	sprite_nave.rotation = 0.0


func ganar() -> void:
	# El portal de meta congela al jugador mientras cambia de escena.
	if nivel_completado or muerto:
		return
	nivel_completado = true
	velocity = Vector2.ZERO
	gano.emit(self)


func morir() -> void:
	if muerto or nivel_completado:
		return
	muerto = true
	velocity = Vector2.ZERO
	sprite_cubo.visible = false
	sprite_nave.visible = false
	particulas_muerte.emitting = true
	_sonar(snd_muerte)
	murio.emit(self)

	# En modo IA es el entrenador quien decide cuándo arranca la próxima
	# generación, así que aquí no se toca la escena.
	if not auto_reiniciar:
		return

	await get_tree().create_timer(0.8).timeout
	# Si la escena ya se recargó (tecla R/Esc), este nodo quedó liberado.
	if not is_inside_tree():
		return
	get_tree().reload_current_scene()


## Pinta el cubo del color del gen, para distinguir bots en pantalla.
func tenir(color: Color) -> void:
	modulate = color


func _sonar(reproductor: AudioStreamPlayer) -> void:
	if silencioso or reproductor == null:
		return
	reproductor.play()
