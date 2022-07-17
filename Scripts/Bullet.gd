extends RigidBody2D

export var throw_speed: float
export var despawn_time: float
onready var player: Player = get_parent().find_node("Player")

func _ready() -> void:
	if linear_velocity.x > 0:
		$Sprite.scale.x = 2
	if linear_velocity.x < 0:
		$Sprite.scale.x = -2
	if linear_velocity:
		$Sprite.rotation = atan(linear_velocity.y/linear_velocity.x)
		$CollisionShape2D.rotation = atan(linear_velocity.y/linear_velocity.x)
	yield(get_tree().create_timer(despawn_time), "timeout")
	despawn()


func despawn() -> void:
	queue_free()


func _on_Bullet_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy"):
		player.kill(body)
	despawn()
