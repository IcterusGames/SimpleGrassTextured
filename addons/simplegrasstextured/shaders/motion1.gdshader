/* motion1.gdshader
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

uniform float delta = 1.0;
uniform sampler2D prev_depth : hint_default_black, repeat_disable, filter_nearest;
uniform sampler2D cur_depth : hint_default_black, repeat_disable, filter_nearest;
uniform sampler2D motion_frame : hint_default_transparent, repeat_disable, filter_nearest;

global uniform vec3 sgt_player_mov = vec3(0.0);


float get_value(sampler2D tex, vec2 uv) {
	vec4 color = textureLod(tex, uv, 0);
	float value = round(color.r * 65280.0) + round(color.g * 255.0);
	return value;
}


void fragment() {
	float value1 = get_value(cur_depth, UV);
	float value2 = get_value(prev_depth, UV - sgt_player_mov.xz) + ((1.0 - clamp(TIME, 0.0, 1.0)) * 65535.0);
	vec4 color_frame = texture(motion_frame, UV);
	value1 = min(value1, value2 + (40000.0 * delta)) * (1.0 - color_frame.a);
	value1 += 65535.0 * color_frame.a;
	COLOR.r = floor(value1 / 256.0) / 255.0;
	COLOR.g = floor(value1 - round(COLOR.r * 65280.0)) / 255.0;
	COLOR.b = 0.0;
}
