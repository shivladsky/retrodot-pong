extends KinematicBody2D

class_name Paddle

export var speed: float = 800.0
var _input_direction: Vector2 = Vector2()
var _up_action = ""
var _down_action = ""

func setup_controls(up_action, down_action):
	_up_action = up_action
	_down_action = down_action

func _physics_process(delta):
	if _up_action != "" and _down_action != "":
		_input_direction = Vector2()
		if Input.is_action_pressed(_up_action):
			_input_direction.y -= 80
		if Input.is_action_pressed(_down_action):
			_input_direction.y += 80
	
		var move_y = _input_direction.y * speed * delta
		var velocity = Vector2(0, move_y)
		apply_velocity(velocity)

func apply_velocity(velocity):
	var _linear_velocity = move_and_slide(velocity)
	clamp_position()
	
func clamp_position():
	var viewport_rect = get_viewport_rect()
	var screen_height = viewport_rect.size.y
	var extents = get_node("PaddleCollision").shape.extents.y
	var offset = 18
	var min_y = extents + offset
	var max_y = screen_height - extents - offset
	global_position.y = clamp(global_position.y, min_y, max_y)
