extends Area3D
var level_2 = preload("res://scenes/world2.tscn")
var level
var level_instantiated = false
@onready var player: Node3D = $"../player"

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		print("body")
		print(level_2)
		level = level_2.instantiate()
		print(level)
		get_tree().current_scene.add_child(level)
		level.global_position = Vector3(0, 30, 0)
		print("player pos:", player.global_position, "World2 pos", level.global_position)
		level_instantiated = true
		print("body now")
		
