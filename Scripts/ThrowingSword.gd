extends RigidBody2D


export var throw_speed: float
export var despawn_time: float
onready var player: Player = get_parent().find_node("Player")
var colliding: bool = false

func _ready() -> void:
	player.sword_anim_player.play("Invisible")
	yield(get_tree().create_timer(despawn_time), "timeout")
	despawn()


func _physics_process(delta: float) -> void:
	if linear_velocity.x > 0:
		var rot = atan(linear_velocity.y/linear_velocity.x) + PI/2
		$SwordSprite.scale.x = 2
		rotate(rot)
	if linear_velocity.x < 0:
		var rot = atan(linear_velocity.y/linear_velocity.x) - PI/2
		$SwordSprite.scale.x = -2
		rotate(rot)


func rotate(rot: float):
	$SwordSprite.rotation = rot
	$CollisionShape2D.rotation = rot
	$HitBox/CollisionShape2D.rotation = rot
		
		

func _on_HitBox_body_entered(body: Node) -> void:
	player.kill(body)
	player.heal()


func despawn() -> void:
	player.sword_anim_player.play("Visible")
	player.sword_anim_player.play("Idle")
	player.has_sword = true
	queue_free()


func _on_ThrowingSword_body_entered(body: Node) -> void:
	colliding = true
	yield(get_tree().create_timer(0.3), "timeout")
	if colliding:
		despawn()
	

func _on_ThrowingSword_body_exited(body: Node) -> void:
	colliding = false

