#version 420 core

layout(location = 0) in vec3 aPos;

out vec3 TextCoords;
uniform mat4 projection;
uniform mat4 view;

void main()
{
	vec4 pos = projection * view * vec4(aPos,1.0f);
	gl_Position = pos.xyww;
	TextCoords = aPos;
}