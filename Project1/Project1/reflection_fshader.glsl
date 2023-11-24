#version 420 core

out vec4 frag_color;

in vec3 pos;
in vec3 normal;

uniform vec3 campos;
uniform samplerCube cubetexture;

void main()
{
	vec3 I = normalize(pos - campos);
	vec3 reflect_dir = reflect(I,normalize(normal));
	frag_color = texture(cubetexture,reflect_dir);

	
}
