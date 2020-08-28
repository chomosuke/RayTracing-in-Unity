using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraControl : MonoBehaviour
{

    public float sensitivity = 2.0f;

    public Quaternion camRotation;

    // Update is called once per frame
    void Update()
    {  

        camRotation.x -= sensitivity * Input.GetAxis("Mouse Y"); // Look left/right
        camRotation.y += sensitivity * Input.GetAxis("Mouse X"); // Look up/down

        transform.localRotation = Quaternion.Euler(camRotation.x, camRotation.y, camRotation.z);

    }

}
