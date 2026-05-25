extends CharacterBody3D

var frequency = 1.1
var amplitude = 0.3
var time:= 0.0
var cur_speed = 0

func _physics_process(delta: float) -> void:
	movement(delta)
	
	move_and_slide()
	
func movement(delta):
	time += delta
	
	velocity.y = sin(time * frequency) * amplitude
	velocity.x = 0
	velocity.z = 0
	
