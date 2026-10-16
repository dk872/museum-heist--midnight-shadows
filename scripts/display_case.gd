extends Area2D

var is_hacking: bool = false
var hack_time: float = 0.0
var required_time: float = 2.0 # 2 seconds per GDD

# Called when the player presses and holds the "interact" button
func interact() -> void:
	is_hacking = true
	hack_time = 0.0
	print("Display case hack started... Hold the key!")

# Called if the player releases the "interact" button before completion
func cancel_interact() -> void:
	if is_hacking:
		is_hacking = false
		hack_time = 0.0
		print("Hack aborted!")

# Built-in Godot function, called every frame
func _process(delta: float) -> void:
	if is_hacking:
		hack_time += delta
		if hack_time >= required_time:
			is_hacking = false
			print("Artifact 'Eye of the Pharaoh' successfully stolen!")
			
			# Notify the global manager
			GameManager.has_artifact = true
