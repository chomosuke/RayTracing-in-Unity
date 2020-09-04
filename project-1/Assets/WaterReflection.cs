using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using Unity.Collections;

public class WaterReflection : MonoBehaviour
{
    public float size;
    public GameObject landscapeObject;
    private DiamondSquare landscape;
    private MeshFilter meshFilter;
    private MeshRenderer renderer;
    // Start is called before the first frame update
    void Start()
    {
        landscape = landscapeObject.GetComponent<DiamondSquare>();
        meshFilter = gameObject.AddComponent<MeshFilter>();
        meshFilter.mesh = GenerateMesh();
        renderer = this.gameObject.AddComponent<MeshRenderer>();
        renderer.material.shader = Shader.Find("Unlit/WaveShader");
        renderer.material.SetInt("numOfVerticesOnPlaneEdge", planeMeshSize);
        renderer.material.SetFloat("planeSize", size);
    }

    float[] landscapeVertices;
    float[] landscapeNormals;
    float[] landscapeColors;
    int landscapeSize;
    public void setLandscapeMesh(Mesh mesh) {
        landscapeVertices = vect3ToFloatArray(mesh.vertices);
        landscapeNormals = vect3ToFloatArray(mesh.normals);
        landscapeColors = colorsToFloatArray(mesh.colors);
        landscapeSize = (int)Math.Sqrt(landscapeVertices.Length/4);
        updateLandscapeUniforms();
    }
    private float[] vect3ToFloatArray(Vector3[] vects) {
        float[] array = new float[vects.Length*4];
        for (int i = 0; i < vects.Length; i++) {
            array[i*4] = vects[i].x;
            array[i*4+1] = vects[i].y;
            array[i*4+2] = vects[i].z;
            array[i*4+3] = 1;
        }
        return array;
    }
    private float[] colorsToFloatArray(Color[] colors) {
        float[] array = new float[colors.Length*4];
        for (int i = 0; i < colors.Length; i++) {
            array[i*4] = colors[i].r;
            array[i*4+1] = colors[i].g;
            array[i*4+2] = colors[i].b;
            array[i*4+3] = colors[i].a;
        }
        return array;
    }

    private void updateLandscapeUniforms() {
        if (landscapeVertices != null 
         && landscapeNormals != null 
         && landscapeColors != null) {

            Texture2D vertices = new Texture2D(landscapeSize, landscapeSize, TextureFormat.RGBAFloat, false);
            vertices.LoadRawTextureData(new NativeArray<float>(landscapeVertices, Allocator.Temp));
            vertices.Apply();
            vertices.filterMode = FilterMode.Point;
            renderer.material.SetTexture("landscapeVertices", vertices);

            Texture2D normals = new Texture2D(landscapeSize, landscapeSize, TextureFormat.RGBAFloat, false);
            normals.LoadRawTextureData(new NativeArray<float>(landscapeNormals, Allocator.Temp));
            normals.Apply();
            normals.filterMode = FilterMode.Point;
            renderer.material.SetTexture("landscapeNormals", normals);

            Texture2D colors = new Texture2D(landscapeSize, landscapeSize, TextureFormat.RGBAFloat, false);
            colors.LoadRawTextureData(new NativeArray<float>(landscapeColors, Allocator.Temp));
            colors.Apply();
            colors.filterMode = FilterMode.Point;
            renderer.material.SetTexture("landscapeColors", colors);

            renderer.material.SetFloat("landscapeSideLength", landscape.sizeOfLandscape);
            renderer.material.SetInt("landscapeSize", landscapeSize);

            // indicate that it's already been passed to uniforms
            landscapeVertices = null;
            landscapeNormals = null;
            landscapeColors = null;
        }
    }

    const int planeMeshSize = 200;
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
        // update uniforms
        renderer.material.SetFloat("n", landscape.n);
        renderer.material.SetFloat("ambient", landscape.ambient);
        renderer.material.SetFloat("specularFraction", landscape.specularFraction);
        renderer.material.SetMatrix("worldToLandscape", landscape.GetComponent<MeshRenderer>().worldToLocalMatrix);
    }
}
