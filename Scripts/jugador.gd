extends CharacterBody2D

const SPEED := 420.0            # velocidad horizontal constante (px/s)
const JUMP_VELOCITY := -640.0   # impulso del salto normal
const FUERZA_ORBE := -640.0     # impulso de la orbe amarilla
const EMPUJE_NAVE := 3200.0     # aceleración hacia arriba al mantener presionado en modo nave
const VEL_MAX_NAVE := 420.0     # velocidad vertical máxima de la nave
const LIMITE_CAIDA := 950.0     # si el jugador cae por debajo de esta Y, muere

var modo_nave := false
var orbe_actual: Area2D = null  # orbe que el jugador está tocando ahora mismo
var muerto := false
var nivel_completado := false

@onready var sprite_cubo: Sprite2D = $Sprite2D
@onready var sprite_nave: Sprite2D = $SpriteNave
@onready var snd_salto: AudioStreamPlayer = $SndSalto
@onready var snd_muerte: AudioStreamPlayer = $SndMuerte
@onready var snd_orbe: AudioStreamPlayer = $SndOrbe
@onready var particulas_muerte: CPUParticles2D = $ParticulasMuerte


func _physics_process(delta: float) -> void:
	if muerto or nivel_completado:
		return

	if modo_nave:
		_fisica_nave(delta)
	else:
		_fisica_cubo(delta)

	velocity.x = SPEED
	move_and_slide()

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


func _fisica_cubo(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		# El cubo gira en el aire, como en Geometry Dash.
		sprite_cubo.rotation += TAU * 1.2 * delta
	else:
		# Al aterrizar, el cubo se endereza al ángulo recto más cercano.
		sprite_cubo.rotation = roundf(sprite_cubo.rotation / (TAU / 4.0)) * (TAU / 4.0)

	if Input.is_action_pressed("jump"):
		# velocity.y >= -1 evita pisar el impulso del trampolín (-1050)
		# cuando el jugador mantiene presionado el salto.
		if is_on_floor() and velocity.y >= -1.0:
			velocity.y = JUMP_VELOCITY
			snd_salto.play()
		elif orbe_actual != null and orbe_actual.disponible():
			# Doble salto en el aire gracias a la orbe.
			velocity.y = FUERZA_ORBE
			orbe_actual.usar()
			snd_orbe.play()


func _fisica_nave(delta: float) -> void:
	if Input.is_action_pressed("jump"):
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
	nivel_completado = true
	velocity = Vector2.ZERO


func morir() -> void:
	if muerto or nivel_completado:
		return
	muerto = true
	velocity = Vector2.ZERO
	sprite_cubo.visible = false
	sprite_nave.visible = false
	particulas_muerte.emitting = true
	snd_muerte.play()
	await get_tree().create_timer(0.8).timeout
	# Si la escena ya se recargó (tecla R/Esc), este nodo quedó liberado.
	if not is_inside_tree():
		return
	get_tree().reload_current_scene()
