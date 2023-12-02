#version 420 core

uniform sampler2D depthMap;

out vec4 frag_color;
in vec2 TexCoords;

void main()
{
	float val = texture(depthMap,TexCoords).r;

	frag_color = vec4(vec3(val),1.0f);
}