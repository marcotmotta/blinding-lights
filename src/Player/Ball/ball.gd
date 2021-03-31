extends RigidBody

var owner_id

var direction = Vector3()
var position = Vector3()
var force = 11

var damage = 15

var max_quicks = 2
var quicks = 0

var timer = 5

func _ready():
	translation = position
	apply_central_impulse(direction * force)
	$Pop.play()
	$Timer.start(timer)

func _on_Ball_body_entered(body):
	#$Timer.start(timer)
	if body.is_in_group('player'):
		body.take_damage(damage, owner_id)

func _on_Timer_timeout():
	queue_free()
