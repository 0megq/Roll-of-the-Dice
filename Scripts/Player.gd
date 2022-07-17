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
enum State {IDLE, WALK, JUMP, LAND, FALL, DASH}

#Look
var looking_right: int = 1

#Melee
export var melee_speed: float
var can_melee: bool = true

#Ability
var current_roll: int = 1

#1
export var arrow_scene: PackedScene
export var arrow_throw_direction: Vector2
export var arrow_cooldown: float
var can_throw_arrow: bool = true

#2
export var extra_jumps: int
var extra_jump_count

#3
export var dash_force: float
export var dash_cooldown: float
export var dash_deacc: float
var can_dash: bool = true
var dash_count: int = 1
var dashing: bool = false

#4
export var bullet_scene: PackedScene
export var bullet_cooldown: float
export var bullet_count: int
export var bullet_spread: float
onready var bullet_spread_rad: float = deg2rad(bullet_spread)
var can_throw_bullet: bool = true

#5
export var bomb_scene: PackedScene
export var bomb_throw_direction: Vector2
export var bomb_cooldown: float
var can_throw_bomb: bool = true

#6
export var tsword_scene: PackedScene
export var tsword_throw_direction: Vector2
export var tsword_cooldown: float
var can_throw_tsword: bool = true
var has_sword: bool = true

#Health
var health: int = 6
export var hud_path: NodePath
onready var hud: Control = get_node(hud_path)
var heart_container: HBoxContainer


func _ready() -> void:
	sword_anim_player.play("Hold")
	rng.randomize()
	health = 6
	heart_container = hud.find_node("HeartContainer")
	

func _physics_process(delta: float) -> void:
	input()
	move(delta)
	look()
	sword()
	ability()
	health()
	animate()


func health() -> void:
	heart_container.update_health(health)


func animate() -> void:
	if dashing:
		state = State.DASH
	elif velocity.y < 0:
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
		State.DASH:
			anim_player.play("Dash")
			
	body_sprite.frame = current_roll - 1


func ability() -> void:
	if current_roll == 3 && is_on_floor():
		dash_count = 1
	if current_roll == 2 && is_on_floor():
		extra_jump_count = 1
	if ability_input:
		match current_roll:
			1:
				if can_throw_arrow:
					can_throw_arrow = false
					throw_arrow()
					yield(get_tree().create_timer(arrow_cooldown), "timeout")
					can_throw_arrow = true
			2:
				if extra_jump_count && !can_jump:
					extra_jump_count -= 1
					$JumpParticles.emitting = true
					jump()
			3:
				if can_dash && dash_count:
					can_dash = false
					dashing = true
					dash_count -= 1
					dash()
					yield(get_tree().create_timer(dash_cooldown), "timeout")
					can_dash = true
			4:
				if can_throw_bullet:
					can_throw_bullet = false
					for i in bullet_count:
						throw_bullet(i)
					yield(get_tree().create_timer(bullet_cooldown), "timeout")
					can_throw_bullet = true
			5:
				if can_throw_bomb:
					can_throw_bomb = false
					throw_bomb()
					yield(get_tree().create_timer(bomb_cooldown), "timeout")
					can_throw_bomb = true
			6:
				if can_throw_tsword && has_sword:
					has_sword = false
					can_throw_tsword = false
					throw_tsword()
					yield(get_tree().create_timer(tsword_cooldown), "timeout")
					can_throw_tsword = true


func dash():
	if x_input >= 0:
		velocity.x = dash_force
	else:
		velocity.x = -dash_force
	

func throw_bomb() -> void:
	var bomb: RigidBody2D = bomb_scene.instance()
	get_parent().add_child(bomb)
	var direction = Vector2(bomb_throw_direction.x * looking_right, bomb_throw_direction.y)
	bomb.global_position = self.position + direction
	var bomb_velocity: Vector2 = bomb.throw_speed * direction + velocity * 0.5
	bomb.linear_velocity = bomb_velocity
	

func throw_arrow() -> void:
	var arrow: RigidBody2D = arrow_scene.instance()
	get_parent().add_child(arrow)
	var direction = Vector2(arrow_throw_direction.x * looking_right, arrow_throw_direction.y)
	arrow.global_position = self.position + direction
	var arrow_velocity: Vector2 = arrow.throw_speed * direction + velocity * 0.5
	arrow.linear_velocity = arrow_velocity
	
	
func throw_bullet(bullet_num: int) -> void:
	var bullet: RigidBody2D = bullet_scene.instance()
	get_parent().add_child(bullet)
	var rotation = bullet_spread_rad * (bullet_num - bullet_count + 2)
	var direction = Vector2(looking_right, 0).rotated(rotation)
	bullet.global_position = self.position + direction
	var bullet_velocity: Vector2 = bullet.throw_speed * direction
	bullet.linear_velocity = bullet_velocity
	
	
func throw_tsword() -> void:
	var tsword: RigidBody2D = tsword_scene.instance()
	get_parent().add_child(tsword)
	var direction = Vector2(tsword_throw_direction.x * looking_right, tsword_throw_direction.y)
	tsword.global_position = self.position + direction
	var tsword_velocity: Vector2 = tsword.throw_speed * direction + velocity * 0.5
	tsword.linear_velocity = tsword_velocity
		
			
func kill(body: Node) -> void:
	body.die()
	current_roll = rng.randi_range(1,6)


func heal() -> void:
	health += 1
	health = clamp(health, 0, 6)


func sword() -> void:
	if melee_input && can_melee && has_sword && !dashing:
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
		sword.position.x = 0
	else:
		looking_right = -1
		sprite.flip_h = true
		sword.scale.x = -1
		sword.position.x = -2


func move(delta: float) -> void:
	#Left/Right
	var h_direction: int = x_input
	
	if abs(velocity.x + h_direction * move_acc) < move_speed:
		velocity.x += h_direction * move_acc
	
	#lerps velocity.x to 0 if player is isn't holding a direction
	if !h_direction:
		velocity.x = lerp(velocity.x, 0, idle_deacc)
	
	#clamps x velocity to recoil value
	if velocity.x > move_speed:
		velocity.x = lerp(velocity.x, move_speed, dash_deacc)
	if velocity.x < -move_speed:
		velocity.x = lerp(velocity.x, -move_speed, dash_deacc)
	
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


func damage() -> void:
	if !dashing:
		health -= 1
		health = clamp(health, 0, 6)
		if health <= 0:
			dead()


func dead() -> void:
	get_tree().reload_current_scene()


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
	if current_roll != 2:
		if Input.is_action_pressed("ability"):
			ability_input = 1
	else:
		if Input.is_action_just_pressed("ability"):
			ability_input = 1

	if current_roll == 2:
		if jump_input:
			ability_input = 1
		if ability_input:
			jump_input = 1


func _on_Sword_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy"):
		kill(body)


func set_dashing(value: bool) -> void:
	dashing = value


func _on_DashHitBox_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy") && dashing:
		kill(body)
		print("Bashed :)")
