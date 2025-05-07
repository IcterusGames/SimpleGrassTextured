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

enum MENU_SHAPE_ID {
	TOOL_SHAPE_SPHERE,
	TOOL_SHAPE_CYLINDER,
	TOOL_SHAPE_CYLINDER_INF_H,
	TOOL_SHAPE_BOX,
	TOOL_SHAPE_BOX_INF_H,
}

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
var _plugin: EditorPlugin = null
var _grass_selected = null

@onready var button_airbrush :Button = %ButtonAirbrush
@onready var button_pencil :Button = %ButtonPencil
@onready var button_eraser :Button = %ButtonEraser
@onready var button_density :Button = %IconDensity
@onready var slider_radius :HSlider = $HSliderRadius
@onready var slider_density :HSlider = $HSliderDensity
@onready var edit_slope_range: Control = %SlopeRange
@onready var edit_scale :EditorSpinSlider
@onready var edit_rotation :EditorSpinSlider
@onready var edit_rotation_rand :EditorSpinSlider
@onready var edit_distance :EditorSpinSlider
@onready var label_stats :Label = $LabelStats

@onready var _label_radius :Label = $HSliderRadius/Label
@onready var _label_density :Label = $HSliderDensity/Label
@onready var _button_more :MenuButton = $ButtonMore
@onready var _airbrush_options: MenuButton = %AirbrushOptions
@onready var _pencil_options: MenuButton = %PencilOptions
@onready var _eraser_options: MenuButton = %EraserOptions
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
	_plugin = plugin
	theme_changed.connect(_on_theme_changed)
	%ButtonMore.set_plugin(plugin)
	var config := ConfigFile.new()
	config.load("res://addons/simplegrasstextured/plugin.cfg")
	%LabelVersion.text = config.get_value("plugin", "version")
	button_airbrush.shortcut = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/airbrush_tool")
	button_pencil.shortcut = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/pencil_tool")
	button_eraser.shortcut = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/eraser_tool")
	button_airbrush.gui_input.connect(_on_button_tool_gui_input.bind(button_airbrush, _airbrush_options))
	button_pencil.gui_input.connect(_on_button_tool_gui_input.bind(button_pencil, _pencil_options))
	button_eraser.gui_input.connect(_on_button_tool_gui_input.bind(button_eraser, _eraser_options))
	_shortcut_radius_inc = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/radius_increment")
	_shortcut_radius_dec = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/radius_decrement")
	_shortcut_density_inc = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/density_increment")
	_shortcut_density_dec = plugin.get_custom_setting("SimpleGrassTextured/Shortcuts/density_decrement")
	_airbrush_options.get_popup().add_radio_check_item("Cylinder", MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER)
	_airbrush_options.get_popup().add_radio_check_item("Box", MENU_SHAPE_ID.TOOL_SHAPE_BOX)
	_airbrush_options.get_popup().about_to_popup.connect(_on_tool_options_about_to_popup.bind(_airbrush_options))
	_airbrush_options.get_popup().id_pressed.connect(_on_sgt_shape_menu_pressed.bind("airbrush", _airbrush_options.get_popup()))
	_pencil_options.get_popup().add_radio_check_item("Cylinder", MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER)
	_pencil_options.get_popup().add_radio_check_item("Box", MENU_SHAPE_ID.TOOL_SHAPE_BOX)
	_pencil_options.get_popup().about_to_popup.connect(_on_tool_options_about_to_popup.bind(_pencil_options))
	_pencil_options.get_popup().id_pressed.connect(_on_sgt_shape_menu_pressed.bind("pencil", _pencil_options.get_popup()))
	_eraser_options.get_popup().add_radio_check_item("Sphere", MENU_SHAPE_ID.TOOL_SHAPE_SPHERE)
	_eraser_options.get_popup().add_radio_check_item("Cylinder", MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER)
	_eraser_options.get_popup().add_radio_check_item("Infinite vertical cylinder", MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER_INF_H)
	_eraser_options.get_popup().add_radio_check_item("Box", MENU_SHAPE_ID.TOOL_SHAPE_BOX)
	_eraser_options.get_popup().add_radio_check_item("Infinite vertical box", MENU_SHAPE_ID.TOOL_SHAPE_BOX_INF_H)
	_eraser_options.get_popup().about_to_popup.connect(_on_tool_options_about_to_popup.bind(_eraser_options))
	_eraser_options.get_popup().id_pressed.connect(_on_sgt_shape_menu_pressed.bind("eraser", _eraser_options.get_popup()))
	_on_theme_changed()


func set_current_grass(grass) -> void:
	_grass_selected = grass
	%ButtonMore.set_current_grass(grass)
	if _grass_selected == null:
		return
	for tool_name in _grass_selected.sgt_tool_shape:
		match tool_name:
			"airbrush":
				_update_shape_menu_from_grass(_airbrush_options.get_popup(), _grass_selected.sgt_tool_shape[tool_name])
			"pencil":
				_update_shape_menu_from_grass(_pencil_options.get_popup(), _grass_selected.sgt_tool_shape[tool_name])
			"eraser":
				_update_shape_menu_from_grass(_eraser_options.get_popup(), _grass_selected.sgt_tool_shape[tool_name])


func set_density_modulate(color: Color) -> void:
	%IconDensity.self_modulate = color
	slider_density.modulate = color


func _create_slider(label :String, min_value :float, max_value :float, step :float, value :float = 0.0) -> EditorSpinSlider:
	var slider := EditorSpinSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.step = step;
	slider.min_value = min_value
	slider.max_value = max_value
	slider.label = label
	slider.value = value
	slider.custom_minimum_size.x = 75
	return slider


func _on_tool_options_about_to_popup(_button_options: MenuButton) -> void:
	set_current_grass(_grass_selected)


func _update_shape_menu_from_grass(popupmenu: PopupMenu, plugin_id_shape: int) -> void:
	for i in popupmenu.item_count:
		popupmenu.set_item_checked(i, false)
	var idx := -1
	match _plugin.get_tool_shape_name(plugin_id_shape):
		"sphere":
			idx = popupmenu.get_item_index(MENU_SHAPE_ID.TOOL_SHAPE_SPHERE)
		"cylinder":
			idx = popupmenu.get_item_index(MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER)
		"cylinder_inf_h":
			idx = popupmenu.get_item_index(MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER_INF_H)
		"box":
			idx = popupmenu.get_item_index(MENU_SHAPE_ID.TOOL_SHAPE_BOX)
		"box_inf_h":
			idx = popupmenu.get_item_index(MENU_SHAPE_ID.TOOL_SHAPE_BOX_INF_H)
		_:
			idx = -1
	if idx == -1:
		return
	popupmenu.set_item_checked(idx, true)


func _on_sgt_shape_menu_pressed(id: int, tool_name: String, popupmenu: PopupMenu) -> void:
	if _grass_selected == null:
		return
	for i in popupmenu.item_count:
		popupmenu.set_item_checked(i, false)
	var idx := popupmenu.get_item_index(id)
	if idx == -1:
		return
	popupmenu.set_item_checked(idx, true)
	var shape_name := ""
	match id:
		MENU_SHAPE_ID.TOOL_SHAPE_SPHERE:
			shape_name = "sphere"
		MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER:
			shape_name = "cylinder"
		MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER_INF_H:
			shape_name = "cylinder_inf_h"
		MENU_SHAPE_ID.TOOL_SHAPE_BOX:
			shape_name = "box"
		MENU_SHAPE_ID.TOOL_SHAPE_BOX_INF_H:
			shape_name = "box_inf_h"
	_plugin.set_tool_shape(tool_name, shape_name)
	_plugin.set_tool(tool_name)


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
	var base_color: Color = EditorInterface.get_base_control().get_theme_color(&"base_color", &"Editor")
	if base_color.get_luminance() < 0.5:
		button_airbrush.icon = load("res://addons/simplegrasstextured/images/sgt_icon_airbrush.svg")
		button_pencil.icon = load("res://addons/simplegrasstextured/images/sgt_icon_pen.svg")
		button_eraser.icon = load("res://addons/simplegrasstextured/images/sgt_icon_eraser.svg")
		_airbrush_options.icon = load("res://addons/simplegrasstextured/images/sgt_icon_arrow_up.svg")
		_pencil_options.icon = load("res://addons/simplegrasstextured/images/sgt_icon_arrow_up.svg")
		_eraser_options.icon = load("res://addons/simplegrasstextured/images/sgt_icon_arrow_up.svg")
		%IconSlope.icon = load("res://addons/simplegrasstextured/images/sgt_icon_slope.svg")
		%IconRadius.icon = load("res://addons/simplegrasstextured/images/sgt_icon_radius.svg")
		%IconDensity.icon = load("res://addons/simplegrasstextured/images/sgt_icon_density.svg")
		%IconDistance.icon = load("res://addons/simplegrasstextured/images/sgt_icon_distance.svg")
	else:
		button_airbrush.icon = load("res://addons/simplegrasstextured/images/sgt_icon_airbrush_dark.svg")
		button_pencil.icon = load("res://addons/simplegrasstextured/images/sgt_icon_pen_dark.svg")
		button_eraser.icon = load("res://addons/simplegrasstextured/images/sgt_icon_eraser_dark.svg")
		_airbrush_options.icon = load("res://addons/simplegrasstextured/images/sgt_icon_arrow_up_dark.svg")
		_pencil_options.icon = load("res://addons/simplegrasstextured/images/sgt_icon_arrow_up_dark.svg")
		_eraser_options.icon = load("res://addons/simplegrasstextured/images/sgt_icon_arrow_up_dark.svg")
		%IconSlope.icon = load("res://addons/simplegrasstextured/images/sgt_icon_slope_dark.svg")
		%IconRadius.icon = load("res://addons/simplegrasstextured/images/sgt_icon_radius_dark.svg")
		%IconDensity.icon = load("res://addons/simplegrasstextured/images/sgt_icon_density_dark.svg")
		%IconDistance.icon = load("res://addons/simplegrasstextured/images/sgt_icon_distance_dark.svg")
	if _button_more != null:
		_button_more.icon = get_theme_icon(&"GuiTabMenuHl", &"EditorIcons")
	# Test that the icons size matches with editor UI scale
	var _ed_scale := 1.0
	var es: int = EditorInterface.get_editor_settings().get_setting("interface/editor/display_scale")
	if es == 7:
		_ed_scale = EditorInterface.get_editor_settings().get_setting("interface/editor/custom_display_scale")
	else:
		_ed_scale = [1.0, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0][clamp(es, 0, 6)]
	if load("res://addons/simplegrasstextured/images/sgt_icon_density.svg").get_width() != roundi(16 * _ed_scale):
		$TimerReimportIcons.start()


func _on_panel_container_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var win = load("res://addons/simplegrasstextured/gui/about.tscn").instantiate()
			get_window().add_child(win)
			win.popup_centered()


func _on_icon_slope_pressed() -> void:
	edit_slope_range.set_value_min(0)
	edit_slope_range.set_value_max(45)


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


func _on_timer_reimport_icons_timeout() -> void:
	if EditorInterface.get_resource_filesystem().is_scanning():
		return
	$TimerReimportIcons.stop()
	EditorInterface.get_resource_filesystem().reimport_files([
	"res://addons/simplegrasstextured/sgt_icon.svg",
	"res://addons/simplegrasstextured/sgt_icon_48.svg",
	"res://addons/simplegrasstextured/images/sgt_icon_density.svg",
	"res://addons/simplegrasstextured/images/sgt_icon_distance.svg",
	"res://addons/simplegrasstextured/images/sgt_icon_radius.svg",
	"res://addons/simplegrasstextured/images/sgt_icon_slope.svg",
	"res://addons/simplegrasstextured/images/sgt_icon_airbrush.svg",
	"res://addons/simplegrasstextured/images/sgt_icon_pen.svg",
	"res://addons/simplegrasstextured/images/sgt_icon_eraser.svg"
	])


func _on_button_tool_gui_input(event: InputEvent, tool: Button, button_options: MenuButton) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			button_options.get_popup().popup(Rect2(tool.global_position + Vector2(tool.size.x, 0), Vector2.ZERO))
