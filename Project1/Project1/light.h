#pragma once
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include "shader.h"
#include "camera.h"

#define AMBIENT glm::vec3(0.05f, 0.05f, 0.05f)
#define DIFFUSE glm::vec3(0.8f, 0.8f, 0.8f)
#define SPECULAR glm::vec3(1.0f, 1.0f, 1.0f)

struct DirectionalLight
{
	glm::vec3 direction;

	glm::vec3 ambient;
	glm::vec3 diffuse;
	glm::vec3 specular;
	
	DirectionalLight(glm::vec3 _direction = glm::vec3(0.0f, -3.0f, -3.0f)):direction(_direction), ambient(AMBIENT), diffuse(DIFFUSE), specular(SPECULAR) {}
};

struct PointLight
{
	glm::vec3 point;

	glm::vec3 ambient;
	glm::vec3 diffuse;
	glm::vec3 specular;

	float constant;
	float linear;
	float quadratic;

	PointLight(glm::vec3 _point = glm::vec3(0, 0, -5.0f), float _constant = 1.0f, float _linear = 0.09f, float _quadratic = 0.032f) :point(_point), ambient(AMBIENT), diffuse(DIFFUSE), specular(SPECULAR), constant(_constant), linear(_linear), quadratic(_quadratic) {}
};

struct FlashLight
{
	glm::vec3 point;
	glm::vec3 direction;

	glm::vec3 ambient;
	glm::vec3 diffuse;
	glm::vec3 specular;

	float constant;
	float linear;
	float quadratic;

	float cutoff;
	float outercutoff;
	

	FlashLight(glm::vec3 _point, glm::vec3 _direction, float _constant = 1.0f, float _linear = 0.09f, float _quadratic = 0.032f)
	{
		point = _point;
		direction = _direction;
		ambient = AMBIENT;
		diffuse = DIFFUSE;
		specular = SPECULAR;
		constant = _constant;
		linear = _linear;
		quadratic = _quadratic;
		cutoff = glm::cos(glm::radians(12.0f));
		outercutoff = glm::cos(glm::radians(15.0f));
	}

};

void set_directional_light(Shader& ourShader, DirectionalLight& dLight)
{
	ourShader.setVec3("dLight.direction", dLight.direction);
	ourShader.setVec3("dLight.ambient", dLight.ambient);
	ourShader.setVec3("dLight.diffuse", dLight.diffuse);
	ourShader.setVec3("dLight.specular", dLight.specular);
}

void set_point_light(Shader& ourShader, PointLight& pLight)
{
	ourShader.setVec3("pLight.point",pLight.point);
	ourShader.setVec3("pLight.ambient",pLight.ambient);
	ourShader.setVec3("pLight.diffuse", pLight.diffuse);
	ourShader.setVec3("pLight.specular", pLight.specular);
	ourShader.setFloat("pLight.constant", pLight.constant);
	ourShader.setFloat("pLight.linear",pLight.linear);
	ourShader.setFloat("pLight.quadratic", pLight.quadratic);
}

void set_flash_light(Shader& ourShader, FlashLight& fLight, Camera& camera)
{
	fLight.point = camera.Position;
	fLight.direction = camera.Front;
	//cout << fLight.cutoff - fLight.outercutoff << endl;

	ourShader.setVec3("fLight.point", fLight.point);
	ourShader.setVec3("fLight.direction", fLight.direction);
	ourShader.setVec3("fLight.ambient", fLight.ambient);
	ourShader.setVec3("fLight.diffuse", fLight.diffuse);
	ourShader.setVec3("fLight.specular", fLight.specular);
	ourShader.setFloat("fLight.constant", fLight.constant);
	ourShader.setFloat("fLight.linear", fLight.linear);
	ourShader.setFloat("fLight.quadratic", fLight.quadratic);
	ourShader.setFloat("fLight.cutoff", fLight.cutoff);
	ourShader.setFloat("fLight.outercutoff", fLight.outercutoff);

}