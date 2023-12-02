#version 420 core

out vec4 frag_color;

in vec2 TexCoords;

uniform sampler2D diffuse_texture1;

void main()
{
	frag_color = texture(diffuse_texture1,TexCoords);
}