extends CharacterBody2D

const IDLE_DOWN_FRAME : int = 0
const IDLE_UP_FRAME : int = 12
const IDLE_LEFT_FRAME : int = 4
const IDLE_RIGHT_FRAME : int = 8

@onready var movement: PlayerMovementComponent = $PlayerMovementComponent
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@export var camera_limit: Dictionary

func _ready():
	movement.started_moving.connect(_on_movement_started)
	movement.stopped.connect(_on_movement_stopped)
	_on_tilemap_changed()

func _on_tilemap_changed():
	camera.change_limit_camera(camera_limit)
	
func _on_movement_started(direction: Vector2):
	if direction.x < Vector2.ZERO.x:
		anim_player.play("walk_left")
	elif direction.x > Vector2.ZERO.x:
		anim_player.play("walk_right")
	elif direction.y > Vector2.ZERO.y:
		anim_player.play("walk_down")
	elif direction.y < Vector2.ZERO.y:
		anim_player.play("walk_up")

func _on_movement_stopped(last_direction: Vector2):
	anim_player.stop()
	if last_direction.x < Vector2.ZERO.x:
		sprite.frame = IDLE_LEFT_FRAME
	if last_direction.x > Vector2.ZERO.x:
		sprite.frame = IDLE_RIGHT_FRAME
	elif last_direction.y > Vector2.ZERO.y:
		sprite.frame = IDLE_DOWN_FRAME
	elif last_direction.y < Vector2.ZERO.y:
		sprite.frame = IDLE_UP_FRAME
