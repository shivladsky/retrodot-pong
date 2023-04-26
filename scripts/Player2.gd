extends Node2D

func _ready():
	$Paddle.setup_controls("player2_up", "player2_down")
