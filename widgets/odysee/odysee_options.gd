extends MarginContainer

var config = null
var receiver : Node = null

func add_config_options(widget_id : String, config : Dictionary) -> void:
	self.config = config
	
	var connection_value = null
	if config.has("connection"): connection_value = config["connection"]

	var text_color_value = "#FFFFFF"
	if config.has("text_color"): text_color_value = config["text_color"]
	
	var username_color_value = "#FFFFFF"
	if config.has("username_color"): username_color_value = config["username_color"]

	var timestamp_color_value = "#FFFFFF"
	if config.has("timestamp_color"): timestamp_color_value = config["timestamp_color"]

	var compact_mode_value = false
	if config.has("compact_mode"): compact_mode_value = config["compact_mode"]

	var show_timestamps_value = false
	if config.has("show_timestamps"): show_timestamps_value = config["show_timestamps"]

	var font_select_value = DefaultSettings.get_default_setting("widgets/font")
	if config.has("font"): font_select_value = config["font"]
	
	var tip_color_value = "#FFFFFF"
	if config.has("tip_color"): tip_color_value = config["tip_color"]
	
	var connections = PasswordStorage.get_secret("connections")
	if !connections: connections = []
	var items = []
	
	for i in connections:
		if i["type"] == "odysee":
			items.append({"name": "Odysee: " + i["name"], "value": i["uuid"]})
		
	var connection = preload("res://ui/elements/options/dropdownoption.tscn").instance()
	$VBoxContainer.add_child(connection)
	connection.set_label("Connection:")
	connection.set_values(items)
	connection.set_option_name("connection")
	if connection_value: connection.set_value(connection_value)
	connection.set_widget_node(self)
	
	var text_color = preload("res://ui/elements/options/coloroption.tscn").instance()
	$VBoxContainer.add_child(text_color)
	text_color.set_label("Text color:")
	text_color.set_option_name("text_color")
	text_color.set_value(text_color_value)
	text_color.set_widget_node(self)
	
	var tip_color = preload("res://ui/elements/options/coloroption.tscn").instance()
	$VBoxContainer.add_child(tip_color)
	tip_color.set_label("Tip color:")
	tip_color.set_option_name("tip_color")
	tip_color.set_value(tip_color_value)
	tip_color.set_widget_node(self)
	
	var username_color = preload("res://ui/elements/options/coloroption.tscn").instance()
	$VBoxContainer.add_child(username_color)
	username_color.set_label("Username color:")
	username_color.set_option_name("username_color")
	username_color.set_value(username_color_value)
	username_color.set_widget_node(self)
	
	var timestamp_color = preload("res://ui/elements/options/coloroption.tscn").instance()
	$VBoxContainer.add_child(timestamp_color)
	timestamp_color.set_label("Timestamp color:")
	timestamp_color.set_option_name("timestamp_color")
	timestamp_color.set_value(timestamp_color_value)
	timestamp_color.set_widget_node(self)
	
	var compact_mode = preload("res://ui/elements/options/toggleoption.tscn").instance()
	$VBoxContainer.add_child(compact_mode)
	compact_mode.set_label("Compact view:")
	compact_mode.set_option_name("compact_mode")
	compact_mode.set_value(compact_mode_value)
	compact_mode.set_widget_node(self)
	
	var show_timestamps = preload("res://ui/elements/options/toggleoption.tscn").instance()
	$VBoxContainer.add_child(show_timestamps)
	show_timestamps.set_label("Show timestamps:")
	show_timestamps.set_option_name("show_timestamps")
	show_timestamps.set_value(show_timestamps_value)
	show_timestamps.set_widget_node(self)

	var font_select = preload("res://ui/elements/options/fontoption.tscn").instance()
	$VBoxContainer.add_child(font_select)
	font_select.set_label("Font:")
	font_select.set_option_name("font")
	font_select.set_value(font_select_value)
	font_select.set_widget_node(self)

func set_receiver_node(receiver : Node) -> void:
	self.receiver = receiver

func set_config_value(key : String, value) -> void:
	config[key] = value
	
	if receiver:
		receiver.save_options_for_widget()
