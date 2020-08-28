using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    
    public float cameraSpeed = 5.0f;

    public CameraControl cameraDirection;

    // Update is called once per frame
    void Update()
    {
    
        if (Input.GetKey(KeyCode.D)) {
            this.transform.localPosition += cameraDirection.transform.right * cameraSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.A)) {
            this.transform.localPosition += cameraDirection.transform.right * -1 * cameraSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.W)) {
            this.transform.localPosition += cameraDirection.transform.forward * cameraSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.S)) {
            this.transform.localPosition += cameraDirection.transform.forward * -1 * cameraSpeed * Time.deltaTime;
        }

    }
}
