extends Spatial

var colors = [
	Color(1, 0.75, 0),
	Color(0.1, 1, 0),
	Color(0, 0.8, 1),
	Color(0.45, 0, 1)
]

var color

var timer = 10

func _ready():
	randomize()

	color = colors[randi() % colors.size()]
	$OmniLight.light_color = color
	#$Particles.draw_pass_1.material.albedo_color = color
	$Timer.start(timer)

func _on_Timer_timeout():
	color = colors[randi() % colors.size()]
	$OmniLight.light_color = color
	#$Particles.draw_pass_1.material.albedo_color = color
	$Timer.start(timer)
