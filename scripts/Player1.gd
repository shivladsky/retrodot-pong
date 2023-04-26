extends Node2D

func _ready():
	$Paddle.setup_controls("player1_up", "player1_down")
