#version 420 core

in vec2 TextureCord;
out vec4 color;

uniform sampler2D texture1;

void main()
{
	color = texture(texture1,TextureCord);
}
