#version 330 core

struct DirectionalLight
{
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

};

struct PointLight
{
    vec3 point;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float constant;
    float linear;
    float quadratic;

   
};

struct FlashLight
{
    vec3 point;
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float constant;
    float linear;
    float quadratic;
    
    float cutoff;
    float outercutoff;
    
};

out vec4 FragColor;

in vec2 TexCoords;
in vec3 Normal;
in vec3 FragPos;

uniform float shiness = 32.0f;
uniform vec3 view_pos;
uniform int texture_sample;
uniform sampler2D texture_diffuse1;
uniform sampler2D texture_specular1;


uniform DirectionalLight dLight;
uniform PointLight pLight;
uniform FlashLight fLight;

vec3 calculate_directional_light(DirectionalLight dLight,vec3 Normal,vec3 view_dir,int texture_sample);
vec3 calculate_point_light(PointLight pLight,vec3 Normal,vec3 FragPos,vec3 view_dir,int texture_sample);
vec3 calculate_flash_light(FlashLight fLight,vec3 Normal,vec3 FragPos,vec3 view_dir,int texture_sample);

void main()
{    
    vec3 color = vec3(0.0f,0.0f,0.0f);
    vec3 view_dir = normalize(FragPos - view_pos);

    color += calculate_directional_light(dLight,Normal,view_dir,texture_sample);
    color += calculate_point_light(pLight,Normal,FragPos,view_dir,texture_sample);
    color += calculate_flash_light(fLight,Normal,FragPos,view_dir,texture_sample);

    float gamma = 2.2;
    color = pow(color,vec3(1.0f/gamma));

    FragColor = vec4(color,1.0f);
    
}

vec3 calculate_directional_light(DirectionalLight dLight,vec3 Normal,vec3 view_dir,int texture_sample)
{
    vec3 norm = normalize(Normal);
    vec3 lightdir = normalize(-dLight.direction);

    vec3 ambient = dLight.ambient * vec3(texture(texture_diffuse1,TexCoords));
    
    float diff = max(0,dot(lightdir,norm));
    vec3 diffuse = diff * dLight.diffuse * vec3(texture(texture_diffuse1,TexCoords));

    vec3 specular;
    if(texture_sample == 0) specular = vec3(0.0f,0.0f,0.0f);
    else
    {
       vec3 h = normalize(lightdir + view_dir);
       float diff = pow(max(0,dot(h,norm)),shiness);
       specular = diff * dLight.specular * vec3(texture(texture_specular1,TexCoords));
    }
    return ambient + diffuse + specular;
}

vec3 calculate_point_light(PointLight pLight,vec3 Normal,vec3 FragPos,vec3 view_dir,int texture_sample)
{
    vec3 norm = normalize(Normal);
    vec3 lightdir = normalize(pLight.point - FragPos);

    vec3 ambient = pLight.ambient * vec3(texture(texture_diffuse1,TexCoords));
    
    float diff = max(0,dot(lightdir,norm));
    vec3 diffuse = diff * pLight.diffuse * vec3(texture(texture_diffuse1,TexCoords));

    vec3 specular;
    if(texture_sample == 0) specular = vec3(0.0f,0.0f,0.0f);
    else
    {
       vec3 h = normalize(lightdir + view_dir);
       float diff = pow(max(0,dot(h,norm)),shiness);
       specular = diff * pLight.specular * vec3(texture(texture_specular1,TexCoords));
    }
    float dist = length(FragPos-pLight.point);
    float attenuation = 1.0f /(pLight.constant + pLight.linear * dist + pLight.quadratic * dist * dist);

    return ambient + diffuse + specular;
}

vec3 calculate_flash_light(FlashLight fLight,vec3 Normal,vec3 FragPos,vec3 view_dir,int texture_sample)
{
   vec3 norm = normalize(Normal);
   vec3 lightdir = normalize(fLight.point - FragPos);

   float theta = dot(normalize(-fLight.direction),lightdir);
   float intensity = clamp((theta - fLight.outercutoff) / (fLight.cutoff - fLight.outercutoff),0.0f,1.0f);

   vec3 ambient = fLight.ambient * vec3(texture(texture_diffuse1,TexCoords));

   float diff = max(0,dot(lightdir,norm));
   vec3 diffuse = diff * fLight.diffuse * vec3(texture(texture_diffuse1,TexCoords));

   vec3 specular;
   if(texture_sample == 0) specular = vec3(0.0f,0.0f,0.0f);
   else
   {
      vec3 h = normalize(lightdir + view_dir);
      float diff = pow(max(0,dot(h,norm)),shiness);
      specular = diff * fLight.specular * vec3(texture(texture_specular1,TexCoords));
   }

   float dist = length(FragPos-fLight.point);
   float attenuation = 1.0f /(fLight.constant + fLight.linear * dist + fLight.quadratic * dist * dist);

   diffuse *= intensity;
   specular *= intensity;

   return attenuation * (ambient + diffuse + specular);
   //return ambient;

   
}