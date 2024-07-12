# default_mesh_builder.gd
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

## Builds and saves the default grass mesh when called.
func rebuild_and_save_default_mesh() -> void:
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
	array_mesh.set_meta(&"GodotVersion", Engine.get_version_info()["string"])
	ResourceSaver.save(array_mesh, "res://addons/simplegrasstextured/default_mesh.tres")
