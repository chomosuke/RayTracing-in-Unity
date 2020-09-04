﻿//UNITY_SHADER_NO_UPGRADE

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
			uniform sampler2D landscapeColors;
			uniform int landscapeSize;
			uniform float landscapeSideLength;
			uniform float4x4 worldToLandscape;
			uniform int numOfVerticesOnPlaneEdge;
			uniform float planeSize; 

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
				float3 positionObject : POSITION_IN_OBJECT_SPACE;
				float3 positionLandscape : POSITION_IN_LANDSCAPE_SPACE;
				float3 lightDirection : LIGHT_DIRECTION_LANDSCAPE_SPACE;
				float3 cameraPos : CAMERA_POSITION_LANDSCAPE_SPACE;
			};

			struct textCoords {
				// texture coordinates of a landscape triangle 
				half2 coord1;
				half2 coord2;
				half2 coord3;
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
				float3 position : POSITION_IN_OBJECT_SPACE;
				float3 lightDirection : LIGHT_DIRECTION_LANDSCAPE_SPACE;
				float3 cameraPos : CAMERA_POSITION_LANDSCAPE_SPACE;
			};

			float getY(float3 v);
			float3 getNormal(float3 v);

			textCoords findTriangle(float3 rayDir, float3 rayOrigin, out float3 intersection);
			bool MTIntersection(float3 rayOrigin, float3 rayDir, 
							    float3 coord1, float3 coord2, float3 coord3,
								out float3 intersection);

			vertOutLandscape landscapeVert(vertInLandscape v);
			fixed4 landscapeFrag(vertOutLandscape v);

			// Implementation of the vertex shader
			vertOut vert(vertIn v)
			{
				v.vertex.y = getY(v.vertex.xyz);

				vertOut o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.positionObject = v.vertex.xyz;
				o.positionLandscape = mul(worldToLandscape, mul(unity_ObjectToWorld, o.positionObject));
				o.cameraPos = mul(worldToLandscape, _WorldSpaceCameraPos);
				o.lightDirection = mul(worldToLandscape, _WorldSpaceLightPos0);
				return o;
			}
			// i hope this place holder fuction get replaced by something more realistic by someone who's not me
			float getY(float3 v) { // displacement can only be in the y direction and 
			// must be directly assigned to v.vertex.y or else everything will break;
			// damn too much coupling between functions for this thing.
			// v.y should not be in this function
			/* + _Time.y*/
				// return sin(v.x*10 + _Time.y)/200 + 0.4;
				return 0.4;
			}

			float3 getNormal(float3 v0, float3 v1, float3 v2) {
				float3 u = v0 - v1;
				float3 v = v0 - v2;
				return normalize(cross(u, v));
			}
			float3 getNormal(float3 v) { 
				float L = planeSize/numOfVerticesOnPlaneEdge; 
				// num too small and it gets cut off when added to the big float v.x and v.z
				// cause remember float only have about 8 digits of precision

				uint length = 4;
				float3 vs[4] = {
					{v.x-L, 0, v.z},
					{v.x, 0, v.z+L},
					{v.x+L, 0, v.z},
					{v.x, 0, v.z-L},
				};
				for (uint i = 0; i < length; i++) {
					// apply displacment
					vs[i].y = getY(vs[i]);
				}
				float3 normal = {0, 0, 0};
				for (i = 0; i < length; i++) {
					normal += getNormal(v, vs[i], vs[(i+1) % length]);
				}
				return normal / length;
			}
			
			
			// Implementation of the fragment shader
			fixed4 frag(vertOut v) : SV_Target {
				
				// per pixel normal
				float3 normal = getNormal(v.positionObject);

				// everything from this point on is in landscape space
				normal = normalize(mul(worldToLandscape, mul(unity_ObjectToWorld, normal)));

				float3 viewDir = v.positionLandscape - v.cameraPos;
				float3 reflectionDir = reflect(viewDir, normal);
				

				fixed4 color = {0, 0, 0, 1};
				float3 intersection;
				textCoords t = findTriangle(reflectionDir, v.positionLandscape, intersection);
				if (t.coord1.x != -1) {
					color.r = t.coord1.x;
					color.g = t.coord1.y;
				}
				return color;
			}

			// search for the triangle that the ray first hit
			textCoords findTriangle(float3 rayDir, float3 rayOrigin, out float3 intersection) {

				textCoords o;
				float2 falseCoord = {-1, -1};
				o.coord1 = falseCoord;
				o.coord2 = falseCoord;
				o.coord3 = falseCoord;

				// first find the triangle rayOrigin is directly above or below
				float texDelta = 1.0 / landscapeSize; // texture delta 
				float texOffset = texDelta / 2; // texture offset so it's at the center
				// to reference to a texture you go tex2D(x*texDelta+texOffset, y*texDelta+texOffset) 
				// where x and y are int index.

				float2 texCoord = rayOrigin.xz / landscapeSideLength * (texDelta * (landscapeSize - 1));
				// texCoord in range [0.0, 1.0-texDelta]
				float maxi = 1 - texDelta;
				// remember to add texOffset when tex2D() to ensure correct texture sampling

				float2 texDir = rayDir.xz;
				// it'll go through texture following y = (x - texCoord.x) / texDir.x * texDir.y + texCoord.y

				if (texDir.x == 0 && texDir.y == 0) {
					return o;
				}

				// direction checking not neccessary here cause the following loop will terminate once it goes out.
				if (texDir.x == 0) {
					if (texCoord.x < 0 || texCoord.x > maxi) {
						return o;
					}
					if (texCoord.y < 0) {
						texCoord.y = 0;
					} else if (texCoord.y > maxi) {
						texCoord.y = maxi;
					}

				} else if (texCoord.x < 0) {
					texCoord.y = (0 - texCoord.x) / texDir.x * texDir.y + texCoord.y;
					texCoord.x = 0;
				} else if (texCoord.x > maxi) {
					texCoord.y = (maxi - texCoord.x) / texDir.x * texDir.y + texCoord.y;
					texCoord.x = maxi; 
				} // x will be in range

				if (texDir.y == 0) {
					if (texCoord.y < 0 || texCoord.y > maxi) {
						return o;
					}
					if (texCoord.x < 0) {
						texCoord.x = 0;
					} else if (texCoord.x > maxi) {
						texCoord.x = maxi;
					}
					
				} else if (texCoord.y < 0) {
					texCoord.x = (0 - texCoord.y) / texDir.y * texDir.x + texCoord.x;
					texCoord.y = 0;
				} else if (texCoord.y > maxi) {
					texCoord.x = (maxi - texCoord.y) / texDir.y * texDir.x + texCoord.x;
					texCoord.y = maxi; 
				} // y will be in range

				// if x is brought out of range by y being in range this means no inteception
				if (texCoord.x > maxi || texCoord.x < 0) {
					return o;
				}

				// ok, begin the loop
				// this loop operate per horizontal line
				while (!
					( // terminate when it's going out of the grid
						(texCoord.x <= 0 && texDir.x < 0) || (texCoord.x >= maxi && texDir.x > 0) ||
						(texCoord.y <= 0 && texDir.y < 0) || (texCoord.y >= maxi && texDir.y > 0)
					)
				) {
					// determine which square is texCoord inside now // - fmod(texCoord.x, texDelta) - fmod(texCoord.y, texDelta)
					float2 bottomLeft = { texCoord.x - fmod(texCoord.x, texDelta), texCoord.y - fmod(texCoord.y, texDelta)};
					float2 nextTexCoord;
					if (texDir.y == 0) { 
						// parallel to x axis
						if (texDir.x > 0) {
							nextTexCoord.x = maxi;
						} else {
							nextTexCoord.x = 0;
						}
						nextTexCoord.y = texCoord.y;
					}
					else {
						if (texDir.y > 0) {
							nextTexCoord.y = bottomLeft.y + texDelta;
						} else {
							if (bottomLeft.y == texCoord.y) {
								nextTexCoord.y = bottomLeft.y - texDelta;
							}
							else {
								nextTexCoord.y = bottomLeft.y;
							}
						} 
						// find next x according to y
						nextTexCoord.x = (nextTexCoord.y - texCoord.y) / texDir.y * texDir.x + texCoord.x;
						// make sure than x doesn't go out of bound
						nextTexCoord.x = min(nextTexCoord.x, maxi);
						nextTexCoord.x = max(nextTexCoord.x, 0);
					}
					// i wonder if you can write a functional shader... that'll be nice
					
					// in the case of nextTexCoord.y < texCoord.y bottomLeft.y should be nextTexCoord.y
					// if (nextTexCoord.y < texCoord.y) {
					// 	bottomLeft.y = nextTexCoord.y;
					// }

					float leftX = bottomLeft.x;
					float rightX = bottomLeft.x + texDelta;
					// iterate through the triangles on this line
					while (leftX < max(nextTexCoord.x, texCoord.x) 
						&& rightX > min(nextTexCoord.x, texCoord.x)) {
						float2 topLeft = {bottomLeft.x, bottomLeft.y + texDelta};
						float2 topRight = {bottomLeft.x + texDelta, bottomLeft.y + texDelta};
						float2 bottomRight = {bottomLeft.x + texDelta, bottomLeft.y};
						// TODO: potential optimization, check if line go through each triangle before MTIntersection()
						if (MTIntersection(rayOrigin, rayDir, 
										   tex2Dlod(landscapeVertices, float4(bottomLeft + texOffset,0,0)),
										   tex2Dlod(landscapeVertices, float4(bottomRight + texOffset,0,0)),
										   tex2Dlod(landscapeVertices, float4(topLeft + texOffset,0,0)),
										   intersection)) {
							o.coord1 = bottomLeft + texOffset;
							o.coord2 = bottomRight + texOffset;
							o.coord3 = topLeft + texOffset;
							return o;
						} 
						if (MTIntersection(rayOrigin, rayDir, 
										   tex2Dlod(landscapeVertices, float4(topRight + texOffset,0,0)),
										   tex2Dlod(landscapeVertices, float4(bottomRight + texOffset,0,0)),
										   tex2Dlod(landscapeVertices, float4(topLeft + texOffset,0,0)),
										   intersection)) {
							o.coord1 = topRight + texOffset;
							o.coord2 = bottomRight + texOffset;
							o.coord3 = topLeft + texOffset;
							return o;
						} 

						if (texDir.x > 0) {
							leftX += texDelta;
							rightX += texDelta;
						} else {
							leftX -= texDelta;
							rightX -= texDelta;
						}
						bottomLeft.x = leftX;
					}


					texCoord = nextTexCoord;
				}

				return o;
			}

			// Moller-Trumbore intersection algorithm
			bool MTIntersection(float3 rayOrigin, float3 rayDir, 
							    float3 coord1, float3 coord2, float3 coord3,
								out float3 intersection) {
				// converted from:
				// https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
				// C++ implementation
				const float EPSILON = 0.0000001;
				float3 edge1 = coord2 - coord1;
				float3 edge2 = coord3 - coord1;
				float3 h = cross(rayDir, edge2);
				float a = dot(edge1, h);
				if (a > -EPSILON && a < EPSILON) {
					return false; // this ray is parallel to this triangle.
				}
				float f = 1.0/a;
				float3 s = rayOrigin - coord1;
				float u = f * dot(s, h);
				if (u < 0.0 || u > 1.0) {
					return false;
				}
				float3 q = cross(s, edge1);
				float v = f * dot(rayDir, q);
				if (v < 0.0 || u + v > 1.0) {
					return false; 
				}
				// at this stage we can compute t to find out where the intersection point is on the line.
				float t = f * dot(edge2, q);
				if (t > EPSILON) // ray intersection
				{
					intersection = rayOrigin + rayDir * t;
					return true;
				}
				else {
					// this means that there is a line intersection but not a ray intersection
					return false;
				}
			}

			// // this fragment shader is to test the correctness of sampler2d passed in
			// fixed4 frag(vertOut v) : SV_Target {
			// 	return tex2D(landscapeVertices, v.positionObject.xz/10);
			// }

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

				// according to documentation Directional lights: (world space direction, 0). Other lights: (world space position, 1).
				// o.lightDirection = ;
				// o.cameraPos = ;
				return o;
			}
			// this shader must be exactly identical to the one in PhongShader.shader
			fixed4 landscapeFrag(vertOutLandscape v)
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
				float4 specularComponent = {specular, specular, specular, 0};
				
				return v.color * (ambient + diffuse) + specularComponent;
			}
			ENDCG
		}
	}
}