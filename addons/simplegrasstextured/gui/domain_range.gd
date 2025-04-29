# domain_range.gd
# This file is part of: SimpleGrassTextured
# Copyright (c) 2025 IcterusGames
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

signal value_changed(value_min: float, value_max: float)

@export var range_min: float = 0.0
@export var range_max: float = 180.0
@export var step: float = 1.0
@export var value_min: float = 0.0 : set = set_value_min
@export var value_max: float = 45.0 : set = set_value_max

var _ed_scale: float = 1.0
var _slider_area := Rect2()
var _slider_range := Rect2()
var _grabber_min_pos := Vector2.ZERO
var _grabber_max_pos := Vector2.ZERO
var _is_grabbing_min_grab := false
var _is_grabbing_max_grab := false
var _is_grabbing_min_value := false
var _is_grabbing_max_value := false
var _is_editing_min := false
var _is_editing_max := false
var _mouse_over := false
var _mouse_click_pos := Vector2.ONE * 100000
var _mouse_click_rel := Vector2.ZERO
var _mouse_click_value := 0.0
var _mouse_over_grabber_min := false
var _mouse_over_grabber_max := false

@onready var _line_edit: LineEdit = $LineEdit


func _ready() -> void:
	theme_changed.connect(_on_theme_changed)
	_on_theme_changed()
	_update_tooltip()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER_SELF:
		_mouse_over = true
		queue_redraw()
	if what == NOTIFICATION_MOUSE_EXIT_SELF:
		_mouse_over = false
		_mouse_over_grabber_min = false
		_mouse_over_grabber_max = false
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_over_grabber_min = false
		_mouse_over_grabber_max = false
		if _is_grabbing_max_value:
			if event.position.distance_to(_mouse_click_pos) > 8 * _ed_scale:
				_mouse_click_pos = Vector2.ONE * 100000
				set_value_max(value_max + event.screen_relative.x * step)
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif _is_grabbing_min_value:
			if event.position.distance_to(_mouse_click_pos) > 8 * _ed_scale:
				_mouse_click_pos = Vector2.ONE * 100000
				set_value_min(value_min + event.screen_relative.x * step)
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif _is_grabbing_max_grab:
			_mouse_click_pos = Vector2.ONE * 100000
			set_value_max((event.position.x - _mouse_click_rel.x - _slider_area.position.x) / _slider_area.size.x * range_max)
		elif _is_grabbing_min_grab:
			_mouse_click_pos = Vector2.ONE * 100000
			set_value_min((event.position.x - _mouse_click_rel.x - _slider_area.position.x) / _slider_area.size.x * range_max)
		if event.position.distance_to(_grabber_max_pos) <= 8 * _ed_scale:
			_mouse_over_grabber_max = true
		if event.position.distance_to(_grabber_min_pos) <= 8 * _ed_scale:
			_mouse_over_grabber_min = true
		queue_redraw()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_click_pos = event.position
				if (event.position.distance_to(_grabber_min_pos) <= 8 * _ed_scale and
				event.position.distance_to(_grabber_max_pos) <= 8 * _ed_scale):
					if event.position.x < (_grabber_min_pos.x + _grabber_max_pos.x) / 2:
						_is_grabbing_min_grab = true
						_mouse_click_rel = event.position - _grabber_min_pos
						_mouse_click_value = value_min
					else:
						_is_grabbing_max_grab = true
						_mouse_click_rel = event.position - _grabber_max_pos
						_mouse_click_value = value_max
				elif event.position.distance_to(_grabber_min_pos) <= 8 * _ed_scale:
					_is_grabbing_min_grab = true
					_mouse_click_rel = event.position - _grabber_min_pos
					_mouse_click_value = value_min
				elif event.position.distance_to(_grabber_max_pos) <= 8 * _ed_scale:
					_is_grabbing_max_grab = true
					_mouse_click_rel = event.position - _grabber_max_pos
					_mouse_click_value = value_max
				elif event.position.x < size.x / 2:
					_is_grabbing_min_value = true
					_mouse_click_value = value_min
				else:
					_is_grabbing_max_value = true
					_mouse_click_value = value_max
			else: # Mouse left released
				if _mouse_click_pos.distance_to(event.position) <= 8 * _ed_scale:
					_grab_end()
					if event.position.x < size.x / 2:
						_line_edit.text = str(value_min)
						_is_editing_min = true
						_is_editing_max = false
					else:
						_line_edit.text = str(value_max)
						_is_editing_min = false
						_is_editing_max = true
					_line_edit.visible = true
					_line_edit.select()
					_line_edit.grab_focus()
				elif _is_grabbing_max_grab or _is_grabbing_max_value:
					_grab_end()
					queue_redraw()
				elif _is_grabbing_min_grab or _is_grabbing_min_value:
					_grab_end()
					queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if _is_grabbing_max_grab or _is_grabbing_max_value:
					_grab_end()
					set_value_max(_mouse_click_value)
				elif _is_grabbing_min_grab or _is_grabbing_min_value:
					_grab_end()
					set_value_min(_mouse_click_value)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			if event.pressed:
				if event.position.x < size.x / 2:
					set_value_min(value_min + step)
				else:
					set_value_max(value_max + step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			if event.pressed:
				if event.position.x < size.x / 2:
					set_value_min(value_min - step)
				else:
					set_value_max(value_max - step)


func _draw() -> void:
	var sb := get_theme_stylebox(&"normal", &"LineEdit")
	var font := get_theme_font(&"font", &"LineEdit")
	var font_size := get_theme_font_size(&"font_size", &"LineEdit")
	var label_min := "%0.0f" % value_min
	var label_max := "%0.0f" % value_max
	var label_w_min := font.get_string_size(label_min, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var label_w_max := font.get_string_size(label_max, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var label_y := (size.y - font.get_height(font_size)) / 2.0 + font.get_ascent(font_size)
	var color := get_theme_color(&"font_color", &"LineEdit")
	
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	if has_focus():
		var sb_focus = get_theme_stylebox(&"focus", &"LineEdit")
		draw_style_box(sb_focus, Rect2(Vector2(), size))
	
	color.a = 0.9
	draw_line(Vector2(size.x / 2.0, label_y - 10.0 * _ed_scale), Vector2(size.x / 2.0, label_y), color, max(1.0, _ed_scale))
	
	draw_string(font, Vector2(size.x * 0.25 - label_w_min / 2.0, label_y), label_min, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	draw_string(font, Vector2(size.x * 0.75 - label_w_max / 2.0, label_y), label_max, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	
	_slider_area = Rect2(_ed_scale * 6.0, size.y - _ed_scale * 5.0, size.x - _ed_scale * 12.0, _ed_scale * 2.0)
	color.a = 0.2
	draw_rect(_slider_area, color)
	
	_slider_range = _slider_area
	_slider_range.size.x *= (value_max - value_min) / (range_max - range_min)
	_slider_range.position.x += value_min / (range_max - range_min) * _slider_area.size.x
	color.a = 0.45
	draw_rect(_slider_range, color)
	
	_grabber_min_pos = _slider_range.position
	_grabber_max_pos = _slider_range.position + Vector2(_slider_range.size.x, 0)
	
	color.a = 0.9
	var tex: Texture2D = null
	if not _is_grabbing_max_grab:
		if _mouse_over_grabber_min or _is_grabbing_min_grab:
			tex = get_theme_icon(&"grabber_highlight", &"HSlider")
		elif _mouse_over and not _mouse_over_grabber_max:
			tex = get_theme_icon(&"grabber", &"HSlider")
	if tex:
		draw_texture(tex, (_grabber_min_pos - tex.get_size() / 2.0) + Vector2.DOWN)
	else:
		draw_rect(Rect2(_grabber_min_pos.x - 2 * _ed_scale, _grabber_min_pos.y - 1 * _ed_scale, 4 * _ed_scale, 4 * _ed_scale), color)
	
	tex = null
	if not _is_grabbing_min_grab:
		if _mouse_over_grabber_max or _is_grabbing_max_grab:
			tex = get_theme_icon(&"grabber_highlight", &"HSlider")
		elif _mouse_over and not _mouse_over_grabber_min:
			tex = get_theme_icon(&"grabber", &"HSlider")
	if tex:
		draw_texture(tex, (_grabber_max_pos - tex.get_size() / 2.0) + Vector2.DOWN)
	else:
		draw_rect(Rect2(_grabber_max_pos.x - 2 * _ed_scale, _grabber_max_pos.y - 1 * _ed_scale, 4 * _ed_scale, 4 * _ed_scale), color)


func set_value(v_min: float, v_max: float) -> void:
	v_min = max(min(v_min, v_max), range_min)
	v_max = min(max(v_min, v_max), range_max)
	if v_min != value_min or v_max != value_max:
		value_min = v_min
		value_max = v_max
		value_changed.emit(value_min, value_max)
		_update_tooltip()
		queue_redraw()


func set_value_min(value: float) -> void:
	value = clampf(snappedf(value, step), range_min, value_max)
	if value != value_min:
		value_min = value
		value_changed.emit(value_min, value_max)
		_update_tooltip()
		queue_redraw()


func set_value_max(value: float) -> void:
	value = clampf(snappedf(value, step), value_min, range_max)
	if value != value_max:
		value_max = value
		value_changed.emit(value_min, value_max)
		_update_tooltip()
		queue_redraw()


func _update_tooltip() -> void:
	tooltip_text = "Slope to avoid:\n"
	tooltip_text += "Min: %0.*f°\n" %[step_decimals(step), value_min]
	tooltip_text += "Max: %0.*f°\n" %[step_decimals(step), value_max]


func _grab_end() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _is_grabbing_max_value:
		Input.warp_mouse(_grabber_max_pos + global_position)
	elif _is_grabbing_min_value:
		Input.warp_mouse(_grabber_min_pos + global_position)
	_is_grabbing_min_grab = false
	_is_grabbing_max_grab = false
	_is_grabbing_min_value = false
	_is_grabbing_max_value = false


func _on_theme_changed() -> void:
	var es: int = EditorInterface.get_editor_settings().get_setting("interface/editor/display_scale")
	if es == 7:
		_ed_scale = EditorInterface.get_editor_settings().get_setting("interface/editor/custom_display_scale")
	else:
		_ed_scale = [1.0, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0][clamp(es, 0, 6)]
	_line_edit.caret_blink = EditorInterface.get_editor_settings().get_setting("text_editor/appearance/caret/caret_blink")


func _on_line_edit_text_submitted(new_text: String) -> void:
	var value := range_min
	var expression = Expression.new()
	if expression.parse(new_text) == OK:
		var result = expression.execute()
		if not expression.has_execute_failed() and (typeof(result) == TYPE_FLOAT or typeof(result) == TYPE_INT):
			value = result
	if _is_editing_min:
		set_value_min(value)
	elif _is_editing_max:
		set_value_max(value)
	_is_editing_min = false
	_is_editing_max = false
	_line_edit.visible = false
	grab_focus()


func _on_line_edit_focus_exited() -> void:
	_line_edit.visible = false


func _on_line_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			_line_edit.visible = false
			grab_focus()
