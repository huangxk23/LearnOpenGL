#version 420 core

out vec4 fragColor;

uniform vec3 lightColor;

void main()
{
	vec3 color = lightColor;
	//tone mapping
	color = color / (color + vec3(1.0f));
	//gamma correction
	color = pow(color,vec3(1.0f/2.2f));
	
	fragColor = vec4(color,1.0f);
}