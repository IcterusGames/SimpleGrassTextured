# grass.gd
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
extends MultiMeshInstance3D

@export var mesh : Mesh = null : set = _on_set_mesh
@export_color_no_alpha var albedo := Color.WHITE : set = _on_set_albedo
@export var texture_albedo : Texture = load("res://addons/simplegrasstextured/textures/grassbushcc008.png") : set = _on_set_texture_albedo
@export_group("Material parameters")
@export var texture_frames : Vector2i = Vector2i(1, 1) : set = _on_set_texture_frames;
@export_range(0.0, 1.0) var alpha_scissor_threshold := 0.5 : set = _on_set_alpha_scissor_threshold
@export_enum("Lambert", "Normal grass", "Unshaded") var light_mode := 1 : set = _on_set_light_mode
@export_subgroup("Normal")
@export var texture_normal : Texture = null : set = _on_set_texture_normal
@export_range(-16.0, 16.0) var normal_scale := 1.0 : set = _on_set_normal_scale
@export_subgroup("Metallic")
@export var texture_metallic : Texture = null : set = _on_set_texture_metallic
@export_enum("Red","Green","Blue","Alpha","Gray") var metallic_texture_channel : int = 0 : set = _on_set_metallic_texture_channel
@export_range(0.0, 1.0) var metallic := 0.0 : set = _on_set_metallic
@export_range(0.0, 1.0) var specular := 0.5 : set = _on_set_specular
@export_subgroup("Roughness")
@export var texture_roughness : Texture = null : set = _on_set_texture_roughness
@export_enum("Red","Green","Blue","Alpha","Gray") var roughness_texture_channel : int = 0 : set = _on_set_roughness_texture_channel
@export_range(0.0, 1.0) var roughness := 1.0 : set = _on_set_roughness
@export_group("")
@export var scale_h := 1.0 : set = _on_set_scale_h
@export var scale_w := 1.0 : set = _on_set_scale_w
@export var scale_var := -0.25 : set = _on_set_scale_var
@export_range(0.0, 1.0) var grass_strength := 0.55 : set = _on_set_grass_strength
@export var interactive : bool = true : set = _on_set_interactive
@export var interactive_level_xz : float = 3.0 : set = _on_set_instactive_level_xz
@export var interactive_level_y : float = 0.3 : set = _on_set_instactive_level_y
@export_group("Optimization")
@export var optimization_by_distance := false : set = _on_set_optimization_by_distance
@export var optimization_level := 7.0 : set = _on_set_optimization_level
@export var optimization_dist_min := 10.0 : set = _on_set_optimization_dist_min
@export var optimization_dist_max := 50.0 : set = _on_set_optimization_dist_max
@export_group("Height Map Data")
@export var baked_height_map : Image = null

var sgt_radius := 2.0
var sgt_density := 25
var sgt_scale := 1.0
var sgt_rotation := 0.0
var sgt_rotation_rand := 1.0
var sgt_dist_min := 0.25
var sgt_follow_normal := false

var temp_dist_min := 0.0

# Deprecated vars:
var player_pos := Vector3(1000000, 1000000, 1000000) : set = _on_set_player_pos
var player_radius := 0.5 : set = _on_set_player_radius
var wind_dir := Vector3.RIGHT : set = _on_set_wind_dir
var wind_strength := 0.15 : set = _on_set_wind_strength
var wind_turbulence := 1.0 : set = _on_set_wind_turbulence
var wind_pattern : Texture = null : set = _on_set_wind_pattern

var _default_mesh : Mesh = null
var _buffer_add : Array[Transform3D] = []
var _material := load("res://addons/simplegrasstextured/materials/grass.material").duplicate() as ShaderMaterial
var _force_update_multimesh := false
var _properties = []
var _node_height_map = null
var _singleton = null

var _wrng_deprec_playerpos = true
var _wrng_deprec_playerrad = true
var _wrng_deprec_windir = true
var _wrng_deprec_windstrng = true
var _wrng_deprec_windturb = true
var _wrng_deprec_windpatt = true


func _init():
	_default_mesh = _build_default_mesh()
	if Engine.is_editor_hint():
		for var_i in get_property_list():
			if not var_i.name.begins_with("sgt_"):
				continue
			_properties.append({
				"name": var_i.name,
				"type": var_i.type,
				"usage": PROPERTY_USAGE_NO_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
			})


func _ready():
	if Engine.is_editor_hint():
		set_process(true)
	else:
		set_process(false)
	_singleton = get_node("/root/SimpleGrass")
	if not has_meta("SimpleGrassTextured"):
		# Update for previous version, 1.0.2 needs vertex color
		set_meta("SimpleGrassTextured", "1.0.2")
		_force_update_multimesh = true
		if multimesh != null:
			if mesh != null:
				multimesh.mesh = mesh
			else:
				multimesh.mesh = _default_mesh
	else:
		if get_meta("SimpleGrassTextured") == "1.0.2":
			# New default mesh update tangents
			set_meta("SimpleGrassTextured", "2.0.3")
			_force_update_multimesh = true
			if multimesh != null:
				if mesh != null:
					multimesh.mesh = mesh
				else:
					multimesh.mesh = _default_mesh
	if multimesh == null:
		multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
	if multimesh.mesh == null:
		if mesh != null:
			multimesh.mesh = mesh
		else:
			multimesh.mesh = _default_mesh
	if light_mode == 2:
		_material = load("res://addons/simplegrasstextured/materials/grass_unshaded.material").duplicate() as ShaderMaterial
	for isur in range(multimesh.mesh.get_surface_count()):
		multimesh.mesh.surface_set_material(isur, _material)
	update_all_material()


func update_all_material():
	_on_set_albedo(albedo)
	_on_set_texture_albedo(texture_albedo)
	_on_set_alpha_scissor_threshold(alpha_scissor_threshold)
	_on_set_light_mode(light_mode)
	_on_set_texture_normal(texture_normal)
	_on_set_normal_scale(normal_scale)
	_on_set_texture_metallic(texture_metallic)
	_on_set_metallic_texture_channel(metallic_texture_channel)
	_on_set_metallic(metallic)
	_on_set_specular(specular)
	_on_set_texture_roughness(texture_roughness)
	_on_set_roughness_texture_channel(roughness_texture_channel)
	_on_set_roughness(roughness)
	_on_set_scale_h(scale_h)
	_on_set_scale_w(scale_w)
	_on_set_scale_var(scale_var)
	_on_set_grass_strength(grass_strength)
	_on_set_interactive(interactive)
	_on_set_instactive_level_xz(interactive_level_xz)
	_on_set_instactive_level_y(interactive_level_y)
	_on_set_optimization_by_distance(optimization_by_distance)
	_on_set_optimization_level(optimization_level)
	_on_set_optimization_dist_min(optimization_dist_min)
	_on_set_optimization_dist_max(optimization_dist_max)


func _enter_tree():
	if interactive:
		_update_height_map.call_deferred()


func _exit_tree():
	if _node_height_map:
		_node_height_map.queue_free()
		_node_height_map = null


func _process(_delta : float):
	if _buffer_add.size() != 0 or _force_update_multimesh:
		_force_update_multimesh = false
		_update_multimesh()


func _get_property_list() -> Array:
	if _properties == null:
		return []
	return _properties


func eval_grass_transform(pos : Vector3, normal : Vector3, scale : Vector3, rotated : float) -> Transform3D:
	var trans := Transform3D()
	if abs(normal.z) == 1:
		trans.basis.x = Vector3(1,0,0)
		trans.basis.y = Vector3(0,0,normal.z)
		trans.basis.z = Vector3(0,normal.z,0)
		trans.basis = trans.basis.orthonormalized()
	else:
		trans.basis.y = normal
		trans.basis.x = normal.cross(trans.basis.z)
		trans.basis.z = trans.basis.x.cross(normal)
		trans.basis = trans.basis.orthonormalized()
	trans = trans.rotated_local(Vector3.UP, rotated)
	trans = trans.scaled(scale)
	trans = trans.translated(pos)
	return trans


func add_grass(pos : Vector3, normal : Vector3, scale : Vector3, rotated : float):
	var trans := eval_grass_transform(pos, normal, scale, rotated)
	if sgt_dist_min > 0:
		for trans_prev in _buffer_add:
			if trans.origin.distance_to(trans_prev.origin) <= sgt_dist_min:
				return
	_buffer_add.append(trans)


func add_grass_batch(transforms : Array):
	var distmin = temp_dist_min
	if temp_dist_min == 0:
		distmin = sgt_dist_min
	if _buffer_add.size() > 0 and distmin > 0:
		for trans_prev in _buffer_add:
			for trans in transforms:
				if trans.origin.distance_to(trans_prev.origin) <= distmin:
					transforms.erase(trans)
					break
	_buffer_add.append_array(transforms)


func erase(pos : Vector3, radius : float):
	var multi_new := MultiMesh.new()
	var array : Array[Transform3D] = []
	multi_new.transform_format = MultiMesh.TRANSFORM_3D
	if mesh != null:
		multi_new.mesh = mesh
	else:
		multi_new.mesh = _default_mesh
	for i in range(multimesh.instance_count):
		var trans := multimesh.get_instance_transform(i)
		if trans.origin.distance_to(pos) > radius:
			array.append(trans)
	multi_new.instance_count = array.size()
	for i in range(array.size()):
		multi_new.set_instance_transform(i, array[i])
	multimesh = multi_new
	if _material != null:
		for isur in range(multimesh.mesh.get_surface_count()):
			multimesh.mesh.surface_set_material(isur, _material)
	if Engine.is_editor_hint():
		baked_height_map = null
		custom_aabb.position = Vector3.ZERO
		custom_aabb.end = Vector3.ZERO


func auto_center_position(editor_interface):
	var aabb : AABB = multimesh.get_aabb()
	var center : Vector3 = global_position + aabb.position + (aabb.size / 2)
	var align : Vector3 = global_position - center
	if center == global_position:
		return
	global_position = center
	var multi_new := MultiMesh.new()
	multi_new.transform_format = MultiMesh.TRANSFORM_3D
	if mesh != null:
		multi_new.mesh = mesh
	else:
		multi_new.mesh = _default_mesh
	multi_new.instance_count = multimesh.instance_count
	for i in range(multimesh.instance_count):
		var trans := multimesh.get_instance_transform(i)
		trans.origin += align
		multi_new.set_instance_transform(i, trans)
	multimesh = multi_new
	if _material != null:
		for isur in range(multimesh.mesh.get_surface_count()):
			multimesh.mesh.surface_set_material(isur, _material)
	if Engine.is_editor_hint():
		if baked_height_map != null:
			baked_height_map = null
			bake_height_map(editor_interface)
		custom_aabb.position = Vector3.ZERO
		custom_aabb.end = Vector3.ZERO
	else:
		baked_height_map = null


func recalculate_custom_aabb():
	var start := Vector3.ONE * 0x7FFFFFFF
	var end := start * -1
	var mesh_end := multimesh.mesh.get_aabb().end * Vector3(scale_w, scale_h, scale_w)
	for i in range(multimesh.instance_count):
		var trans := multimesh.get_instance_transform(i)
		var point : Vector3 = trans * mesh_end
		if point.x < start.x: start.x = point.x
		if point.y < start.y: start.y = point.y
		if point.z < start.z: start.z = point.z
		point = trans * mesh_end
		if point.x > end.x: end.x = point.x
		if point.y > end.y: end.y = point.y
		if point.z > end.z: end.z = point.z
	custom_aabb.position = start
	custom_aabb.end = end


func _update_multimesh():
	if multimesh == null:
		return
	var multi_new := MultiMesh.new()
	var count_prev := multimesh.instance_count
	multi_new.transform_format = MultiMesh.TRANSFORM_3D
	if mesh != null:
		multi_new.mesh = mesh
	else:
		multi_new.mesh = _default_mesh
	if _buffer_add.size() > 0 and (sgt_dist_min > 0 or temp_dist_min > 0):
		var pos_min := Vector3(10000000, 10000000, 10000000)
		var pos_max := pos_min * -1
		for trans in _buffer_add:
			if pos_min.x > trans.origin.x: pos_min.x = trans.origin.x
			if pos_min.y > trans.origin.y: pos_min.y = trans.origin.y
			if pos_min.z > trans.origin.z: pos_min.z = trans.origin.z
			if pos_max.x < trans.origin.x: pos_max.x = trans.origin.x
			if pos_max.y < trans.origin.y: pos_max.y = trans.origin.y
			if pos_max.z < trans.origin.z: pos_max.z = trans.origin.z
		pos_min -= Vector3.ONE
		pos_max += Vector3.ONE
		var dist_min := temp_dist_min
		if dist_min == 0:
			dist_min = sgt_dist_min
		for i in range(multimesh.instance_count):
			var trans := multimesh.get_instance_transform(i)
			if trans.origin.x < pos_min.x or trans.origin.x > pos_max.x: continue
			if trans.origin.y < pos_min.y or trans.origin.y > pos_max.y: continue
			if trans.origin.z < pos_min.z or trans.origin.z > pos_max.z: continue
			for trans_add in _buffer_add:
				if trans_add.origin.distance_to(trans.origin) > dist_min:
					continue
				_buffer_add.erase(trans_add)
				break
	multi_new.instance_count = count_prev + _buffer_add.size()
	for i in range(multimesh.instance_count):
		multi_new.set_instance_transform(i, multimesh.get_instance_transform(i))
	for i in range(_buffer_add.size()):
		multi_new.set_instance_transform(i + count_prev, _buffer_add[i])
	multimesh = multi_new
	if _material != null:
		for isur in range(multimesh.mesh.get_surface_count()):
			multimesh.mesh.surface_set_material(isur, _material)
	_buffer_add.clear()
	temp_dist_min = 0
	if Engine.is_editor_hint():
		baked_height_map = null
		custom_aabb.position = Vector3.ZERO
		custom_aabb.end = Vector3.ZERO


func _build_default_mesh() -> Mesh:
	var array_mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var index := PackedInt32Array()
	
	vertices.push_back(Vector3(-0.5, 1, 0))
	vertices.push_back(Vector3(0.5, 0, 0))
	vertices.push_back(Vector3(-0.5, 0, 0))
	vertices.push_back(Vector3(0.5, 1, 0))
	vertices.push_back(Vector3(0, 1, -0.5))
	vertices.push_back(Vector3(0, 0, 0.5))
	vertices.push_back(Vector3(0, 0, -0.5))
	vertices.push_back(Vector3(0, 1, 0.5))
	normals.push_back(Vector3(0, 0, 1))
	normals.push_back(Vector3(0, 0, 1))
	normals.push_back(Vector3(0, 0, 1))
	normals.push_back(Vector3(0, 0, 1))
	normals.push_back(Vector3(-1, 0, 0))
	normals.push_back(Vector3(-1, 0, 0))
	normals.push_back(Vector3(-1, 0, 0))
	normals.push_back(Vector3(-1, 0, 0))
	for i in range(4):
		tangents.push_back(1)
		tangents.push_back(0)
		tangents.push_back(0)
		tangents.push_back(1)
	for i in range(4):
		tangents.push_back(0)
		tangents.push_back(0)
		tangents.push_back(1)
		tangents.push_back(1)
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(1, 1))
	uvs.push_back(Vector2(0, 1))
	uvs.push_back(Vector2(1, 0))
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(1, 1))
	uvs.push_back(Vector2(0, 1))
	uvs.push_back(Vector2(1, 0))
	colors.push_back(Color(1, 0, 0))
	colors.push_back(Color(0, 0, 0))
	colors.push_back(Color(0, 0, 0))
	colors.push_back(Color(1, 0, 0))
	colors.push_back(Color(1, 0, 0))
	colors.push_back(Color(0, 0, 0))
	colors.push_back(Color(0, 0, 0))
	colors.push_back(Color(1, 0, 0))
	index.push_back(0)
	index.push_back(1)
	index.push_back(2)
	index.push_back(3)
	index.push_back(1)
	index.push_back(0)
	index.push_back(4)
	index.push_back(5)
	index.push_back(6)
	index.push_back(7)
	index.push_back(5)
	index.push_back(4)
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_TANGENT] = tangents
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arrays[ArrayMesh.ARRAY_COLOR] = colors
	arrays[ArrayMesh.ARRAY_INDEX] = index
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh


func _create_height_map_image(local : bool) -> Image:
	var aabb : AABB = multimesh.get_aabb()
	var img_size := Vector2i(
			clamp(snappedi(aabb.size.x * 4, 32), 32, 128),
			clamp(snappedi(aabb.size.z * 4, 32), 32, 128)
	)
	var img := Image.create(img_size.x, img_size.y, false, Image.FORMAT_RGBA8)
	var relx := float(img_size.x) / aabb.size.x
	var relz := float(img_size.y) / aabb.size.z
	
	img.fill(Color(1.0, 1.0, 1.0, 0.0))
	for i in range(multimesh.instance_count):
		var trans : Transform3D = multimesh.get_instance_transform(i)
		trans.origin -= aabb.position
		var x := clampi(int(trans.origin.x * relx), 0, img_size.x)
		var y := clampi(int(trans.origin.z * relz), 0, img_size.y)
		var posy := trans.origin.y + aabb.position.y + 16200.0
		if local:
			posy += global_position.y
		var r := (floorf(posy / 180.0) + 75.0) / 255.0
		var g := (floorf(posy - ((roundf(r * 255.0) - 75.0) * 180.0)) + 75.0) / 255.0
		var b := fmod(absf(posy), 1.0)
		var color := Color(r, g, b, 1.0)
		img.set_pixel(x, y, color)
		for n in range(1, 3):
			if x - n >= 0 and img.get_pixel(x - n, y).a == 0:
				img.set_pixel(x - n, y, color)
				if y - n >= 0 and img.get_pixel(x - n, y - n).a == 0:
					img.set_pixel(x - n, y - n, color)
				if y + n < img_size.y and img.get_pixel(x - n, y + n).a == 0:
					img.set_pixel(x - n, y + n, color)
			if x + n < img_size.x and img.get_pixel(x + n, y).a == 0:
				img.set_pixel(x + n, y, color)
				if y - n >= 0 and img.get_pixel(x + n, y - n).a == 0:
					img.set_pixel(x + n, y - n, color)
				if y + n < img_size.y and img.get_pixel(x + n, y + n).a == 0:
					img.set_pixel(x + n, y + n, color)
			if y - n >= 0 and img.get_pixel(x, y - n).a == 0:
				img.set_pixel(x, y - n, color)
			if y + n < img_size.y and img.get_pixel(x, y + n).a == 0:
				img.set_pixel(x, y + n, color)
	return img


func _local_height_map_to_global(img : Image) -> Image:
	var result : Image = Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	for y in img.get_height():
		for x in img.get_width():
			var color : Color = img.get_pixel(x, y)
			if color.a == 0:
				continue
			var posy : float = (((roundf(color.r * 255.0) - 75.0) * 180.0) + (roundf(color.g * 255.0) - 75.0) + color.b)
			posy += global_position.y
			color.r = (floorf(posy / 180.0) + 75.0) / 255.0
			color.g = (floorf(posy - ((roundf(color.r * 255.0) - 75.0) * 180.0)) + 75.0) / 255.0
			color.b = fmod(absf(posy), 1.0)
			result.set_pixel(x, y, color)
	return result


func bake_height_map(editor_interface):
	if not Engine.is_editor_hint():
		return null
	await get_tree().process_frame
	var _dummy = multimesh.buffer.size()
	await get_tree().process_frame
	var img : Image = _create_height_map_image(false)
	baked_height_map = img


func clear_all(editor_interface = null):
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	if Engine.is_editor_hint():
		if baked_height_map != null:
			baked_height_map = null
			bake_height_map(editor_interface)
		custom_aabb.position = Vector3.ZERO
		custom_aabb.end = Vector3.ZERO


func _update_height_map():
	if Engine.is_editor_hint():
		return
	
	var img : Image = null
	
	if baked_height_map == null:
		await get_tree().process_frame
		var _dummy = multimesh.buffer.size()
		await get_tree().process_frame
		img = _create_height_map_image(true)
	else:
		img = _local_height_map_to_global(baked_height_map)
	
	var aabb : AABB = multimesh.get_aabb()
	var texture := ImageTexture.create_from_image(img)
	if _node_height_map != null:
		_node_height_map.queue_free()
	_node_height_map = MeshInstance3D.new()
	_node_height_map.mesh = PlaneMesh.new()
	_node_height_map.mesh.size = Vector2(aabb.size.x, aabb.size.z)
	var mat = load("res://addons/simplegrasstextured/materials/position.material").duplicate(true)
	mat.set_shader_parameter("texture_albedo", texture)
	_node_height_map.material_override = mat
	_singleton._height_view.add_child(_node_height_map)
	var align := Vector3(
		(aabb.position.x + (aabb.size.x / 2.0)),
		0,
		(aabb.position.z + (aabb.size.z / 2.0))
	)
	_node_height_map.global_position = global_position + align
	_node_height_map.visible = visible


func _on_set_mesh(value : Mesh):
	mesh = value
	if _material != null:
		if mesh != null:
			_material.set_shader_parameter("grass_size_y", mesh.get_aabb().size.y)
		else:
			_material.set_shader_parameter("grass_size_y", 1.0)
	if Engine.is_editor_hint() and is_inside_tree():
		_update_multimesh()


func _on_set_albedo(value : Color):
	albedo = value;
	if _material != null:
		_material.set_shader_parameter("albedo", albedo)


func _on_set_texture_albedo(value : Texture):
	texture_albedo = value
	if _material != null:
		_material.set_shader_parameter("texture_albedo", texture_albedo)


func _on_set_texture_frames(value : Vector2i):
	texture_frames = value
	if texture_frames.x <= 0:
		texture_frames.x = 1
	if texture_frames.y <= 0:
		texture_frames.y = 1
	if _material != null:
		_material.set_shader_parameter("texture_frames", Vector2(texture_frames.x, texture_frames.y))


func _on_set_light_mode(value : int):
	light_mode = value
	if _material == null:
		return
	if light_mode == 2:
		if _material.get_shader().resource_path != "res://addons/simplegrasstextured/shaders/grass_unshaded.gdshader":
			_material = load("res://addons/simplegrasstextured/materials/grass_unshaded.material").duplicate() as ShaderMaterial
			update_all_material()
			return
	else:
		if _material.get_shader().resource_path != "res://addons/simplegrasstextured/shaders/grass.gdshader":
			_material = load("res://addons/simplegrasstextured/materials/grass.material").duplicate() as ShaderMaterial
			update_all_material()
			return
	if _material != null:
		_material.set_shader_parameter("light_mode", light_mode)
		if multimesh.mesh != null:
			for isur in range(multimesh.mesh.get_surface_count()):
				multimesh.mesh.surface_set_material(isur, _material)


func _on_set_texture_normal(value : Texture):
	texture_normal = value
	if _material != null:
		_material.set_shader_parameter("texture_normal", texture_normal)


func _on_set_normal_scale(value : float):
	normal_scale = value
	if _material != null:
		_material.set_shader_parameter("normal_scale", normal_scale)


func _on_set_texture_metallic(value : Texture):
	texture_metallic = value
	if _material != null:
		_material.set_shader_parameter("texture_metallic", texture_metallic)


func _on_set_metallic_texture_channel(value : int):
	metallic_texture_channel = value
	if _material != null:
		var channel : Vector4
		if value == 0:
			channel = Vector4(1,0,0,0)
		elif value == 1:
			channel = Vector4(0,1,0,0)
		elif value == 2:
			channel = Vector4(0,0,1,0)
		elif value == 3:
			channel = Vector4(0,0,0,1)
		elif value == 4:
			channel = Vector4(1,1,1,1)
		_material.set_shader_parameter("metallic_texture_channel", channel)


func _on_set_metallic(value : float):
	metallic = value
	if _material != null:
		_material.set_shader_parameter("metallic", metallic)


func _on_set_specular(value : float):
	specular = value
	if _material != null:
		_material.set_shader_parameter("specular", specular)


func  _on_set_texture_roughness(value : Texture):
	texture_roughness = value
	if _material != null:
		_material.set_shader_parameter("texture_roughness", texture_roughness)


func  _on_set_roughness_texture_channel(value : int):
	roughness_texture_channel = value
	if _material != null:
		var channel : Vector4
		if value == 0:
			channel = Vector4(1,0,0,0)
		elif value == 1:
			channel = Vector4(0,1,0,0)
		elif value == 2:
			channel = Vector4(0,0,1,0)
		elif value == 3:
			channel = Vector4(0,0,0,1)
		elif value == 4:
			channel = Vector4(1,1,1,1)
		_material.set_shader_parameter("roughness_texture_channel", channel)


func  _on_set_roughness(value : float):
	roughness = value
	if _material != null:
		_material.set_shader_parameter("roughness", roughness)


func _on_set_alpha_scissor_threshold(value : float):
	alpha_scissor_threshold = value
	if _material != null:
		_material.set_shader_parameter("alpha_scissor_threshold", alpha_scissor_threshold)


func _on_set_scale_h(value : float):
	scale_h = value
	if _material != null:
		_material.set_shader_parameter("scale_h", scale_h)


func _on_set_scale_w(value : float):
	scale_w = value
	if _material != null:
		_material.set_shader_parameter("scale_w", scale_w)


func _on_set_scale_var(value : float):
	scale_var = value
	if _material != null:
		_material.set_shader_parameter("scale_var", scale_var)


func _on_set_grass_strength(value : float):
	grass_strength = value
	if _material != null:
		_material.set_shader_parameter("grass_strength", grass_strength)


func _on_set_interactive(value : bool):
	if interactive == value:
		return
	interactive = value
	if Engine.is_editor_hint():
		return
	if interactive:
		_update_height_map()
	else:
		if _node_height_map != null:
			_node_height_map.queue_free()
			_node_height_map = null
	if _material != null:
		_material.set_shader_parameter("interactive_mode", interactive)


func _on_set_instactive_level_xz(value : float):
	interactive_level_xz = value
	if _material != null:
		_material.set_shader_parameter("interactive_level_xz", interactive_level_xz)


func _on_set_instactive_level_y(value : float):
	interactive_level_y = value
	if _material != null:
		_material.set_shader_parameter("interactive_level_y", interactive_level_y)


func _on_set_optimization_by_distance(value : bool):
	optimization_by_distance = value
	if _material != null:
		_material.set_shader_parameter("optimization_by_distance", optimization_by_distance)


func _on_set_optimization_level(value : float):
	optimization_level = value
	if _material != null:
		_material.set_shader_parameter("optimization_level", optimization_level)


func _on_set_optimization_dist_min(value : float):
	optimization_dist_min = value
	if _material != null:
		_material.set_shader_parameter("optimization_dist_min", optimization_dist_min)


func _on_set_optimization_dist_max(value : float):
	optimization_dist_max = value
	if _material != null:
		_material.set_shader_parameter("optimization_dist_max", optimization_dist_max)


func _on_set_player_pos(value : Vector3):
	player_pos = Vector3(1000000, 1000000, 1000000)
	if value != Vector3(1000000, 1000000, 1000000):
		#_singleton.set_player_position(value)
		if _wrng_deprec_playerpos and (Engine.is_editor_hint() or OS.is_debug_build()):
			_wrng_deprec_playerpos = false
			push_warning("Simple Grass Textured: ("+name+") player_pos parameter is deprecated, use SimpleGrass.set_player_position")


func _on_set_player_radius(value : float):
	player_radius = 0.5
	if _wrng_deprec_playerrad and (Engine.is_editor_hint() or OS.is_debug_build()):
		_wrng_deprec_playerrad = false
		push_warning("Simple Grass Textured: ("+name+") player_radius parameter is deprecated")


func _on_set_wind_dir(value : Vector3):
	wind_dir = Vector3.RIGHT
	#_singleton.wind_direction = value
	if _wrng_deprec_windir and (Engine.is_editor_hint() or OS.is_debug_build()):
		_wrng_deprec_windir = false
		push_warning("Simple Grass Textured: ("+name+") wind_dir parameter is deprecated, use SimpleGrass.wind_direction")


func _on_set_wind_strength(value : float):
	wind_strength = 0.15
	#_singleton.wind_strength = value
	if _wrng_deprec_windstrng and (Engine.is_editor_hint() or OS.is_debug_build()):
		_wrng_deprec_windstrng = false
		push_warning("Simple Grass Textured: ("+name+") wind_strength parameter is deprecated, use SimpleGrass.wind_strength")


func _on_set_wind_turbulence(value : float):
	wind_turbulence = 1.0
	#_singleton.wind_turbulence = value
	if _wrng_deprec_windturb and (Engine.is_editor_hint() or OS.is_debug_build()):
		_wrng_deprec_windturb = false
		push_warning("Simple Grass Textured: ("+name+") wind_turbulence parameter is deprecated, use SimpleGrass.wind_turbulence")


func _on_set_wind_pattern(value : Texture):
	wind_pattern = null
	#RenderingServer.global_shader_parameter_set("sgt_wind_pattern", value)
	if value != null and _wrng_deprec_windpatt and (Engine.is_editor_hint() or OS.is_debug_build()):
		_wrng_deprec_windpatt = false
		push_warning("Simple Grass Textured: ("+name+") wind_pattern parameter is deprecated, use SimpleGrass.set_wind_pattern")
