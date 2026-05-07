extends CharacterBody3D

@onready var camera: Camera3D = $head/Camera3D
@onready var head: Node3D = $head
@onready var fps: Label3D = $head/Camera3D/FPS_Count
@onready var walljumpRC: RayCast3D = $head/Camera3D/Walljumpcast
@onready var wallkickRC: RayCast3D = $head/Camera3D/Wallkickcast
@onready var grapplecast: RayCast3D = $head/Camera3D/Grapplecast
@onready var grappleline:= MeshInstance3D.new()

var gravity_player = 40

var cur_speed = Vector3.ZERO
var target_speed_gehen = 8.0
var target_speed_sprint = 13.0
var target_speed_grappling = 25.0
var max_speed = 0.0
var sprinting = false
var dir = Vector3.ZERO

var sprungstaerke = 15.0
var air_control_mult = 0.2
var sprungbuffertimer = 0
var koyotebuffertimer = 0

var x_rot = 0.0
var y_rot = 0.0
var mouse_sensi = 0.0015
var fov_normal = 91.0
var fov_sprinting = 100.0

var can_walljump = true
var can_wallkick = true
var wallkickstr = 20
var wallkickjumpstr = 12
var walljumpstr = 18
var walljumpbuffertimer = 0.0
var wallkickbuffertimer = 0.0

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

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_child(grappleline)
	grappleline.mesh = im_mesh
	
func _physics_process(delta: float) -> void:
	movement(delta)
	
	grav(delta)
	
	if is_on_wall():
		var normal = get_wall_normal()
		cur_speed = cur_speed.slide(normal)
	
	grappling_hook(delta)
	
	move_and_slide()
	
	fps_anzeige()
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
	if grappelnd:
		cur_speed = lerp(cur_speed, max_speed * dir, 3 * delta)
	#LUFTMOVEMENT
	elif not is_on_floor():
		cur_speed = lerp(cur_speed, max_speed * dir, 12 * delta * air_control_mult)
	#BODENMOVEMENT
	else:
		cur_speed = lerp(cur_speed, max_speed * dir, 12 * delta)

	velocity.x = cur_speed.x
	velocity.z = cur_speed.z
	
	##WALLKICK/JUMP UND NORMALER JUMP
	#wall kick
	var WJcollider = walljumpRC.get_collider()
	var WKcollider = wallkickRC.get_collider()
	
	if not is_on_floor() and can_walljump:
		if Input.is_action_just_pressed("Space"):
			walljumpbuffertimer = 0.150
	if not is_on_floor() and can_wallkick:
		if Input.is_action_just_pressed("LC"):
			wallkickbuffertimer = 0.150
	
	walljumpbuffertimer -= delta
	walljumpbuffertimer = clamp(walljumpbuffertimer, 0, 0.150)
	
	wallkickbuffertimer -= delta
	wallkickbuffertimer = clamp(wallkickbuffertimer, 0, 0.150)
	print(cur_speed)
	if wallkickbuffertimer > 0:
		if WKcollider and WKcollider.collision_layer == 1:
			print("sex")
			var opp_dir = Vector3(transform.basis.z.x, camera.transform.basis.z.y, transform.basis.z.z)
			cur_speed = opp_dir * wallkickstr
			velocity.y = opp_dir.y * wallkickstr
			can_wallkick = false
			wallkickbuffertimer = 0
	
	if walljumpbuffertimer > 0:
		if WJcollider and WJcollider.collision_layer == 1:
			velocity.y = walljumpstr
			can_walljump = false
			walljumpbuffertimer = 0
		
	if is_on_floor():
		can_walljump = true
		can_wallkick = true
		walljumpbuffertimer = 0
		
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
		velocity.y = sprungstaerke
		koyotebuffertimer = 0
	elif not is_on_floor() and koyotebuffertimer > 0 and Input.is_action_just_pressed("Space"):
		velocity.y = sprungstaerke
		koyotebuffertimer = 0
	
func grappling_hook(_delta):
	if can_grapple and not grappelnd and not is_on_floor() and grapplecast:
		if Input.is_action_just_pressed("RC"):
			hitpoint = grapplecast.get_collision_point()
			#if hitpoint.y > position.y:
			distance = (hitpoint - position).length()
			direction = (hitpoint - position).normalized()
			rope_direction = (position - hitpoint).normalized()
			grappelnd = true
			can_grapple = false
	
	if grappelnd:
		
		direction = (hitpoint - position).normalized()
		rope_direction = (position - hitpoint).normalized()
		
		if Input.is_action_just_released("RC") or is_on_floor():
			grappelnd = false
		
		elif Input.is_action_just_pressed("Space"):
			grappelnd = false
			velocity.y = sprungstaerke / 1.5
		cur_speed = cur_speed.clamp(Vector3(-16, 0, -16), Vector3(16, 0, 16))
		velocity = velocity.slide(rope_direction)
		var power = ((hitpoint - position).length() - desired_distance) * 2
		print(cur_speed)
		velocity += direction * power
		
	if not grappelnd and is_on_floor():
		can_grapple = true
	
func grav(delta):
	if not is_on_floor() and not grappelnd:
		velocity.y -= gravity_player * delta
	elif grappelnd:
		velocity.y = -gravity_player * delta * 8

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
