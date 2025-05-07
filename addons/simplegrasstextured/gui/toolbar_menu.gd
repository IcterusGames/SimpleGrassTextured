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
	TOOL_SHAPE_AIRBRUSH,
	TOOL_SHAPE_PENCIL,
	TOOL_SHAPE_ERASER,
	AUTO_CENTER_POSITION,
	CAST_SHADOW,
	BAKE_HEIGHT_MAP,
	GLOBAL_PARAMETERS,
	CLEAR_ALL,
	HELP_ABOUT,
	RECALCULATE_AABB,
}

enum MENU_SHAPE_ID {
	TOOL_SHAPE_SPHERE,
	TOOL_SHAPE_CYLINDER,
	TOOL_SHAPE_CYLINDER_INF_H,
	TOOL_SHAPE_BOX,
	TOOL_SHAPE_BOX_INF_H,
}

var _plugin: EditorPlugin = null
var _grass_selected = null
var _tools_menu: PopupMenu = null
var _airbrush_shape_menu: PopupMenu = null
var _pencil_shape_menu: PopupMenu = null
var _eraser_shape_menu: PopupMenu = null


func set_plugin(plugin :EditorPlugin) -> void:
	var popup := get_popup()
	_plugin = plugin
	_airbrush_shape_menu = PopupMenu.new()
	_airbrush_shape_menu.name = &"AirbrushShapeMenu"
	_airbrush_shape_menu.add_radio_check_item("Cylinder", MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER)
	_airbrush_shape_menu.add_radio_check_item("Box", MENU_SHAPE_ID.TOOL_SHAPE_BOX)
	_pencil_shape_menu = PopupMenu.new()
	_pencil_shape_menu.name = &"PencilShapeMenu"
	_pencil_shape_menu.add_radio_check_item("Cylinder", MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER)
	_pencil_shape_menu.add_radio_check_item("Box", MENU_SHAPE_ID.TOOL_SHAPE_BOX)
	_eraser_shape_menu = PopupMenu.new()
	_eraser_shape_menu.name = &"EraserShapeMenu"
	_eraser_shape_menu.add_radio_check_item("Sphere", MENU_SHAPE_ID.TOOL_SHAPE_SPHERE)
	_eraser_shape_menu.add_radio_check_item("Cylinder", MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER)
	_eraser_shape_menu.add_radio_check_item("Infinite vertical cylinder", MENU_SHAPE_ID.TOOL_SHAPE_CYLINDER_INF_H)
	_eraser_shape_menu.add_radio_check_item("Box", MENU_SHAPE_ID.TOOL_SHAPE_BOX)
	_eraser_shape_menu.add_radio_check_item("Infinite vertical box", MENU_SHAPE_ID.TOOL_SHAPE_BOX_INF_H)
	_tools_menu = PopupMenu.new()
	_tools_menu.add_child(_airbrush_shape_menu)
	_tools_menu.add_child(_pencil_shape_menu)
	_tools_menu.add_child(_eraser_shape_menu)
	_tools_menu.name = &"ToolsMenu"
	_tools_menu.add_check_item("Follow terrain's normal", MENU_ID.TOOL_FOLLOW_NORMAL)
	_tools_menu.add_submenu_item("Airbrush shape", "AirbrushShapeMenu")
	_tools_menu.add_submenu_item("Pencil shape", "PencilShapeMenu")
	_tools_menu.add_submenu_item("Eraser shape", "EraserShapeMenu")
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
	_airbrush_shape_menu.id_pressed.connect(_on_sgt_shape_menu_pressed.bind("airbrush", _airbrush_shape_menu))
	_pencil_shape_menu.id_pressed.connect(_on_sgt_shape_menu_pressed.bind("pencil", _pencil_shape_menu))
	_eraser_shape_menu.id_pressed.connect(_on_sgt_shape_menu_pressed.bind("eraser", _eraser_shape_menu))
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
	for tool_name in _grass_selected.sgt_tool_shape:
		match tool_name:
			"airbrush":
				_update_shape_menu_from_grass(_airbrush_shape_menu, _grass_selected.sgt_tool_shape[tool_name])
			"pencil":
				_update_shape_menu_from_grass(_pencil_shape_menu, _grass_selected.sgt_tool_shape[tool_name])
			"eraser":
				_update_shape_menu_from_grass(_eraser_shape_menu, _grass_selected.sgt_tool_shape[tool_name])


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
			for child in _grass_selected.get_children():
				if child.has_meta(&"SimpleGrassTexturedRegion"):
					_plugin.get_undo_redo().add_undo_property(child, &"cast_shadow", child.cast_shadow)
			if _grass_selected.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				_grass_selected.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			else:
				_grass_selected.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_plugin.get_undo_redo().add_do_property(_grass_selected, &"cast_shadow", _grass_selected.cast_shadow)
			for child in _grass_selected.get_children():
				if child.has_meta(&"SimpleGrassTexturedRegion"):
					child.cast_shadow = _grass_selected.cast_shadow
					_plugin.get_undo_redo().add_do_property(child, &"cast_shadow", child.cast_shadow)
			_plugin.get_undo_redo().commit_action()
		MENU_ID.BAKE_HEIGHT_MAP:
			_grass_selected.bake_height_map()
		MENU_ID.GLOBAL_PARAMETERS:
			var _global_parameters = load("res://addons/simplegrasstextured/gui/global_parameters.tscn").instantiate()
			get_window().add_child(_global_parameters)
			_global_parameters.popup_centered()
		MENU_ID.CLEAR_ALL:
			var win = load("res://addons/simplegrasstextured/gui/clear_all_confirmation_dialog.tscn").instantiate()
			get_window().add_child(win)
			win.confirmed.connect(_on_clear_all_confirmation_dialog_confirmed)
			win.popup_centered()
		MENU_ID.HELP_ABOUT:
			var win = load("res://addons/simplegrasstextured/gui/about.tscn").instantiate()
			get_window().add_child(win)
			win.popup_centered()


func _on_sgt_tools_menu_button(id :int) -> void:
	if _grass_selected == null:
		return
	match id:
		MENU_ID.TOOL_FOLLOW_NORMAL:
			var idx := _tools_menu.get_item_index(id)
			_tools_menu.set_item_checked(idx, not _tools_menu.is_item_checked(idx))
			_grass_selected.sgt_follow_normal = _tools_menu.is_item_checked(idx)


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
