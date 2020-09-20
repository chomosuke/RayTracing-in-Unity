**The University of Melbourne**
# COMP30019 – Graphics and Interaction

# Project-1 README

## Table of contents
* [Team Members](#team-members)
* [General Info](#general-info)
* [Technologies](#technologies)
* [Diamond-Square implementation](#diamond-square-implementation)
* [Camera Motion](#camera-motion)
* [Vertex Shader](#vertex-shader)
* [Reflection and Refraction](#ray-tracing-for-reflection-and-refraction-of-water)
* [Bump Map](#bump-map)

## Team Members

| Name | Task | State |
| :---         |     :---:      |          ---: |
| Shuang Li    | Phong shader, Diamond Square, Water Shader (the one with reflection and refraction), ReadMe | Done |
| Jasmine Bond | Camera Boundaries, Diamond Square, ReadMe      | Done |
| Ju Wey Tan   | Bump Map, Colouring, Diamond Square, ReadMe | Done |
| Jasper Ng    | Camera Control, Water Shader, ReadMe      | Done |

## General info
This is project - 1 where we were tasked with generating a fractal landscape in Unity using the Diamond Square Algorithm. We also had to write our own custom CG/HLSL shader for the landscape with the Phong illumination model, and a water shader, where we have included the option for ray tracing. We have also applied a bump map to the landscape mesh.

## About Ray Tracing and the fact that it's resource intensive
Considering that, we've written a Phong shader for our water. You can find a tick box in MainScene -> Water -> Water Reflection (Script) that says Set Ray Tracing. You can untick that if the RayTracing and dropping frames, or you just want to see the phong shader version of our water. Note that I've adjusted the Wave amplitude extrememly low for good reflection, so if you turn off RayTracing it's recommended for you to set water heigh to 0.01 as well.
	
## Technologies
Project is created with:
* Unity 2019.4.3f1

## Diamond-Square implementation :mountain:

We generated the height map for the fractal landscape using a 2D float array (the height map) with a size that can be defined in the unity inspector and initialised the four corners. Then, we iteratively performed the diamond step and the square step until the 2D array was filled.

#### Diamond step :large_blue_diamond:
For each existing top-left point, tracked by the current length between each point in the array, we got the other three points that formed a square to get the average of their heights as the height of the point at the middle of four points plus a random value.

#### Square step :blue_square: 
At the iteration of square step, for each point to be generated, we calculated its height by averaging the heights of the surrounding points (top, left, right, and bottom) plus a random value. Any surrounding point would be removed if it fell outside of the 2D array (if it was at an edge).

For the random value, we created a function that takes in a minimum and a maximum and outputs a random number between them. We used a variable randomness which we iteratively halved to decrease the range of randomness.

```c#
public class meshGenerator : MonoBehaviour
{
    //This function run once when Unity is in Play
     void Start ()
    {
      GenerateMesh(); 
    }
    
    void GenerateMesh(int iterations){
      float[][] grid = this.GenerateHeightMap(iterations);
      .
      .
      .
    }
    
    float[][] GenerateHeightMap(int iterations)
    {
      // Iteratively performing diamond and square step
      for (int h = 0; h < iterations; h++)
        {
            // Diamond Step
            // Traversing squares
            for (int i = 0; i < length-1; i+=currentLength)
            {
                for (int j = 0; j < length-1; j+=currentLength)
                {
                    float slot = (grid[i][j] + grid[i+currentLength][j] 
                        + grid[i][j+currentLength] + grid[i+currentLength][j+currentLength]) / 4;
                        
                    grid[i+(currentLength/2)][j+(currentLength/2)]
                        = slot + RandomRange(randomness/2, -randomness/2);
                }
            }

            Boolean isEvenLine = true;
            // Square Step
            for (int i = 0; i < length; i+=(currentLength/2))
            {
                int j;
                if(isEvenLine){
                    j = currentLength/2;
                }
                else{
                    j = 0;
                }
                for (; j < length; j+=currentLength)
                {
                    ArrayList heights = new ArrayList();
                    heights.Add(new int[2]{i+currentLength/2, j});
                    heights.Add(new int[2]{i-currentLength/2, j});
                    heights.Add(new int[2]{i, j-currentLength/2});
                    heights.Add(new int[2]{i, j+currentLength/2});
                    for (int k = 0; k < heights.Count; k++)
                    {
                        if (((int[])heights[k])[0] < 0 || ((int[])heights[k])[1] < 0 
                        || ((int[])heights[k])[0] >= length || ((int[])heights[k])[1] >= length){
                            heights.RemoveAt(k);
                            k--;
                        }
                    }
                    float sum = 0;

                    foreach (int[] point in heights)
                    {
                        sum += grid[point[0]][point[1]];
                    }
                    grid[i][j] = sum / heights.Count + RandomRange(randomness/2, -randomness/2);
                }
                isEvenLine = !isEvenLine;
            }

            currentLength /= 2;
            randomness /= 2;
        }
    }
}
```

#### Turning the 2D height map array into a mesh
We first initialize a array of vectors with the same size as the height map array and iteratively fill the array with vectors with y component from the height map and x and z component derieved for the first and second index of the 2D array scaled appropirately to match the landscape size specified in the editor. We then set the triangles' index to match each of the vector's corrisponding position in the 2D height map array so that when looking from top down the triangles form a grid. After that we assign everything to a mesh and because our triangles share vertices we can use unity's built in RecalculateNormals() and RecalculateTangents() to automatically fill in the normals and tangents for the mesh.

## Camera Motion :movie_camera:
To control the orientation of the camera, we simply read user inputs and converted them to a rotation in the camera using the Quaternion struct in Unity. 

```c#
void Update()
    {  
        camRotation.x -= sensitivity * Input.GetAxis("Mouse Y"); // Look left/right
        camRotation.y += sensitivity * Input.GetAxis("Mouse X"); // Look up/down
        transform.localRotation = Quaternion.Euler(camRotation.x, camRotation.y, camRotation.z);
    }
```

As for the position for the camera, given user input, we updated the position of the camera relative to its orientation. For example, if the user inputs "D" on the keyboard, the camera will move right relative to the orientation of the camera. 

```c#
if (Input.GetKey(KeyCode.D)) {
            this.transform.localPosition += gameObject.transform.right * cameraSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.A)) {
            this.transform.localPosition += gameObject.transform.right * -1 * cameraSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.W)) {
            this.transform.localPosition += gameObject.transform.forward * cameraSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.S)) {
            this.transform.localPosition += gameObject.transform.forward * -1 * cameraSpeed * Time.deltaTime;
        }
```

Users are given the option of the changing the sensitivity and speed of the camera to their preference. Furthermore, if the user presses "SPACE", and there is a pre-existing landscape, the program will generate a new landscape and reset the camera position to a suitable position.

## Landscape Boundaries :construction:

For the boundaries of the landscape, we chose to have it controlled by the CameraMovement script. Every time the landscape is generated, the script retrieves the landscape mesh's vertices, and maxY from the DiamondSquare script. It also retrieves minY by obtaining the sum of the position of the 'Water' object, and the offset from the WaterReflection script.

```c#
landscapeVertices = landscape.GetComponent<MeshFilter>().mesh.vertices;
gridSize = landscape.GetComponent<DiamondSquare>().sizeOfLandscape;
maxY = landscape.GetComponent<DiamondSquare>().getMaxY();
minY = GameObject.Find("Water").transform.position.y
        + GameObject.Find("Water").GetComponent<WaterReflection>().getOffset();
```

Every time Update is called, the camera's position before a transform is stored. After the position of the camera is updated, the camera's new position is used as a parameter in the landscape_collision function, which returns a boolean based on whether the camera has a collision. Firstly the function checks if the camera is within the bounds of the landscape.

```c#
if(newPosition.x > gridSize || newPosition.x < 0 || newPosition.z > gridSize || newPosition.z < 0 
    || newPosition.y <= (minY + waveHeight + threshold)) {
        return true;
}
```

If it's not, then the function checks if the camera is colliding with the terrain. Firstly, for the landscape vertices array, the number of vectors in one row if it were in grid form (gridLength), and the distance between each of the vectors (unitLength) is calculated. Using those variables, the position of the closest vector in the array is retrieved as closestZ and closestY. An array of the 4 closest vectors to the camera is retrieved from the vertices array.

```c#
// number of vectors in one row of grid
int gridLength = (int) Math.Sqrt(landscapeVertices.Length);
// distance between each vector
float unitLength = gridSize / (gridLength - 1);
            
// finds closest vector in landscape to new position 
int closestX = (int) (newPosition.x/unitLength);
int closestZ = (int) (newPosition.z/unitLength);
// bottomleft
            
// gets group of 4 vectors around closest vector
Vector3[] closestPositions = {
    landscapeVertices[closestZ * gridLength + closestX], // closest point
    landscapeVertices [closestZ * gridLength + (closestX + 1)], 
    landscapeVertices[(closestZ + 1) * gridLength + closestX], 
    landscapeVertices[(closestZ + 1) * gridLength + (closestX + 1)]
};
```

Afterwards, the y value of each vector is compared to the y value of the camera, and if any y value is less than or equal to the sum of camera's y position and a threshold, the camera is colliding with the landscape and thus the function returns true. 

```c#
foreach(Vector3 position in closestPositions) {
    if(newPosition.y <= (position.y + threshold)) {
            return true;
    }
}
```

If the function returns true in the update function, the position is changed back to the original position.

## Vertex Shader :ocean:

I imagine that in the real world, there will be many waves traveling in random directions where each of them have a different amplitude and wave length. 
To simulate this, I had 64 seeds acting as the origin of the waves evenly spread across the water surface. 

From each origin there are 4 waves constantly going outwards with an amplitude of 5, 1, 0.2, 0.04 and wavelength of 0.5, 0.1, 0.02, 0.004. 

After I tried that I realized that the waves were too strong, and the reflection and refraction of the water were very distorted, so I divided the amplitude by 5000 to make the water look better.

## Ray Tracing for reflection and refraction of water :bulb:

Ok so it's not recursive ray tracing. After the reflection and refraction from the water I used vertex and fragment shaders copied from PhongShader.shader (with slight modification) to render the color for the pixel (using data passing into waveshader as uniforms). 

The reason I was able to do ray tracing for this landscape is the fact that if you look directly from the top in isotropic view you'll realize that the wireframe of the landscape forms a grid. This makes sense because of the way the diamondsquare algorithm works. Therefore to check which triangle each ray hits, we do not have to iterate through all of the triangles for the landscape, but only the one directly above or below it (i.e. the ones it goes through ignoring the y axis). This reduces the time complexity from O(n) to O(sqrt(n)) (n being the number of triangles in the landscape). 

When iterating through everything above and below the ray, I did it on a per square basis instead of per triangle. This is because most of the time if the ray goes through one of the triangle that form the square, it'll go through the other one as well and also frankly I just couldn't be bothered... 

I found a C++ implementation of the Moller-Trumbore intersection (apparently that's the best one we have) on wikipedia at https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm and I ported it to HLSL.

Users will be given an option to switch between different settings for the water shader, one more graphically-intensive than the other. For the water setting without ray tracing, a standard Phong Illumination model was used to render the water, done by calculating the ambient component, diffuse component, and specular component. While this setting looks considerably worse, it satisfies the project requirements, while providing better performance if required. Implementation of this illumination model is shown below.

```c#
    uniform float4 color;
    uniform float Ka;
    uniform float Kd;
    uniform float fAtt;
    uniform float Ks;
    uniform float specN;
    uniform float ambient;

    .
    .
    .

    float3 normal = getNormal(v.positionObject);

    float3 L = normalize(v.lightDirection);
    float3 N = normalize(normal);

    // Calculating ambient RGB intensities
    float3 amb = Ka * ambient * color.rgb;

    // Calculating RGB diffuse reflections
    float LdotN = dot(L, N);
    LdotN = max(LdotN, 0.0);
    float3 dif = fAtt * Kd * LdotN * color.rgb;

    // Calculating specular reflections
    float3 V = normalize(v.positionObject - v.cameraPos);
    float3 R = normalize(reflect(v.lightDirection, -normal));

    float specularFloat = dot(V, R);

    // Taking negative number to a power causes issues 
    if (specularFloat <= 0.0) {
        specularFloat = 0.0;
    } else {
        specularFloat = fAtt * Ks * pow(specularFloat, specN);
    }

    float4 spe = {specularFloat, specularFloat, specularFloat, 0};

    // Combine Phong Illumination model components

    float4 returnColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
    returnColor.rgb = amb + dif + spe;
    returnColor.a = color.a;

    return returnColor;
    
```

The colour and parameters of the Phong illumination model for the water were all passed as uniforms into the shader, which allows users to tinker with the values in the Unity editor. Firstly, the albedo was adjusted such that when the sun was underneath the landscape (i.e. nighttime), the water was not too brightly coloured. Next, the coefficient of diffuse reflection was adjusted such that when the sun rose over the landscape, the water wasn't diffusing too much light such that it's appearance would be overly bright and saturated. The attenuation factor was adjusted such that water that is further away from the sun had less diffuse reflection of the light, hence appearing duller. Then, the specular reflection coefficient was adjusted so that the specular component is sufficiently intense (i.e. it is not too dull/too bright). The specular power was adjusted so that the specular reflections were sufficiently sharp and not too spread out, to reproduce the slightly glossy texture of water.
Finally, the color and transparency of the water were adjusted to make it look as realistic as possible with the Phong Illumination model.

## Bump Map :world_map:

We decided to use a bump map to create some textures for the fractal landscape instead of it being flat. We sourced a texture bump map from the Asset Store and applied it. In order to make the bump map apply the illumination model we had to recalculate the surface normals, taking into account the changes the bump map would apply.

This was done by getting the normal and tangent of the vertex, and translating them to world normal and tangent. Then, we created the world bitangent from the world tangent and normal, and created a transformation matrix with the world tangent, bitangent, and normal.

Then, in the fragment shader, we got the normal from the bump map and performed a dot multiplication with the matrix to transform the normal from tangent to world space.

## Landscape's phong shader's parameters :mountain:
We set landscape's specular fraction (Ks) to 0.032 because a mountain is not shiny as all and there really shouldn't be any specular fraction. We set landscape's Ambient fraction (Ka) to 0.15 because we feel like that's a suitable number, any lower and it'll look like we're on the moon (shadow being completely black) and any higher
