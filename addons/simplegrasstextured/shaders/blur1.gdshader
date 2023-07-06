/* blur1.gdshader
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

uniform sampler2D normal_texture : hint_normal, filter_nearest, repeat_disable;


void fragment() {
	vec2 pixel = 1.0 / vec2(textureSize(normal_texture, 0));
	float lvl = round(float(textureSize(normal_texture, 0).y) * 0.01);
	highp vec4 color = vec4(0.0);
	highp float total = 0.0;
	for(float x = -lvl * 2.0; x <= lvl * 2.0; x += 1.0) {
		float gauss = (1.0 / (sqrt(TAU * lvl * lvl))) * pow(E, -((x * x) / (2.0 * lvl * lvl)));
		color += texture(normal_texture, UV + vec2(0.0, x * pixel.x)) * gauss;
		total += gauss;
	}
	COLOR = color / total;
}