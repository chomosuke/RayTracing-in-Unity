using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class CameraMovement : MonoBehaviour
{
    
    public float cameraSpeed = 5.0f;
    private bool positionSet = false;

    private Vector3[] landscapeVertices;
    private float maxY;
    private float minY;
    private float gridSize;


    // Update is called once per frame
    void Update()
    {
        Vector3 previousPosition = this.gameObject.transform.position;

        if (Input.GetKeyDown(KeyCode.Space)){
            positionSet = false;
        }

        GameObject landscape = GameObject.Find("Landscape");

        if(!positionSet && landscape.GetComponent<MeshFilter>() != null) {
            positionSet = true;

            landscapeVertices = landscape.GetComponent<MeshFilter>().mesh.vertices;
            gridSize = landscape.GetComponent<DiamondSquare>().sizeOfLandscape;
            maxY = landscape.GetComponent<DiamondSquare>().getMaxY();
            minY = GameObject.Find("Water").transform.position.y;
        

            this.gameObject.transform.position = landscapeVertices[landscapeVertices.Length/2];
            this.gameObject.transform.position += Vector3.up * maxY;
        }
    
    
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

        if (landscape_collision (transform.position)) {
            transform.position = previousPosition;
        }
    }

    bool landscape_collision (Vector3 newPosition) {
        float threshold = 0.8f;
        
        // if camera is at the edge of the map
        if(newPosition.x > gridSize || newPosition.x < 0 || newPosition.z > gridSize || newPosition.z < 0 
             || newPosition.y > 2*maxY || newPosition.y <= (minY + threshold)) {
            return true;
        } else {
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
                landscapeVertices [(closestZ * gridLength + closestX) + 1], 
                landscapeVertices[(closestZ + 1) * gridLength + closestX], 
                landscapeVertices[((closestZ + 1) * gridLength + closestZ) + 1]
            };

            foreach(Vector3 position in closestPositions) {
                if(newPosition.y <= (position.y + threshold)) {
                    return true;
                }
            }
        }
        return false;
    }
}
