//UNITY_SHADER_NO_UPGRADE

Shader "Unlit/WaveShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D_float landscapeVertices;
			uniform sampler2D_float landscapeNormals;
			uniform sampler2D_float landscapeColors;
			uniform int landscapeSize;
			// uniform float planeSize; 
			// uniform int numOfVerticesOnPlaneEdge;

			// uniform for PhongShader
			uniform float n;
			uniform float ambient;
			uniform float specularFraction;

			struct vertIn
			{
				float4 vertex : POSITION;
			};

			struct vertOut
			{
				float4 vertex : SV_POSITION;
				float3 position : POSITION_IN_WORLD_SPACE;
			};

			// like landscapeFrag, this struct have to be identical to the one in PhongShader.shader
			struct vertInLandscape
			{
				float4 vertex : POSITION;
				float4 color : COLOR0;
				float3 normal : NORMAL;
			};
			// like landscapeFrag, this struct have to be identical to the one in PhongShader.shader
			struct vertOutLandscape
			{
				float4 vertex : SV_POSITION;
				float4 color : COLOR0;
				float3 normal : NORMAL;
				float3 position : POSITION_IN_WORLD_SPACE;
			};

			float getDisplacement(float3 v);
			float3 getNormal(float3 v);

			vertOutLandscape landscapeVert(vertInLandscape v);
			fixed4 landscapeFrag(vertOutLandscape v);

			// Implementation of the vertex shader
			vertOut vert(vertIn v)
			{
				v.vertex.y = getDisplacement(v.vertex.xyz);

				vertOut o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.position = v.vertex.xyz;
				return o;
			}
			// i hope this place holder fuction get replaced by something more realistic by someone who's not me
			float getDisplacement(float3 v) { // displacement can only be in the y direction and 
			// must be directly assigned to v.vertex.y or else everything will break;
			// damn too much coupling between function for this thing.
				return sin(v.x*50 + _Time.y)/20;
			}

			float3 getNormal(float3 v0, float3 v1, float3 v2) {
				float3 u = v0 - v1;
				float3 v = v0 - v2;
				return normalize(cross(u, v));
			}
			float3 getNormal(float3 v) { 
				float L = 0.01; 
				// num too small and it gets cut off when added to the big float v.x and v.z
				// cause remember float only have about 8 digit of precision

				int length = 4;
				float3 vs[4] = {
					{v.x-L, 0, v.z},
					{v.x, 0, v.z+L},
					{v.x+L, 0, v.z},
					{v.x, 0, v.z-L},
				};
				for (int i = 0; i < length; i++) {
					// apply displacment
					vs[i].y = getDisplacement(vs[i]);
				}
				float3 normal = {0, 0, 0};
				for (int i = 0; i < length; i++) {
					normal += getNormal(v, vs[i], vs[(i+1) % length]);
				}
				return normalize(normal);
			}
			
			
			// Implementation of the fragment shader
			fixed4 frag(vertOut v) : SV_Target {
				float3 normal = getNormal(v.position); // per pixel normal
				
			}

			// // this fragment shader test the getNormal function
			// fixed4 frag(vertOut v) : SV_Target {
			// 	float3 normal = getNormal(v.position);
			// 	fixed4 color= {normal, 1.0};
			// 	return color;
			// }
			
			// this shader must be exactly identical to the one in PhongShader.shader
			vertOutLandscape landscapeVert(vertInLandscape v)
			{
				vertOutLandscape o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.color = v.color;
				o.normal = v.normal;
				o.position = v.vertex;
				return o;
			}
			// this shader must be exactly identical to the one in PhongShader.shader
			fixed4 landscapeFrag(vertOutLandscape v)
			{
				// according to documentation Directional lights: (world space direction, 0). Other lights: (world space position, 1).
				float3 lightDirection = _WorldSpaceLightPos0;
				
				float3 cameraTransform = mul(unity_WorldToObject, _WorldSpaceCameraPos);

				// dot product will give ||a|| ||b|| cos(theta)
				// as both a and b are unit vector (i normalized them)
				// dot(...) will return cos(theta)
				// in case of theta larger than 90 degrees cos(theta) will be smaller than 0
				// that isn't very acceptable cause theta > 90 just mean the light is on the other side
				// so hence max(dot(...), 0)
				float diffuse = max(dot(normalize(v.normal), normalize(lightDirection)), 0.0);
				diffuse *= 1.0-ambient; // this is so that diffuse + ambient <= 1

				float3 viewDir = v.position - cameraTransform;
				float3 reflectionDir = reflect(lightDirection, -v.normal); // this will be normalized
				
				float specular = dot(normalize(viewDir), normalize(reflectionDir));
				if (specular <= 0.0) {
					// one thing very fustrating is that this pow function misbehave when the first argument is 0
					specular = 0.0;
				} else {
					specular = pow(specular, n) * specularFraction;
				}
				float4 specularComponent = {specular, specular, specular, specular };
				
				return v.color * (ambient + diffuse) + specularComponent;
			}
			ENDCG
		}
	}
}