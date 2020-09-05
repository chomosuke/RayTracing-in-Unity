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

    public void setLandscapeMesh(Mesh mesh) {
        Vector3[] vertices = mesh.vertices;
        int landscapeSize = (int)Math.Sqrt(vertices.Length);
        
        setUniform(landscapeSize, TextureFormat.RGBAFloat, vect3ToFloatArray(vertices), "landscapeVertices");
        setUniform(landscapeSize, TextureFormat.RGBAFloat, vect3ToFloatArray(mesh.normals), "landscapeNormals");
        setUniform(landscapeSize, TextureFormat.RGBAFloat, colorsToFloatArray(mesh.colors), "landscapeColors");
        setUniform(landscapeSize, TextureFormat.RGFloat, vect2ToFloatArray(mesh.uv), "landscapeUV");
        setUniform(landscapeSize, TextureFormat.RGBAFloat, vect4ToFloatArray(mesh.tangents), "landscapeTangents");
        renderer.material.SetTexture("_BumpMap", landscape.GetTexture("_BumpMap"));

        renderer.material.SetFloat("landscapeSideLength", landscape.sizeOfLandscape);
        renderer.material.SetInt("landscapeSize", landscapeSize);
    }
    private void setUniform(int size, TextureFormat textureFormat, float[] data, String textureName) {
        
        Texture2D texture = new Texture2D(size, size, textureFormat, false);
        texture.LoadRawTextureData(new NativeArray<float>(data, Allocator.Temp));
        texture.Apply();
        texture.filterMode = FilterMode.Point;
        renderer.material.SetTexture(textureName, texture);
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
    private float[] vect2ToFloatArray(Vector2[] vects) {
        float[] array = new float[vects.Length*2];
        for (int i = 0; i < vects.Length; i++) {
            array[i*2] = vects[i].x;
            array[i*2+1] = vects[i].y;
        }
        return array;
    }
    private float[] vect4ToFloatArray(Vector4[] vects) {
        float[] array = new float[vects.Length*4];
        for (int i = 0; i < vects.Length; i++) {
            array[i*4] = vects[i].x;
            array[i*4+1] = vects[i].y;
            array[i*4+2] = vects[i].z;
            array[i*4+3] = vects[i].w;
        }
        return array;
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
