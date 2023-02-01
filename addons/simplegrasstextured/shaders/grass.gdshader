/* grass.gdshader
This file is part of: SimpleGrassTextured
Copyright (c) 2023 IcterusGames

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to 
the following conditions: 

The above copyright notice and this permission notice shall be 
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.*/

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx,world_vertex_coords;
uniform vec3 player_pos = vec3(1000000.0);
uniform float player_radius = 0.5;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_disable;
uniform float alpha_scissor_threshold = 0.5;
uniform float metallic : hint_range(0,1) = 0.0;
uniform float roughness : hint_range(0,1) = 1.0;
uniform float specular : hint_range(0,1) = 0.0;
uniform float scale_h = 1.0;
uniform float scale_w = 1.0;
uniform float scale_var : hint_range(-1.0, 1.0) = -0.25;
uniform float grass_strength : hint_range(0.0, 1.0) = 0.8;
uniform vec3 wind_dir = vec3(1.0, 0.0, 0.0);
uniform float wind_strength = 0.15;
uniform float wind_turbulence = 1.0;
uniform sampler2D wind_pattern : source_color,filter_linear,repeat_enable;
uniform bool optimization_by_distance = false;
uniform float optimization_level = 7.0;
uniform float optimization_dist_min = 10.0;
uniform float optimization_dist_max = 50.0;
uniform float grass_size_y = 1.0;


void vertex() {
	float lev = (VERTEX.y - NODE_POSITION_WORLD.y) / grass_size_y;
	float varid = float(INSTANCE_ID);
	float text_wind = texture(wind_pattern, (vec2(NODE_POSITION_WORLD.x, NODE_POSITION_WORLD.z) * 0.005) - (vec2(wind_dir.x, wind_dir.z) * TIME * (0.1 * wind_strength))).r;
	VERTEX.x += text_wind * lev * wind_strength * wind_dir.x;
	VERTEX.z += text_wind * lev * wind_strength * wind_dir.z;
	VERTEX.x += sin((TIME + varid) * wind_turbulence) * lev * ((1.0 - grass_strength) / 10.0);
	VERTEX.x += wind_dir.x * lev * (wind_strength + (sin(TIME + varid) * 0.2 * (1.0 - grass_strength) * min(1.0, wind_turbulence)));
	VERTEX.y += sin((TIME + varid) * wind_turbulence) * lev * ((1.0 - grass_strength) / 10.0) * wind_dir.y;
	VERTEX.y += wind_dir.y * lev * (wind_strength + (sin(TIME + varid) * 0.2 * (1.0 - grass_strength) * min(1.0, wind_turbulence)));
	VERTEX.z += cos((TIME + varid) * wind_turbulence) * lev * ((1.0 - grass_strength) / 10.0);
	VERTEX.z += wind_dir.z * lev * (wind_strength + (sin(TIME + varid) * 0.2 * (1.0 - grass_strength) * min(1.0, wind_turbulence)));
	vec3 align = VERTEX - NODE_POSITION_WORLD;
	float varh = ((float(INSTANCE_ID % 5) / 5.0) * scale_var);
	float varw = ((float(INSTANCE_ID % 5) / 5.0) * scale_var);
	float dist = 1.0;
	if(optimization_by_distance) {
		float node_dist = distance(NODE_POSITION_WORLD, CAMERA_POSITION_WORLD);
		dist = 1.0 - clamp(0.0, 1.0, float(INSTANCE_ID % int(max(1.0, node_dist / optimization_level))));
		dist *= smoothstep(optimization_dist_max, optimization_dist_min, node_dist);
	}
	VERTEX.y = (align.y * ((varh * scale_h) + scale_h) * dist) + NODE_POSITION_WORLD.y;
	VERTEX.x = (align.x * (scale_w - varw) * dist) + NODE_POSITION_WORLD.x;
	VERTEX.z = (align.z * (scale_w - varw) * dist) + NODE_POSITION_WORLD.z;
	float dist_player = 1.0 - clamp(0.0, 1.0, distance(NODE_POSITION_WORLD, player_pos) / max(player_radius, 0.1));
	VERTEX.x += dist_player * (NODE_POSITION_WORLD.x - player_pos.x) * player_radius * 4.0 * lev * scale_w;
	VERTEX.y -= dist_player * (VERTEX.y - player_pos.y) * player_radius * 0.1 * lev;
	VERTEX.z += dist_player * (NODE_POSITION_WORLD.z - player_pos.z) * player_radius * 4.0 * lev * scale_w;
}


void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	ALPHA *= albedo.a * albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}
