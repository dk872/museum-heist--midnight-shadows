extends Area2D

func interact() -> void:
	if GameManager.panel_is_disabled:
		return
	print("Security panel successfully hacked!")
	GameManager.on_panel_disabled()
