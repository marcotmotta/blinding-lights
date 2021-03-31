extends KinematicBody

onready var ball_scene = preload('res://Player/Ball/Ball.tscn')
onready var blood_scene = preload('res://Player/Blood.tscn')

const GRAVITY = -10
var vel = Vector3()
const MAX_SPEED = 7
const JUMP_SPEED = 5
const ACCEL = 2.5
const THROW_DELAY = 1
var can_throw = true

var max_health = 100.0
var health = 100.0

var bar_mesh = CubeMesh.new()
var bar_mat = SpatialMaterial.new()
var bar_color = Color(1, 0, 0)
var bar_size = Vector3(2, 0.15, 0.15)

var dir = Vector3()

const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

var camera
var rotation_helper
var first_person = true

var MOUSE_SENSITIVITY = 0.05

var leaderboard = ""

var score = 10

func _ready():
	randomize()

	bar_mesh.size = bar_size
	bar_mesh.material = bar_mat
	bar_mesh.material.albedo_color = bar_color
	$Healthbar.mesh = bar_mesh
	$GUI/Label.text = leaderboard
	
	$GUI.visible = false

	if is_network_master():
		rpc('setName', get_tree().get_network_unique_id(), network_globals.selected_name)

		$GUI.visible = true
		$Healthbar.visible = false

		var hat_color = network_globals.selected_color
		rpc("setHatColor", hat_color)
		$GUI/HealthBar.get("custom_styles/fg").set_bg_color(hat_color)

		camera = $Rotation_Helper/Camera
		rotation_helper = $Rotation_Helper

		camera.make_current()

		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta):
	$GUI/HealthBar.value = health
	$Healthbar.mesh.size.x = health/100*2

	network_globals.players.sort_custom(self, "sortByKills")
	leaderboard = ""
	for p in network_globals.players:
		leaderboard = leaderboard + str(p['name']) + ' - ' + str(p['kills']) + '\n'
	$GUI/Label.text = leaderboard
	if network_globals.players[0].kills >= score:
		print(network_globals.players[0]['name'])
		restartGame(network_globals.players[0])

	rpc_unreliable("faceBar")

func _physics_process(delta):
	if is_network_master():
		process_input(delta)
		process_movement(delta)

func process_input(_delta):
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()

	if Input.is_action_pressed("ui_up"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("ui_down"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("ui_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_movement_vector.x = 1

	input_movement_vector = input_movement_vector.normalized()

	dir += -cam_xform.basis.z.normalized() * input_movement_vector.y
	dir += cam_xform.basis.x.normalized() * input_movement_vector.x

	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("ui_select"):
			vel.y = JUMP_SPEED

	# Throw
	if Input.is_action_pressed("throw") and can_throw:
		var ball_direction = -camera.get_global_transform().basis.z
		var ball_position = translation + -camera.get_global_transform().basis.z.normalized() * 0.7
		rpc("throwBall", ball_direction, ball_position, get_tree().get_network_unique_id())
		can_throw = false
		yield(get_tree().create_timer(THROW_DELAY), "timeout")
		can_throw = true

	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()

	vel.y += delta*GRAVITY

	var hvel = vel
	hvel.y = 0

	var target = dir
	target *= MAX_SPEED

	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel*delta)
	vel.x = hvel.x
	vel.z = hvel.z

	vel = move_and_slide(vel,Vector3(0,1,0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))
	#var vel_result = move_and_collide(vel)

	rpc_unreliable("setPosition", translation, rotation_degrees)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and is_network_master():
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		$Hat.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		var hat_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		hat_rot.x = clamp(hat_rot.x, 0, 70)
		rotation_helper.rotation_degrees = camera_rot
		$Hat.rotation_degrees.z = hat_rot.x

	if Input.is_action_just_pressed("f5") and is_network_master():
		if first_person:
			camera.translation.y = 3
			camera.translation.z = 4
			camera.rotation_degrees.x = -35
			$GUI/Aim.visible = false
			first_person = false
		else:
			camera.translation.y = 0
			camera.translation.z = 0
			camera.rotation_degrees.x = 0
			$GUI/Aim.visible = true
			first_person = true

func take_damage(dmg, from):
	if is_network_master():
		health -= dmg
		$HitSound.play()
		rpc('playSound')
		rpc('playBlood')
		if health <= 0:
			health = max_health
			rpc('setHealth', health)
			translation = get_parent().get_node('Spawn' + str(randi() % 6)).translation
			rpc("setPosition", translation, rotation_degrees)
			if get_tree().get_network_unique_id() != from:
				rpc('kill', from)
			else:
				rpc('suicide', from)
		else:
			rpc('setHealth', health)

func sortByKills(a, b):
	if a["kills"] > b["kills"]:
		return true
	return false

func restartGame(winner):
	$GUI/Winner.text = winner['name'] + ' won the game!'
	$GUI/Winner.visible = true
	$GUI/Winner/Timer.start(5)

	for p in network_globals.players:
		p['kills'] = 0

	health = max_health
	rpc('setHealth', health)
	translation = get_parent().get_node('Spawn' + str(randi() % 6)).translation
	rpc("setPosition", translation, rotation_degrees)

func _on_Timer_timeout():
	$GUI/Winner.visible = false

# Net functions

remote func setPosition(pos, rot):
	translation = pos
	rotation_degrees = rot

remote func setHealth(value):
	health = value

remotesync func throwBall(ball_direction, ball_position, owner_id):
	var ball = ball_scene.instance()
	ball.direction = ball_direction
	ball.position = ball_position
	ball.owner_id = owner_id
	get_parent().add_child(ball)

remote func faceBar():
	$Healthbar.look_at(get_viewport().get_camera().global_transform.origin + Vector3(0.0, 0.0, 0.01), Vector3(0,1,0))

remotesync func setHatColor(hat_color):
	var material = SpatialMaterial.new()
	material.albedo_color = hat_color
	$Hat.set_surface_material(0, material)

remote func playSound():
	$HitSound.play()

remotesync func playBlood():
	var blood = blood_scene.instance()
	add_child(blood)

remotesync func kill(id):
	for p in network_globals.players:
		if p['id'] == id:
			p['kills'] += 1
			break

remotesync func suicide(id):
	for p in network_globals.players:
		if p['id'] == id:
			p['kills'] -= 1
			break

remote func setName(id, name):
	for p in network_globals.players:
		if p['id'] == id:
			p['name'] = name
			break
