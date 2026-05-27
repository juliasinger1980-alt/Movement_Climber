extends Node3D

var level_1 = preload("res://scenes/level_1.tscn")
var level_2 = preload("res://scenes/level_2.tscn")

var level

var parkour_levels = [level_1, level_2]

var chunkplan = []

var preload_level_amount = 5

var chunk_counter = 30.0

var j = 0

func _ready():
	
	EventBus.chunk_triggered.connect(_on_chunk_triggered)
	
	for i in range(100):
		chunkplan.append(parkour_levels.pick_random())
	
	for i in range(preload_level_amount):
		print("preload chunk i:", i)
		spawn_next_chunk()


func _on_chunk_triggered(trigger):
	#print("chunk triggered")
	spawn_next_chunk()
	

func spawn_next_chunk():
	if j == 99:
		print("letztes level")
		return
	
	level = chunkplan[j].instantiate()
	add_child(level)
	print(chunkplan[j], "gespawned")
	level.global_position = Vector3(0, chunk_counter, 0)
	chunk_counter += 30.0
	j += 1
