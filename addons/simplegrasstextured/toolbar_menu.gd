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

var _plugin: EditorPlugin = null
var _grass_selected = null
var _tools_menu :PopupMenu = null


func set_plugin(plugin :EditorPlugin) -> void:
	var popup := get_popup()
	_plugin = plugin
	_tools_menu = PopupMenu.new()
	_tools_menu.name = &"ToolsMenu"
	_tools_menu.add_check_item("Follow terrain's normal", MENU_ID.TOOL_FOLLOW_NORMAL)
	popup.add_child(_tools_menu)
	popup.clear()
	popup.add_submenu_item("Tools", "ToolsMenu")
	popup.add_separator()
	popup.add_item("Auto center position", MENU_ID.AUTO_CENTER_POSITION)
	popup.add_item("Recalculate custom AABB", MENU_ID.RECALCULATE_AABB)
	popup.add_item("Bake height map", MENU_ID.BAKE_HEIGHT_MAP)
	popup.add_check_item("Cast shadow", MENU_ID.CAST_SHADOW)
	popup.add_item("Global parameters", MENU_ID.GLOBAL_PARAMETERS)
	popup.add_separator()
	popup.add_item("Clear all", MENU_ID.CLEAR_ALL)
	popup.add_separator()
	popup.add_item("About SimpleGrassTextured", MENU_ID.HELP_ABOUT)
	popup.id_pressed.connect(_on_sgt_menu_button)
	_tools_menu.id_pressed.connect(_on_sgt_tools_menu_button)
	about_to_popup.connect(_on_about_to_popup)


func set_current_grass(grass_selected) -> void:
	_grass_selected = grass_selected
	if grass_selected == null:
		return
	var popup := get_popup()
	if grass_selected.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		popup.set_item_checked(popup.get_item_index(MENU_ID.CAST_SHADOW), false)
	else:
		popup.set_item_checked(popup.get_item_index(MENU_ID.CAST_SHADOW), true)
	if _grass_selected.baked_height_map != null:
		popup.set_item_text(popup.get_item_index(MENU_ID.BAKE_HEIGHT_MAP), "Bake height map (already baked)")
		popup.set_item_disabled(popup.get_item_index(MENU_ID.BAKE_HEIGHT_MAP), true)
	else:
		popup.set_item_text(popup.get_item_index(MENU_ID.BAKE_HEIGHT_MAP), "Bake height map")
		popup.set_item_disabled(popup.get_item_index(MENU_ID.BAKE_HEIGHT_MAP), false)
	_tools_menu.set_item_checked(_tools_menu.get_item_index(MENU_ID.TOOL_FOLLOW_NORMAL), _grass_selected.sgt_follow_normal)


func _on_sgt_menu_button(id :int) -> void:
	if _grass_selected == null:
		return
	match id:
		MENU_ID.AUTO_CENTER_POSITION:
			_plugin.get_undo_redo().create_action(_grass_selected.name + " Auto Center Position")
			_plugin.get_undo_redo().add_undo_property(_grass_selected, &"baked_height_map", _grass_selected.baked_height_map)
			_plugin.get_undo_redo().add_undo_property(_grass_selected, &"multimesh", _grass_selected.multimesh)
			_plugin.get_undo_redo().add_undo_property(_grass_selected, &"global_position", _grass_selected.global_position)
			_grass_selected.auto_center_position()
			_plugin.get_undo_redo().add_do_property(_grass_selected, &"baked_height_map", _grass_selected.baked_height_map)
			_plugin.get_undo_redo().add_do_property(_grass_selected, &"multimesh", _grass_selected.multimesh)
			_plugin.get_undo_redo().add_do_property(_grass_selected, &"global_position", _grass_selected.global_position)
			_plugin.get_undo_redo().commit_action()
		MENU_ID.RECALCULATE_AABB:
			_plugin.get_undo_redo().create_action(_grass_selected.name + " Recalculate Custom AABB")
			_plugin.get_undo_redo().add_undo_property(_grass_selected, &"custom_aabb", _grass_selected.custom_aabb)
			_grass_selected.recalculate_custom_aabb()
			_plugin.get_undo_redo().add_do_property(_grass_selected, &"custom_aabb", _grass_selected.custom_aabb)
			_plugin.get_undo_redo().commit_action()
		MENU_ID.CAST_SHADOW:
			_plugin.get_undo_redo().create_action(_grass_selected.name + " Toogle Cast Shadow")
			_plugin.get_undo_redo().add_undo_property(_grass_selected, &"cast_shadow", _grass_selected.cast_shadow)
			if _grass_selected.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				_grass_selected.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			else:
				_grass_selected.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_plugin.get_undo_redo().add_do_property(_grass_selected, &"cast_shadow", _grass_selected.cast_shadow)
			_plugin.get_undo_redo().commit_action()
		MENU_ID.BAKE_HEIGHT_MAP:
			_grass_selected.bake_height_map()
		MENU_ID.GLOBAL_PARAMETERS:
			var _global_parameters = load("res://addons/simplegrasstextured/global_parameters.tscn").instantiate()
			get_window().add_child(_global_parameters)
			_global_parameters.popup_centered()
		MENU_ID.CLEAR_ALL:
			var win = load("res://addons/simplegrasstextured/clear_all_confirmation_dialog.tscn").instantiate()
			get_window().add_child(win)
			win.confirmed.connect(_on_clear_all_confirmation_dialog_confirmed)
			win.popup_centered()
		MENU_ID.HELP_ABOUT:
			var win = load("res://addons/simplegrasstextured/about.tscn").instantiate()
			get_window().add_child(win)
			win.popup_centered()


func _on_sgt_tools_menu_button(id :int) -> void:
	if _grass_selected == null:
		return
	match id:
		MENU_ID.TOOL_FOLLOW_NORMAL:
			_tools_menu.set_item_checked(id, not _tools_menu.is_item_checked(id))
			_grass_selected.sgt_follow_normal = _tools_menu.is_item_checked(id)


func _on_about_to_popup() -> void:
	set_current_grass(_grass_selected)


func _on_clear_all_confirmation_dialog_confirmed() -> void:
	if _grass_selected == null:
		return
	_plugin.get_undo_redo().create_action(_grass_selected.name + " Clear All Grass")
	_plugin.get_undo_redo().add_undo_property(_grass_selected, &"baked_height_map", _grass_selected.baked_height_map)
	_plugin.get_undo_redo().add_undo_property(_grass_selected, &"multimesh", _grass_selected.multimesh)
	_grass_selected.clear_all()
	_plugin.get_undo_redo().add_do_property(_grass_selected, &"baked_height_map", _grass_selected.baked_height_map)
	_plugin.get_undo_redo().add_do_property(_grass_selected, &"multimesh", _grass_selected.multimesh)
	_plugin.get_undo_redo().commit_action()
