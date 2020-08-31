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
            cameraDirection.transform.position += cameraDirection.transform.right * cameraSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.A)) {
            cameraDirection.transform.position += cameraDirection.transform.right * -1 * cameraSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.W)) {
            cameraDirection.transform.position += cameraDirection.transform.forward * cameraSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.S)) {
            cameraDirection.transform.position += cameraDirection.transform.forward * -1 * cameraSpeed * Time.deltaTime;
        }

    }
}
