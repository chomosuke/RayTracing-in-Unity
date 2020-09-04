//UNITY_SHADER_NO_UPGRADE

Shader "Unlit/PhongShader"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform float n;
			uniform float ambient;
			uniform float specularFraction;

			struct vertIn
			{
				float4 vertex : POSITION;
				float4 color : COLOR0;
				float3 normal : NORMAL;
			};

			struct vertOut
			{
				float4 vertex : SV_POSITION;
				float4 color : COLOR0;
				float3 normal : NORMAL;
				float3 position : POSITION_IN_OBJECT_SPACE;
				float3 lightDirection : LIGHT_DIRECTION_LANDSCAPE_SPACE;
				float3 cameraPos : CAMERA_POSITION_LANDSCAPE_SPACE;
			};

			// Implementation of the vertex shader
			vertOut vert(vertIn v)
			{
				vertOut o;
				
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.color = v.color;
				o.normal = v.normal;
				o.position = v.vertex;

				// according to documentation Directional lights: (world space direction, 0). Other lights: (world space position, 1).
				o.lightDirection = normalize(mul(unity_WorldToObject, _WorldSpaceLightPos0));
				o.cameraPos = mul(unity_WorldToObject, _WorldSpaceCameraPos);
				return o;
			}
			
			// Implementation of the fragment shader
			fixed4 frag(vertOut v) : SV_Target
			{

				// dot product will give ||a|| ||b|| cos(theta)
				// as both a and b are unit vector (i normalized them)
				// dot(...) will return cos(theta)
				// in case of theta larger than 90 degrees cos(theta) will be smaller than 0
				// that isn't very acceptable cause theta > 90 just mean the light is on the other side
				// so hence max(dot(...), 0)
				float diffuse = max(dot(normalize(v.normal), normalize(v.lightDirection)), 0.0);
				diffuse *= 1.0-ambient; // this is so that diffuse + ambient <= 1

				float3 viewDir = v.position - v.cameraPos;
				float3 reflectionDir = reflect(v.lightDirection, -v.normal);
				
				float specular = dot(normalize(viewDir), normalize(reflectionDir));
				if (specular <= 0.0) {
					// one thing very fustrating is that this pow function misbehave when the first argument is 0
					specular = 0.0;
				} else {
					specular = pow(specular, n) * specularFraction;
				}
				float4 specularComponent = {specular, specular, specular, 0 };
				
				return v.color * (ambient + diffuse) + specularComponent;
			}
			ENDCG
		}
	}
}
