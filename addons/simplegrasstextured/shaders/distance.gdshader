/* distance.gdshader
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
render_mode blend_mix,depth_draw_never,cull_back,unshaded,ambient_light_disabled;
uniform sampler2D heightmap_texture : hint_default_white, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

global uniform int sgt_legacy_renderer = 0;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.y = 1.0 - uv.y;
	float depth = textureLod(depth_texture, uv, 0.0).r;
	
	// If using Compatibility renderer, apply proper depth range
	vec3 ndc = mix(vec3(uv * 2.0 - 1.0, depth), vec3(uv, depth) * 2.0 - 1.0, float(sgt_legacy_renderer));
	vec4 upos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float pos_y = -upos.z + CAMERA_POSITION_WORLD.y;
	vec3 color_h = textureLod(heightmap_texture, UV, 0).rgb;
	highp float map_y = (((round(color_h.r * 255.0) - 75.0) * 180.0) + (round(color_h.g * 255.0) - 75.0) + color_h.b) - 16200.0;
	float dist = clamp(abs(map_y - pos_y) / 0.35, 0.0, 1.0) * 65535.0;
	ALBEDO.r = floor(dist / 256.0) / 255.0;
	ALBEDO.g = (dist - round(ALBEDO.r * 65280.0)) / 255.0;
	ALBEDO.b = 0.0;
	ALPHA = 1.0;
}
