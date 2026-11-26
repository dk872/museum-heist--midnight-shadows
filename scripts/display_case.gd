extends Area2D

signal hold_progress(ratio: float)   # 0..1 while holding E
signal hold_cancelled

var is_hacking: bool = false
var hack_time: float = 0.0
var required_time: float = 2.0 # 2 seconds per GDD

@onready var hack_loop_sound: AudioStreamPlayer = $HackLoopSound
@onready var abort_sound: AudioStreamPlayer = $AbortSound
@onready var success_sound: AudioStreamPlayer = $SuccessSound

func _ready() -> void:
	area_exited.connect(_on_area_exited)

# TC-01-D1: walking away while holding E must cancel the hack, not finish it from a distance
func _on_area_exited(area: Area2D) -> void:
	if is_hacking and area.get_parent().is_in_group("player"):
		cancel_interact()

# Called when the player presses and holds the "interact" button
func interact() -> void:
	if GameManager.has_artifact:
		return
	# Locked until the security panel is hacked (GDD: panel -> case)
	if not GameManager.panel_is_disabled:
		GameManager.show_message("The case is protected. Disable the security panel first")
		return
	is_hacking = true
	hack_time = 0.0
	hack_loop_sound.play()
	print("Display case hack started... Hold the key!")

# Called if the player releases the "interact" button before completion
func cancel_interact() -> void:
	if is_hacking:
		is_hacking = false
		hack_time = 0.0
		hold_cancelled.emit()
		abort_sound.play()
		print("Hack aborted!")

# Built-in Godot function, called every frame
func _process(delta: float) -> void:
	if is_hacking and GameManager.state == GameManager.State.PLAYING:
		hack_time += delta
		hold_progress.emit(minf(hack_time / required_time, 1.0))
		if hack_time >= required_time:
			is_hacking = false
			hold_progress.emit(1.0)
			success_sound.play()
			print("Artifact 'Eye of the Pharaoh' successfully stolen!")
			
			# Notify the global manager
			GameManager.has_artifact = true
