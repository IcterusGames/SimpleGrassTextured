# toolbar_menu.gd
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
extends MenuButton

enum MENU_ID {
	TOOL_FOLLOW_NORMAL,
	AUTO_CENTER_POSITION,
	CAST_SHADOW,
	BAKE_HEIGHT_MAP,
	GLOBAL_PARAMETERS,
	CLEAR_ALL,
	HELP_ABOUT,
	RECALCULATE_AABB,
}

var _global_parameters = load("res://addons/simplegrasstextured/global_parameters.tscn").instantiate()
var _clear_all_confirmation = load("res://addons/simplegrasstextured/clear_all_confirmation_dialog.tscn").instantiate()
var _grass_selected = null
var _tools_menu : PopupMenu = null
var _editor_interface : EditorInterface = null


func _ready():
	get_window().call_deferred(StringName("add_child"), _global_parameters)
	get_window().call_deferred(StringName("add_child"), _clear_all_confirmation)
	_clear_all_confirmation.confirmed.connect(_on_clear_all_confirmation_dialog_confirmed)
	var popup := get_popup()
	_tools_menu = PopupMenu.new()
	_tools_menu.name = "ToolsMenu"
	_tools_menu.add_check_item("Follow terrain's normal", MENU_ID.TOOL_FOLLOW_NORMAL)
	popup.add_child(_tools_menu)
	popup.clear()
	popup.add_submenu_item("Tools", "ToolsMenu")
	popup.add_separator()
	popup.add_item("Auto center position", MENU_ID.AUTO_CENTER_POSITION)
	popup.add_item("Recalculate custom AABB", MENU_ID.RECALCULATE_AABB)
	popup.add_check_item("Bake height map", MENU_ID.BAKE_HEIGHT_MAP)
	popup.add_check_item("Cast shadow", MENU_ID.CAST_SHADOW)
	popup.add_item("Global parameters", MENU_ID.GLOBAL_PARAMETERS)
	popup.add_separator()
	popup.add_item("Clear all", MENU_ID.CLEAR_ALL)
	popup.add_separator()
	popup.add_item("About SimpleGrassTextured", MENU_ID.HELP_ABOUT)
	popup.id_pressed.connect(_on_sgt_menu_button)
	_tools_menu.id_pressed.connect(_on_sgt_tools_menu_button)
	about_to_popup.connect(_on_about_to_popup)


func set_current_grass(editor_interface : EditorInterface, grass_selected):
	_editor_interface = editor_interface
	_grass_selected = grass_selected
	if grass_selected == null:
		return
	var popup := get_popup()
	if grass_selected.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		popup.set_item_checked(popup.get_item_index(MENU_ID.CAST_SHADOW), false)
	else:
		popup.set_item_checked(popup.get_item_index(MENU_ID.CAST_SHADOW), true)
	popup.set_item_checked(popup.get_item_index(MENU_ID.BAKE_HEIGHT_MAP), _grass_selected.baked_height_map != null)
	_tools_menu.set_item_checked(_tools_menu.get_item_index(MENU_ID.TOOL_FOLLOW_NORMAL), _grass_selected.sgt_follow_normal)


func _on_sgt_menu_button(id : int):
	if _grass_selected == null:
		return
	match id:
		MENU_ID.AUTO_CENTER_POSITION:
			_grass_selected.auto_center_position(_editor_interface)
		MENU_ID.RECALCULATE_AABB:
			_grass_selected.recalculate_custom_aabb()
		MENU_ID.CAST_SHADOW:
			if _grass_selected.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				_grass_selected.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			else:
				_grass_selected.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		MENU_ID.BAKE_HEIGHT_MAP:
			_grass_selected.bake_height_map(_editor_interface)
		MENU_ID.GLOBAL_PARAMETERS:
			_global_parameters.popup_centered()
		MENU_ID.CLEAR_ALL:
			_clear_all_confirmation.popup_centered()
		MENU_ID.HELP_ABOUT:
			var about = get_window().get_node("SimpleGrassTexturedHelpAbout")
			if about != null:
				about.popup_centered()


func _on_sgt_tools_menu_button(id : int):
	if _grass_selected == null:
		return
	match id:
		MENU_ID.TOOL_FOLLOW_NORMAL:
			_tools_menu.set_item_checked(id, not _tools_menu.is_item_checked(id))
			_grass_selected.sgt_follow_normal = _tools_menu.is_item_checked(id)


func _on_about_to_popup():
	set_current_grass(_editor_interface, _grass_selected)


func _on_clear_all_confirmation_dialog_confirmed():
	if _grass_selected == null:
		return
	_grass_selected.clear_all(_editor_interface)

