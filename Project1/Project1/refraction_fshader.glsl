#version 420 core

out vec4 frag_color;

in vec3 pos;
in vec3 normal;

uniform vec3 campos;
uniform samplerCube cubetextrue;

void main()
{
	vec3 I = normalize(pos - campos);
	float ratio = 1.0f / 1.52;
	vec3 refract_dir = refract(I,normalize(normal),ratio);

	frag_color = texture(cubetextrue,refract_dir);

}