# singleton.gd
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
extends Node3D

var wind_direction := Vector3(1, 0, 0) : set = set_wind_direction
var wind_strength := 0.15 : set = set_wind_strength
var wind_turbulence := 1.0 : set = set_wind_turbulence
var player_position := Vector3.ZERO : set = set_player_position
var interactive := false : set = set_interactive

var _RESOLUTION := 512.0
var _PIXEL_STEEP := Vector3(50.0 / _RESOLUTION, 50.0 / _RESOLUTION, 50.0 / _RESOLUTION)
var _CAM_DIST := Vector3(0, 25, 0)

var _wind_movement := Vector3.ZERO
var _time_wind := 0.0
var _player_pos_snapped := Vector3.ZERO
var _player_prev_pos := Vector3.ZERO
var _player_mov := Vector3.ZERO
var _gui_debug : VBoxContainer = null
var _label_names_debug : Label = null
var _label_datas_debug : Label = null
var _timer_debug : Timer = null

@onready var _height_view := $HeightMapView as SubViewport
@onready var _height_cam := $HeightMapView/Camera as Camera3D
@onready var _dist_view := $DistanceView as SubViewport
@onready var _dist_cam := $DistanceView/Camera as Camera3D
@onready var _dist_mesh := $DistanceView/Camera/Mesh as MeshInstance3D
@onready var _motion1_view := $Motion1 as SubViewport
@onready var _motion1_rect := $Motion1/Motion1Rect as ColorRect
@onready var _motion2_view := $Motion2 as SubViewport
@onready var _motion2_rect := $Motion2/Motion2Rect as ColorRect
@onready var _normal_view := $Normal as SubViewport
@onready var _normal_rect := $Normal/NormalRect as ColorRect
@onready var _blur1_view := $Blur1 as SubViewport
@onready var _blur1_rect := $Blur1/Blur1Rect as ColorRect
@onready var _blur2_view := $Blur2 as SubViewport
@onready var _blur2_rect := $Blur2/Blur2Rect as ColorRect


func _ready():
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		_RESOLUTION = 256.0
		_PIXEL_STEEP = Vector3(50.0 / _RESOLUTION, 50.0 / _RESOLUTION, 50.0 / _RESOLUTION)
	wind_direction = ProjectSettings.get_setting("shader_globals/sgt_wind_direction", {"value":wind_direction}).value
	wind_strength = ProjectSettings.get_setting("shader_globals/sgt_wind_strength", {"value":wind_strength}).value
	wind_turbulence = ProjectSettings.get_setting("shader_globals/sgt_wind_turbulence", {"value":wind_turbulence}).value
	RenderingServer.global_shader_parameter_set("sgt_wind_direction", wind_direction)
	RenderingServer.global_shader_parameter_set("sgt_wind_strength", wind_strength)
	RenderingServer.global_shader_parameter_set("sgt_wind_turbulence", wind_turbulence)
	_height_cam.size = 50.0
	_dist_cam.size = 50.0
	_dist_mesh.mesh.size = Vector2(50.0, 50.0)
	_dist_view.size = Vector2i(_RESOLUTION, _RESOLUTION)
	_dist_view.size_2d_override = _dist_view.size
	_motion1_view.size = _dist_view.size
	_motion1_view.size_2d_override = _dist_view.size
	_motion2_view.size = _dist_view.size
	_motion2_view.size_2d_override = _dist_view.size
	_normal_view.size = _dist_view.size
	_normal_view.size_2d_override = _dist_view.size
	_blur1_view.size = _dist_view.size
	_blur1_view.size_2d_override = _dist_view.size
	_blur2_view.size = _dist_view.size
	_blur2_view.size_2d_override = _dist_view.size
	if Engine.is_editor_hint():
		get_tree().connect("sgt_globals_params_changed", _on_globals_params_changed)
	else:
		set_interactive(false)


func _process(delta : float):
	if interactive:
		_player_pos_snapped = player_position.snapped(_PIXEL_STEEP) / 50.0
		_player_mov = _player_prev_pos - _player_pos_snapped
		RenderingServer.global_shader_parameter_set("sgt_player_mov", _player_mov)
		_motion1_rect.material.set_shader_parameter("delta", delta)
		_player_prev_pos = _player_pos_snapped
		_dist_cam.global_position = player_position.snapped(_PIXEL_STEEP) - _CAM_DIST
		_height_cam.global_position = player_position + _CAM_DIST * 2
		RenderingServer.global_shader_parameter_set("sgt_player_position", _player_pos_snapped)
	_time_wind += delta * wind_turbulence
	_wind_movement += wind_direction * delta * 0.1 * wind_strength
	_wind_movement.y = _time_wind
	RenderingServer.global_shader_parameter_set("sgt_wind_movement", _wind_movement)


func set_player_position(global_pos : Vector3) -> void:
	player_position = global_pos


func set_wind_direction(direction : Vector3) -> void:
	wind_direction = direction
	RenderingServer.global_shader_parameter_set("sgt_wind_direction", wind_direction)


func set_wind_strength(strength : float) -> void:
	wind_strength = strength
	RenderingServer.global_shader_parameter_set("sgt_wind_strength", wind_strength)


func set_wind_turbulence(turbulence : float) -> void:
	wind_turbulence = turbulence
	RenderingServer.global_shader_parameter_set("sgt_wind_turbulence", wind_turbulence)


func set_wind_pattern(pattern : Texture) -> void:
	RenderingServer.global_shader_parameter_set("sgt_wind_pattern", pattern)


func set_interactive(enable : bool) -> void:
	var mode := SubViewport.UPDATE_ALWAYS
	interactive = enable
	_dist_mesh.visible = interactive
	if not interactive:
		mode = SubViewport.UPDATE_ONCE
		_dist_mesh.material_override.set_shader_parameter("heightmap_texture", _height_view.get_texture())
		_motion2_rect.material.set_shader_parameter("prev_depth", load("res://addons/simplegrasstextured/images/motion.png"))
		_motion1_rect.material.set_shader_parameter("prev_depth", load("res://addons/simplegrasstextured/images/motion.png"))
		_motion1_rect.material.set_shader_parameter("cur_depth", load("res://addons/simplegrasstextured/images/motion.png"))
		_normal_rect.material.set_shader_parameter("depth_texture", _motion1_view.get_texture())
		_blur1_rect.material.set_shader_parameter("normal_texture", load("res://addons/simplegrasstextured/images/normal.png"))
		_blur2_rect.material.set_shader_parameter("normal_texture", load("res://addons/simplegrasstextured/images/normal.png"))
		RenderingServer.global_shader_parameter_set("sgt_normal_displacement", _blur2_view.get_texture())
		RenderingServer.global_shader_parameter_set("sgt_motion_texture", _motion1_view.get_texture())
	else:
		_dist_mesh.material_override.set_shader_parameter("heightmap_texture", _height_view.get_texture())
		_motion2_rect.material.set_shader_parameter("prev_depth", _motion1_view.get_texture())
		_motion1_rect.material.set_shader_parameter("prev_depth", _motion2_view.get_texture())
		_motion1_rect.material.set_shader_parameter("cur_depth", _dist_view.get_texture())
		_normal_rect.material.set_shader_parameter("depth_texture", _motion1_view.get_texture())
		_blur1_rect.material.set_shader_parameter("normal_texture", _normal_view.get_texture())
		_blur2_rect.material.set_shader_parameter("normal_texture", _blur1_view.get_texture())
		RenderingServer.global_shader_parameter_set("sgt_normal_displacement", _blur2_view.get_texture())
		RenderingServer.global_shader_parameter_set("sgt_motion_texture", _motion1_view.get_texture())
	_height_view.render_target_update_mode = mode
	_dist_view.render_target_update_mode = mode
	_normal_view.render_target_update_mode = mode
	_blur1_view.render_target_update_mode = mode
	_blur2_view.render_target_update_mode = mode
	_motion1_view.render_target_update_mode = mode
	_motion2_view.render_target_update_mode = mode


func is_interactive() -> bool:
	return interactive


func set_debugger_visible(show : bool):
	if show:
		if _gui_debug == null:
			_gui_debug = VBoxContainer.new()
			_gui_debug.position = Vector2(10, 10)
			var hbox := HBoxContainer.new()
			hbox.custom_minimum_size.y = 155
			_gui_debug.add_child(hbox)
			hbox.add_child(_new_debug_trect(_height_view.get_texture(), "Height map"))
			hbox.add_child(_new_debug_trect(_dist_view.get_texture(), "Distance"))
			hbox.add_child(_new_debug_trect(_motion1_view.get_texture(), "Motion #1"))
			hbox.add_child(_new_debug_trect(_motion2_view.get_texture(), "Motion #2"))
			hbox.add_child(_new_debug_trect(_normal_view.get_texture(), "Normal"))
			hbox.add_child(_new_debug_trect(_blur1_view.get_texture(), "Blur #1"))
			hbox.add_child(_new_debug_trect(_blur2_view.get_texture(), "Blur #2"))
			_label_names_debug = Label.new()
			_label_names_debug.label_settings = LabelSettings.new()
			_label_names_debug.label_settings.outline_color = Color.BLACK
			_label_names_debug.label_settings.font_size = 12
			_label_names_debug.label_settings.outline_size = 2
			_label_datas_debug = Label.new()
			_label_datas_debug.label_settings = _label_names_debug.label_settings
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_child(_label_names_debug)
			grid.add_child(_label_datas_debug)
			_gui_debug.add_child(grid)
			add_child(_gui_debug)
			_timer_debug = Timer.new()
			_timer_debug.timeout.connect(_on_timer_debug)
			add_child(_timer_debug)
			_timer_debug.start(0.03)
	else:
		if _gui_debug != null:
			_gui_debug.queue_free()
			_gui_debug = null
			_timer_debug.queue_free()
			_timer_debug = null


func is_debugger_visible() -> bool:
	return _gui_debug != null


func _on_globals_params_changed():
	wind_direction = ProjectSettings.get_setting("shader_globals/sgt_wind_direction", {"value":wind_direction}).value
	wind_strength = ProjectSettings.get_setting("shader_globals/sgt_wind_strength", {"value":wind_strength}).value
	wind_turbulence = ProjectSettings.get_setting("shader_globals/sgt_wind_turbulence", {"value":wind_turbulence}).value


func _new_debug_trect(texture : ViewportTexture, title : String) -> TextureRect:
	var trect := TextureRect.new()
	var label := Label.new()
	trect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	trect.texture = texture
	label.text = title
	label.label_settings = LabelSettings.new()
	label.label_settings.outline_color = Color.BLACK
	label.label_settings.font_size = 12
	label.label_settings.outline_size = 2
	label.position.y = 155
	trect.add_child(label)
	return trect


func _on_timer_debug():
	var text1 := ""
	var text2 := ""
	text1 += "\nInteractive:"
	text2 += "\n" + str(interactive)
	text1 += "\nPlayer position:"
	text2 += "\n" + str(player_position)
	text1 += "\nPlayer movement:"
	text2 += "\n" + str(_player_mov)
	text1 += "\nWind direction:"
	text2 += "\n" + str(wind_direction)
	text1 += "\nWind strength:"
	text2 += "\n" + str(wind_strength)
	text1 += "\nWind turbulence:"
	text2 += "\n" + str(wind_turbulence)
	text1 += "\nWind movement:"
	text2 += "\n" + str(_wind_movement)
	text1 += "\nResolution:"
	text2 += "\n" + str(_RESOLUTION)
	text1 += "\nPixel steep:"
	text2 += "\n" + str(_PIXEL_STEEP)
	text1 += "\nCamera distance:"
	text2 += "\n" + str(_CAM_DIST)
	_label_names_debug.text = text1
	_label_datas_debug.text = text2

