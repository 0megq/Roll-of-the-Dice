extends KinematicBody2D
class_name Player

#Input
var x_input: int = 0
var jump_input: int = 0
var melee_input: int = 0
var ability_input: int = 0

#General
var velocity: Vector2 = Vector2.ZERO
export var sprite_path: NodePath
onready var sprite: Sprite = get_node(sprite_path)
export var body_sprite_path: NodePath
onready var body_sprite: Sprite = get_node(body_sprite_path)
export var sword_path: NodePath
onready var sword: Area2D = get_node(sword_path)
var rng = RandomNumberGenerator.new()

#Movement
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
var coyote_time_length: float = 0.15
var jump_was_pressed: bool = false
var remember_jump_length: float = 0.1

#Animation
export var anim_player_path: NodePath
onready var anim_player: AnimationPlayer = get_node(anim_player_path)
export var sword_anim_player_path: NodePath
onready var sword_anim_player: AnimationPlayer = get_node(sword_anim_player_path)
var state: int = 0
enum State {IDLE, WALK, JUMP, LAND, FALL}

#Look
var looking_right: int = 1

#Melee
export var melee_speed: float
var can_melee: bool = true

#Ability
var current_roll: int = 5
#1
#2
#3
#4
#5
export var bomb_scene: PackedScene
export var throw_direction: Vector2
export var bomb_cooldown: float
var can_throw_bomb: bool = true
#6


func _ready() -> void:
	sword_anim_player.play("Hold")
	rng.randomize()
	

func _physics_process(delta: float) -> void:
	input()
	move(delta)
	look()
	sword()
	ability()
	animations()


func animations() -> void:
	if velocity.y < 0:
		state = State.JUMP
	elif velocity.y > 0.2:
		state = State.FALL
	elif abs(velocity.x) > 0.1:
		state = State.WALK
	elif velocity.x < 0.1 && state == State.FALL && is_on_floor():
		state = State.LAND
	else:
		state = State.IDLE
		
	match state:
		State.JUMP:
			anim_player.play("Jump")
		State.FALL:
			anim_player.play("Fall")
		State.WALK:
			anim_player.play("Walk")
		State.IDLE:
			if anim_player.current_animation == "Walk":
				anim_player.play("Idle")
			else:
				anim_player.queue("Idle")
		State.LAND:
			anim_player.play("Land")
			
	body_sprite.frame = current_roll - 1


func ability() -> void:
	if ability_input:
		match current_roll:
			1:
				print("1")
			2:
				print("2")
			3:
				print("3")
			4:
				print("4")
			5:
				if can_throw_bomb:
					can_throw_bomb = false
					throw_bomb()
					yield(get_tree().create_timer(bomb_cooldown), "timeout")
					can_throw_bomb = true
			6:
				print("6")


func throw_bomb() -> void:
	var bomb: RigidBody2D = bomb_scene.instance()
	get_parent().add_child(bomb)
	var direction = Vector2(throw_direction.x * looking_right, throw_direction.y)
	bomb.global_position = self.position + direction
	var bomb_velocity: Vector2 = bomb.throw_speed * direction + velocity * 0.5
	bomb.linear_velocity = bomb_velocity
		
			
func kill(body: Node) -> void:
	body.die()
	current_roll = rng.randi_range(1,6)


func sword() -> void:
	if melee_input && can_melee:
		can_melee = false
		sword_anim_player.stop()
		sword_anim_player.play("Swing")
		sword_anim_player.queue("Hold")
		yield(get_tree().create_timer(melee_speed), "timeout")
		can_melee = true
	

func look() -> void:
	if velocity.x >= 0:
		looking_right = 1
		sprite.flip_h = false
		sword.scale.x = 1
	else:
		looking_right = -1
		sprite.flip_h = true
		sword.scale.x = -1


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
		if jump_was_pressed:
			jump()

	if jump_input:
		jump_was_pressed = true
		remember_jump_time()
		if can_jump:
			jump()
	
	if !is_on_floor():
		reset_y_vel = true
		coyote_time()
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


func coyote_time():
	yield(get_tree().create_timer(coyote_time_length), "timeout")
	can_jump = false


func remember_jump_time():
	yield(get_tree().create_timer(remember_jump_length), "timeout")
	jump_was_pressed = false


func input() -> void:
	#Resets variables
	x_input = 0
	jump_input = 0
	melee_input = 0
	ability_input = 0
	
	#Horizontal
	if Input.is_action_pressed("right"):
		x_input += 1
	if Input.is_action_pressed("left"):
		x_input -= 1
	#Jump
	if Input.is_action_just_pressed("jump"):
		jump_input = 1
	#Melee
	if Input.is_action_pressed("melee"):
		melee_input = 1
	#Ability
	if Input.is_action_pressed("ability"):
		ability_input = 1


func _on_Sword_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy"):
		kill(body)
