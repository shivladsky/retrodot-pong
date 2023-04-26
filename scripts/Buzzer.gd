extends AudioStreamPlayer

var sounds = {
	"ball_hit": preload("res://assets/sounds/ball_hit.wav"),
	"ball_bounce": preload("res://assets/sounds/ball_bounce.wav"),
	"ball_score": preload("res://assets/sounds/ball_score.wav")
}

func play_sound(event: String):
	stream = sounds[event]
	play()
