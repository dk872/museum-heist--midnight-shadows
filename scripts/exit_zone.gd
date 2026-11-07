extends Area2D

# This function is called automatically when the player enters the CollisionShape
func _on_body_entered(body: Node2D) -> void:
	# Check if the entered body is our player
	if body.name == "Player":
		# Check the global condition: did the player steal the artifact?
		if GameManager.has_artifact:
			print("Victory! You successfully escaped with the artifact.")
			GameManager.win()
		else:
			print("You haven't stolen the artifact yet! Go back.")
			GameManager.show_message("Steal the Eye of the Pharaoh first")
