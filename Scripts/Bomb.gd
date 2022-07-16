extends RigidBody2D


export var throw_speed: float
onready var player: Player = get_parent().find_node("Player")


func _ready() -> void:
	yield(get_tree().create_timer(0.5), "timeout")
	$AnimationPlayer.play("Ignite")
	$AnimationPlayer.queue("Explode")

func _on_BlastRadius_body_entered(body: Node) -> void:
	player.kill(body)
