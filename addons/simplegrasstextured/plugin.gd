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
var _edit_erase := false : set = _on_set_erase
var _gui_toolbar = null
var _time_draw := 0
var _draw_paused := true
var _mouse_event := EVENT_MOUSE.EVENT_NONE
var _project_ray_origin := Vector3.INF
var _project_ray_normal := Vector3.INF


func _enter_tree():
	add_custom_type(
		"SimpleGrassTextured",
		"MultiMeshInstance3D",
		load("res://addons/simplegrasstextured/grass.gd"),
		load("res://addons/simplegrasstextured/icon.svg")
	)
	_gui_toolbar = load("res://addons/simplegrasstextured/toolbar.tscn").instantiate()
	_gui_toolbar.visible = false
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, _gui_toolbar)
	_raycast_3d = RayCast3D.new()
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
	_gui_toolbar.button_erase.toggled.connect(_on_button_erase_toggled)
	_gui_toolbar.edit_scale.value_changed.connect(_on_edit_scale_value_changed)
	_gui_toolbar.edit_rotation.value_changed.connect(_on_edit_rotation_value_changed)
	_gui_toolbar.edit_rotation_rand.value_changed.connect(_on_edit_rotation_rand_value_changed)
	_gui_toolbar.edit_distance.value_changed.connect(_on_edit_distance_value_changed)
	_gui_toolbar.chk_normals.toggled.connect(_on_chk_normals_toggled)
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
	else:
		_gui_toolbar.visible = false
		_decal_pointer.visible = false
		_grass_selected = null


func _physics_process(_delta):
	if _mouse_event == EVENT_MOUSE.EVENT_CLICK:
		_raycast_3d.global_transform.origin = _project_ray_origin
		_raycast_3d.global_transform.basis.y = _project_ray_normal
		_raycast_3d.target_position = Vector3(0, 100000, 0)
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
		_decal_pointer.visible = _edit_draw or _edit_erase
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
			if not (_edit_draw or _edit_erase):
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


func _update_gui():
	if _grass_selected != null:
		_gui_toolbar.slider_radius.value = _grass_selected.sgt_radius
		_gui_toolbar.slider_density.value = _grass_selected.sgt_density
		_gui_toolbar.edit_scale.value = _grass_selected.sgt_scale
		_gui_toolbar.edit_rotation.value = _grass_selected.sgt_rotation
		_gui_toolbar.edit_rotation_rand.value = _grass_selected.sgt_rotation_rand
		_gui_toolbar.edit_distance.value = _grass_selected.sgt_dist_min
		_gui_toolbar.chk_normals.button_pressed = _grass_selected.sgt_follow_normal
		if _grass_selected.multimesh != null:
			_gui_toolbar.label_stats.text = "Count: " + str(_grass_selected.multimesh.instance_count)


func _on_button_draw_toggled(pressed : bool):
	_edit_draw = pressed
	if _edit_draw:
		self._edit_erase = false
	if _grass_selected != null:
		_decal_pointer.visible = _edit_draw or _edit_erase
	else:
		_decal_pointer.visible = false


func _on_button_erase_toggled(pressed : bool):
	_edit_erase = pressed
	if _edit_erase:
		self._edit_draw = false
	if _grass_selected != null:
		_decal_pointer.visible = _edit_draw or _edit_erase
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


func _on_chk_normals_toggled(pressed : bool):
	if _grass_selected != null:
		_grass_selected.sgt_follow_normal = pressed


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


func _eval_brush():
	if _grass_selected == null:
		return
	if _edit_draw:
		for i in _edit_density:
			var variation = Vector3.RIGHT * _edit_radius * randf()
			variation = variation.rotated(Vector3.UP, randf() * TAU)
			variation = _decal_pointer.to_global(variation) - _decal_pointer.global_position
			_raycast_3d.global_transform.basis.x = Vector3.RIGHT
			_raycast_3d.global_transform.basis.y = _normal_draw * -1
			_raycast_3d.global_transform.basis.z = Vector3.BACK
			_raycast_3d.global_transform.origin = _position_draw + _normal_draw + variation
			_raycast_3d.target_position = Vector3(0, DEPTH_BRUSH, 0)
			_raycast_3d.force_raycast_update()
			if _raycast_3d.is_colliding() and _raycast_3d.get_collider() == _object_draw:
				var normal := Vector3.UP
				if _gui_toolbar.chk_normals.button_pressed:
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
