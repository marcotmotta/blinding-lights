extends Spatial

onready var player_scene = preload("res://Player/Player.tscn")

sync func _ready():
	print (network_globals.ids)
	randomize()

	var me = player_scene.instance()
	me.set_name(str(get_tree().get_network_unique_id()))
	me.set_network_master(get_tree().get_network_unique_id())
	var pos = 'Spawn' + str(randi() % 6)
	print(pos)
	me.translation = get_node(pos).translation
	network_globals.players.append({'id': get_tree().get_network_unique_id(), 'kills': 0, 'name': network_globals.selected_name})
	add_child(me)

	for p in network_globals.ids:
		var player = player_scene.instance()
		player.set_name(str(p))
		player.set_network_master(p)
		pos = 'Spawn' + str(randi() % 6)
		player.translation = get_node(pos).translation
		network_globals.players.append({'id': p, 'kills': 0})
		add_child(player)
