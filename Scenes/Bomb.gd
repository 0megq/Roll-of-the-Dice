extends RigidBody2D


export var throw_speed: float
var player: Player


func _ready() -> void:
	player = get_parent().find_node("Player")
	yield(get_tree().create_timer(0.5), "timeout")
	$AnimationPlayer.play("Ignite")
	$AnimationPlayer.queue("Explode")

func _on_BlastRadius_body_entered(body: Node) -> void:
	player.kill(body)
