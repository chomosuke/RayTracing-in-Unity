using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class WaterReflection : MonoBehaviour
{
    public float size;
    private DiamondSquare landScape;
    private MeshFilter meshFilter;
    private MeshRenderer renderer;
    // Start is called before the first frame update
    void Start()
    {
        landScape = GameObject.Find("Landscape").GetComponent<DiamondSquare>();
        meshFilter = gameObject.AddComponent<MeshFilter>();
        meshFilter.mesh = GenerateMesh();
        renderer = this.gameObject.AddComponent<MeshRenderer>();
        renderer.material.shader = Shader.Find("Unlit/WaveShader");
        // renderer.material.SetInt("numOfVerticesOnPlaneEdge", planeMeshSize);
        // renderer.material.SetFloat("planeSize", size);
    }

    const int planeMeshSize = 500;
    private Mesh GenerateMesh() {
        Mesh m = new Mesh();
        m.name = "water";
        
        // this will allow more than 65k vertices (up to 2^32)
        // that means that iteration can go higher than 8
        m.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;

        Vector3[] vertices = GenerateVectors(planeMeshSize);
        m.vertices = vertices;
        int[] triangles = GenerateTriangles(vertices);
        m.triangles = triangles;
        // m.normals = GenerateNormals(triangles, vertices);
        // m.RecalculateNormals();
        return m;
    }

    private Vector3[] GenerateVectors(int width){
        Vector3[] vectors = new Vector3[width * width];
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < width; y++)
            {
                vectors[y*width+x] = new Vector3(x*(size / (width-1))
                    , 0, y*(size / (width-1)));
            }
        }
        return vectors;
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

    // Update is called once per frame
    void Update()
    {
        
    }
}
