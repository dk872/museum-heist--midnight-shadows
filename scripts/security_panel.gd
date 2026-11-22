extends Area2D

@onready var hack_sound: AudioStreamPlayer = $HackSound

func interact() -> void:
	if GameManager.panel_is_disabled:
		return
	hack_sound.play()
	print("Security panel successfully hacked!")
	GameManager.on_panel_disabled()
