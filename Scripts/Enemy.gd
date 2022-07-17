extends KinematicBody2D
class_name Enemy

#Input
var x_input: int = 0
var jump_input: int = 0
var melee_input: int = 0

#AI
var tracking: bool = false
export var jump_cast_path: NodePath
onready var jump_cast: RayCast2D = get_node(jump_cast_path)

#General
var looking_right: int = 1
var velocity: Vector2 = Vector2.ZERO
export var sword_path: NodePath
onready var sword: Area2D = get_node(sword_path)
onready var player: Player = get_parent().find_node("Player")

#Moving
export var move_speed: float
export var move_acc: float
export var idle_deacc: float

#Jumping
export var jump_height: float
export var jump_duration: float
export var fall_duration: float
export var max_fall: float

onready var fall_gravity: float = ((-2 * jump_height) / (fall_duration * fall_duration)) * -1
onready var jump_gravity: float =  ((-2 * jump_height) / (jump_duration * jump_duration)) *-1
onready var jump_velocity: float = ((2 * jump_height) / jump_duration) * -1

var reset_y_vel: bool = true
var can_jump: bool = true

#Animation
export var anim_player_path: NodePath
onready var anim_player: AnimationPlayer = get_node(anim_player_path)
export var sword_anim_player_path: NodePath
onready var sword_anim_player: AnimationPlayer = get_node(sword_anim_player_path)

#Melee
export var melee_speed: float
export var melee_reaction: float
var can_melee: bool = true
var should_melee: bool = false


func _ready() -> void:
	sword_anim_player.play("Hold")
	anim_player.play("Idle")


func _physics_process(delta: float) -> void:
	ai()
	move(delta)
	look()
	sword()
	animate()


func ai() -> void:
	x_input = 0
	jump_input = 0
	melee_input = 0
	
	if tracking: #x input
		var x_diff: float = player.position.x - self.position.x
		if x_diff > 0:
			x_input = 1
		if x_diff < 0:
			x_input = -1
			
	if should_melee:
		melee_input = 1
		
	if jump_cast.is_colliding():
		jump_input = 1
	
	var allies: Array = $DetectionRadius.get_overlapping_bodies()
	for i in allies:
		if i.is_in_group("Enemy"):
			if i.tracking:
				tracking = true
		else:
			tracking = true
	
		

func sword() -> void:
	if melee_input && can_melee:
		can_melee = false
		sword_anim_player.stop()
		sword_anim_player.play("Swing")
		sword_anim_player.queue("Hold")
		yield(get_tree().create_timer(melee_speed), "timeout")
		can_melee = true


func animate() -> void:
	if abs(velocity.x) > 0.1:
		anim_player.play("Walk")
	else:
		anim_player.play("Idle")
	
	
func look() -> void:
	if velocity.x > 0:
		looking_right = 1
	if velocity.x < 0:
		looking_right = -1
		
	if looking_right == 1:
		sword.scale.x = 1
		jump_cast.scale.y = 1
	if looking_right == -1:
		sword.scale.x = -1
		jump_cast.scale.y = -1
	

func move(delta: float) -> void:
	#Left/Right
	var h_direction: int = x_input

	velocity.x += h_direction * move_acc
	
	
	#lerps velocity.x to 0 if player is isn't holding a direction
	if !h_direction:
		velocity.x = lerp(velocity.x, 0, idle_deacc)
	
	#clamps x velocity to recoil value
	velocity.x = clamp(velocity.x, -move_speed, move_speed)
	
	#Jumping
	if is_on_floor():
		if reset_y_vel:
			velocity.y = 0.1
			reset_y_vel = false
		can_jump = true

	if jump_input:
		if can_jump:
			jump()
	
	if !is_on_floor():
		can_jump = false
		reset_y_vel = true
		apply_gravity(delta)
	
	move_and_slide(velocity, Vector2.UP)


func apply_gravity(delta: float) -> void:
	var gravity: float = jump_gravity if velocity.y < 0 else fall_gravity
	if gravity:
		velocity.y += gravity * delta
	if velocity.y > max_fall:
		velocity.y = max_fall


func jump() -> void:
	velocity.y = jump_velocity


func die() -> void:
	queue_free()


func _on_Sword_body_entered(body: Node) -> void:
	if body is Player:
		body.damage()


func _on_DetectionRadius_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		tracking = false


func _on_SwordDetection_body_entered(body: Node) -> void:
	yield(get_tree().create_timer(melee_reaction), "timeout")
	should_melee = true


func _on_SwordDetection_body_exited(body: Node) -> void:
	yield(get_tree().create_timer(melee_reaction), "timeout")
	should_melee = false
