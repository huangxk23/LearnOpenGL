#version 420 core

in vec3 TextCoords;

uniform samplerCube cubetexture;

void main()
{
	gl_FragColor = texture(cubetexture,TextCoords);
}