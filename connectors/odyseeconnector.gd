extends "res://connectors/baseconnector.gd"

var display_name : String = "Odysee"
var tooltip : String = "Connect to odysee chat using websockets"
var icon : StreamTexture = preload("res://widgets/odyseechat.png")
var type : String = "odysee"

var scene : String = "res://connectors/odyseeconnector_ui.tscn"
