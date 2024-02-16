extends Area2D


@export
var pos_left := Vector2(-800, 0)
@export
var pos_right := Vector2(800, 0)
@export
var dps: float = 30.0
@export
var speed: float = 900

var speed_boost: float = 1.0

var target: Vector2 = pos_right

func _process(delta: float) -> void:
	var path_to_target: Vector2 = (target - position)
	position += speed*speed_boost*path_to_target.normalized()*delta
	if path_to_target.length() < 50:
		target = pos_left if target == pos_right else pos_right
	
	for enemy: Enemy in get_overlapping_bodies():
		enemy.hurt(dps*delta)

func cooldown_boost(boost: float):
	speed_boost = boost
