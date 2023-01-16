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

const _TOOLBAR := preload("toolbar.gd")

var _raycast_3d : RayCast3D = null
var _decal_pointer : Decal = null
var _grass_selected : SimpleGrassTextured = null
var _timer_draw : Timer = null
var _position_draw := Vector3.ZERO
var _normal_draw := Vector3.ZERO
var _edit_density := 25
var _edit_radius := 2.0 : set = _on_set_radius
var _edit_scale := Vector3.ONE
var _edit_draw := true : set = _on_set_draw
var _edit_erase := false : set = _on_set_erase
var _gui_toolbar : _TOOLBAR = preload("toolbar.tscn").instantiate()


func _enter_tree():
	add_custom_type("SimpleGrassTextured", "MultiMeshInstance3D", preload("grass.gd"), preload("icon.png"))
	_gui_toolbar.visible = false
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, _gui_toolbar)
	_raycast_3d = RayCast3D.new()
	_raycast_3d.visible = false
	_decal_pointer = Decal.new()
	_decal_pointer.set_texture(Decal.TEXTURE_ALBEDO, preload("images/pointer.png"))
	_decal_pointer.visible = false
	_decal_pointer.scale = Vector3(_edit_radius, 20, _edit_radius)
	_timer_draw = Timer.new()
	_timer_draw.timeout.connect(_on_timer_draw_timeout)
	add_child(_raycast_3d)
	add_child(_decal_pointer)
	add_child(_timer_draw)
	_gui_toolbar.slider_radius.value_changed.connect(func(value:float): _edit_radius = value)
	_gui_toolbar.slider_density.value_changed.connect(func(value:float): _edit_density = value)
	_gui_toolbar.button_draw.toggled.connect(_on_button_draw_toggled)
	_gui_toolbar.button_erase.toggled.connect(_on_button_erase_toggled)
	_gui_toolbar.edit_scale.value_changed.connect(_on_edit_scale_value_changed)
	_gui_toolbar.edit_distance.value_changed.connect(_on_edit_distance_value_changed)
	self._edit_draw = true


func _exit_tree():
	_raycast_3d.queue_free()
	_decal_pointer.queue_free()
	remove_custom_type("SimpleGrassTextured")
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, _gui_toolbar)
	_gui_toolbar.queue_free()


func _get_plugin_name() -> String:
	return "SimpleGrassTextured"


func _handles(object) -> bool:
	if object is SimpleGrassTextured and object.visible:
		_grass_selected = object
		return true
	_grass_selected = null
	return false


func _edit(object : Variant):
	_grass_selected = object


func _make_visible(visible : bool):
	if visible:
		_gui_toolbar.slider_radius.value = _edit_radius
		_gui_toolbar.slider_density.value = _edit_density
		if _grass_selected != null:
			_gui_toolbar.edit_distance.value = _grass_selected.dist_min
			if _grass_selected.multimesh != null:
				_gui_toolbar.label_stats.text = "Count: " + str(_grass_selected.multimesh.instance_count)
		_gui_toolbar.visible = true
	else:
		_gui_toolbar.visible = false
		_decal_pointer.visible = false
		_grass_selected = null


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if _grass_selected == null:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if _grass_selected.multimesh != null:
		_gui_toolbar.label_stats.text = "Count: " + str(_grass_selected.multimesh.instance_count)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not (_edit_draw or _edit_erase):
				return EditorPlugin.AFTER_GUI_INPUT_PASS
			if event.pressed:
				var normal := viewport_camera.project_ray_normal(event.position)
				_raycast_3d.position = viewport_camera.project_ray_origin(event.position)
				_raycast_3d.target_position = normal * 100000
				_raycast_3d.force_raycast_update()
				if _raycast_3d.is_colliding():
					_position_draw = _raycast_3d.get_collision_point()
					_normal_draw = _raycast_3d.get_collision_normal()
					_on_timer_draw_timeout()
					_timer_draw.start(0.15)
			else:
				_timer_draw.stop()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	if event is InputEventMouseMotion:
		var normal := viewport_camera.project_ray_normal(event.position)
		_raycast_3d.position = viewport_camera.project_ray_origin(event.position)
		_raycast_3d.target_position = normal * 100000
		_raycast_3d.force_raycast_update()
		if not _raycast_3d.is_colliding():
			_decal_pointer.visible = false
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		_position_draw = _raycast_3d.get_collision_point()
		_normal_draw = _raycast_3d.get_collision_normal()
		_decal_pointer.position = _position_draw
		_decal_pointer.visible = _edit_draw or _edit_erase
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _on_button_draw_toggled(pressed : bool):
	_edit_draw = pressed
	if _edit_draw:
		self._edit_erase = false
	_decal_pointer.visible = _edit_draw or _edit_erase


func _on_button_erase_toggled(pressed : bool):
	_edit_erase = pressed
	if _edit_erase:
		self._edit_draw = false
	_decal_pointer.visible = _edit_draw or _edit_erase


func _on_edit_scale_value_changed(value : float):
	_edit_scale = Vector3(value, value, value)


func _on_edit_distance_value_changed(value : float):
	if _grass_selected != null:
		_grass_selected.dist_min = value


func _on_set_radius(value : float):
	_edit_radius = value
	_decal_pointer.scale = Vector3(_edit_radius, 20, _edit_radius)


func _on_set_draw(value : bool):
	_edit_draw = value
	if _edit_draw:
		_decal_pointer.modulate = Color.WHITE
	_gui_toolbar.button_draw.button_pressed = _edit_draw


func _on_set_erase(value : bool):
	_edit_erase = value
	if _edit_erase:
		_decal_pointer.modulate = Color.RED
	else:
		_decal_pointer.modulate = Color.WHITE
	_gui_toolbar.button_erase.button_pressed = _edit_erase


func _on_timer_draw_timeout():
	if _grass_selected == null:
		return
	if _edit_draw:
		for i in _edit_density:
			var variation := Vector3(randf() * _edit_radius, 1, 0).rotated(Vector3.UP, randf() * TAU)
			_raycast_3d.global_position = _position_draw + variation
			_raycast_3d.target_position = Vector3(0, -20, 0)
			_raycast_3d.force_raycast_update()
			if _raycast_3d.is_colliding():
				var normal := Vector3.UP
				if _gui_toolbar.chk_normals.button_pressed:
					normal = _raycast_3d.get_collision_normal()
				_grass_selected.add_grass(_raycast_3d.get_collision_point(), normal, _edit_scale)
	elif _edit_erase:
		_grass_selected.erase(_position_draw, _edit_radius)
	if _grass_selected.multimesh != null:
		_gui_toolbar.label_stats.text = "Count: " + str(_grass_selected.multimesh.instance_count)

