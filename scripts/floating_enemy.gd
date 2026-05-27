extends CharacterBody3D

@onready var area_3d: Area3D = $Area3D

var player

var frequency = 1.1
var amplitude = 0.3
var time:= 0.0
var cur_speed = 0
var bounce_amount = 0

func _ready() -> void:
	player =  get_node("/root/World/player/CharacterBody3D")
	area_3d.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	
	movement(delta)
	
	death()
	
	move_and_slide()
	
func movement(delta):
	time += delta
	
	velocity.y = sin(time * frequency) * amplitude
	velocity.x = 0
	velocity.z = 0
	
func _on_body_entered(body):
	if body.is_in_group("Player"):
		player.velocity.y += 30
		bounce_amount += 1
		if player.pulling_enemy:
			player.pulling_enemy = false
			
func death():
	#print(bounce_amount)
	if bounce_amount == 5:
		queue_free()
