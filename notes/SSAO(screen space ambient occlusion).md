### SSAO(screen space ambient occlusion)

###  three key ideas :

1. ambient light is the same in every direction 
2. diffuse material
3. but take visibility into consideration -> some ambient lights comes from some direction will be occluded 



### how to calculate the visibility approximately -> sampling light on the normal oriented hemisphere:

for each fragment on a screen filled quad we calculate an occlusion factor base on the fragment's surrounding depth values. the occlusion factor is the fraction of the occluded sample points and sample points. The number of samples  that have a higher depth is depth value than the fragment depth represents the occlusion factor.(This is an assumption that can be wrong but can approximately determine occluded or not)



### Implementation details 

1. sample count small -> Artifacts banding
2.  By randomly rotating the sample kernel each fragment we can get high quality results with a much smaller amount of samples -> Artifacts noise pattern
3. blur



####  samples buffers:

1. position vector
2. normal vector
3. albedo vector
4. sample kernel
5. random rotation 



####  very very important: how to sample on the normal oriented hemisphere

1. can not define a sample kernel for all normals 
2. define a sample kernel on the tangent space for a unit hemisphere

follow this two requirements:

1. x and y is randomly picked between [-1,1]
2. z is randomly picked between [0,1] -> for we need on the normal oriented hemisphere
3. normalzie it 
4. now we some points on the surface of the normal oriented hemisphere
5. what we need to do next is normalize it and randomly scale it inside the normal oriented hemisphere
6. what is more , we prefer the sample points to be more closer to the origin
7. assign a larger weight -> scale -> scale is define as a lerp(0.1,1.0f,scale * scale) scale = i / 64 

```c++
std::uniform_real_distribution<float> randomFloats(0.0, 1.0); // random floats between [0.0, 1.0]
std::default_random_engine generator;
std::vector<glm::vec3> ssaoKernel;
for (unsigned int i = 0; i < 64; ++i)
{
    glm::vec3 sample(
        randomFloats(generator) * 2.0 - 1.0, 
        randomFloats(generator) * 2.0 - 1.0, 
        randomFloats(generator)
    );
    sample  = glm::normalize(sample);
    sample *= randomFloats(generator);
    float scale = (float)i / 64;
    scale = lerp(0.1f,1.0f,scale * scale);
    smaple *= scale;
    ssaoKernel.push_back(sample);  
}
```

嗯？？？有点多余啊，1，2步其实已经在半球内部随机采样到一些样本点了，为什么还需要normalized到球面上面，然后再随机scale到半球内部的随机的采样点呢？？？？



#### random kernel rotation 

为了确保每一个fragment的sample kernel 都是不一样具有一定的随机性，所以需要在切线空间沿着正z轴对sample kernel 进行旋转。

```c++
std::vector<glm::vec3> ssaoNoise;
for (unsigned int i = 0; i < 16; i++)
{
    glm::vec3 noise(
    randomFloats(generator) * 2.0 - 1.0, 
    randomFloats(generator) * 2.0 - 1.0, 
   		0.0f); 
    ssaoNoise.push_back(noise);
}  
```

emm那么旋转之后如何计算tangent呢？

使用Gramm-Schmidt正交化得到一组正交基，每次tangent向量都是沿着randvec 方向稍微倾斜一下。 

已有normal 需要计算tangent和bitangent作为正交基：

那么自然有：
$$
v1 = normal\\
v2 = randvec - normal * dot(normal,ranvec)
$$
在normal oriented的半球上面的采样写的真好，首先在CPU端预生成随机采样的kernel，然后为了保证每个fragment的sample kernel具有一定的随机性，然后需要将sample kernel 进行随机的旋转！！！所有的sample kernel 和 random kernel rotation 都是在CPU端precompute 的，保证了fragment shader运行的性能！！！只需要查询即可。

如果是我会怎么写？我才不会precompute sample kernel,在fragment shader中不是有fragpos 和 normal吗，那就直接在fragment shader里面对normal 和fragpos进行64 次的随机采样。什么？GLSL没有随机函数，没事写一个。在fragment shader 再随机采样性能肯定比不上precompute sample kernel 的。



### range check 

Whenever a fragment is tested for ambient occlusion that is aligned close to the edge of a surface, it will also consider depth values of surfaces far behind the test surface; these values will (incorrectly) contribute to the occlusion factor. We can solve this by introducing a range check as the following image (courtesy of [John Chapman](http://john-chapman-graphics.blogspot.com/)) illustrates.

```c++
float rangeCheck = smoothstep(0.0, 1.0, radius / abs(fragPos.z - sampleDepth));
occlusion       += (sampleDepth >= samplePos.z + bias ? 1.0 : 0.0) * rangeCheck;  
```



### blur 

模糊操作实际上就是平均卷积。









