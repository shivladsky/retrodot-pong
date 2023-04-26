extends KinematicBody2D

signal ball_hit_paddle
signal ball_reflected
signal ball_exited_screen

var viewport_rect
var screen_width
var screen_height
var top_limit
var bottom_limit
var widescreen: float = 0.63    # Widescreen adjustment of slopes

var walls_closed: bool = true   # Walls closed in attract mode
var player_scored: int = 0      # Remember which player scored last
var current_round: int = 0      # Keep track of current round

# Testrict the ball movement to only these predefined slopes:
var slope: Array = [
	-1.77 * widescreen,  # [0] Very steep up
	-1.18 * widescreen,  # [1] Steep up
	-0.8 * widescreen,   # [2] Shallow up
	-0.398 * widescreen, # [3] Very shallow up
	0,                   # [4] Straight
	0.398 * widescreen,  # [5] Very shallow down
	0.8 * widescreen,    # [6] Shallow down
	1.18 * widescreen,   # [7] Steep down
	1.77 * widescreen,   # [8] Very steep down
]

var slope_history: Array = []

var speed: float = 520.0
var min_speed_ratio: float = 0.5
var velocity: Vector2 = Vector2.ZERO
var ball_exit_height: float = 0       # Remember where the ball left the screen
var ball_exit_slope: float = slope[0] # Also remember the slope that was used

func check_viewport():
	viewport_rect = get_viewport_rect()
	screen_width = viewport_rect.size.x
	screen_height = viewport_rect.size.y
	top_limit = screen_height * 0.1
	bottom_limit = screen_height * 0.9

func _ready():
	var main_node = get_node("/root/Main")
	main_node.connect("game_started", self, "_on_game_started")
	main_node.connect("game_ended", self, "_on_game_ended")
	main_node.connect("player1_scored", self, "_on_player1_scored")
	main_node.connect("player2_scored", self, "_on_player2_scored")

	check_viewport()
	randomize()
	launch_ball()

func launch_ball():
	var direction_x = 0.0
	var direction_y = 0.0
	var random_slope

	if walls_closed and current_round == 0:
		direction_x = 1.0
		direction_y = slope[0]
	elif walls_closed and current_round > 0:
		direction_x = 1.0
		if rand_range(0, 1) > 0.5:
			direction_x *= -1
		direction_y = slope[0]
	else:
		if player_scored == 0:
			direction_x = 1.0
			if rand_range(0, 1) > 0.5:
				direction_x *= -1
			random_slope = get_random_slope()
		elif player_scored == 1:
			direction_x = 1.0
			random_slope = get_random_slope()
		elif player_scored == 2:
			direction_x = -1.0
			random_slope = get_random_slope()

		direction_y = random_slope

	var direction = Vector2(direction_x, direction_y).normalized()
	velocity = direction * speed

func reset_ball(serve_timer):
	# Hide the ball and place it on the playfield
	visible = false
	clear_slope_history()
	ball_exit_height = get_exit_height()
	if rand_range(0, 1) > 0.5:
		# Serve the ball from where it left the screen
		global_position = Vector2(665, ball_exit_height)
	else:
		# Serve the ball from the opposite side
		global_position = Vector2(665, screen_height - ball_exit_height)

	velocity = Vector2.ZERO
	if serve_timer:
		# Start the timer
		$ServeTimer.start()
	else:
		# Skip the timer
		visible = true
		launch_ball()

func _physics_process(delta):
	if global_position.x <= 0 or global_position.x >= screen_width:
		check_viewport()
		if walls_closed:
			# Let the ball bounce around the walls
			velocity.x = -velocity.x
		else:
			# Let it score and save its exit height
			get_exit_height()
			emit_signal("ball_exited_screen")

	if global_position.y <= 0 or global_position.y >= screen_height:
		# Reflect the ball off the floor and ceiling
		emit_signal("ball_reflected")
		velocity.y = -velocity.y

	var collision = move_and_collide(velocity * delta)
	if collision:
		if collision.collider is Paddle:
			emit_signal("ball_hit_paddle")
			var bounce_data = calculate_bounce_data(collision.collider)
			var bounce_direction = bounce_data.direction
			var speed_factor = bounce_data.speed_factor
			velocity = bounce_direction * speed * speed_factor
		else:
			velocity = velocity.bounce(collision.normal)

func calculate_bounce_data(paddle_body):
	var paddle_collision = paddle_body.get_node("PaddleCollision")
	var ball_collision = get_node("BallCollision")

	var relative_intersect = (global_position.y - paddle_body.global_position.y) / (paddle_collision.shape.extents.y + ball_collision.shape.extents.y)
#	print("Relative intersect:", relative_intersect)

	var bounce_slope

	if relative_intersect < -0.8:
		bounce_slope = slope[0] 
	elif relative_intersect < -0.5:
		bounce_slope = slope[1]
	elif relative_intersect < -0.3:
		bounce_slope = slope[2]
	elif relative_intersect < -0.1:
		bounce_slope = slope[3]
	elif relative_intersect < 0.1:
		bounce_slope = slope[4]
	elif relative_intersect < 0.3:
		bounce_slope = slope[5]
	elif relative_intersect < 0.5:
		bounce_slope = slope[6]
	elif relative_intersect < 0.8:
		bounce_slope = slope[7]
	else:
		bounce_slope = slope[8]

	bounce_slope = check_slope_history(bounce_slope)
	ball_exit_slope = bounce_slope

	var bounce_angle = rad2deg(atan(bounce_slope))
	var bounce_dir_x = -1 if velocity.x > 0 else 1
	var bounce_direction = Vector2(bounce_dir_x * cos(deg2rad(bounce_angle)), sin(deg2rad(bounce_angle))).normalized()

	var speed_factor = 0.8 + abs(relative_intersect)
	return {"direction": bounce_direction, "speed_factor": speed_factor}

func get_exit_height():
	var safe_exit_height
	
	if global_position.y < top_limit:
		safe_exit_height = screen_height * 0.05
	elif global_position.y > bottom_limit:
		safe_exit_height = screen_height * 0.95
	else:
		safe_exit_height = global_position.y

	return safe_exit_height

func get_random_slope():
	check_viewport()
	if rand_range(0, 1) > 0.5:
		ball_exit_slope *= -1
		
	return ball_exit_slope

func check_slope_history(bounce_slope):
	var index = slope.find(bounce_slope)
	# Check if the ball hit the paddle 2+ times and patch the slope if needed
	if slope_history.size() >= 2 and abs(bounce_slope) == abs(slope_history[-1]) and abs(bounce_slope) == abs(slope_history[-2]):
		if index == 0:
			bounce_slope = slope[1]
		elif index == 4:
			if rand_range(0,1) > 0.5:
				bounce_slope = slope[index - 2]
			else:
				bounce_slope = slope[index + 2]
		elif index == 8:
			bounce_slope = slope[7]
		else:
			if rand_range(0,1) > 0.5:
				bounce_slope = slope[index - 1]
			else:
				bounce_slope = slope[index + 1]

	slope_history.append(bounce_slope)
	return bounce_slope

func clear_slope_history():
	slope_history = []

func _on_ServeTimer_timeout():
	visible = true
	launch_ball()

func _on_game_started():
	walls_closed = false
	current_round += 1

func _on_player1_scored():
	player_scored = 1

func _on_player2_scored():
	player_scored = 2

func _on_game_ended():
	player_scored = 0
	walls_closed = true
