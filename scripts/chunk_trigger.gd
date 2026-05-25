extends Area3D

var triggered = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if triggered:
		return
	if body.is_in_group("Player"):
		triggered = true
		EventBus.chunk_triggered.emit(self)
