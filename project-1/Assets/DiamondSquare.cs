using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
public class DiamondSquare : MonoBehaviour
{
    public float maxSeedHeight; 
    public float noise;
    public float sizeOfLandscape;
    public int iterations;
    private MeshFilter landScapeMesh;
    
    // Start is called before the first frame update
    void Start()
    {
        random = new System.Random((int)(Time.realtimeSinceStartup*1000));
        landScapeMesh = this.gameObject.AddComponent<MeshFilter>();
        landScapeMesh.mesh = this.CreateLandScapeMesh(iterations);
        MeshRenderer renderer = this.gameObject.AddComponent<MeshRenderer>();
        renderer.material.shader = Shader.Find("Unlit/PhongShader");
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space)){
            landScapeMesh.mesh = this.CreateLandScapeMesh(iterations);
        }
    }

    private Mesh CreateLandScapeMesh(int iterations){
        Mesh m = new Mesh();
        m.name = "Landscape";

        Vector3[] vertices = GenerateVectors(iterations);
        m.vertices = vertices;
        Color[] colors =  new Color[vertices.Length];
        for (int i = 0; i < colors.Length; i++)
        {
            // colors[i] = new Color(RandomRange(0f, 1f), RandomRange(0f, 1f),RandomRange(0f, 1f));
            colors[i] = Color.blue;
        }
        m.colors = colors;
        int[] triangles = GenerateTriangles(vertices);
        m.triangles = triangles;
        m.normals = GenerateNormals(triangles, vertices);
        return m;
    }

    private Vector3[] GenerateNormals(int[] triangles, Vector3[] vertices) {
        // the normal for each vertex is the average of all the normal of triangles that shares that vertex
        // so naturally we would want to figure out how many triangles shares a vertex
        // but turns out that actually doesn't matter here because
        // our normal is directional so as long as we don't have different absolute value for each triangle's normal
        // and we normalize (change the absolute value for a vector to 1) all vertex normals in the end
        // they should average out just fine
        // so what i'm going to do here is:
        // calculate each triangle's normal
        // normalize them
        // add them to each three corrisponding vertexes of each triangle
        // and normalize the normals for vertexes in the end

        Vector3[] normals = new Vector3[vertices.Length];
        for (int i = 0; i < normals.Length; i++) {
            // initialize normals to 0
            normals[i] = new Vector3(0f, 0f, 0f);
        }
        for (int i = 0; i < triangles.Length; i+=3) {
            // calculate this triangle's normal
            // by cross producting two edges of the triangle
            Vector3 vertex1 = vertices[triangles[i]];
            Vector3 vertex2 = vertices[triangles[i+1]];
            Vector3 vertex3 = vertices[triangles[i+2]];
            Vector3 u = vertex1 - vertex2;
            Vector3 v = vertex1 - vertex3;
            Vector3 thisNormal = Vector3.Cross(u, v).normalized;
            normals[triangles[i]] += thisNormal;
            normals[triangles[i+1]] += thisNormal;
            normals[triangles[i+2]] += thisNormal;
        }
        // normalize all vectors
        for (int i = 0; i < normals.Length; i++) {
            normals[i].Normalize();
        }
        
        return normals;
    }

    private Vector3[] GenerateVectors(int iterations){
        float[][] grid = GenerateHeightMap(iterations);
        Vector3[] vectors = new Vector3[grid.Length * grid.Length];
        for (int x = 0; x < grid.Length; x++)
        {
            for (int y = 0; y < grid.Length; y++)
            {
                vectors[y*grid.Length+x] = new Vector3(x*(sizeOfLandscape / (grid.Length-1))
                    , grid[x][y], y*(sizeOfLandscape / (grid.Length-1)));
            }
        }
        return vectors;
    }

    // Creates height map
    private float[][] GenerateHeightMap(int iterations){

        int length = GenerateLengths(iterations);
        float[][] grid = new float[length][];
        for (int i = 0; i < grid.Length; i++)
        {
            grid[i] = new float[length];
        }

        // Create 4 corners
        grid[0][0] = RandomRange(0, maxSeedHeight);
        grid[0][length-1] = RandomRange(0, maxSeedHeight);
        grid[length-1][0] =  RandomRange(0, maxSeedHeight);
        grid[length-1][length-1] = RandomRange(0, maxSeedHeight);

        int currentLength = length-1;
        float randomness = noise;

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
        return grid;
    }

    private int[] GenerateTriangles(Vector3[] vectorsPreTriangle){
        int squaresOnEdge = (((int)Math.Sqrt(vectorsPreTriangle.Length)-1));
        int[] triangles = new int[(squaresOnEdge * squaresOnEdge)*6];
        int x = 0;
        int y = 0;
        for (int i = 0; i < triangles.Length; i+=6)
        {
            triangles[i] = y*(squaresOnEdge+1)+x;
            triangles[i+1] = (y+1)*(squaresOnEdge+1)+x;
            triangles[i+2] = y*(squaresOnEdge+1)+x+1;
            triangles[i+3] = y*(squaresOnEdge+1)+x+1;
            triangles[i+4] = (y+1)*(squaresOnEdge+1)+x;
            triangles[i+5] = (y+1)*(squaresOnEdge+1)+x+1;

            x++;
            if(x == squaresOnEdge){
                y++;
                x = 0;
            }
        }
        return triangles;
    }

    private int GenerateLengths(int iterations){
        if (iterations == 0){
            return 2;
        }
        return 2*GenerateLengths(iterations-1)-1;
    }

    private System.Random random;
    private float RandomRange(float minimum, float maximum){
        return minimum + (float) random.NextDouble() * (maximum - minimum);
    }
}
