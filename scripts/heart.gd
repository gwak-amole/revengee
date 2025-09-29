extends CharacterBody2D
signal heart_contacted

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.name != "player_hitbox":
		return
	emit_signal("heart_contacted")
	print("HEART CONTACTED ------------")
	queue_free()
