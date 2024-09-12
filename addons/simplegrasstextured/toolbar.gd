# toolbar.gd
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
extends Control

const DEFAULT_RADIUS := 2.0
const DEFAULT_DENSITY := 25.0
const DEFAULT_SCALE := 1.0
const DEFAULT_ROTATION := 0.0
const DEFAULT_ROTATION_RAND := 1.0
const DEFAULT_DISTANCE := 0.25

var _shortcut_radius_inc := Shortcut.new()
var _shortcut_radius_dec := Shortcut.new()
var _shortcut_density_inc := Shortcut.new()
var _shortcut_density_dec := Shortcut.new()

@onready var button_draw :Button = $ButtonDraw
@onready var button_fill :Button = $ButtonFill
@onready var button_erase :Button = $ButtonEraser
@onready var button_density :Button = %IconDensity
@onready var slider_radius :HSlider = $HSliderRadius
@onready var slider_density :HSlider = $HSliderDensity
@onready var edit_scale :EditorSpinSlider
@onready var edit_rotation :EditorSpinSlider
@onready var edit_rotation_rand :EditorSpinSlider
@onready var edit_distance :EditorSpinSlider
@onready var label_stats :Label = $LabelStats

@onready var _label_radius :Label = $HSliderRadius/Label
@onready var _label_density :Label = $HSliderDensity/Label
@onready var _button_more :MenuButton = $ButtonMore
@onready var _tween_radius :Tween = null
@onready var _tween_density :Tween = null


func _ready() -> void:
	edit_scale = _create_slider("", 0.01, 10.0, 0.01, DEFAULT_SCALE)
	edit_rotation = _create_slider("", 0.0, 360.0, 0.1, DEFAULT_ROTATION)
	edit_rotation_rand = _create_slider("", 0.0, 1.0, 0.01, DEFAULT_ROTATION_RAND)
	edit_distance = _create_slider("", 0.0, 5.0, 0.01, DEFAULT_DISTANCE)
	%ScaleCont.add_child(edit_scale)
	%RotationCont.add_child(edit_rotation)
	%RotationRandCont.add_child(edit_rotation_rand)
	%DistanceCont.add_child(edit_distance)


func _unhandled_input(event :InputEvent) -> void:
	if not event.is_pressed():
		return
	if _shortcut_radius_inc.matches_event(event):
		slider_radius.value += 0.1
	if _shortcut_radius_dec.matches_event(event):
		slider_radius.value -= 0.1
	if slider_density.editable and _shortcut_density_inc.matches_event(event):
		slider_density.value += 1
	if slider_density.editable and _shortcut_density_dec.matches_event(event):
		slider_density.value -= 1


func set_plugin(plugin :EditorPlugin) -> void:
	theme_changed.connect(_on_theme_changed)
	%ButtonMore.set_plugin(plugin)
	var config := ConfigFile.new()
	config.load("res://addons/simplegrasstextured/plugin.cfg")
	%LabelVersion.text = config.get_value("plugin", "version")
	button_draw.shortcut = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/draw")
	button_fill.shortcut = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/fill")
	button_erase.shortcut = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/erase")
	_shortcut_radius_inc = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/radius_increment")
	_shortcut_radius_dec = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/radius_decrement")
	_shortcut_density_inc = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/density_increment")
	_shortcut_density_dec = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/density_decrement")
	_on_theme_changed()


func set_current_grass(grass) -> void:
	%ButtonMore.set_current_grass(grass)


func _create_slider(label :String, min :float, max :float, step :float, value :float = 0.0) -> EditorSpinSlider:
	var slider := EditorSpinSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.step = step;
	slider.min_value = min
	slider.max_value = max
	slider.label = label
	slider.value = value
	slider.custom_minimum_size.x = 75
	return slider


func _on_h_slider_radius_value_changed(value :float) -> void:
	if _tween_radius != null:
		_tween_radius.kill()
	_label_radius.set(&"theme_override_colors/font_outline_color", _label_radius.get_theme_color(&"font_color").inverted())
	_tween_radius = _label_radius.create_tween()
	_tween_radius.tween_property(_label_radius, ^"modulate", Color.WHITE, 0.1)
	_tween_radius.tween_interval(2)
	_tween_radius.tween_property(_label_radius, ^"modulate", Color(1,1,1,0), 2)
	_label_radius.text = "%0.1f" % value
	slider_radius.tooltip_text = "(" + _shortcut_radius_dec.get_as_text() + ") - (" + _shortcut_radius_inc.get_as_text() + ")\n"
	slider_radius.tooltip_text += "Radius = %0.1f" % value


func _on_h_slider_density_value_changed(value :float) -> void:
	if _tween_density != null:
		_tween_density.kill()
	_label_density.set(&"theme_override_colors/font_outline_color", _label_density.get_theme_color(&"font_color").inverted())
	_tween_density = _label_density.create_tween()
	_tween_density.tween_property(_label_density, ^"modulate", Color.WHITE, 0.1)
	_tween_density.tween_interval(2)
	_tween_density.tween_property(_label_density, ^"modulate", Color(1,1,1,0), 2)
	_label_density.text = str(value)
	slider_density.tooltip_text = "(" + _shortcut_density_dec.get_as_text() + ") - (" + _shortcut_density_inc.get_as_text() + ")\n"
	slider_density.tooltip_text += "Density = %0.0f" % value


func _on_theme_changed() -> void:
	%IconScale.icon = get_theme_icon(&"ToolScale", &"EditorIcons")
	%IconRotation.icon = get_theme_icon(&"ToolRotate", &"EditorIcons")
	%IconRotationRand.icon = get_theme_icon(&"RandomNumberGenerator", &"EditorIcons")
	%IconRadius.modulate = get_theme_color(&"font_color", &"Label")
	%IconDensity.modulate = get_theme_color(&"font_color", &"Label")
	%IconDistance.modulate = get_theme_color(&"font_color", &"Label")
	if _button_more != null:
		_button_more.icon = get_theme_icon(&"GuiTabMenuHl", &"EditorIcons")


func _on_panel_container_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var win = load("res://addons/simplegrasstextured/about.tscn").instantiate()
			get_window().add_child(win)
			win.popup_centered()


func _on_icon_scale_pressed() -> void:
	edit_scale.value = DEFAULT_SCALE


func _on_icon_rotation_pressed() -> void:
	edit_rotation.value = DEFAULT_ROTATION


func _on_icon_rotation_rand_pressed() -> void:
	edit_rotation_rand.value = DEFAULT_ROTATION_RAND


func _on_icon_distance_pressed() -> void:
	edit_distance.value = DEFAULT_DISTANCE


func _on_icon_radius_pressed() -> void:
	slider_radius.value = DEFAULT_RADIUS


func _on_icon_radius_2_pressed() -> void:
	slider_density.value = DEFAULT_DENSITY
