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
| Jasmine Bond | Camera Control, Diamond Square, ReadMe      | Not Done |
| Ju Wey Tan   | Bump Map, Colouring, Diamond Square, ReadMe | Done |
| Jasper Ng    | Camera Control, Water Shader ?, ReadMe      | Not done |

## General info
This is project - 1 where we were tasked with generating a fractal landscape in Unity using the Diamond Square Algorithm. We also had to write our own custom CG/HLSL shader for the landscape with the Phong illumination model, and a water shader, where we have included the option for ray tracing. We have also applied a bump map to the landscape mesh.
	
## Technologies
Project is created with:
* Unity 2019.4.3f1

## Diamond-Square implementation :mountain:

We generated the height map for the fractal landscape using a 2D float array with a size that can be defined in the unity inspector and initialised the four corners. Then, we iteratively performed the diamond step and the square step until the 2D array was filled.

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


#### Landscape Boundaries :construction:

For the boundaries of the landscape, we chose to use a box collider for each outer edge of our landscape (i.e. for the top, bottom, left, right, front and back). A collider is attached to 6 cube objects corresponding to each side. This is handled by the LandscapeBoundary script. In order to reduce repetition, enums were used to identify which side was to be generated by the script.

```c#
public enum Side {Front, Back, Top, Bottom, Left, Right }
```

Depending on the edge the collider represents, a size and position is assigned to it. For the sizes, each pair of the following sides are equal:

- top and bottom
- left and right
- front and back

In order to gain the length of each side, and the height of the landscape, the script gathers the maxSeedHeight and sizeOfLandscape from the DiamondSquare script. A 'margin' is added to these values to ensure there is some space between the collider and the landscape.

i.e.
```c#
DiamondSquare diamondSquare = GameObject.Find("Landscape").GetComponent<DiamondSquare>();
float unitHeight = diamondSquare.maxSeedHeight + margin;
float unitSide = diamondSquare.sizeOfLandscape + margin;
```

The total height of the boundary *cube* is 2 unitHeights, and each side is 1 unitSide.

A switch statement was used to assign the position of each collider. 

e.g. For the front face:
```c#
case Side.Front:
  this.gameObject.transform.localPosition = new Vector3(unitSide/2 - margin/2, unitHeight, unitSide - margin/2);
      break;
```

**-------------TODO----------------**
#### Landscape Collider
#### Camera Collider
For the Main Camera, the collider is controlled by CameraCollider. In the script, the Main Camera is made a rigid body, so that it can interact with other colliders. The gravity of the camera is set to 0 so that it does not fall. The size of the box collider is determined by the margin variable, which is a public variable that can be modified in the Unity editor.

```c#
void Start()
    {
        Rigidbody rigidbody = this.gameObject.AddComponent<Rigidbody>();
        rigidbody.useGravity = false;
        BoxCollider cameraCollider = this.gameObject.AddComponent<BoxCollider>();
        // Setting the size of the collider
        cameraCollider.size = new Vector3(margin, margin, margin);
    }
```


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

## Bump Map :map:

We decided to use a bump map to create some textures for the fractal landscape instead of it being flat. We sourced a texture bump map from the Asset Store and applied it. In order to make the bump map apply the illumination model we had to recalculate the surface normals, taking into account the changes the bump map would apply.

This was done by getting the normal and tangent of the vertex, and translating them to world normal and tangent. Then, we created the world bitangent from the world tangent and normal, and created a transformation matrix with the world tangent, bitangent, and normal.

Then, in the fragment shader, we got the normal from the bump map and performed a dot multiplication with the matrix to transform the normal from tangent to world space.

**Now Get ready to complete all the tasks:**

- [x] Read the handout for Project-1 carefully
- [x] Modelling of fractal landscape
- [x] Camera motion 
- [x] Surface properties
- [x] Project organisation and documentation
