using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LandscapeBoundary : MonoBehaviour
{
    public enum Side {Front, Back, Top, Bottom, Left, Right }
    private BoxCollider boundary;

    // Assign edge to boundary in editor
    public Side edge;

    // Determines space between boundary and landscape
    public float margin = 1.0f;

    // Thickness of boundary
    private float thickness = 0.1f;

    private bool boundarySet = false;
    
    // Start is called before the first frame update
    void Start() {
        boundary = this.gameObject.AddComponent<BoxCollider>();
        setBoundary();
        boundarySet = true;
    }

      // Update is called once per frame
    void Update() {
        // Resets boundary if new terrain is generated
        if(!boundarySet) {
            setBoundary();
            boundarySet = true;
        }
        if (Input.GetKeyDown(KeyCode.Space)){
            boundarySet = false;
        }


    }
    
    public void setBoundary()
    {
        DiamondSquare diamondSquare = GameObject.Find("Landscape").GetComponent<DiamondSquare>();
        float unitHeight = diamondSquare.maxSeedHeight + margin;
        float unitSide = diamondSquare.sizeOfLandscape + margin;
        
        // Setting the size of box collider for the edge
        if(edge == Side.Top || edge == Side.Bottom) {
            boundary.size = new Vector3(unitSide, thickness, unitSide);
        } else if (edge == Side.Front || edge == Side.Back) {
            boundary.size = new Vector3(unitSide, unitHeight*2.0f, thickness);
        } else {
            boundary.size = new Vector3(thickness, unitHeight*2.0f, unitSide);
        }

        // Sets the position of the box collider (size: total height = 2 * unitHeight, side = unitSide)
        switch(edge) {
            case Side.Top:
               this.gameObject.transform.localPosition = new Vector3(unitSide/2 - margin/2, unitHeight*2.0f, unitSide/2 - margin/2);
                break;
            case Side.Bottom:
                this.gameObject.transform.localPosition = new Vector3(unitSide/2 - margin/2, 0.0f, unitSide/2 - margin/2);
                break;
            case Side.Left:
                this.gameObject.transform.localPosition = new Vector3(-margin/2, unitHeight, unitSide/2 - margin/2);
                break;
            case Side.Right:
                this.gameObject.transform.localPosition = new Vector3(unitSide - margin/2, unitHeight, unitSide/2 - margin/2);
                break;
            case Side.Front:
                this.gameObject.transform.localPosition = new Vector3(unitSide/2 - margin/2, unitHeight, unitSide - margin/2);
                break;
            case Side.Back:
                this.gameObject.transform.localPosition = new Vector3(unitSide/2 - margin/2, unitHeight, -margin/2);
                break;
        }

        
    }

  
    
    
}
