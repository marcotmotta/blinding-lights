extends Particles

func _ready():
	emitting = true
	yield(get_tree().create_timer(2), "timeout")
	queue_free()
