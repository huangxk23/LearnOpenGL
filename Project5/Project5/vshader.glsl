#version 420 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aTexCoords;

out vec3 FragPos;
out vec3 Normal;
out vec2 TexCoords;
out vec4 FragPosLightSpace;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;
uniform mat4 lightSpaceMatrix;

void main()
{
	gl_Position =  projection * view * model * vec4(aPos,1.0f);
	FragPos = vec3(model * vec4(aPos,1.0f));
	Normal = aNormal;
	TexCoords = aTexCoords;
	FragPosLightSpace = lightSpaceMatrix * model * vec4(aPos,1.0f);

}