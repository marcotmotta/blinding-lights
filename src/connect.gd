extends Control

onready var main = preload("res://Main.tscn")

var colors = [
	Color(0, 0, 1),
	Color(0, 1, 0),
	Color(1, 0, 0),
	Color(1, 1, 0),
	Color(1, 0, 1),
	Color(1, 1, 1)
]

var i_color = 0

func _ready():
	$ColorRect/ColorRect.color = colors[i_color]
	get_tree().connect("network_peer_connected", self, "_player_connected")

func _player_connected(id):
	print(id)
	network_globals.ids.append(id)
	print(network_globals.ids)

func _on_HostButton_pressed():
	print('host')
	var host = NetworkedMultiplayerENet.new()
	var ret = host.create_server(int($ColorRect/Port.text), 10)
	#var ret = host.create_server(5251, 10)

	print(IP.get_local_addresses ( ))
	$ColorRect/Label.text = str(IP.get_local_addresses ())

	network_globals.selected_color = $ColorRect/ColorRect.color
	network_globals.selected_name = $ColorRect/Name.text

	$ColorRect/AddressLabel.text = str(ret)

	$ColorRect/HostButton.disabled = true
	$ColorRect/LoginButton.disabled = true
	$ColorRect/StartButton.disabled = false
	$ColorRect/Ip.visible = false
	$ColorRect/Port.visible = false
	$ColorRect/Name.visible = false
	
	$ColorRect/ColorLeft.disabled = true
	$ColorRect/ColorRight.disabled = true

	get_tree().set_network_peer(host)

	#get_tree().get_root().add_child(main.instance())
	#hide()

func _on_LoginButton_pressed():
	print('join')
	var host = NetworkedMultiplayerENet.new()
	var ret = host.create_client($ColorRect/Ip.text, int($ColorRect/Port.text))
	#var ret = host.create_client("127.0.0.1", 5251)

	network_globals.selected_color = $ColorRect/ColorRect.color
	network_globals.selected_name = $ColorRect/Name.text

	$ColorRect/AddressLabel.text = str(ret)

	$ColorRect/HostButton.disabled = true
	$ColorRect/LoginButton.disabled = true
	$ColorRect/Ip.visible = false
	$ColorRect/Port.visible = false
	$ColorRect/Name.visible = false
	
	$ColorRect/ColorLeft.disabled = true
	$ColorRect/ColorRight.disabled = true

	get_tree().set_network_peer(host)

	#get_tree().get_root().add_child(main.instance())
	#hide()

func _on_StartButton_pressed():
	rpc('start_game')

remotesync func start_game():
	get_tree().get_root().add_child(main.instance())
	hide()

func _on_ColorRight_pressed():
	i_color += 1
	if i_color >= colors.size():
		i_color = 0
	$ColorRect/ColorRect.color = colors[i_color]

func _on_ColorLeft_pressed():
	i_color -= 1
	if i_color < 0:
		i_color = colors.size() - 1
	$ColorRect/ColorRect.color = colors[i_color]
