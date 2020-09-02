using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraBoundary : MonoBehaviour
{
    public enum Side {Front, Back, Top, Bottom, Left, Right }
    private BoxCollider boundary;
    public Side edge;

    public float margin = 1.0f;

    private bool boundarySet = false;
    
    // Start is called before the first frame update
    void Start() {
        boundary = this.gameObject.AddComponent<BoxCollider>();
        setBoundary();
        boundarySet = true;
    }

      // Update is called once per frame
    void Update() {
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
        float maxHeight = diamondSquare.maxSeedHeight + margin;
        float maxSide = diamondSquare.sizeOfLandscape + margin;
        


        if(edge == Side.Top || edge == Side.Bottom) {
            boundary.size = new Vector3(maxSide, margin, maxSide);
        } else if (edge == Side.Front || edge == Side.Back) {
            boundary.size = new Vector3(maxSide, maxHeight*4.0f, margin);
        } else {
            boundary.size = new Vector3(margin, maxHeight*4.0f, maxSide);
        }

        switch(edge) {
            case Side.Top:
               this.gameObject.transform.position = new Vector3(maxSide/2, maxHeight*3.0f, maxSide/2);
                break;
            case Side.Bottom:
                this.gameObject.transform.position = new Vector3(maxSide/2, -maxHeight, maxSide/2);
                break;
            case Side.Left:
                this.gameObject.transform.position = new Vector3(0.0f, maxHeight, maxSide/2);
                break;
            case Side.Right:
                this.gameObject.transform.position = new Vector3(maxSide, maxHeight, maxSide/2);
                break;
            case Side.Front:
                this.gameObject.transform.position = new Vector3(maxSide/2, maxHeight, maxSide);
                break;
            case Side.Back:
                this.gameObject.transform.position = new Vector3(maxSide/2, maxHeight, 0.0f);
                break;
        }

        
    }

  
    
    
}
