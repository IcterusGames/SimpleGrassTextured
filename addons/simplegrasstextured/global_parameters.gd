# global_parameters.gd
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
extends AcceptDialog

const DEFAULT_WIND_DIR := Vector3.RIGHT
const DEFAULT_WIND_STRENGTH := 0.15
const DEFAULT_WIND_TURBULENCE := 1.0
const DEFAULT_WIND_PATTERN := "res://addons/simplegrasstextured/images/wind_pattern.png"

var _wind_dir_x_slider : EditorSpinSlider
var _wind_dir_y_slider : EditorSpinSlider
var _wind_dir_z_slider : EditorSpinSlider
var _wind_strength_slider : EditorSpinSlider
var _wind_turbulence_slider : EditorSpinSlider
var _wind_pattern : EditorResourcePicker


func _ready():
	name = "SimpleGrassTexturedGlobalParameters"
	size = Vector2.ZERO
	_wind_dir_x_slider = _create_slider("X", -1, 1, 0.01)
	_wind_dir_y_slider = _create_slider("Y", -1, 1, 0.01)
	_wind_dir_z_slider = _create_slider("Z", -1, 1, 0.01)
	_wind_strength_slider = _create_slider("", 0, 1, 0.001)
	_wind_turbulence_slider = _create_slider("", 0, 20, 0.01)
	_wind_pattern = EditorResourcePicker.new()
	_wind_pattern.base_type = "Texture"
	_wind_pattern.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wind_dir_x_slider.value_changed.connect(_on_wind_dir_x_value_changed)
	_wind_dir_y_slider.value_changed.connect(_on_wind_dir_y_value_changed)
	_wind_dir_z_slider.value_changed.connect(_on_wind_dir_z_value_changed)
	_wind_strength_slider.value_changed.connect(_on_wind_strength_value_changed)
	_wind_turbulence_slider.value_changed.connect(_on_wind_turbulence_value_changed)
	_wind_pattern.resource_changed.connect(_on_wind_pattern_resource_changed)
	%WindDirHbox.add_child(_wind_dir_x_slider)
	%WindDirHbox.add_child(_wind_dir_y_slider)
	%WindDirHbox.add_child(_wind_dir_z_slider)
	%WindStrengthHBox.add_child(_wind_strength_slider)
	%WindTurbulenceHBox.add_child(_wind_turbulence_slider)
	%WindPatternHBox.add_child(_wind_pattern)
	get_ok_button().custom_minimum_size.x = 100
	_on_theme_changed()


func _create_slider(label : String, min : float, max : float, step : float) -> EditorSpinSlider:
	var slider := EditorSpinSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.step = step;
	slider.min_value = min
	slider.max_value = max
	slider.label = label
	slider.custom_minimum_size.x = 80
	return slider


func disable_button(button : Button, disabled : bool) -> void:
	if disabled:
		button.disabled = true
		button.modulate.a = 0
		button.focus_mode = Control.FOCUS_NONE
	else:
		button.disabled = false
		button.modulate.a = 1
		button.focus_mode = Control.FOCUS_ALL


func _on_about_to_popup():
	var windir : Vector3 = ProjectSettings.get_setting("shader_globals/sgt_wind_direction").value
	_wind_dir_x_slider.value = windir.x
	_wind_dir_y_slider.value = windir.y
	_wind_dir_z_slider.value = windir.z
	_wind_strength_slider.value = ProjectSettings.get_setting("shader_globals/sgt_wind_strength").value
	_wind_turbulence_slider.value = ProjectSettings.get_setting("shader_globals/sgt_wind_turbulence").value
	_wind_pattern.edited_resource = load(ProjectSettings.get_setting("shader_globals/sgt_wind_pattern").value)
	_on_wind_pattern_resource_changed(_wind_pattern.edited_resource)


func _on_wind_dir_x_value_changed(value : float):
	var windir : Vector3 = ProjectSettings.get_setting("shader_globals/sgt_wind_direction", {"value":Vector3.RIGHT}).value
	windir.x = value
	ProjectSettings.set_setting("shader_globals/sgt_wind_direction", {
		"type": "vec3",
		"value": windir
	})
	RenderingServer.global_shader_parameter_set("sgt_wind_direction", windir)
	$SaveConfigTimer.start()
	get_tree().emit_signal("sgt_globals_params_changed")
	disable_button(%DefaultWindDirButton, windir == DEFAULT_WIND_DIR)


func _on_wind_dir_y_value_changed(value : float):
	var windir : Vector3 = ProjectSettings.get_setting("shader_globals/sgt_wind_direction", {"value":Vector3.RIGHT}).value
	windir.y = value
	ProjectSettings.set_setting("shader_globals/sgt_wind_direction", {
		"type": "vec3",
		"value": windir
	})
	RenderingServer.global_shader_parameter_set("sgt_wind_direction", windir)
	$SaveConfigTimer.start()
	get_tree().emit_signal("sgt_globals_params_changed")
	disable_button(%DefaultWindDirButton, windir == DEFAULT_WIND_DIR)


func _on_wind_dir_z_value_changed(value : float):
	var windir : Vector3 = ProjectSettings.get_setting("shader_globals/sgt_wind_direction", {"value":Vector3.RIGHT}).value
	windir.z = value
	ProjectSettings.set_setting("shader_globals/sgt_wind_direction", {
		"type": "vec3",
		"value": windir
	})
	RenderingServer.global_shader_parameter_set("sgt_wind_direction", windir)
	$SaveConfigTimer.start()
	get_tree().emit_signal("sgt_globals_params_changed")
	disable_button(%DefaultWindDirButton, windir == DEFAULT_WIND_DIR)


func _on_wind_strength_value_changed(value : float):
	ProjectSettings.set_setting("shader_globals/sgt_wind_strength", {
		"type": "float",
		"value": value
	})
	RenderingServer.global_shader_parameter_set("sgt_wind_strength", value)
	$SaveConfigTimer.start()
	get_tree().emit_signal("sgt_globals_params_changed")
	disable_button(%DefaultWindStrengthButton, _wind_strength_slider.value == DEFAULT_WIND_STRENGTH)


func _on_wind_turbulence_value_changed(value : float):
	ProjectSettings.set_setting("shader_globals/sgt_wind_turbulence", {
		"type": "float",
		"value": value
	})
	RenderingServer.global_shader_parameter_set("sgt_wind_turbulence", value)
	$SaveConfigTimer.start()
	get_tree().emit_signal("sgt_globals_params_changed")
	disable_button(%DefaultWindTurbulenceButton, _wind_turbulence_slider.value == DEFAULT_WIND_TURBULENCE)


func _on_wind_pattern_resource_changed(resource : Resource):
	if resource.resource_path == "":
		_wind_pattern.edited_resource = load(DEFAULT_WIND_PATTERN)
		_on_wind_pattern_resource_changed(_wind_pattern.edited_resource)
		return
	ProjectSettings.set_setting("shader_globals/sgt_wind_pattern", {
		"type": "sampler2D",
		"value": resource.resource_path
	})
	RenderingServer.global_shader_parameter_set("sgt_wind_pattern", load(resource.resource_path))
	$SaveConfigTimer.start()
	get_tree().emit_signal("sgt_globals_params_changed")
	disable_button(%DefaultWindPatternButton, resource.resource_path == DEFAULT_WIND_PATTERN)


func _on_theme_changed():
	%DefaultWindDirButton.icon = get_theme_icon("Reload", "EditorIcons")
	%DefaultWindStrengthButton.icon = get_theme_icon("Reload", "EditorIcons")
	%DefaultWindTurbulenceButton.icon = get_theme_icon("Reload", "EditorIcons")
	%DefaultWindPatternButton.icon = get_theme_icon("Reload", "EditorIcons")


func _on_save_config_timer_timeout():
	ProjectSettings.save()


func _on_confirmed():
	ProjectSettings.save()


func _on_default_wind_dir_button_pressed():
	_wind_dir_x_slider.value = DEFAULT_WIND_DIR.x
	_wind_dir_y_slider.value = DEFAULT_WIND_DIR.y
	_wind_dir_z_slider.value = DEFAULT_WIND_DIR.z


func _on_default_wind_strength_button_pressed():
	_wind_strength_slider.value = DEFAULT_WIND_STRENGTH


func _on_default_wind_turbulence_button_pressed():
	_wind_turbulence_slider.value = DEFAULT_WIND_TURBULENCE


func _on_default_wind_pattern_button_pressed():
	_wind_pattern.edited_resource = load(DEFAULT_WIND_PATTERN)
	_on_wind_pattern_resource_changed(_wind_pattern.edited_resource)
