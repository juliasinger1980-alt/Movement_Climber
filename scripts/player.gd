extends CharacterBody3D

@onready var camera: Camera3D = $head/Camera3D
@onready var head: Node3D = $head
@onready var fps: Label3D = $head/Camera3D/FPS_Count
@onready var walljumpRC: RayCast3D = $head/Camera3D/Walljumpcast
@onready var wallkickRC: RayCast3D = $head/Camera3D/Wallkickcast
@onready var grapplecast: RayCast3D = $head/Camera3D/Grapplecast
@onready var grappleline:= MeshInstance3D.new()
@onready var pullRC: RayCast3D = $head/Camera3D/Pullcast
@onready var flying_enemy: Node3D = $"../../flying_enemy"

var gravity_player = 40

var cur_speed = Vector3.ZERO
var target_speed_gehen = 6.0
var target_speed_sprint = 11.0
var sliding_speed = 15.5
var target_speed_grappling = 25.0
var max_speed = 0.0
var sprinting = false
var dir = Vector3.ZERO

var sprungstaerke = 13.0
var air_control_mult = 0.2
var sprungbuffertimer = 0
var koyotebuffertimer = 0

var x_rot = 0.0
var y_rot = 0.0
var mouse_sensi = 0.0015
var fov_normal = 100.0
var fov_sprinting = 110.0
var fov_sliding = 115.0
@onready var original_cam_pos =  camera.position

var can_walljump = true
var can_wallkick = true
var can_enemykick = true
var wallkickstr = 18
#var wallkickjumpstr = 12
var walljumpstr = 18
var walljumpbuffertimer = 0.0
var wallkickbuffertimer = 0.0
var wallkickmovementtimer = 0.0
var enemykickbuffertimer = 0.0

@export var desired_distance:float = 2
var grappelnd = false
var can_grapple = true
var grapple_dampening = 0.5
var hitobj = null
var hitpoint = Vector3.ZERO
var distance = 0
var direction = Vector3.ZERO
var rope_direction = Vector3.ZERO
var im_mesh:= ImmediateMesh.new()

var can_pull = true
var pulling_self = false
var pulling_enemy = false
var orig_distance
var pulling_enemy_weight = 0.1
var collider
var holding_distance = 2
var punkt = Vector3.ZERO
var orig_dist = 0.0
var orig_direction_to_point = Vector3.ZERO
var orig_direction_to_player = Vector3.ZERO
var wanted_dist = 1.5

var can_slide = true
var sliding
var camera_slide_offset = 0.7
var slide_timer = 0.6
var slide_control_mult = 0.1
var slidejumpstaerke = 10.0
var slidejumpboost = 11.0
var slide_cooldown = 0.2
@onready var slide_cooldown_max = slide_cooldown
@onready var slide_duration_max = slide_timer

var fliegend = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_child(grappleline)
	grappleline.mesh = im_mesh
	
func _physics_process(delta: float) -> void:
	movement(delta)
	
	grav(delta)
	
	if is_on_wall() and wallkickmovementtimer == 0:
		var n = get_wall_normal()
		if cur_speed.dot(n) < 0:
			cur_speed = cur_speed.slide(n)
	
	pull(delta)
	
	#grappling_hook(delta)
	
	move_and_slide()
	
	fps_anzeige()
	
	Debugging()

func _process(_delta: float) -> void:
	#GRAPPLE_SCHNUR
	if grappelnd:
		im_mesh.clear_surfaces()
		im_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		im_mesh.surface_add_vertex(to_local(hitpoint))
		im_mesh.surface_add_vertex(Vector3.ZERO)
		im_mesh.surface_end()
	else:
		im_mesh.clear_surfaces()

func movement(delta):
	dir = Vector3.ZERO
	#BASIC X/Z-MOVEMENT
	if Input.is_action_pressed("W"):
		dir += -global_transform.basis.z
	if Input.is_action_pressed("S"):
		dir += global_transform.basis.z
	if Input.is_action_pressed("A"):
		dir += -global_transform.basis.x
	if Input.is_action_pressed("D"):
		dir += global_transform.basis.x
	
	var move_input = Input.get_vector("A","D","W","S")
	dir = dir.normalized()
	#SPRINTEN UND GRAPPLING MAX SPEED
	if grappelnd:
		sprinting = false
		max_speed = target_speed_grappling
	elif sliding:
		camera.fov = lerp(camera.fov, fov_sliding, 8*delta)
	elif Input.is_action_pressed("Shift"):
		sprinting = true
		max_speed = target_speed_sprint
		if move_input != Vector2.ZERO:
			camera.fov = lerp(camera.fov, fov_sprinting, 8*delta)
	else:
		sprinting = false
		max_speed = target_speed_gehen
		camera.fov = lerp(camera.fov, fov_normal, 8*delta)
	
	
	##CUR SPEED UND VELOCITY SETZEN
	if wallkickbuffertimer == 0:
		if grappelnd:
			cur_speed = lerp(cur_speed, max_speed * dir, 3 * delta)
		#LUFTMOVEMENT
		elif not is_on_floor():
			cur_speed = lerp(cur_speed, max_speed * dir, 12 * delta * air_control_mult)
		elif sliding:
			cur_speed = lerp(cur_speed, sliding_speed * dir, 12 * delta * slide_control_mult)
		#BODENMOVEMENT
		else:
			cur_speed = lerp(cur_speed, max_speed * dir, 12 * delta)
	
	velocity.x = cur_speed.x
	velocity.z = cur_speed.z
	
	#SLIDE

	if move_input != Vector2.ZERO and slide_cooldown == 0 and can_slide and slide_timer > 0 and (Input.is_action_just_pressed("STRG") or Input.is_action_just_pressed("C")):
		cur_speed = sliding_speed * dir
		sliding = true
		
	if sliding:
		slide_timer -= delta
		slide_timer = clamp(slide_timer, 0, slide_duration_max)
		camera.position.y = lerp(camera.position.y, original_cam_pos.y - camera_slide_offset, delta * 8)
		
		
		cur_speed *= 0.97
		
		if slide_timer == 0 or (Input.is_action_just_released("STRG") or Input.is_action_just_released("C")):
			sliding = false
			slide_timer = slide_duration_max
			slide_cooldown = slide_cooldown_max
	else: 
		camera.position.y = lerp(camera.position.y, original_cam_pos.y, delta * 8)
	
	if is_on_floor(): 
		if slide_timer == slide_duration_max:
			slide_cooldown -= delta
			slide_cooldown = clamp(slide_cooldown, 0, slide_cooldown_max)
			if slide_cooldown == 0:
				can_slide = true
	else: 
		sliding = false
		slide_timer = slide_duration_max
		can_slide = false
	
	##WALLKICK/JUMP UND NORMALER JUMP UND SLIDE JUMP
	#wall kick
	var WJcollider = walljumpRC.get_collider()
	var WKcollider = wallkickRC.get_collider()
	
	if not is_on_floor() and can_walljump:
		if Input.is_action_just_pressed("Space"):
			walljumpbuffertimer = 0.150
	if can_wallkick:
		if Input.is_action_just_pressed("RC"):
			wallkickbuffertimer = 0.150
			wallkickmovementtimer = 0.5
			
	if can_enemykick:
		if Input.is_action_just_pressed("RC"):
			enemykickbuffertimer = 0.150
	
	walljumpbuffertimer -= delta
	walljumpbuffertimer = clamp(walljumpbuffertimer, 0, 0.150)
	
	enemykickbuffertimer -= delta
	enemykickbuffertimer = clamp(walljumpbuffertimer, 0, 0.150)
	
	wallkickmovementtimer -= delta
	wallkickmovementtimer = clamp(walljumpbuffertimer, 0, 0.5)
	
	wallkickbuffertimer -= delta
	wallkickbuffertimer = clamp(wallkickbuffertimer, 0, 0.150)
	
	#print(camera.global_transform.basis.z)
	
	if wallkickbuffertimer > 0:
		if WKcollider and WKcollider.is_in_group("Obstacle"):
			var opp_dir = camera.global_transform.basis.z
			cur_speed = opp_dir * wallkickstr
			velocity.y = opp_dir.y * wallkickstr
			can_wallkick = false
			wallkickbuffertimer = 0
			
	#if enemykickbuffertimer > 0:
		#if WKcollider and WKcollider.is_in_group("Obstacle"):
			#var opp_dir = Vector3(transform.basis.z.x, camera.transform.basis.z.y, transform.basis.z.z)
			#cur_speed = opp_dir * wallkickstr
			#velocity.y = opp_dir.y * wallkickstr
			#can_wallkick = false
			#wallkickbuffertimer = 0
	
	if walljumpbuffertimer > 0:
		if WJcollider and WJcollider.collision_layer == 1:
			velocity.y = walljumpstr
			can_walljump = false
			walljumpbuffertimer = 0
		
	if is_on_floor():
		can_walljump = true
		walljumpbuffertimer = 0
	can_wallkick = true
		
	#SPRINGEN
	if not grappelnd and Input.is_action_just_pressed("Space"):
		sprungbuffertimer = 0.150
	
	if is_on_floor():
		koyotebuffertimer = 0.150
	if not is_on_floor():
		koyotebuffertimer -= delta
	koyotebuffertimer = clamp(koyotebuffertimer, 0, 0.150)
	
	sprungbuffertimer -= delta
	sprungbuffertimer = clamp(sprungbuffertimer, 0, 0.150)
	
	if is_on_floor() and sprungbuffertimer > 0:
		if sliding:
			sliding = false
			slide_timer = slide_duration_max
			velocity.y = slidejumpstaerke
			cur_speed += slidejumpboost * dir
		else:
			velocity.y = sprungstaerke
			koyotebuffertimer = 0
	elif not is_on_floor() and koyotebuffertimer > 0 and Input.is_action_just_pressed("Space"):
		velocity.y = sprungstaerke
		koyotebuffertimer = 0
	
#func grappling_hook(_delta):
	#if can_grapple and not grappelnd and not is_on_floor() and grapplecast:
		#if Input.is_action_just_pressed("MC"):
			#hitpoint = grapplecast.get_collision_point()
			##if hitpoint.y > position.y:
			#distance = (hitpoint - position).length()
			#direction = (hitpoint - position).normalized()
			#rope_direction = (position - hitpoint).normalized()
			#grappelnd = true
			#can_grapple = false
	#
	#if grappelnd:
		#
		#direction = (hitpoint - position).normalized()
		#rope_direction = (position - hitpoint).normalized()
		#
		#if Input.is_action_just_released("MC") or is_on_floor():
			#grappelnd = false
		#
		#elif Input.is_action_just_pressed("Space"):
			#grappelnd = false
			#velocity.y = sprungstaerke / 1.5
		#cur_speed = cur_speed.clamp(Vector3(-16, 0, -16), Vector3(16, 0, 16))
		#if cur_speed.dot(rope_direction) >= 0:
			#velocity = velocity.slide(rope_direction)
		#var power = ((hitpoint - position).length() - desired_distance) * 2
		#print(cur_speed)
		#if dir == Vector3.ZERO:
			#velocity += direction * power
		#else:
			#velocity += direction * power
		#
	#if not grappelnd and is_on_floor():
		#can_grapple = true

func pull(_delta):
	var pos = camera.global_position
	var look_dir = -camera.global_transform.basis.z
	if can_pull and pullRC.is_colliding() and Input.is_action_just_pressed("LC"):
		collider = pullRC.get_collider()
		if collider.is_in_group("Obstacle"):
			punkt = pullRC.get_collision_point()
			var _obj = pullRC.get_collider()
			orig_dist = (punkt - pos).length()
			orig_direction_to_point = (punkt - pos).normalized()
			orig_direction_to_player = (pos - punkt).normalized()
			#var wall_normal =  obj.get_normal()
			#var final_dist = 0.8 / orig_dist
			#if final_dist > orig_dist:
				#wanted_dist = final_dist
			#else:
				#wanted_dist = orig_dist
			#print(wanted_dist)
			can_pull = false
			pulling_self = true
			
		elif collider.is_in_group("Enemy"):
			#print("JETZT")
			can_pull = false
			pulling_enemy = true
			

	if pulling_self:
		var _dist = (punkt - pos).length()
		var _direction_to_point = (punkt - pos).normalized()
		var look_direction_to_point = look_dir.normalized()
		var _direction_to_player = (pos - punkt).normalized()
		var _cam_point_dir = ((punkt + wanted_dist * -look_direction_to_point) - position).normalized()
		
		var old_position = position
		
		position = position.lerp(punkt + wanted_dist * -look_direction_to_point, 0.3)
		position.y -= camera.position.y
		
		#cur_speed = (position - old_position) * 100
		velocity.y += (position.y - old_position.y) * 40
		cur_speed.x += (position.x - old_position.x) * 17
		cur_speed.z += (position.z - old_position.z) * 17
		velocity.y = clamp(velocity.y, -INF, 20)
		
		if Input.is_action_just_released("LC"):
			pulling_self = false
		
	#if is_on_floor():
	can_pull = true
	
	if pulling_enemy:
		orig_distance = holding_distance
		collider.cur_speed = Vector3.ZERO
		collider.velocity = Vector3.ZERO
		
		#var dist_to_collider = (collider.global_position - global_position).length()
		#if dist_to_collider < orig_distance:
			#pulling_enemy_weight = lerp(pulling_enemy_weight, 0.5, 0.3)
		#else:
			#pulling_enemy_weight = lerp(pulling_enemy_weight, 0.1, 0.1)
			
		var target_position = global_position + holding_distance * -camera.global_transform.basis.z
		var old_collider_pos = collider.global_position
		collider.global_position = lerp(collider.global_position, target_position + Vector3(0,1,0), 0.25)
		
		
		collider.cur_speed.x += (collider.global_position.x - old_collider_pos.x) * 50
		collider.cur_speed.z += (collider.global_position.z - old_collider_pos.z) * 50
		collider.velocity.y += (collider.global_position.y - old_collider_pos.y) * 50
		
		#print(dist_to_collider)
		
		if Input.is_action_just_released("LC"):
			pulling_enemy = false
			

func grav(delta):
	if not fliegend:
		if not pulling_self:
			if not is_on_floor() and not grappelnd:
				velocity.y -= gravity_player * delta
			elif grappelnd:
				velocity.y = -gravity_player * delta * 8
		#else:
			#velocity.y -= gravity_player * delta /2
		

func fps_anzeige():
	fps.text = str(Engine.get_frames_per_second())
	
#MOUSE INPUT
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		x_rot = -event.relative.y * mouse_sensi
		camera.rotation.x += x_rot
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
		y_rot = -event.relative.x * mouse_sensi
		rotation.y += y_rot
		
##DEBUGGING
func Debugging():
	if Input.is_action_just_pressed("T"):
		if fliegend:
			fliegend = false
		elif not fliegend:
			fliegend = true
	
	if Input.is_action_just_pressed("Q"):
		if flying_enemy:
			flying_enemy.queue_free()
		
	
