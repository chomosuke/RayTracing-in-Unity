using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    
    public float cameraSpeed = 5.0f;
    private bool positionSet = false;

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space)){
            positionSet = false;
        }

        if(!positionSet && GameObject.Find("Landscape").GetComponent<MeshFilter>() != null) {
            positionSet = true;
            Vector3[] landscapeVertices = GameObject.Find("Landscape").GetComponent<MeshFilter>().mesh.vertices;
            this.gameObject.transform.position = landscapeVertices[landscapeVertices.Length/2] + Vector3.up;
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

    }
}
