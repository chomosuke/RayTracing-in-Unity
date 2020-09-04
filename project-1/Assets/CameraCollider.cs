using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraCollider : MonoBehaviour
{
    public float margin = 2.0f;
   
    // Start is called before the first frame update
    void Start()
    {
        Rigidbody rigidbody = this.gameObject.AddComponent<Rigidbody>();
        rigidbody.useGravity = false;
        BoxCollider cameraCollider = this.gameObject.AddComponent<BoxCollider>();
        // Setting the size of the collider
        cameraCollider.size = new Vector3(margin, margin, margin);

    }

    // Prevents camera from 'bouncing' away when colliding with another collider
    void OnCollisionStay(Collision other) {
        GetComponent<Rigidbody>().velocity = Vector3.zero;
        GetComponent<Rigidbody>().angularVelocity = Vector3.zero;
    }

}
