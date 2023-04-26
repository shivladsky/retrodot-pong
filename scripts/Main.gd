extends Node2D

signal ball_ready(ball_node)
signal game_started
signal player1_scored
signal player2_scored
signal game_ended

onready var player1 = preload("res://scenes/Player1.tscn").instance()
onready var player2 = preload("res://scenes/Player2.tscn").instance()
onready var ball = preload("res://scenes/Ball.tscn").instance()
onready var buzzer = preload("res://scenes/Buzzer.tscn").instance()

var sound_enabled = true
var game_started = false
var serve_timer = false

var player1_score: int = 0
var player2_score: int = 0
var max_score: int = 11 # 11 or 15

var score_sprites: Array = []
var alpha_value: float = 0.83

func _ready():
	# Hide the mouse pointer
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Load score sprite textures into an array
	for i in range(16):
			score_sprites.append(load("res://assets/sprites/digits-%02d.png" % i))
	
	add_child(ball)
	add_child(buzzer)

	player1.position = Vector2(125, get_viewport_rect().size.y / 2)
	player2.position = Vector2(1156, get_viewport_rect().size.y / 2)
	ball.position = Vector2(665, 200) # Was 240
	
	update_score_sprites()
	
	# Apply opacity to the score sprites
	$Player1ScoreSprite.modulate = Color(1,1,1, alpha_value)
	$Player2ScoreSprite.modulate = Color(1,1,1, alpha_value)

	ball.connect("ball_hit_paddle", self, "_on_ball_hit_paddle")
	ball.connect("ball_reflected", self, "_on_ball_reflected")
	ball.connect("ball_exited_screen", self, "_on_ball_exited_screen")
	
	emit_signal("ball_ready", ball)
	
func _input(event):
	if event.is_action_pressed("toggle_sound"):
		sound_enabled = not sound_enabled
	elif event.is_action_pressed("toggle_full_screen"):
		OS.window_fullscreen = not OS.window_fullscreen
		if not OS.window_fullscreen:
			OS.window_size = Vector2(1280, 720)
	elif event.is_action_pressed("change_screen") and OS.window_fullscreen:
		change_screen()
	elif event.is_action_pressed("start_game") and not game_started:
		start_game()
	elif event.is_action_pressed("exit_game"):
		get_tree().quit()

func _on_ball_hit_paddle():
	if game_started and sound_enabled:
		buzzer.play_sound("ball_hit")
	
func _on_ball_reflected():
	if game_started and sound_enabled:
		buzzer.play_sound("ball_bounce")

func _on_ball_exited_screen():
	if ball.global_position.x > get_viewport().size.x / 2:
		player1_score += 1
		emit_signal("player1_scored")
	else:
		player2_score += 1
		emit_signal("player2_scored")
		
	if game_started and sound_enabled and player1_score != max_score and player2_score != max_score:
		buzzer.play_sound("ball_score")

	update_score_sprites()

	if player1_score == max_score or player2_score == max_score:
		end_game()
	else:
		serve_timer = true
		ball.reset_ball(serve_timer)
		
func update_score_sprites():
	$Player1ScoreSprite.texture = score_sprites[player1_score]
	$Player2ScoreSprite.texture = score_sprites[player2_score]

func start_game():
	emit_signal("game_started")
	serve_timer = false
	ball.reset_ball(serve_timer)
	game_started = true
	player1_score = 0
	player2_score = 0
	update_score_sprites()
	add_child(player1)
	add_child(player2)

func end_game():
	emit_signal("game_ended")
	serve_timer = false
	game_started = false
	ball.reset_ball(serve_timer)
	remove_child(player1)
	remove_child(player2)

func change_screen():
	var screen_count = OS.get_screen_count()
	var current_screen = OS.current_screen

	if screen_count > 1:
		if current_screen == (screen_count - 1):
			current_screen = 0
		else:
			current_screen += 1

	OS.current_screen = current_screen
