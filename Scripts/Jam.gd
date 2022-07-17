extends Area2D






func _on_Jam_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		Global.win()
