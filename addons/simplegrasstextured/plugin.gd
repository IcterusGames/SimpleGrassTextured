# plugin.gd
# This file is part of: SimpleGrassTextured
# Copyright (c) 2023 IcterusGames
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the 
# "Software"), to deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, merge, publish, 
# distribute, sublicense, and/or sell copies of the Software, and to 
# permit persons to whom the Software is furnished to do so, subject to 
# the following conditions: 
#
# The above copyright notice and this permission notice shall be 
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@tool
extends EditorPlugin

const DEPTH_BRUSH := 10.0

enum EVENT_MOUSE {
	EVENT_NONE,
	EVENT_MOVE,
	EVENT_CLICK,
}

var _raycast_3d : RayCast3D = null
var _decal_pointer : Decal = null
var _grass_selected = null
var _position_draw := Vector3.ZERO
var _normal_draw := Vector3.ZERO
var _object_draw : Object = null
var _edit_density := 25
var _edit_radius := 2.0
var _edit_scale := Vector3.ONE
var _edit_rotation := 0.0
var _edit_rotation_rand := 1.0
var _edit_draw := true : set = _on_set_draw
var _edit_fill := false : set = _on_set_fill
var _edit_erase := false : set = _on_set_erase
var _gui_toolbar = null
var _gui_toolbar_up = null
var _time_draw := 0
var _draw_paused := true
var _mouse_event := EVENT_MOUSE.EVENT_NONE
var _project_ray_origin := Vector3.INF
var _project_ray_normal := Vector3.INF
var _inspector_plugin : EditorInspectorPlugin = null
var _prev_config := ""
var _custom_settings := [{
		"name": "SimpleGrassTextured/General/default_terrain_physics_layer",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_LAYERS_3D_PHYSICS,
		"hint_string": "",
		"default": pow(2, 32) - 1,
		"basic": true
	},{
		"name": "SimpleGrassTextured/General/interactive_resolution",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Low:256,High:512",
		"default": 512,
		"basic": false
	},{
		"name": "SimpleGrassTextured/General/interactive_resolution.android",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Low:256,High:512",
		"default": 256,
		"basic": false
	},{
		"name": "SimpleGrassTextured/General/interactive_resolution.ios",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Low:256,High:512",
		"default": 256,
		"basic": false
	},{
		"name": "SimpleGrassTextured/Shortcuts/draw",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Shortcut",
		"default": _create_shortcut(KEY_D),
		"basic": true
	},{
		"name": "SimpleGrassTextured/Shortcuts/fill",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Shortcut",
		"default": _create_shortcut(KEY_B),
		"basic": true
	},{
		"name": "SimpleGrassTextured/Shortcuts/erase",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Shortcut",
		"default": _create_shortcut(KEY_X),
		"basic": true
	},{
		"name": "SimpleGrassTextured/Shortcuts/radius_increment",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Shortcut",
		"default": _create_shortcut(KEY_BRACKETRIGHT),
		"basic": true
	},{
		"name": "SimpleGrassTextured/Shortcuts/radius_decrement",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Shortcut",
		"default": _create_shortcut(KEY_BRACKETLEFT),
		"basic": true
	},{
		"name": "SimpleGrassTextured/Shortcuts/density_increment",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Shortcut",
		"default": _create_shortcut(KEY_EQUAL),
		"basic": true
	},{
		"name": "SimpleGrassTextured/Shortcuts/density_decrement",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Shortcut",
		"default": _create_shortcut(KEY_MINUS),
		"basic": true
	}
]


func _enter_tree():
	if not get_tree().has_user_signal(&"sgt_globals_params_changed"):
		get_tree().add_user_signal(&"sgt_globals_params_changed")
	_verify_global_shader_parameters()
	_enable_shaders(true)
	_init_default_project_settings()
	_prev_config = _custom_config_memorize()
	if ProjectSettings.has_signal(&"settings_changed"):
		ProjectSettings.connect(&"settings_changed", _on_project_settings_changed)
	# Must ensure the resource file of default_mesh.tres match the current Godot version
	var default_mesh = load("res://addons/simplegrasstextured/default_mesh.tres")
	if not default_mesh.has_meta(&"GodotVersion") or default_mesh.get_meta(&"GodotVersion") != Engine.get_version_info()["string"]:
		print("SimpleGrassTextured, updating file res://addons/simplegrasstextured/default_mesh.tres")
		default_mesh = null
		var mesh_builder = load("res://addons/simplegrasstextured/default_mesh_builder.gd").new()
		mesh_builder.rebuild_and_save_default_mesh()
		default_mesh = load("res://addons/simplegrasstextured/default_mesh.tres")
		default_mesh.emit_changed()
	add_custom_type(
		"SimpleGrassTextured",
		"MultiMeshInstance3D",
		load("res://addons/simplegrasstextured/grass.gd"),
		load("res://addons/simplegrasstextured/sgt_icon.svg")
	)
	
	_gui_toolbar = load("res://addons/simplegrasstextured/toolbar.tscn").instantiate()
	_gui_toolbar.visible = false
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, _gui_toolbar)
	_gui_toolbar.set_plugin(self)
	
	_gui_toolbar_up = load("res://addons/simplegrasstextured/toolbar_up.tscn").instantiate()
	_gui_toolbar_up.visible = false
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _gui_toolbar_up)
	_gui_toolbar_up.set_plugin(self)
	
	_inspector_plugin = load("res://addons/simplegrasstextured/sgt_inspector.gd").new()
	add_inspector_plugin(_inspector_plugin)
	
	_raycast_3d = RayCast3D.new()
	_raycast_3d.collision_mask = pow(2, 32) - 1
	_raycast_3d.visible = false
	_decal_pointer = Decal.new()
	_decal_pointer.set_texture(Decal.TEXTURE_ALBEDO, load("res://addons/simplegrasstextured/images/pointer.png"))
	_decal_pointer.visible = false
	_decal_pointer.extents = Vector3(_edit_radius, DEPTH_BRUSH, _edit_radius)
	add_child(_raycast_3d)
	add_child(_decal_pointer)
	
	_gui_toolbar.slider_radius.value_changed.connect(_on_slider_radius_value_changed)
	_gui_toolbar.slider_density.value_changed.connect(_on_slider_density_value_changed)
	_gui_toolbar.button_draw.toggled.connect(_on_button_draw_toggled)
	_gui_toolbar.button_fill.toggled.connect(_on_button_fill_toggled)
	_gui_toolbar.button_erase.toggled.connect(_on_button_erase_toggled)
	_gui_toolbar.edit_scale.value_changed.connect(_on_edit_scale_value_changed)
	_gui_toolbar.edit_rotation.value_changed.connect(_on_edit_rotation_value_changed)
	_gui_toolbar.edit_rotation_rand.value_changed.connect(_on_edit_rotation_rand_value_changed)
	_gui_toolbar.edit_distance.value_changed.connect(_on_edit_distance_value_changed)
	self._edit_draw = true


func _exit_tree():
	var current_config := _custom_config_memorize()
	if current_config != _prev_config:
		# Force save settings if some shortcut has been changed
		ProjectSettings.save()
	_grass_selected = null
	_raycast_3d.queue_free()
	_decal_pointer.queue_free()
	remove_custom_type("SimpleGrassTextured")
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, _gui_toolbar)
	_gui_toolbar.queue_free()
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _gui_toolbar_up)
	_gui_toolbar_up.queue_free()
	if _inspector_plugin != null:
		remove_inspector_plugin(_inspector_plugin)


func _enable_plugin():
	_verify_global_shader_parameters()


func _disable_plugin():
	_enable_shaders(false)
	remove_autoload_singleton("SimpleGrass")
	if ProjectSettings.has_setting("shader_globals/sgt_player_position"):
		ProjectSettings.set_setting("shader_globals/sgt_player_position", null)
	if ProjectSettings.has_setting("shader_globals/sgt_player_mov"):
		ProjectSettings.set_setting("shader_globals/sgt_player_mov", null)
	if ProjectSettings.has_setting("shader_globals/sgt_normal_displacement"):
		ProjectSettings.set_setting("shader_globals/sgt_normal_displacement", null)
	if ProjectSettings.has_setting("shader_globals/sgt_motion_texture"):
		ProjectSettings.set_setting("shader_globals/sgt_motion_texture", null)
	if ProjectSettings.has_setting("shader_globals/sgt_wind_direction"):
		ProjectSettings.set_setting("shader_globals/sgt_wind_direction", null)
	if ProjectSettings.has_setting("shader_globals/sgt_wind_movement"):
		ProjectSettings.set_setting("shader_globals/sgt_wind_movement", null)
	if ProjectSettings.has_setting("shader_globals/sgt_wind_strength"):
		ProjectSettings.set_setting("shader_globals/sgt_wind_strength", null)
	if ProjectSettings.has_setting("shader_globals/sgt_wind_turbulence"):
		ProjectSettings.set_setting("shader_globals/sgt_wind_turbulence", null)
	if ProjectSettings.has_setting("shader_globals/sgt_wind_pattern"):
		ProjectSettings.set_setting("shader_globals/sgt_wind_pattern", null)
	# Remove custom settings from Project Settings
	for entry in _custom_settings:
		if ProjectSettings.has_setting(entry["name"]):
			ProjectSettings.set_setting(entry["name"], null)
	# Fix editor crash when disable plugin while SimpleGrassTextured node is selected
	_grass_selected = null
	var editor = get_editor_interface()
	if editor != null:
		var scene_root = editor.get_edited_scene_root()
		if scene_root != null:
			editor.edit_node(scene_root)
			var selection = editor.get_selection()
			if selection != null:
				selection.clear()


func _get_plugin_name() -> String:
	return "SimpleGrassTextured"


func _handles(object) -> bool:
	if object != null and object.has_meta("SimpleGrassTextured") and object.visible:
		_grass_selected = object
		_update_gui()
		return true
	_grass_selected = null
	return false


func _edit(object):
	_grass_selected = object
	_update_gui()


func _make_visible(visible : bool):
	if visible:
		if _grass_selected != null:
			_update_gui()
		_gui_toolbar.visible = true
		_gui_toolbar_up.visible = true
	else:
		_gui_toolbar.visible = false
		_gui_toolbar_up.visible = false
		_decal_pointer.visible = false
		_grass_selected = null
		_gui_toolbar.set_current_grass(null)
		_gui_toolbar_up.set_current_grass(null)


func _physics_process(_delta):
	if _mouse_event == EVENT_MOUSE.EVENT_CLICK:
		_raycast_3d.global_transform.origin = _project_ray_origin
		_raycast_3d.global_transform.basis.y = _project_ray_normal
		_raycast_3d.target_position = Vector3(0, 100000, 0)
		_raycast_3d.collision_mask = _grass_selected.collision_mask
		_raycast_3d.force_raycast_update()
		if _raycast_3d.is_colliding():
			_position_draw = _raycast_3d.get_collision_point()
			_normal_draw = _raycast_3d.get_collision_normal()
			_object_draw = _raycast_3d.get_collider()
			_eval_brush()
			_time_draw = Time.get_ticks_msec()
			_draw_paused = false
		else:
			_time_draw = 0
			_draw_paused = true
			_object_draw = null
		_mouse_event = EVENT_MOUSE.EVENT_NONE
	elif _mouse_event == EVENT_MOUSE.EVENT_MOVE:
		_raycast_3d.global_transform.origin = _project_ray_origin
		_raycast_3d.global_transform.basis.y = _project_ray_normal
		_raycast_3d.target_position = Vector3(0, 100000, 0)
		_raycast_3d.collision_mask = _grass_selected.collision_mask
		_raycast_3d.force_raycast_update()
		if ( not _raycast_3d.is_colliding()
		or ( _object_draw != null and _raycast_3d.get_collider() != _object_draw )):
			_decal_pointer.visible = false
			_draw_paused = true
			_mouse_event = EVENT_MOUSE.EVENT_NONE
			return
		else:
			_draw_paused = false
		_position_draw = _raycast_3d.get_collision_point()
		_normal_draw = _raycast_3d.get_collision_normal()
		var trans := Transform3D()
		if abs(_normal_draw.z) == 1:
			trans.basis.x = Vector3(1,0,0)
			trans.basis.y = Vector3(0,0,_normal_draw.z)
			trans.basis.z = Vector3(0,_normal_draw.z,0)
		else:
			trans.basis.y = _normal_draw
			trans.basis.x = _normal_draw.cross(trans.basis.z)
			trans.basis.z = trans.basis.x.cross(_normal_draw)
			trans.basis = trans.basis.orthonormalized()
		trans.origin = _position_draw
		_decal_pointer.global_transform = trans
		_decal_pointer.extents = Vector3(_edit_radius, DEPTH_BRUSH, _edit_radius)
		_decal_pointer.visible = _edit_draw or _edit_fill or _edit_erase
		_mouse_event = EVENT_MOUSE.EVENT_NONE
	if _time_draw > 0:
		if not _draw_paused:
			if Time.get_ticks_msec() - _time_draw >= 150:
				_time_draw = Time.get_ticks_msec()
				_eval_brush()


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if _grass_selected == null:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if _grass_selected.multimesh != null:
		_gui_toolbar.label_stats.text = "Count: " + str(_grass_selected.multimesh.instance_count)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not (_edit_draw or _edit_fill or _edit_erase):
				return EditorPlugin.AFTER_GUI_INPUT_PASS
			if event.pressed:
				_project_ray_origin = viewport_camera.project_ray_origin(event.position)
				_project_ray_normal = viewport_camera.project_ray_normal(event.position)
				_mouse_event = EVENT_MOUSE.EVENT_CLICK
			else:
				_time_draw = 0
				_object_draw = null
				_mouse_event = EVENT_MOUSE.EVENT_NONE
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	if event is InputEventMouseMotion:
		if _mouse_event != EVENT_MOUSE.EVENT_CLICK:
			_project_ray_origin = viewport_camera.project_ray_origin(event.position)
			_project_ray_normal = viewport_camera.project_ray_normal(event.position)
			_mouse_event = EVENT_MOUSE.EVENT_MOVE
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _verify_global_shader_parameters():
	if not ProjectSettings.has_setting("shader_globals/sgt_player_position"):
		ProjectSettings.set_setting("shader_globals/sgt_player_position", {
			"type": "vec3",
			"value": Vector3(1000000, 1000000, 1000000)
		})
		if RenderingServer.global_shader_parameter_get("sgt_player_position") == null:
			RenderingServer.global_shader_parameter_add("sgt_player_position", RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3(1000000,1000000,1000000))
	if not ProjectSettings.has_setting("shader_globals/sgt_player_mov"):
		ProjectSettings.set_setting("shader_globals/sgt_player_mov", {
			"type": "vec3",
			"value": Vector3.ZERO
		})
		if RenderingServer.global_shader_parameter_get("sgt_player_mov") == null:
			RenderingServer.global_shader_parameter_add("sgt_player_mov", RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3.ZERO)
	if not ProjectSettings.has_setting("shader_globals/sgt_normal_displacement"):
		ProjectSettings.set_setting("shader_globals/sgt_normal_displacement", {
			"type": "sampler2D",
			"value": "res://addons/simplegrasstextured/images/normal.png"
		})
		if RenderingServer.global_shader_parameter_get("sgt_normal_displacement") == null:
			RenderingServer.global_shader_parameter_add("sgt_normal_displacement", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, load("res://addons/simplegrasstextured/images/normal.png"))
	if not ProjectSettings.has_setting("shader_globals/sgt_motion_texture"):
		ProjectSettings.set_setting("shader_globals/sgt_motion_texture", {
			"type": "sampler2D",
			"value": "res://addons/simplegrasstextured/images/motion.png"
		})
		if RenderingServer.global_shader_parameter_get("sgt_motion_texture") == null:
			RenderingServer.global_shader_parameter_add("sgt_motion_texture", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, load("res://addons/simplegrasstextured/images/motion.png"))
	if not ProjectSettings.has_setting("shader_globals/sgt_wind_direction"):
		ProjectSettings.set_setting("shader_globals/sgt_wind_direction", {
			"type": "vec3",
			"value": Vector3(1, 0, 0)
		})
		if RenderingServer.global_shader_parameter_get("sgt_wind_direction") == null:
			RenderingServer.global_shader_parameter_add("sgt_wind_direction", RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3(1, 0, 0))
	if not ProjectSettings.has_setting("shader_globals/sgt_wind_movement"):
		ProjectSettings.set_setting("shader_globals/sgt_wind_movement", {
			"type": "vec3",
			"value": Vector2.ZERO
		})
		if RenderingServer.global_shader_parameter_get("sgt_wind_movement") == null:
			RenderingServer.global_shader_parameter_add("sgt_wind_movement", RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3.ZERO)
	if not ProjectSettings.has_setting("shader_globals/sgt_wind_strength"):
		ProjectSettings.set_setting("shader_globals/sgt_wind_strength", {
			"type": "float",
			"value": 0.15
		})
		if RenderingServer.global_shader_parameter_get("sgt_wind_strength") == null:
			RenderingServer.global_shader_parameter_add("sgt_wind_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.15)
	if not ProjectSettings.has_setting("shader_globals/sgt_wind_turbulence"):
		ProjectSettings.set_setting("shader_globals/sgt_wind_turbulence", {
			"type": "float",
			"value": 1.0
		})
		if RenderingServer.global_shader_parameter_get("sgt_wind_turbulence") == null:
			RenderingServer.global_shader_parameter_add("sgt_wind_turbulence", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.0)
	if not ProjectSettings.has_setting("shader_globals/sgt_wind_pattern"):
		ProjectSettings.set_setting("shader_globals/sgt_wind_pattern", {
			"type": "sampler2D",
			"value": "res://addons/simplegrasstextured/images/wind_pattern.png"
		})
		if RenderingServer.global_shader_parameter_get("sgt_wind_pattern") == null:
			RenderingServer.global_shader_parameter_add("sgt_wind_pattern", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, load("res://addons/simplegrasstextured/images/wind_pattern.png"))
	add_autoload_singleton("SimpleGrass", "res://addons/simplegrasstextured/singleton.tscn")


func _enable_shaders(enable :bool) -> void:
	if enable:
		var dir := DirAccess.open("res://")
		if dir.file_exists("res://addons/simplegrasstextured/shaders/.gdignore"):
			dir.remove("res://addons/simplegrasstextured/shaders/.gdignore")
		if dir.file_exists("res://addons/simplegrasstextured/materials/.gdignore"):
			dir.remove("res://addons/simplegrasstextured/materials/.gdignore")
		var editor = get_editor_interface()
		editor.get_resource_filesystem().scan.call_deferred()
	else:
		var file := FileAccess.open("res://addons/simplegrasstextured/shaders/.gdignore", FileAccess.WRITE)
		file.close()
		file = FileAccess.open("res://addons/simplegrasstextured/materials/.gdignore", FileAccess.WRITE)
		file.close()
		var editor = get_editor_interface()
		editor.get_resource_filesystem().scan.call_deferred()


func _create_shortcut(keycode :Key) -> Shortcut:
	var shortcut := Shortcut.new()
	var key := InputEventKey.new()
	key.keycode = keycode
	key.pressed = true
	shortcut.events.append(key)
	return shortcut


func _custom_config_memorize() -> String:
	var config := ConfigFile.new()
	for entry in _custom_settings:
		config.set_value("s", entry["name"], ProjectSettings.get_setting_with_override(entry["name"]))
	return config.encode_to_text()


func get_custom_setting(name :String) -> Variant:
	if ProjectSettings.has_setting(name):
		return ProjectSettings.get_setting_with_override(name)
	for entry in _custom_settings:
		if entry["name"] != name:
			continue
		return entry["default"]
	push_error("SimpleGrassTextured, setting not found: ", name)
	return null


func _init_default_project_settings() -> void:
	for entry in _custom_settings:
		if not ProjectSettings.has_setting(entry["name"]):
			ProjectSettings.set(entry["name"], entry["default"])
		ProjectSettings.set_initial_value(entry["name"], entry["default"])
		ProjectSettings.add_property_info(entry)
		if entry.has("basic") and ProjectSettings.has_method(&"set_as_basic"):
			ProjectSettings.call(&"set_as_basic", entry["name"], entry["basic"])


func _update_gui():
	if _grass_selected != null:
		_gui_toolbar.slider_radius.value = _grass_selected.sgt_radius
		_gui_toolbar.slider_density.value = _grass_selected.sgt_density
		_gui_toolbar.edit_scale.value = _grass_selected.sgt_scale
		_gui_toolbar.edit_rotation.value = _grass_selected.sgt_rotation
		_gui_toolbar.edit_rotation_rand.value = _grass_selected.sgt_rotation_rand
		_gui_toolbar.edit_distance.value = _grass_selected.sgt_dist_min
		_gui_toolbar.set_current_grass(_grass_selected)
		_gui_toolbar_up.set_current_grass(_grass_selected)
		if _grass_selected.multimesh != null:
			_gui_toolbar.label_stats.text = "Count: " + str(_grass_selected.multimesh.instance_count)
		_raycast_3d.collision_mask = _grass_selected.collision_mask


func _on_project_settings_changed() -> void:
	_prev_config = _custom_config_memorize()


func _on_button_draw_toggled(pressed : bool):
	_edit_draw = pressed
	if _edit_draw:
		self._edit_fill = false
		self._edit_erase = false
	if _grass_selected != null:
		_decal_pointer.visible = _edit_draw or _edit_fill or _edit_erase
	else:
		_decal_pointer.visible = false


func _on_button_fill_toggled(pressed : bool):
	_edit_fill = pressed
	if _edit_fill:
		self._edit_draw = false
		self._edit_erase = false
	if _grass_selected != null:
		_decal_pointer.visible = _edit_draw or _edit_fill or _edit_erase
	else:
		_decal_pointer.visible = false


func _on_button_erase_toggled(pressed : bool):
	_edit_erase = pressed
	if _edit_erase:
		self._edit_draw = false
		self._edit_fill = false
	if _grass_selected != null:
		_decal_pointer.visible = _edit_draw or _edit_fill or _edit_erase
	else:
		_decal_pointer.visible = false


func _on_slider_radius_value_changed(value : float):
	_edit_radius = value
	_decal_pointer.extents = Vector3(_edit_radius, DEPTH_BRUSH, _edit_radius)
	if _grass_selected != null:
		_grass_selected.sgt_radius = value


func _on_slider_density_value_changed(value : float):
	_edit_density = value
	if _grass_selected != null:
		_grass_selected.sgt_density = value


func _on_edit_scale_value_changed(value : float):
	_edit_scale = Vector3(value, value, value)
	if _grass_selected != null:
		_grass_selected.sgt_scale = value


func _on_edit_rotation_value_changed(value : float):
	_edit_rotation = value
	if _grass_selected != null:
		_grass_selected.sgt_rotation = value


func _on_edit_rotation_rand_value_changed(value : float):
	_edit_rotation_rand = value
	if _grass_selected != null:
		_grass_selected.sgt_rotation_rand = value


func _on_edit_distance_value_changed(value : float):
	if _grass_selected != null:
		_grass_selected.sgt_dist_min = value


func _on_set_draw(value : bool):
	_edit_draw = value
	if _edit_draw:
		_decal_pointer.modulate = Color.WHITE
		_gui_toolbar.slider_density.editable = true
		_gui_toolbar.button_density.disabled = false
	_gui_toolbar.button_draw.button_pressed = _edit_draw


func _on_set_fill(value : bool):
	_edit_fill = value
	if _edit_fill:
		_decal_pointer.modulate = Color.YELLOW
		_gui_toolbar.slider_density.editable = false
		_gui_toolbar.button_density.disabled = true
	_gui_toolbar.button_fill.button_pressed = _edit_fill


func _on_set_erase(value : bool):
	_edit_erase = value
	if _edit_erase:
		_decal_pointer.modulate = Color.RED
		_gui_toolbar.slider_density.editable = false
		_gui_toolbar.button_density.disabled = true
	_gui_toolbar.button_erase.button_pressed = _edit_erase


func _eval_brush():
	if _grass_selected == null:
		return
	if _edit_fill:
		var steep : float = _grass_selected.sgt_dist_min
		var list_trans := []
		var follow_normal : bool = _grass_selected.sgt_follow_normal
		if steep < 0.05:
			steep = 0.4
		_grass_selected.temp_dist_min = steep
		var x := -_edit_radius
		while x < _edit_radius:
			var z := -_edit_radius
			while z < _edit_radius:
				var variation = Vector3(x + (randf() * steep * 0.5), 0, z + (randf() * steep * 0.5))
				variation = _decal_pointer.to_global(variation) - _decal_pointer.global_position
				_raycast_3d.global_transform.basis.x = Vector3.RIGHT
				_raycast_3d.global_transform.basis.y = _normal_draw * -1
				_raycast_3d.global_transform.basis.z = Vector3.BACK
				_raycast_3d.global_transform.origin = _position_draw + _normal_draw + variation
				_raycast_3d.target_position = Vector3(0, DEPTH_BRUSH, 0)
				_raycast_3d.collision_mask = _grass_selected.collision_mask
				_raycast_3d.force_raycast_update()
				var pos_grass : Vector3 = _raycast_3d.get_collision_point()
				if _position_draw.distance_to(pos_grass) >= _edit_radius:
					z += steep
					continue
				if _raycast_3d.is_colliding() and _raycast_3d.get_collider() == _object_draw:
					var normal := Vector3.UP
					if follow_normal:
						normal = _raycast_3d.get_collision_normal()
					list_trans.append(_grass_selected.eval_grass_transform(
						_raycast_3d.get_collision_point() - _grass_selected.global_position,
						normal,
						_edit_scale,
						deg_to_rad(_edit_rotation) + (PI * (_edit_rotation_rand - (randf() * _edit_rotation_rand * 2.0)))
					))
				z += steep
			x += steep
		_grass_selected.add_grass_batch(list_trans)
	elif _edit_draw:
		var follow_normal : bool = _grass_selected.sgt_follow_normal
		for i in _edit_density:
			var variation = Vector3.RIGHT * _edit_radius * randf()
			variation = variation.rotated(Vector3.UP, randf() * TAU)
			variation = _decal_pointer.to_global(variation) - _decal_pointer.global_position
			_raycast_3d.global_transform.basis.x = Vector3.RIGHT
			_raycast_3d.global_transform.basis.y = _normal_draw * -1
			_raycast_3d.global_transform.basis.z = Vector3.BACK
			_raycast_3d.global_transform.origin = _position_draw + _normal_draw + variation
			_raycast_3d.target_position = Vector3(0, DEPTH_BRUSH, 0)
			_raycast_3d.collision_mask = _grass_selected.collision_mask
			_raycast_3d.force_raycast_update()
			if _raycast_3d.is_colliding() and _raycast_3d.get_collider() == _object_draw:
				var normal := Vector3.UP
				if follow_normal:
					normal = _raycast_3d.get_collision_normal()
				_grass_selected.add_grass(
					_raycast_3d.get_collision_point() - _grass_selected.global_position,
					normal,
					_edit_scale,
					deg_to_rad(_edit_rotation) + (PI * (_edit_rotation_rand - (randf() * _edit_rotation_rand * 2.0)))
				)
	elif _edit_erase:
		_grass_selected.erase(_position_draw - _grass_selected.global_position, _edit_radius)
	if _grass_selected.multimesh != null:
		_gui_toolbar.label_stats.text = "Count: " + str(_grass_selected.multimesh.instance_count)
