﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
public class DiamondSquare : MonoBehaviour
{
    public float maxSeedHeight; 
    public float noise;
    public float sizeOfLandscape;
    public int iterations;
    public float n;
    public GameObject water;
    public GameObject lightSource;

    [Range(0.0f, 1.0f)]
    public float specularFraction;
    
    [Range(0.0f, 1.0f)]
    public float ambient;
    public Texture2D _BumpMap;
    private MeshFilter landScapeMesh;
    private MeshRenderer renderer;
    // Start is called before the first frame update
    void Start()
    {
        random = new System.Random((int)(DateTime.Now.Millisecond));
        landScapeMesh = this.gameObject.AddComponent<MeshFilter>();
        landScapeMesh.mesh = CreateLandScapeMesh(iterations);
        
        renderer = this.gameObject.AddComponent<MeshRenderer>();
        renderer.material.shader = Shader.Find("Unlit/PhongShader");
        renderer.material.SetTexture("_BumpMap", _BumpMap);

        water.GetComponent<WaterReflection>().setLandscapeMesh(landScapeMesh.mesh);
    }

    // Update is called once per frame
    void Update()
    {
        renderer.material.SetFloat("n", n);
        renderer.material.SetFloat("ambient", ambient);
        renderer.material.SetFloat("specularFraction", specularFraction);
        renderer.material.SetVector("lightPos", lightSource.transform.position - transform.position);
        if (Input.GetKeyDown(KeyCode.Space)){
            landScapeMesh.mesh = this.CreateLandScapeMesh(iterations);
            renderer.material.SetTexture("_BumpMap", _BumpMap);
            water.GetComponent<WaterReflection>().setLandscapeMesh(landScapeMesh.mesh);
        }
    }

    public Texture GetTexture(String name) {
        return renderer.material.GetTexture(name);
    }

    private Mesh CreateLandScapeMesh(int iterations){
        Mesh m = new Mesh();
        m.name = "Landscape";
        
        // this will allow more than 65k vertices (up to 2^32)
        // that means that iteration can go higher than 8
        m.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;

        Vector3[] vertices = GenerateVectors(iterations);
        m.vertices = vertices;
        updateMaxMinY(vertices);

        Color[] colors =  new Color[vertices.Length];
        for (int i = 0; i < colors.Length; i++)
        {
            colors[i] = this.GetColor(vertices[i].y);
        }
        m.colors = colors;
        int[] triangles = GenerateTriangles(vertices);
        m.triangles = triangles;

        Vector2[] uvs = new Vector2[vertices.Length];
        for (int i = 0; i < uvs.Length; i++)
        {
            uvs[i] = new Vector2(vertices[i].x, vertices[i].z);
        }
        m.uv = uvs;
        // m.normals = GenerateNormals(triangles, vertices);
        m.RecalculateNormals();
        m.RecalculateTangents();
        return m;
    }

    private float maxY, minY;
    public float getMaxY() { return maxY; }
    public float getMinY() { return minY; }
    private void updateMaxMinY(Vector3[] vertices) {
        maxY = vertices[0].y;
        minY = vertices[0].y;
        foreach (Vector3 vertex in vertices) {
            if (vertex.y > maxY) {
                maxY = vertex.y;
            }
            if (vertex.y < minY) {
                minY = vertex.y;
            }
        }
    }

    // this function was written before i know RecalculateNormals() exists
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

    private Color GetColor(float height){
        Gradient gradient = new Gradient();
        GradientAlphaKey[] gradientAlphaKeys = new GradientAlphaKey[4];
        GradientColorKey[] gradientColorKeys = new GradientColorKey[4];

        float maxMinYDiff = getMaxY() - getMinY();
        float heightToTime = (height - getMinY())/maxMinYDiff;

        gradientColorKeys[0].color = new Color(231f/255,196f/255,150f/255);
        gradientColorKeys[0].time = 0.41f;
        gradientColorKeys[1].color = new Color(135f/255,182f/255,124f/255);
        gradientColorKeys[1].time = 0.51f;
        gradientColorKeys[2].color = new Color(135f/255,182f/255,124f/255);
        gradientColorKeys[2].time = 0.61f;
        gradientColorKeys[3].color = Color.white;
        gradientColorKeys[3].time = 0.85f;

        gradientAlphaKeys[0].alpha = 1f;
        gradientAlphaKeys[0].time = 0.41f;
        gradientAlphaKeys[1].alpha = 1f;
        gradientAlphaKeys[1].time = 0.51f;
        gradientAlphaKeys[2].alpha = 1f;
        gradientAlphaKeys[2].time = 0.61f;
        gradientAlphaKeys[3].alpha = 1f;
        gradientAlphaKeys[3].time = 0.85f;

        gradient.SetKeys(gradientColorKeys, gradientAlphaKeys);
        return gradient.Evaluate(heightToTime);
    }

    private int GenerateLengths(int iterations){
        return (int) Math.Pow(2, iterations) + 1;
    }

    private System.Random random;
    private float RandomRange(float minimum, float maximum){
        return minimum + (float) random.NextDouble() * (maximum - minimum);
    }

}