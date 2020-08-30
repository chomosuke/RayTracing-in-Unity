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
			};

			// Implementation of the vertex shader
			vertOut vert(vertIn v)
			{
				vertOut o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.color = v.color;
				o.normal = v.normal;
				return o;
			}
			
			// Implementation of the fragment shader
			fixed4 frag(vertOut v) : SV_Target
			{
				float ambient = 0.1f;
				float3 lightDirection = { 0.6f, 0.6f, 0.6f };

				// dot product will give ||a|| ||b|| cos(theta)
				// as both a and b are unit vector (i normalized them)
				// dot(...) will return cos(theta)
				// in case of theta larger than 90 degrees cos(theta) will be smaller than 0
				// that isn't very acceptable cause theta > 90 just mean the light is on the other side
				// so hence max(dot(...), 0)
				float diffuse = max(dot(normalize(v.normal), normalize(lightDirection)), 0.0);
				
				return v.color * (ambient + diffuse);
			}
			ENDCG
		}
	}
}
