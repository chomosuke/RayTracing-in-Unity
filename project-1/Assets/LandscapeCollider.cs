using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LandscapeCollider : MonoBehaviour
{
    // Iteration limit before convex is triggered for mesh collider
    private int limit = 5;
    private bool meshAssigned;
    private MeshCollider landscapeCollider;
    // Start is called before the first frame update
    void Start()
    {   
        DiamondSquare diamondSquare = this.gameObject.GetComponent<DiamondSquare>();
        landscapeCollider = this.gameObject.AddComponent<MeshCollider>();
        meshAssigned = false;
        
        if(diamondSquare.iterations > limit) {
            landscapeCollider.convex = true;
        } else {
            landscapeCollider.convex = false;
        }
        
    }

    void Update() {
        // Unassigns a mesh, and generates/assigns a new mesh to attach to collider
        if(!meshAssigned) {
            MeshFilter landscapeMesh = this.gameObject.GetComponent<MeshFilter>();
            landscapeCollider.sharedMesh = null;
            landscapeCollider.sharedMesh = landscapeMesh.mesh;
            meshAssigned = true;
        }
         if (Input.GetKeyDown(KeyCode.Space)){
            meshAssigned = false;
        }
    }


}
