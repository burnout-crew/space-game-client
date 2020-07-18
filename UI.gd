extends Control

export var websocket_url = "ws://10.0.0.225:29979"
export var client_id = ""

var _client = WebSocketClient.new()

onready var _World = $ViewportContainer/Viewport/World

func _ready():
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)

func _process(_delta):
	_client.poll()
	if id:
		var ship = _World.get_ship(id)
		$Panel/Label.text = to_json(ship.translation)
		$Panel/Label2.text = to_json(ship.a)
		$Panel/Label3.text = to_json(ship.v)

func dict_to_vec(dict):
	return Vector3(dict.x, dict.y, dict.z)

func vec_to_dict(vec):
	return { "x": vec.x, "y": vec.y, "z": vec.z }


const THRUST = 10.0

var thrust = Vector3(0, 0, 0)
var torque = Vector3(0, 0, 0)

func _input(event):
	if event is InputEventKey:
		thrust = Vector3(0, 0, 0)
		if Input.is_action_pressed("ui_up"):
			thrust.z -= THRUST
		if Input.is_action_pressed("ui_down"):
			thrust.z += THRUST
		if Input.is_action_pressed("ui_left"):
			thrust.x -= THRUST
		if Input.is_action_pressed("ui_right"):
			thrust.x += THRUST
	
		torque = Vector3(0, 0, 0)
		if Input.is_action_pressed("rotate_roll_left"):
			torque.z += THRUST
		if Input.is_action_pressed("rotate_roll_right"):
			torque.z -= THRUST
	
		$ViewportContainer/Viewport/World/Ship.thrust = thrust
		$ViewportContainer/Viewport/World/Ship.torque = torque
	
		var data = {
			"Controls": {
				"thrust": vec_to_dict(thrust),
				"torque": vec_to_dict(torque)
			}
		}
		
		#_client.get_peer(1).put_packet(to_json(data).to_utf8())


func _closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)

func _connected(proto = ""):
	print("Connected with protocol: ", proto)
	_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)



var id = null

func _on_data():
	var data = _client.get_peer(1).get_packet()
	var dict = parse_json(data.get_string_from_utf8())
	if dict.has("Init"):
		id = dict.Init
		
	if dict.has("Change"):
		if dict.Change.has("Load"):
			var details = dict.Change.Load
			var is_me = details.id == id

			var ship = _World.get_ship(details.id)
			ship.m = details.phys.m
			ship.epoch = details.phys.epoch
			ship.r = dict_to_vec(details.phys.r)
			ship.v = dict_to_vec(details.phys.v)
			ship.a = dict_to_vec(details.phys.a)
			ship.get_node("Camera").current = is_me
			
		if dict.Change.has("Unload"):
			_World.remove_ship(dict.Change.Unload)
