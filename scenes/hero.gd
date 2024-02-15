extends CharacterBody2D

const JUMP_FORCE = 3000
const MAX_JUMP_IMPULSE_TIME: float = 0.3

@export
var player_speed: int = 200
@export
var max_life_points: int = 50
@export
var arm_rotation_speed: float = 2*PI

var life_points: float = 50.0
var level: int = 0
var xp: int = 0
var xp_threshold: int = 100

var jump_impulse_time: float = 0.0

signal shot(spawn_position: Vector2, orientation: float)
signal died

func _ready() -> void:
	life_points = max_life_points
	velocity.x = player_speed
	$UI.sync_life(life_points, max_life_points)
	level_up()

func _process(delta: float) -> void:
	
	if is_on_floor():
		$Body.animation = "run"
		$Legs.animation = "run"
		$JumpingShape.disabled = true
		$RunningShape.disabled = false
		jump_impulse_time = MAX_JUMP_IMPULSE_TIME
	else:
		$Body.animation = "jump"
		$Legs.animation = "jump"
		$JumpingShape.disabled = false
		$RunningShape.disabled = true
		jump_impulse_time -= delta
		velocity.y += delta*GameConstants.GRAVITY
	
	if Input.is_action_pressed("jump") and jump_impulse_time > 0:
		velocity.y -= delta*JUMP_FORCE
	
	move_and_slide()
	
	if global_position.y > GameConstants.DEATH_GLOBAL_Y_POSITION:
		hurt(1000)
	
	var lock_on_target = select_target()
	aim_to(lock_on_target.global_position, delta)
	
	if Input.is_action_just_pressed("ui_accept"): # To be removed
		shoot()

func hurt(damage: float):
	life_points -= damage
	$UI.sync_life(life_points, max_life_points)
	if life_points <= 0:
		die()

func die():
	died.emit()

func shoot():
	var orientation = $ShoulderPivot.rotation
	shot.emit($ShoulderPivot.global_position + Vector2.from_angle(orientation)*120, orientation)

func select_target() -> Node2D:
	var target = self
	var current_min_distance = 10000
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if (enemy.global_position - global_position).length() < current_min_distance:
			target = enemy
	return target

func aim_to(location: Vector2, delta: float):
	var target_orientation = $ShoulderPivot.global_position.angle_to_point(location)
	var rotation_strength = fposmod(target_orientation-$ShoulderPivot.rotation, 2*PI)/PI - 1
	$ShoulderPivot.rotation -= rotation_strength*arm_rotation_speed*delta

func get_xp(amount: int):
	xp += amount
	if(xp >= xp_threshold):
		xp -= xp_threshold
		await level_up()
	get_tree().paused = false

func level_up():
	get_tree().paused = true
	$UI/LevelUpScreen.pick_powerup()
	var powerup = await $UI/LevelUpScreen.powerup_selected
	get_tree().paused = false
	level += 1
	xp_threshold = level*100
	OnScreenTerminal.log(powerup)


func _on_enermy_defeated(who: Variant) -> void:
	get_xp(who.xp_value)
