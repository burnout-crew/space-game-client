extends Spatial

export var websocket_url = "ws://10.0.0.225:29979"

var _client = WebSocketClient.new()

func _ready():
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)

func _closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)

func _connected(proto = ""):
	print("Connected with protocol: ", proto)
	_client.get_peer(1).put_packet("Test packet".to_utf8())

var id = null
onready var Constructs = get_node("Constructs")
onready var Ship = preload("res://Ship.tscn")

func _on_data():
	var d = parse_json(_client.get_peer(1).get_packet().get_string_from_utf8())
	if d.has("Init"):
		id = d.Init
	if d.has("Change"):
		if d.Change.has("Unload"):
			var uid = d.Change.Unload
			for child in Constructs.get_children():
				if child.id == uid:
					Constructs.remove_child(child)
		if d.Change.has("Load"):
			var c = d.Change.Load
			var ship = Ship.instance()
			Constructs.add_child(ship)
			ship.id = c.id
			ship.epoch = c.phys.epoch
			ship.s = Vector3(c.phys.s.x, c.phys.s.y, c.phys.s.z)
			ship.p = Vector3(c.phys.p.x, c.phys.p.y, c.phys.p.z)
			ship.m = c.phys.m
			ship.get_node("Camera").visible = c.id == id

func _process(delta):
	_client.poll()
