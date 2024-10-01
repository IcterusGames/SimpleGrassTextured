/* normal.gdshader
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

shader_type canvas_item;
render_mode blend_mix;

const float LVL = 4.0;

uniform sampler2D depth_texture : repeat_disable, filter_nearest, hint_default_white;


float get_value(sampler2D tex, vec2 uv) {
	vec4 color = textureLod(tex, uv, 0);
	return (round(color.r * 65280.0) + round(color.g * 255.0)) / 65535.0;
}


void fragment() {
	vec2 pixel = 1.0 / vec2(textureSize(depth_texture, 0));
	float c = get_value(depth_texture, UV);
	float l = get_value(depth_texture, UV - (vec2(1.0, 0.0) * pixel));
	float r = get_value(depth_texture, UV + (vec2(1.0, 0.0) * pixel));
	float u = get_value(depth_texture, UV - (vec2(0.0, 1.0) * pixel));
	float d = get_value(depth_texture, UV + (vec2(0.0, 1.0) * pixel));
	COLOR = vec4((r - l) * LVL * 0.5 + 0.5, (d - u) * LVL * 0.5 + 0.5, 1.0 - c, 1.0);
}
