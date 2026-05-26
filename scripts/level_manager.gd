extends Node3D

var level_1 = preload("res://scenes/level1.tscn")

var parkour_levels = [level_1]

var preload_level_amount = 5

var chunk_counter = 30.0

func _ready():
	
	EventBus.chunk_triggered.connect(_on_chunk_triggered)
	for i in range(preload_level_amount):
		print("preload chunk i:", i)
		spawn_next_chunk()


func _on_chunk_triggered(trigger):
	print("chunk triggered")
	spawn_next_chunk()
	

func spawn_next_chunk():
	var level = level_1.instantiate()
	add_child(level)
	level.global_position = Vector3(0, chunk_counter, 0)
	chunk_counter += 30.0
