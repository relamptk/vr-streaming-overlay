extends RichTextLabel

# Current chat lines displayed in the chat window
var chat_lines = PoolStringArray()

# Connection-checking timestamps
var last_ping = 0
var last_pong = 0
var last_check = 0

# Configuration data
var username = null
var chat_token = null
var compact_mode = false

var claim_id = "edf63b41a82a93bad1d53b159af2e7e1fe119a5e"
var text_color = Color(255, 255, 255)
var tip_color = Color(255, 255, 255)
var timestamp_color = Color(255, 255, 255)
var username_color = Color(255, 255, 255)
var show_timestamps = false
var stream_claim = ""

# Apply config given by widget manager
func apply_config(widget_id, config):
	var connections = PasswordStorage.get_secret("connections")
	if !connections: connections = []
	
	if config.has("ratio"): size_flags_stretch_ratio = config["ratio"]
	if config.has("text_color"): text_color = config["text_color"]
	if config.has("tip_color"): tip_color = config["tip_color"]
	if config.has("username_color"): username_color = config["username_color"]
	if config.has("timestamp_color"): timestamp_color = config["timestamp_color"]
	if config.has("compact_mode"): compact_mode = config["compact_mode"]
	if config.has("show_timestamps"): show_timestamps = config["show_timestamps"]
	
	if config.has("font"):
		var dynamic_font = DynamicFont.new()
		dynamic_font.font_data = load(config["font"].file)
		dynamic_font.size = config["font"].size
		dynamic_font.add_fallback(load("res://ui/font/TwitterColorEmoji-SVGinOT.ttf"))
		set("custom_fonts/normal_font", dynamic_font)
 
		if config.has("connection"):
			for i in connections:
				if config["connection"] == i["uuid"]:
					claim_id = i["claimid"]
					

# Called when the node enters the scene tree for the first time.

# Get stream claim id from channel claim id		
	
func _on_sql_request_completed(result, response_code, headers, body):
	print("requesting claim id")
	streamClaim.disconnect("request_completed", self, "_on_sql_request_completed")
	_client.disconnect("connection_closed", self, "_closed")
	var query = JSON.parse(body.get_string_from_utf8())

	if query.result["data"].size() == 0:
		print("Cannot find stream on channel, assuming claim id is for stream ")
		stream_claim = claim_id
	else:
		print("Found stream claim_id " + query.result["data"][0]["claim_id"])
		stream_claim = query.result["data"][0]["claim_id"]
	
	# Prepare our chat lines array
	for i in range(0, 200):
		chat_lines.append("\n")
	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	# This signal is emitted when not using the Multiplayer API every time
	# a full packet is received.
	# Alternatively, you could check get_peer(1).get_available_packets() in a loop.
	_client.connect("data_received", self, "_on_data")
	
	# Initiate connection to the given URL.
	var err = _client.connect_to_url("wss://comments.lbry.com/api/v2/live-chat/subscribe?subscription_id=" + stream_claim)
	if err != OK:
		append_message("Unable to connect to odysee", "#B22222", "info", 0)
		print("Unable to connect")
		set_process(false)
	else:
		print("Connected to Odysee using " + stream_claim)

	
# Connect to Odysee via websockets
func connect_to_odysee():
	return

# Redraws chat text in the richtextlabel
func redraw_chat():
	chat_lines.invert()
	chat_lines.resize(200)
	chat_lines.invert()
	
	clear()
	append_bbcode(chat_lines.join(""))

# Appends a message to the rich text label for display
func append_message(message, color, sender, tip_amount):
	if typeof(color) == TYPE_COLOR:
		color = '#' + color.to_html(true)
	var timestamp = "[color=#" + timestamp_color.to_html(true) + "]" + str(OS.get_time()["hour"]).pad_zeros(2) + ":" + str(OS.get_time()["minute"]).pad_zeros(2) + "[/color] " if show_timestamps else ""

	if tip_amount > 0:
		message = "[color=#" + tip_color.to_html(true) + "] Tipped " + str(tip_amount) + " [/color]" + "[color=#" + username_color.to_html(true) + "]" + sender + "[/color]" + ' | ' + "[color=" + color + "]" + message + "[/color]"
	elif sender: 
		message = "[color=#" + username_color.to_html(true) + "]" + sender + "[/color]" + ' | ' + "[color=" + color + "]" + message + "[/color]"
	message = timestamp + message

	chat_lines.append(message)
	redraw_chat()


# Our WebSocketClient instance
var _client = WebSocketClient.new()
onready var streamClaim = HTTPRequest.new()

func _ready():
	print("Odysee chat widget loading!")
	add_child(streamClaim)
	streamClaim.connect("request_completed", self, "_on_sql_request_completed", [], CONNECT_DEFERRED)
	print("Using connector: " + claim_id)
	var error = streamClaim.request("https://chainquery.lbry.com/api/sql?query=SELECT%20*%20FROM%20claim%20WHERE%20publisher_id=%22" + claim_id + "%22%20AND%20bid_state%3C%3E%22Spent%22%20AND%20claim_type=1%20AND%20source_hash%20IS%20NULL%20ORDER%20BY%20id%20DESC%20LIMIT%201")

func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	append_message("Disconnected from odysee,", "#B22222", "info", 0)
	print("Closed, clean: ", was_clean)
	set_process(false)
	_client.poll()

func _connected(proto = ""):
	# This is called on connection, "proto" will be the selected WebSocket
	# sub-protocol (which is optional)
	append_message("Connected to Odysee", "#B22222", "info", 0)
	print("Connected with protocol: ", proto)
	# You MUST always use get_peer(1).put_packet to send data to server,
	# and not put_packet directly when not using the MultiplayerAPI.
	_client.get_peer(1).put_packet("Hello LBRY!".to_utf8())

func _on_data():
	# Print the received packet, you MUST always use get_peer(1).get_packet
	# to receive data from server, and not get_packet directly when not
	# using the MultiplayerAPI.
	var comment = JSON.parse(_client.get_peer(1).get_packet().get_string_from_utf8())
	print(comment.result["data"]["comment"]["channel_name"] + ": " + comment.result["data"]["comment"]["comment"] + " Tipped: " + str(comment.result["data"]["comment"]["support_amount"]))
	append_message(comment.result["data"]["comment"]["comment"] + "\n", text_color, comment.result["data"]["comment"]["channel_name"], comment.result["data"]["comment"]["support_amount"])

func _process(delta):
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	_client.poll()
