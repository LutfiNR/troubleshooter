extends CharacterBody2D

# References
@onready var movement: PlayerMovementComponent = $PlayerMovementComponent
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@export var camera_limit: Dictionary

func _ready():
	# Connect the signals from the component
	movement.started_moving.connect(_on_movement_started)
	movement.stopped.connect(_on_movement_stopped)
	_on_tilemap_changed()

# --- Signal Callbacks ---
func _on_tilemap_changed():
	camera.change_limit_camera(camera_limit)
	
func _on_movement_started(direction: Vector2):
	if direction.x < 0:
		anim_player.play("walk_left")
	elif direction.x > 0:
		anim_player.play("walk_right")
	elif direction.y > 0:
		anim_player.play("walk_down")
	elif direction.y < 0:
		anim_player.play("walk_up")

func _on_movement_stopped(last_direction: Vector2):
	anim_player.stop()
	if last_direction.x < 0:
		sprite.frame = 4
	if last_direction.x > 0:
		sprite.frame = 8
	elif last_direction.y > 0:
		sprite.frame = 0
	elif last_direction.y < 0:
		sprite.frame = 12
