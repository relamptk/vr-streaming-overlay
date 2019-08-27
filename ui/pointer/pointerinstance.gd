extends Control

var OpenVROverlay
var overlay_id : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.connect("render_targetsize", self, "_on_render_targetsize_changed")
	SignalManager.connect("settings_changed", self, "_on_settings_changed")
	
	# Listen for trackers becoming available / going away
	ARVRServer.connect("tracker_added", self, "_on_trackers_changed")
	ARVRServer.connect("tracker_removed", self, "_on_trackers_changed")
	
	# Wait for everything to be ready!?
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	# Create and display our overlay
	OpenVROverlay = preload("res://addons/godot-openvr/OpenVROverlay.gdns").new()

	var texid_overlay = VisualServer.texture_get_texid(VisualServer.viewport_get_texture($VRViewport.get_viewport_rid()))
	
	overlay_id = OpenVROverlay.create_overlay("beniwtv.vr-streaming.overlay-pointer-" + str(get_index()), "VR Streaming Overlay - Pointer #" + str(get_index()), texid_overlay) # Unique key and friendly name
	OpenVROverlay.set_overlay_width_in_meters(0.005, overlay_id)

	OpenVROverlay.show_overlay(overlay_id)
	
	attempt_tracking()

func _on_render_targetsize_changed(size : Vector2) -> void:
	$VRViewport.size = size
	$"3DVRViewport".size = size

func _on_settings_changed() -> void:
	attempt_tracking()
	
func _on_trackers_changed(tracker_name : String, tracker_type : int, tracker_id) -> void:
	attempt_tracking()

func attempt_tracking() -> void:
	if OpenVROverlay:
		var position_x : float
		var position_y : float
		var position_z : float
		
		var rotation_x : float
		var rotation_y : float
		var rotation_z : float
		
		var transform : Transform
		
		position_x = 0.06
		position_y = -0.61
		position_z = -0.63
		rotation_x = 2.3
		rotation_y = 6.1
		rotation_z = 3.2
	
		#position_x = SettingsManager.get_value("user", "overlay/position_x", DefaultSettings.get_default_setting("overlay/position_x"))
		#position_y = SettingsManager.get_value("user", "overlay/position_y", DefaultSettings.get_default_setting("overlay/position_y"))
		#position_z = SettingsManager.get_value("user", "overlay/position_z", DefaultSettings.get_default_setting("overlay/position_z"))
		#rotation_x = SettingsManager.get_value("user", "overlay/rotation_x", DefaultSettings.get_default_setting("overlay/rotation_x"))
		#rotation_y = SettingsManager.get_value("user", "overlay/rotation_y", DefaultSettings.get_default_setting("overlay/rotation_y"))
		#rotation_z = SettingsManager.get_value("user", "overlay/rotation_z", DefaultSettings.get_default_setting("overlay/rotation_z"))
		
		transform = Transform(Basis(Vector3(0, 0, 0)), Vector3(position_x, position_y, position_z))
		transform.basis = transform.basis.rotated(Vector3(1, 0, 0), rotation_x)
		transform.basis = transform.basis.rotated(Vector3(0, 1, 0), rotation_y)
		transform.basis = transform.basis.rotated(Vector3(0, 0, 1), rotation_z)
	
		transform = transform.orthonormalized()
		transform.basis = transform.basis.scaled(Vector3(1, 300, 1))

		var leftTrackingIdFound = null
		var rightTrackingIdFound = null
		
		for i in range(0, ARVRServer.get_tracker_count()):
			var tracker = ARVRServer.get_tracker(i)
			
			match tracker.get_hand():
				ARVRPositionalTracker.TRACKER_LEFT_HAND:
					var name_parts = tracker.get_name().split("_")
					leftTrackingIdFound = name_parts[name_parts.size() - 1]
				ARVRPositionalTracker.TRACKER_RIGHT_HAND:
					var name_parts = tracker.get_name().split("_")
					rightTrackingIdFound = name_parts[name_parts.size() - 1]

		if rightTrackingIdFound != null:
			OpenVROverlay.track_relative_to_device(rightTrackingIdFound, transform, overlay_id)
		elif leftTrackingIdFound != null:
			OpenVROverlay.track_relative_to_device(leftTrackingIdFound, transform, overlay_id)
		else:
			print("No trackers (hands) available at the moment - no pointer!")
