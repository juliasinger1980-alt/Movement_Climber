extends CharacterBody3D

var held:int

var cur_speed = Vector3.ZERO
var player
var max_speed = 6
var random_dir: Vector3
var dir: Vector3
var detection_range = 50
var melee_range = 2.5
var enemyknockbackstrength = 15
var playerknockbackstrength = 30
var hitcooldown = 0.5
var hitcooldownmax = 0.5
var randomness_cooldown = 0
var randomness_cooldown_max = 1
var randomness_multiplier = 0.5

func _ready() -> void:
	player =  get_node("/root/World/player/CharacterBody3D")
	
func _physics_process(delta: float) -> void:
	look_at(player.position)
	hitcooldown -= delta
	hitcooldown = clamp(hitcooldown, 0, hitcooldownmax)
	
	randomness_cooldown -= delta
	randomness_cooldown = clamp(randomness_cooldown, 0, randomness_cooldown_max)
	
	movement(delta)
	
	move_and_slide()

func movement(delta):
	var distance = (player.global_position - global_position).length()
	dir = (player.global_position - global_position).normalized()
	var random_vector = randf_range(-1.0, 1.0) * randomness_multiplier
	
	if randomness_cooldown == 0:
		random_dir = ((player.global_position - global_position)).normalized() + Vector3(random_vector, random_vector, random_vector)
		randomness_cooldown = randomness_cooldown_max
	if player.pulling_enemy:
		cur_speed = lerp(cur_speed, Vector3.ZERO, 1*delta)
	elif distance <= melee_range:
		cur_speed = lerp(cur_speed, max_speed * dir, 3*delta)
	elif distance <= detection_range:
		cur_speed = lerp(cur_speed, max_speed * random_dir, 2*delta)
	else:
		cur_speed = lerp(cur_speed, Vector3.ZERO, 1*delta)
	
	if not player.pulling_enemy:
		velocity = cur_speed

func _on_area_3d_body_entered(body: Node3D) -> void:
	if hitcooldown == 0 and not body.is_in_group("Enemy"):
		if not player.pulling_enemy and body.is_in_group("Player"):
			cur_speed += enemyknockbackstrength * -dir
			player.velocity.y += 3
			player.cur_speed += playerknockbackstrength * -global_transform.basis.z
			hitcooldown = hitcooldownmax
			player.pulling_self = false
		else:
			player.pulling_enemy = false
