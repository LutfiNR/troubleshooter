class_name PlayerMovementComponent
extends Node


signal started_moving(direction: Vector2)
signal stopped(last_direction: Vector2)

@export var speed : float
@export var character: CharacterBody2D

var is_moving : bool = false
var last_nonzero_direction : Vector2 = Vector2.DOWN 

func _ready():
	if not character:
		push_error("PlayerMovementComponent requires a reference to the CharacterBody2D node.")

func _physics_process(_delta):
	if not character:
		return

	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	character.velocity = direction * speed
	character.move_and_slide()
	
	if direction != Vector2.ZERO:
		is_moving = true
		last_nonzero_direction = direction
		started_moving.emit(direction)
		
	elif is_moving:
		is_moving = false
		stopped.emit(last_nonzero_direction)
