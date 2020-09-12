//UNITY_SHADER_NO_UPGRADE

Shader "Unlit/WaveShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (1, 1, 1, 1)
	}
	SubShader
	{
		Pass
		{

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			#define EPSILON 0.0000001
			// to combat floating point precision problem when ==

			uniform sampler2D_float landscapeVertices;
			uniform sampler2D_float landscapeNormals;
			uniform sampler2D landscapeColors;
			uniform sampler2D_float landscapeUV;
			uniform sampler2D_float landscapeTangents;
			uniform sampler2D _BumpMap;
			uniform int landscapeSize;
			uniform float landscapeSideLength;
			uniform float4x4 worldToLandscape;
			uniform int numOfVerticesOnPlaneEdge;
			uniform float planeSize; 
			uniform float offset;
			uniform int enableRayTracing;
			uniform float3 lightPos;

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
				float2 uv : TEXCOORD0;
				float4 tangent : TANGENT;
			};
			// like landscapeFrag, this struct have to be identical to the one in PhongShader.shader
			struct vertOutLandscape
			{
				float4 vertex : SV_POSITION;
				float4 color : COLOR0;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				half3 tspace0 : TEXCOORD1;
                half3 tspace1 : TEXCOORD2;
                half3 tspace2 : TEXCOORD3;
				float4 tangent : TANGENT;
				float3 position : POSITION_IN_OBJECT_SPACE;
			};

			float getY(float3 v);
			float3 getNormal(float3 v);

			textCoords findTriangle(float3 rayDir, float3 rayOrigin, out float3 intersection);
			bool MTIntersection(float3 rayOrigin, float3 rayDir, 
							    float3 coord1, float3 coord2, float3 coord3,
								out float3 intersection);
								
			fixed4 getLandscapeColor(textCoords t, float3 intersection, float3 lightDirection, float3 cameraPos);

			vertOutLandscape landscapeVert(vertInLandscape v);
			fixed4 landscapeFrag(vertOutLandscape v, float3 lightDirection, float3 cameraPos);

			// Implementation of the vertex shader
			vertOut vert(vertIn v)
			{
				v.vertex.y = getY(v.vertex.xyz);

				vertOut o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.positionObject = v.vertex.xyz;
				o.positionLandscape = mul(worldToLandscape, mul(unity_ObjectToWorld, o.positionObject));
				o.cameraPos = mul(worldToLandscape, _WorldSpaceCameraPos);
				o.lightDirection = mul(worldToLandscape, lightPos - v.vertex);
				return o;
			}

			float getY(float3 v) { // displacement can only be in the y direction and 
			// must be directly assigned to v.vertex.y or else everything will break;
			// damn too much coupling between functions for this thing.
			// v.y should not be in this function
			/* + _Time.y*/
				// return sin(v.x*25 + _Time.y)/500 + offset;
				// return offset;
				const uint seedsSize = 8;
				float2 seeds[seedsSize * seedsSize];
				for (uint i = 0; i < seedsSize; i++) {
					for (uint j = 0; j < seedsSize; j++) {
						seeds[i*seedsSize + j] = float2(i, j) / seedsSize * landscapeSideLength;
					}
				}
				float delta = 0;
				for (i = 0; i < seedsSize * seedsSize; i++) {
					delta += sin(distance(seeds[i], v.xz) * 250 + _Time.y) / 25;
					delta += sin(distance(seeds[i], v.xz) * 50 + _Time.y) / 5;
					delta += sin(distance(seeds[i], v.xz) * 10 + _Time.y);
					delta += sin(distance(seeds[i], v.xz) * 2 + _Time.y) * 5;
				}
				return offset + delta / 2000;
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
				
				if (enableRayTracing == 1) {
					// only render when pixel is visible i.e. don't render if pixel is under the landscape
					if (v.positionLandscape.y + 0.2 < // TODO: find a good value other than 0.2 using parameters
						tex2D(landscapeVertices, v.positionObject.xz/landscapeSideLength).y)
						discard;
					
					// per pixel normal
					float3 normal = getNormal(v.positionObject);

					// everything from this point on is in landscape space
					normal = normalize(mul(worldToLandscape, mul(unity_ObjectToWorld, normal)));

					float3 viewDir = v.positionLandscape - v.cameraPos;
					float3 reflectionDir = reflect(viewDir, normal);
					
					float3 intersection;
					textCoords t = findTriangle(reflectionDir, v.positionLandscape, intersection);
					fixed3 reflection;
					if (t.coord1.x != -1) {
						// return fixed4(1, 0, 0, 1);
						reflection = getLandscapeColor(t, intersection, v.lightDirection, v.cameraPos);
					} else {
						reflection = fixed4(104.0/256, 131.0/256, 170.0/256, 1) * max(normalize(v.lightDirection).y, 0);
					}

					float3 refractDir = refract(viewDir, normal, 1/1.333);
					t = findTriangle(refractDir, v.positionLandscape, intersection);
					fixed3 refraction;
					if (t.coord1.x != -1) {

						refraction = 
							getLandscapeColor(t, intersection, v.lightDirection, v.cameraPos)
							* pow(0.5, distance(intersection, v.positionLandscape) + (offset - intersection.y));
					} else {
						refraction = fixed4(104.0/256, 131.0/256, 170.0/256, 1) / 2;
					}

					return fixed4(refraction * 0.5 + reflection * 0.5, 1);


				}
				else {

					float4 color = float4(1, 1, 1, 1);

					float3 normal = getNormal(v.positionObject);

					// everything from this point on is in landscape space
					normal = normalize(mul(worldToLandscape, mul(unity_ObjectToWorld, normal)));
		
					// Ambient RGB intensities passed as uniform

					// Calculating RGB diffuse reflections
					float fAtt = 0.05;
					float Kd = 1;
					float3 L = normalize(v.lightDirection);
					float LdotN = dot(L, normal);
					float3 diffuse = fAtt * color.rgb * Kd * saturate(LdotN);

					// Calculating specular reflections
					float Ks = 1;
					float specN = 5;
					float3 V = v.positionLandscape - v.cameraPos;
					float3 R = reflect(v.lightDirection, -normal);

					float3 specular = fAtt * color.rgb * Ks * pow(saturate(dot(V, R)), specN);

					// Calculating refraction

					
					float3 refractDir = refract(V, normal, 1/1.333);
					float3 intersection;
					textCoords t = findTriangle(refractDir, v.positionLandscape, intersection);
					float3 refraction;
					if (t.coord1.x != -1) {

						refraction = 
							getLandscapeColor(t, intersection, v.lightDirection, v.cameraPos)
							* pow(0.5, distance(intersection, v.positionLandscape) + (offset - intersection.y));
					} else {
						refraction = float4(104.0/256, 131.0/256, 170.0/256, 1) / 2;
					}


					
					/*float specular = dot(normalize(viewDir), normalize(reflectionDir));
					if (specular <= 0.0) {
						// one thing very fustrating is that this pow function misbehave when the first argument is 0
						specular = 0.0;
					} else {
						specular = pow(specular, n) * specularFraction;
					}
					float4 specularComponent = {specular, specular, specular, 0};
					
					return v.color * (ambient + diffuse) + specularComponent;*/

					// Combine Phong Illumination model components
					float4 returnColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
					returnColor.rgb = 0.1 * ambient + diffuse + specular + refraction;
					returnColor.a = color.a;

					return returnColor;


				}
			

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
							float diff = bottomLeft.y - texCoord.y;
							if (diff > -EPSILON && diff < EPSILON) {
								// i had some floating point precision problem here
								nextTexCoord.y = bottomLeft.y - texDelta;
							}
							else {
								nextTexCoord.y = bottomLeft.y;
							}
						} 
						// find next x according to y
						nextTexCoord.x = (nextTexCoord.y - texCoord.y) / texDir.y * texDir.x + texCoord.x;
						// make sure that x doesn't go out of bound
						nextTexCoord.x = min(nextTexCoord.x, maxi - EPSILON);
						nextTexCoord.x = max(nextTexCoord.x, 0 + EPSILON);
						// those EPSILON in the above 2 line is necessary but i don't know why
					}
					// i wonder if you can write a functional shader... that'll be nice
					
					// in the case of nextTexCoord.y < texCoord.y bottomLeft.y should be nextTexCoord.y
					if (nextTexCoord.y < texCoord.y) {
						bottomLeft.y = nextTexCoord.y;
					}

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
				if (t > 0) // ray intersection
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
			// 	return tex2D(landscapeVertices, v.positionObject.xz/landscapeSideLength);
			// }

			// // this fragment shader test the getNormal function
			// fixed4 frag(vertOut v) : SV_Target {
			// 	float3 normal = getNormal(v.position);
			// 	fixed4 color= {normal, 1.0};
			// 	return color;
			// }

			fixed4 getLandscapeColor(textCoords t, float3 intersection, float3 lightDirection, float3 cameraPos) {
				// linearly interpolate
				vertInLandscape vIn;
				half2 coords[3];
				coords[0] = t.coord1;
				coords[1] = t.coord2;
				coords[2] = t.coord3;
				vertOutLandscape vOut[3];
				for (uint i = 0; i < 3; i++) {
					vIn.vertex = tex2Dlod(landscapeVertices, float4(coords[i], 0, 0));
					vIn.color = tex2Dlod(landscapeColors, float4(coords[i], 0, 0));
					vIn.normal = tex2Dlod(landscapeNormals, float4(coords[i], 0, 0));
					vIn.uv = tex2Dlod(landscapeUV, float4(coords[i], 0, 0));
					vIn.tangent = tex2Dlod(landscapeTangents, float4(coords[i], 0, 0));
					vOut[i] = landscapeVert(vIn);
				}

				float w[3]; // linear interpolation
				w[0] = ((vOut[1].position.y - vOut[2].position.y) * (intersection.x - vOut[2].position.x)
						+ (vOut[2].position.x - vOut[1].position.x) * (intersection.y - vOut[2].position.y))
						/
						((vOut[1].position.y - vOut[2].position.y) * (vOut[0].position.x - vOut[2].position.x)
						+ (vOut[2].position.x - vOut[1].position.x) * (vOut[0].position.y - vOut[2].position.y));

				w[1] = ((vOut[2].position.y - vOut[0].position.y) * (intersection.x - vOut[2].position.x)
						+ (vOut[0].position.x - vOut[2].position.x) * (intersection.y - vOut[2].position.y))
						/
						((vOut[1].position.y - vOut[2].position.y) * (vOut[0].position.x - vOut[2].position.x)
						+ (vOut[2].position.x - vOut[1].position.x) * (vOut[0].position.y - vOut[2].position.y));

				w[2] = 1 - w[0] - w[1];

				vertOutLandscape vOutIn;
				vOutIn.color = float4(0, 0, 0, 0);
				vOutIn.vertex = float4(0, 0, 0, 0);
				vOutIn.normal = float3(0, 0, 0);
				vOutIn.position = float3(0, 0, 0);
				vOutIn.uv = float2(0, 0);
				vOutIn.tspace0 = half3(0, 0, 0);
				vOutIn.tspace1 = half3(0, 0, 0);
				vOutIn.tspace2 = half3(0, 0, 0);
				vOutIn.tangent = float4(0, 0, 0, 0);
				for (i = 0; i < 3; i++) {
					vOutIn.vertex += vOut[i].vertex * w[i];
					vOutIn.color += vOut[i].color * w[i];
					vOutIn.normal += vOut[i].normal * w[i];
					vOutIn.position += vOut[i].position * w[i];
					vOutIn.uv += vOut[i].uv * w[i];
					vOutIn.tspace0 += vOut[i].tspace0 * w[i];
					vOutIn.tspace1 += vOut[i].tspace1 * w[i];
					vOutIn.tspace2 += vOut[i].tspace2 * w[i];
					vOutIn.tangent += vOut[i].tangent * w[i];
				}

				return landscapeFrag(vOutIn, lightDirection, cameraPos);
			}
			
			// this shader must be exactly identical to the one in PhongShader.shader
			vertOutLandscape landscapeVert(vertInLandscape v)
			{
				vertOutLandscape o;

				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.color = v.color;
				o.normal = v.normal;
				o.position = v.vertex;

				o.uv = v.uv;
				o.tangent = v.tangent;
				half3 wNormal = UnityObjectToWorldNormal(o.normal);
                half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
                o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
                o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
                o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);

				return o;
			}
			// this shader must be exactly identical to the one in PhongShader.shader except reference to lightdirection and cameraPos
			fixed4 landscapeFrag(vertOutLandscape v, float3 lightDirection, float3 cameraPos)
			{
				// sample the normal map, and decode from the Unity encoding
                half3 tnormal = UnpackNormal(tex2D(_BumpMap, v.uv));
				half3 worldNormal;
                worldNormal.x = dot(v.tspace0, tnormal);
                worldNormal.y = dot(v.tspace1, tnormal);
                worldNormal.z = dot(v.tspace2, tnormal);

				v.normal = worldNormal;

				// dot product will give ||a|| ||b|| cos(theta)
				// as both a and b are unit vector (i normalized them)
				// dot(...) will return cos(theta)
				// in case of theta larger than 90 degrees cos(theta) will be smaller than 0
				// that isn't very acceptable cause theta > 90 just mean the light is on the other side
				// so hence max(dot(...), 0)
				float diffuse = max(dot(normalize(v.normal), normalize(lightDirection)), 0.0);
				diffuse *= 1.0-ambient; // this is so that diffuse + ambient <= 1

				float3 viewDir = v.position - cameraPos;
				float3 reflectionDir = reflect(lightDirection, -v.normal);
				
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