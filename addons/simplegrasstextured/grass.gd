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
class_name SimpleGrassTextured extends MultiMeshInstance3D
@icon ("icon.png")

@export var mesh : Mesh = null : set = _on_set_mesh
@export var player_pos := Vector3(1000000, 1000000, 1000000) : set = _on_set_player_pos
@export var player_radius := 0.5 : set = _on_set_player_radius
@export_color_no_alpha var albedo := Color.WHITE : set = _on_set_albedo
@export var texture_albedo : Texture = preload("textures/grassbushcc008.png") : set = _on_set_texture_albedo
@export var alpha_scissor_threshold := 0.5 : set = _on_set_alpha_scissor_threshold
@export var scale_h := 1.0 : set = _on_set_scale_h
@export var scale_w := 1.0 : set = _on_set_scale_w
@export var scale_var := -0.25 : set = _on_set_scale_var
@export_range(0.0, 1.0) var grass_strength := 0.8 : set = _on_set_grass_strength
@export var wind_dir := Vector3.RIGHT : set = _on_set_wind_dir
@export var wind_strength := 0.03 : set = _on_set_wind_strength
@export var wind_speed := 1.0 : set = _on_set_wind_speed
@export var optimization_by_distance := false : set = _on_set_optimization_by_distance
@export var optimization_level := 7.0 : set = _on_set_optimization_level

var dist_min : float = 0.0

var _default_mesh : Mesh = null
var _buffer_add : Array[Transform3D] = []
var _material := preload("materials/grass.material").duplicate() as ShaderMaterial


func _init():
	_default_mesh = _build_default_mesh()


func _ready():
	if Engine.is_editor_hint():
		set_process(true)
	else:
		set_process(false)
	if multimesh == null:
		multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
	if multimesh.mesh == null:
		if mesh != null:
			multimesh.mesh = mesh
		else:
			multimesh.mesh = _default_mesh
	for isur in range(multimesh.mesh.get_surface_count()):
		multimesh.mesh.surface_set_material(isur, _material)
	_on_set_player_pos(player_pos)
	_on_set_player_radius(player_radius)
	_on_set_texture_albedo(texture_albedo)
	_on_set_alpha_scissor_threshold(alpha_scissor_threshold)
	_on_set_scale_h(scale_h)
	_on_set_scale_w(scale_w)
	_on_set_scale_var(scale_var)
	_on_set_grass_strength(grass_strength)
	_on_set_wind_dir(wind_dir)
	_on_set_wind_strength(wind_strength)
	_on_set_wind_speed(wind_speed)
	_on_set_optimization_by_distance(optimization_by_distance)
	_on_set_optimization_level(optimization_level)


func _process(_delta : float):
	if _buffer_add.size() == 0:
		return
	_update_multimesh()


func add_grass(pos : Vector3, normal : Vector3, scale : Vector3):
	var trans := Transform3D()
	trans = trans.rotated(Vector3.UP, TAU * randf())
	trans.basis.y = normal
	trans = trans.scaled(scale)
	trans = trans.translated(pos)
	if dist_min > 0:
		for trans_prev in _buffer_add:
			if trans.origin.distance_to(trans_prev.origin) <= dist_min:
				return
	_buffer_add.append(trans)


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
	if _buffer_add.size() > 0 and dist_min > 0:
		for i in range(multimesh.instance_count):
			var trans := multimesh.get_instance_transform(i)
			for trans_add in _buffer_add:
				if trans_add.origin.distance_to(trans.origin) <= dist_min:
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


func _build_default_mesh() -> Mesh:
	var array_mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
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
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(1, 1))
	uvs.push_back(Vector2(0, 1))
	uvs.push_back(Vector2(1, 0))
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(1, 1))
	uvs.push_back(Vector2(0, 1))
	uvs.push_back(Vector2(1, 0))
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
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arrays[ArrayMesh.ARRAY_INDEX] = index
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh


func _on_set_mesh(value : Mesh):
	mesh = value
	if Engine.is_editor_hint() and is_inside_tree():
		_update_multimesh()


func _on_set_player_pos(value : Vector3):
	player_pos = value
	if _material != null:
		_material.set_shader_parameter("player_pos", player_pos)


func _on_set_player_radius(value : float):
	player_radius = value
	if _material != null:
		_material.set_shader_parameter("player_radius", player_radius)


func _on_set_albedo(value : Color):
	albedo = value;
	if _material != null:
		_material.set_shader_parameter("albedo", albedo)


func _on_set_texture_albedo(value : Texture):
	texture_albedo = value
	if _material != null:
		_material.set_shader_parameter("texture_albedo", texture_albedo)


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


func _on_set_wind_dir(value : Vector3):
	wind_dir = value
	if _material != null:
		_material.set_shader_parameter("wind_dir", wind_dir)


func _on_set_wind_strength(value : float):
	wind_strength = value
	if _material != null:
		_material.set_shader_parameter("wind_strength", wind_strength)


func _on_set_wind_speed(value : float):
	wind_speed = value
	if _material != null:
		_material.set_shader_parameter("wind_speed", wind_speed)


func _on_set_optimization_by_distance(value : bool):
	optimization_by_distance = value
	if _material != null:
		_material.set_shader_parameter("optimization_by_distance", optimization_by_distance)


func _on_set_optimization_level(value : float):
	optimization_level = value
	if _material != null:
		_material.set_shader_parameter("optimization_level", optimization_level)
