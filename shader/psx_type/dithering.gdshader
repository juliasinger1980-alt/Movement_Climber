shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D font_atlas;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float brightness = 0.0;
	vec2 asd = (floor(FRAGCOORD.xy / 10.0) * 10.0 + 7.0) * SCREEN_PIXEL_SIZE;
	vec4 screenpixel = texture(SCREEN_TEXTURE, asd);
	brightness = (screenpixel[0] + screenpixel[1] + screenpixel[2]) / 10.0;
	float index = floor(brightness * 95.0);
	float Atlas_UV_X = (index * 10.0 + mod(FRAGCOORD.x, 10.0)) / 795.0;
	float Atlas_UV_Y = mod(FRAGCOORD.y, 10.0) / 10.0;
	vec4 fin = (texture(font_atlas, vec2(Atlas_UV_X, Atlas_UV_Y))) * screenpixel;
	COLOR = fin;
}
