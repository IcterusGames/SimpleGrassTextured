# sgt_inspector.gd
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

extends EditorInspectorPlugin


func _can_handle(object: Object) -> bool:
	if object != null:
		if object.has_meta("SimpleGrassTextured"):
			return true
	return false


func _parse_category(object: Object, category: String):
	if category != "grass.gd":
		return
	var hbox = HBoxContainer.new()
	var label := RichTextLabel.new()
	var button := Button.new()
	label.fit_content = true
	label.bbcode_enabled = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "[b]by IcterusGames:[/b]"
	button.text = "About"
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_button_about_pressed.bind(button))
	hbox.add_child(label)
	hbox.add_child(button)
	add_custom_control(hbox)


func _on_button_about_pressed(button :Button):
	var win = load("res://addons/simplegrasstextured/gui/about.tscn").instantiate()
	button.get_window().add_child(win)
	win.popup_centered()
