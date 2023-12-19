#version 420 core

out vec4 frag_color;

in vec3 pos;
in vec3 normal;
in vec2 TexCoords;

uniform vec3 camPos;
uniform vec3 lightPos[4];
uniform vec3 lightColor[4];

uniform sampler2D texture_diffuse;
uniform sampler2D texture_metallic;
uniform sampler2D texture_roughness;
uniform sampler2D texture_normal;
uniform sampler2D texture_ao;

uniform sampler2D ltc1;
uniform sampler2D ltc2;

uniform samplerCube irradianceMap; 
uniform samplerCube prefilterMap;
uniform sampler2D brdfLUT;

struct triLight
{
    vec3 lightColor;
    vec3 position[3];
    vec3 normal;
};
uniform triLight tlight;

const float pi = 3.1415926535;

const float LUT_SIZE  = 64.0; // ltc_texture size 
const float LUT_SCALE = (LUT_SIZE - 1.0)/LUT_SIZE;
const float LUT_BIAS  = 0.5/LUT_SIZE;

//acos computation has artifacts
//use a rational fit instead
vec3 IntegrateEdgeVec(vec3 v1, vec3 v2)
{
    float x = dot(v1, v2);
    float y = abs(x);

    float a = 0.8543985 + (0.4965155 + 0.0145206*y)*y;
    float b = 3.4175940 + (4.1616724 + y)*y;
    float v = a / b;

    float theta_sintheta = (x > 0.0) ? v : 0.5*inversesqrt(max(1.0 - x*x, 1e-7)) - v;

    return cross(v1, v2)*theta_sintheta;
}

float IntegrateEdge(vec3 v1, vec3 v2)
{
    return IntegrateEdgeVec(v1, v2).z;
}

vec3 LTC_Evaluate(vec3 N, vec3 V, vec3 P, mat3 Minv, vec3 points[3],vec3 lightNormal)
{
    //M is defined in tangent space
    vec3 T1, T2;
    T1 = normalize(V - N * dot(V, N));
    T2 = cross(N, T1);

    // rotate area light in (T1, T2, N) basis
    Minv = Minv * transpose(mat3(T1, T2, N)); 
    
    vec3 L[3];
    // transform polygon from LTC back to origin Do (cosine weighted) 
    L[0] = Minv * (points[0] - P); 
    L[1] = Minv * (points[1] - P);
    L[2] = Minv * (points[2] - P);
    

    // integrate
    float sum = 0.0;

    // use tabulated horizon-clipped sphere
    // check if the shading point is behind the light
    vec3 dir = points[0] - P; 
    bool behind = (dot(dir, lightNormal) < 0.0); 

    // cos weighted space
    L[0] = normalize(L[0]);
    L[1] = normalize(L[1]);
    L[2] = normalize(L[2]);

    vec3 vsum = vec3(0.0);
    
    vsum += IntegrateEdgeVec(L[0], L[1]);
    vsum += IntegrateEdgeVec(L[1], L[2]);
    vsum += IntegrateEdgeVec(L[2], L[0]);
    
    // form factor of the polygon in direction vsum
    float len = length(vsum);
    float z = vsum.z/len;
    
    
    if (behind)
        z = -z;
    
    vec2 uv = vec2(z*0.5 + 0.5, len); // range [0, 1]
    uv = uv*LUT_SCALE + LUT_BIAS;
    
    float scale = texture(ltc2, uv).w;
    
    sum = len*scale;
    
    if (!behind)
        sum = 0.0;
    
    vec3 Lo_i = vec3(sum, sum, sum);

    return Lo_i;
}

vec3 getNormalFromMap()
{
    //from [0,1] to [-1,1]
    vec3 tangentNormal = texture(texture_normal, TexCoords).xyz * 2.0 - 1.0;

    vec3 Q1  = dFdx(pos);
    vec3 Q2  = dFdy(pos);
    vec2 st1 = dFdx(TexCoords);
    vec2 st2 = dFdy(TexCoords);

    vec3 N   = normalize(normal);
    vec3 T  = normalize(Q1*st2.t - Q2*st1.t);
    vec3 B  = -normalize(cross(N, T));
    mat3 TBN = mat3(T, B, N);

    return normalize(TBN * tangentNormal);
}

float GGX(vec3 h,vec3 n,float roughness)
{
    float r2 = roughness * roughness;
    float ndoth = max(dot(n,h),0);
    float ndoth2 = ndoth * ndoth;

    float ans = r2 / ((ndoth2 * (r2 -1)+1) * (ndoth2 * (r2-1)+1));

    return ans;
}

float SchlickGGX(vec3 n,vec3 v,float k)
{
    float ndotv = max(dot(n,v),0);
    
    return ndotv / (ndotv*(1-k) + k);
}

float GeometrySmith(vec3 n,vec3 wo,vec3 wi,float k)
{
    float g1 = SchlickGGX(n,wo,k);
    float g2 = SchlickGGX(n,wi,k);

    return g1 * g2;
}

vec3 fresnelSchlick(float cosine,vec3 F0)
{
    return F0 + (1.0f - F0) * pow(1.0f-cosine,5.0f);
}

vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness)
{
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
} 


void main()
{
	vec3 albedo = pow(texture(texture_diffuse,TexCoords).rgb,vec3(2.2));
	float metallic = texture(texture_metallic,TexCoords).r;
	float roughness = texture(texture_roughness,TexCoords).r;
    float ao = texture(texture_ao,TexCoords).r;
    vec3 n = getNormalFromMap();
    vec3 wo = normalize(camPos - pos);

    vec3 F0 = vec3(0.04);
    F0 = mix(F0,albedo,metallic);

    vec3 radiance_view = {0,0,0};
    for(int i = 0;i < 4;++i)
    {
        vec3 wi = normalize(lightPos[i] - pos);
        vec3 h = normalize(wo + wi);

        float NDF = GGX(h,n,roughness);
        float k = (roughness + 1.0f) * (roughness + 1) / 8.0f; 
        float shadowingMasking = GeometrySmith(n,wi,wo,k);
        vec3 Fresnel = fresnelSchlick(max(dot(h,wo),0),F0);
        
        float distance = length(lightPos[i] - pos);
        vec3 radiance = lightColor[i] / distance / distance;

        vec3 ks = Fresnel;
        vec3 kd = 1 - Fresnel;
        kd = kd * (1 - metallic);

        float ndotwo = max(dot(n,wo),0);
        float ndotwi = max(dot(n,wi),0);
        vec3 specular = Fresnel * NDF * shadowingMasking / (4 * ndotwo * ndotwi + 0.00001);

        radiance_view += (kd * albedo / pi + specular) * radiance * ndotwi;
        
    }
    

    //ltc light
    vec3 mspec = metallic * albedo;
    vec3 mdiffuse = (1-metallic) * albedo;

    float ndotwo = max(dot(n,wo),0);
    vec2 uv = vec2(roughness,sqrt(1 - ndotwo));
    uv = uv * LUT_SCALE + LUT_BIAS;

    // get 4 parameters for inverse_M
    vec4 t1 = texture(ltc1, uv); 

    // Get 2 parameters for Fresnel calculation
    vec4 t2 = texture(ltc2, uv);

    mat3 Minv = mat3(
        vec3(t1.x, 0, t1.y),
        vec3(  0,  1,    0),
        vec3(t1.z, 0, t1.w)
    );
    
    vec3 diffuse = LTC_Evaluate(normal,wo,pos,mat3(1.0f),tlight.position,tlight.normal);
	vec3 specular = LTC_Evaluate(normal,wo,pos,Minv,tlight.position,tlight.normal);

    specular *= mspec * t2.x + (1.0 - mspec) * t2.y;

    radiance_view += tlight.lightColor * (specular + mdiffuse * diffuse);

    //ambient light
    vec3 F = fresnelSchlickRoughness(max(dot(n, wo), 0.0), F0, roughness);
    vec3 r = reflect(-wo,n);

    vec3 ks = F;
    vec3 kd = 1.0f - ks;
    kd *= 1.0f - metallic;

    vec3 irradiance = texture(irradianceMap,n).rgb;
    vec3 diffuse_part = irradiance * albedo;

    const float MAX_REFLECTION = 4.0f;
    vec3 specular_light = textureLod(prefilterMap,r,roughness * MAX_REFLECTION).rgb;
    vec2 brdf = texture(brdfLUT,vec2(max(dot(n,wo),0),roughness)).rg;
    vec3 specular_part = specular_light * (F * brdf.x+brdf.y);
    vec3 ambient = (kd * diffuse_part + specular_part) * ao;
    
    radiance_view += ambient;

    vec3 color = radiance_view;
    
    //tone mapping
    color = color / (color + vec3(1.0f));

    //gamma correction
    color = pow(color,vec3(1.0f/2.2));

    //vec3 test = rlight.position[0] + rlight.position[1] + rlight.position[2] + rlight.position[3];
    //test.y /= 6.0f;
    //test.z /= -100.0f;
    frag_color = vec4(color,1);
}