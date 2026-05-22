class_name PlayerMovementComponent
extends Node

# Signals to tell the parent (Player) what is happening
signal started_moving(direction: Vector2)
signal stopped(last_direction: Vector2)

@export var speed := 100.0
@export var character: CharacterBody2D

# State tracking
var is_moving := false
# Default to "Down" so we have a valid direction at game start
var last_nonzero_direction := Vector2.DOWN 

func _ready():
	# Auto-assign if not set in Inspector
	if not character:
		character = get_parent()

func _physics_process(_delta):
	if not character:
		return

	# 1. Get Input
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 2. Apply Velocity
	character.velocity = direction * speed
	character.move_and_slide()
	
	# 3. Handle State & Signals
	if direction != Vector2.ZERO:
		# We are moving
		is_moving = true
		last_nonzero_direction = direction # MEMORY: Save where we are facing
		started_moving.emit(direction)
		
	elif is_moving:
		# We just stopped
		is_moving = false
		# Send the MEMORY (last_nonzero_direction) so the player knows which Idle to play
		stopped.emit(last_nonzero_direction)
