
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles
// Workaround for SHADOW_COORDS being missing for shadowcaster pass
#if defined (SHADOWS_DEPTH) && !defined (SPOT)
    #define SHADOW_COORDS(idx1) unityShadowCoord2 _ShadowCoord : TEXCOORD##idx1;
#endif

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"              // must be after `UnityPBSLighting` because Unity forgot to include it.
#include "UnityLightingCommon.cginc"
#include "UnityStandardCore.cginc"


////////////////////////////////////////////////////////////////////////////////
// General Matrix Functions

/**
 * Calculates the inverse of a matrix.
 * Probably causes the universe to implode if the input matrix has no inverse.
 * If this eats literally all your cats I am not responsible.
 *
 * @param input the input matrix.
 * @return its inverse.
 */
float4x4 InvertMatrix(float4x4 input)
{
    #define minor(a, b, c) determinant(float3x3(input.a, input.b, input.c))

    float4x4 cofactors = float4x4(
        minor(_22_23_24, _32_33_34, _42_43_44),
       -minor(_21_23_24, _31_33_34, _41_43_44),
        minor(_21_22_24, _31_32_34, _41_42_44),
       -minor(_21_22_23, _31_32_33, _41_42_43),

       -minor(_12_13_14, _32_33_34, _42_43_44),
        minor(_11_13_14, _31_33_34, _41_43_44),
       -minor(_11_12_14, _31_32_34, _41_42_44),
        minor(_11_12_13, _31_32_33, _41_42_43),

        minor(_12_13_14, _22_23_24, _42_43_44),
       -minor(_11_13_14, _21_23_24, _41_43_44),
        minor(_11_12_14, _21_22_24, _41_42_44),
       -minor(_11_12_13, _21_22_23, _41_42_43),

       -minor(_12_13_14, _22_23_24, _32_33_34),
        minor(_11_13_14, _21_23_24, _31_33_34),
       -minor(_11_12_14, _21_22_24, _31_32_34),
        minor(_11_12_13, _21_22_23, _31_32_33));

   #undef minor
   return transpose(cofactors) / determinant(input);
}


////////////////////////////////////////////////////////////////////////////////
// General Unity Utilities

/**
 * Transforms a position in world space to object space.
 *
 * @param worldPos the position in world space.
 * @return its position in object space.
 */
float3 WorldToObjectPos(float3 worldPos)
{
    return mul(unity_WorldToObject, float4(worldPos, 1.0)).xyz;
}

/**
 * Transforms a direction in world space to object space.
 *
 * @param worldDir the direction in world space.
 * @return its position in object space.
 */
float3 WorldToObjectNormal(float3 worldDir)
{
    return mul(unity_WorldToObject, float4(worldDir, 0.0)).xyz;
}

/**
 * Transforms a position in object space to world space.
 *
 * @param objectPos the position in object space.
 * @return its position in world space.
 */
float3 ObjectToWorldPos(float3 objectPos)
{
    return mul(unity_ObjectToWorld, float4(objectPos, 1.0)).xyz;
}

/**
 * Transforms a position in clip space to object space.
 *
 * @param clipPos the position in clip space.
 * @return its position in object space.
 */
float3 ClipToObjectPos(float4 clipPos)
{
    return mul(unity_WorldToObject, mul(InvertMatrix(UNITY_MATRIX_VP), clipPos)).xyz;
}


////////////////////////////////////////////////////////////////////////////////
// Ray Casting

/**
 * Performs a sphere-ray intersection check.
 * Coordinates are in object space.
 *
 * @param sphereCentre the centre of the sphere.
 * @param sphereRadius2 the square of the radius of the sphere.
 * @param rayOrigin the origin of the ray.
 * @param rayDirection the direction of the ray.
 * @param solution [out] receives the point of intersection.
 * @return `true` if an intersection is found, `false` otherwise.
 */
bool SphereRayIntersect(float3 sphereCentre, float sphereRadius2, float3 rayOrigin, float3 rayDirection, out float solution)
{
    float a = dot(rayDirection, rayDirection);
    float3 s0_r0 = rayOrigin - sphereCentre;
    float b = 2.0 * dot(rayDirection, s0_r0);
    float c = dot(s0_r0, s0_r0) - sphereRadius2;
    float disc = b * b - 4.0 * a* c;
    if (disc < 0.0)
    {
        solution = 0.0;
        return false;
    }
    else
    {
        solution = min(-b - sqrt(disc), -b + sqrt(disc)) / (2.0 * a);
        return true;
    }
}

/**
 * Entry point for generic raycast render framework.
 * Modified somewhat to suit this particular shader, as is seen from the parameters.
 *
 * All coordinate parameters are in object space.
 *
 * @param face the face of the die being rendered. 1 ~ 6.
 * @param objectRayStart the ray origin.
 * @param objectRayDir the ray direction.
 * @param objectPos [out] receives the position where the ray hit.
 * @param objectNormal [out] receives the surface normal at the position where the ray hit.
 * @param material [out] receives a value which is later used to produce a material.
 * @return `true` if the ray hits the object, `false` otherwise.
 */
bool Raycast(uint face, float3 objectRayStart, float3 objectRayDir, out float3 objectPos, out float3 objectNormal, out float material)
{
    static const float sphereRadius = 0.00125;
    static const float k = 0.00275;
    static const float sphereRadius2 = sphereRadius * sphereRadius;
    static const float3 spherePositions[] = {
        // 1
        float3(0.0, 0.0, 0.0),
        // 2
        float3(0.0, k, k), float3(0.0, -k, -k),
        // 3
        float3(0.0, 0.0, 0.0), float3(k, 0.0, -k), float3(-k, 0.0, k),
        // 4
        float3(k, 0.0, k), float3(k, 0.0, -k), float3(-k, 0.0, k), float3(-k, 0.0, -k),
        // 5
        float3(0.0, 0.0, 0.0), float3(0.0, k, k), float3(0.0, k, -k), float3(0.0, -k,  k), float3(0.0, -k, -k),
        // 6
        float3(k, k, 0.0), float3(k, -k, 0.0), float3(0.0, k, 0.0), float3(0.0, -k, 0.0), float3(-k, k, 0.0), float3(-k, -k, 0.0),
    };
    // Index of first sphere in `spherePositions`
    static const uint spherePositionOffsets[] = {0, 0, 1, 3, 6, 10, 15};

    uint offset = spherePositionOffsets[face];
    float tBest = 100.0;
    bool hit = false;
    for (uint i = 0; i < face; i++)
    {
        float3 sphereCentre = spherePositions[offset + i];

        float t;
        if (SphereRayIntersect(sphereCentre, sphereRadius2, objectRayStart, objectRayDir, t))
        {
            hit = true;
            if (t < tBest)
            {
                objectPos = objectRayStart + objectRayDir * t;
                objectNormal = normalize(objectPos - sphereCentre);
                material = 1.0;
                tBest = t;
            }
        }
    }

    return hit;
}


////////////////////////////////////////////////////////////////////////////////
// Input / Output Data Structures

struct AppData
{
    float4 vertex   : POSITION;
    float2 texcoord : TEXCOORD0;
    float3 normal   : NORMAL;
    float4 tangent  : TANGENT;
    float4 color    : COLOR;
};

struct Varyings
{
    float4 pos              : SV_POSITION;
    float2 texcoord         : TEXCOORD0;
    float2 texcoordMetallic : TEXCOORD1;
    float2 texcoordNormal   : TEXCOORD2;
    float2 texcoordEmission : TEXCOORD3;
    float4 vertex           : TEXCOORD4;
    float3 normal           : NORMAL;
    float4 color            : COLOR;
    float3 objectRayStart   : TEXCOORD5;
    float3 objectRayDir     : TEXCOORD6;
};

struct FragmentOutput
{
    float4 color    : SV_Target;
    float clipDepth : SV_Depth;
};

// Commenting out what other includes have provided for us - documented here for completeness.
// There may in fact be more which I have simply not named consistently.
// If you are reading this and know that this is the case, let me know and I'll rename my stuff.

//uniform sampler2D _MainTex;
//uniform float4 _MainTex_ST;
//uniform float4 _Color;
uniform sampler2D _MetallicTex;
uniform float4 _MetallicTex_ST;
uniform sampler2D _NormalMap;
uniform float4 _NormalMap_ST;
//uniform float _Metallic;
uniform float _Smoothness;
//uniform sampler2D _EmissionMap;
uniform float4 _EmissionMap_ST;
//uniform float3 _EmissionColor;
uniform float3 _BallAlbedo;
uniform float3 _BallEmission;
uniform float _BallMetallic;
uniform float _BallSmoothness;


////////////////////////////////////////////////////////////////////////////////
// Vertex Shader

Varyings Vertex(AppData input)
{
    Varyings output;
    UNITY_INITIALIZE_OUTPUT(Varyings, output);
    output.pos = UnityObjectToClipPos(input.vertex);

    output.vertex = input.vertex;
    output.texcoord = TRANSFORM_TEX(input.texcoord, _MainTex);
    output.texcoordMetallic = TRANSFORM_TEX(input.texcoord, _MetallicTex);
    output.texcoordNormal = TRANSFORM_TEX(input.texcoord, _NormalMap);
    output.texcoordEmission = TRANSFORM_TEX(input.texcoord, _EmissionMap);
    output.color = input.color;
    output.normal = input.normal;

    // Variables like `unity_OrthoParams` and `_WorldSpaceCameraPos` lie.
    // What I mean by 'lie' here is that when you're rendering shadows, the
    // "world space camera position" is still literally the position of the camera
    // in the scene, but in that situation what you really want is the position of the light.
    // To handle all situations correctly, the transform matrices give you what you want.

    if (UNITY_MATRIX_P[3][3] == 1.0)
    {
        // Orthographic case - `-UNITY_MATRIX_V[2]` is camera forward vector
        output.objectRayDir = WorldToObjectNormal(-UNITY_MATRIX_V[2].xyz);
        output.objectRayStart = input.vertex - normalize(output.objectRayDir);
    }
    else
    {
        // Perspective case - `UNITY_MATRIX_I_V._m03_m13_m23` is camera position
        output.objectRayStart = WorldToObjectPos(UNITY_MATRIX_I_V._m03_m13_m23);
        output.objectRayDir = input.vertex - output.objectRayStart;
    }

    return output;
}


////////////////////////////////////////////////////////////////////////////////
// Fragment Shader

/**
 * Decodes the floating point material value to produce surface shader parameters.
 *
 * @param input the fragment shader input.
 * @param material the material value.
 * @param output [inout] a standard surface shader output structure to populate.
 */
void DecodeMaterial(Varyings input, float material, inout SurfaceOutputStandard output)
{
    if (material > 0.5)
    {
        // XXX: I want to texture this better too some day, but smooth balls are nice too. uwu
        output.Albedo = _BallAlbedo;
        output.Emission = _BallEmission;
        output.Metallic = _BallMetallic;
        output.Smoothness = _BallSmoothness;
    }
    else
    {
        float4 albedo = tex2D(_MainTex, input.texcoord) * _Color;
        output.Albedo = albedo.rgb;
        output.Alpha = albedo.a;

        float4 metal = tex2D(_MetallicTex, input.texcoordMetallic);
        output.Metallic = metal.r * _Metallic;
        output.Smoothness = metal.a * _Smoothness;

        output.Normal = UnpackNormal(tex2D(_NormalMap, input.texcoordNormal));

        output.Emission = tex2D(_EmissionMap, input.texcoordEmission) * _EmissionColor;
    }
}

/**
 * Performs a raycast for a fragment shader.
 *
 * Really the code here is responsible for taking the fragment shader input structure and unpacking
 * the information necessary to call the other raycast function which does the hard work.
 *
 * @param input the fragment shader input.
 * @param objectPos [out] receives the position where the ray hit.
 * @param objectNormal [out] receives the surface normal at the position where the ray hit.
 * @param material [out] receives a value which is later used to produce a material.
 * @return `true` if the ray hits the object, `false` otherwise.
 */
bool FragmentRaycast(Varyings input, out float3 objectPos, out float3 objectNormal, out float material)
{
    // Determine the face of the die which was hit by looking at the vertex colour.
    // I coloured the model systematically so that this could be written programmatically.
    // R=1, G=2, B=4, and add the values together.
    // e.g., cyan is green + blue, so it would be face 6.
    uint face = dot(input.color > 0.5 ? 1 : 0, uint3(1, 2, 4));

    // We use vertex colours to indicate which face has been hit.
    // Face 7 is used to indicate the frame, which bypasses the raycast logic entirely.

    if (face < 7)
    {
        return Raycast(face, input.objectRayStart, normalize(input.objectRayDir), objectPos, objectNormal, material);
    }
    else
    {
        // Frame
        material = 0.0;
        objectPos = input.vertex;
        objectNormal = input.normal;
        return true;
    }
}

/**
 * Performs a raycast and returns a standard surface shader output.
 *
 * This part is more or less what you would be writing if you were writing this as a surface shader.
 * Of course it wasn't possible to write this as a surface shader, as it was not possible to write
 * to the depth buffer.
 *
 * @param input the fragment input.
 * @param objectPos [out] receives the position where the ray hit.
 * @param objectNormal [out] receives the surface normal at the position where the ray hit.
 * @return a populated standard surface shader output structure.
 */
SurfaceOutputStandard SurfaceRaycast(Varyings input, out float3 objectPos, out float3 objectNormal)
{
    SurfaceOutputStandard output;
    UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, output);

    float material;

    bool hit = FragmentRaycast(input, objectPos, objectNormal, material);
    clip(hit ? 1.0 : -1.0);

    output.Normal = UnityObjectToWorldNormal(objectNormal);
    output.Occlusion = 1.0;
    DecodeMaterial(input, material, output);

    return output;
}

/**
 * Wraps `UNITY_TRANSFER_SHADOW` and `UNITY_LIGHT_ATTENUATION` for abusing to use in fragment shader.
 *
 * @param objectPos the position in object space.
 * @param worldPos the position in world space.
 * @param clipPos the position in clip space.
 * @return the light attenuation factor.
 */
float CalculateLightAttenuation(float3 objectPos, float3 worldPos, float4 clipPos)
{
    // Has to be called `v` because `UNITY_TRANSFER_SHADOW` sucks
    struct
    {
        float3 vertex;
    } v;
    v.vertex = objectPos;

    struct
    {
        float4 pos;
        UNITY_SHADOW_COORDS(0)
    } o;
    o.pos = clipPos;
    UNITY_TRANSFER_SHADOW(o, float2(0.0, 0.0));

    UNITY_LIGHT_ATTENUATION(attenuation, o, worldPos);
    return attenuation;
}

/**
 * Wraps `UNITY_TRANSFER_FOG` and `UNITY_APPLY_FOG` for abusing to use in fragment shader.
 *
 * @param objectPos the position in object space.
 * @param clipPos the position in clip space.
 * @param c the colour without fog applied.
 * @return the colour with fog applied.
 */
float4 CalculateFog(float3 objectPos, float4 clipPos, float4 c)
{
    struct
    {
        float4 pos;
        UNITY_FOG_COORDS(0)
    } o;
    o.pos = clipPos;
    UNITY_TRANSFER_FOG(o, o.pos);

    UNITY_APPLY_FOG(o.fogCoord, c);
    return c;
}

FragmentOutput Fragment(Varyings input)
{
    // Here we're using as much as possible of the actual surface shader / standard lighting code.

    FragmentOutput output;
    UNITY_INITIALIZE_OUTPUT(FragmentOutput, output);

    float3 objectPos;
    float3 objectNormal;
    SurfaceOutputStandard surfaceOutput = SurfaceRaycast(input, objectPos, objectNormal);

    float3 worldPos = ObjectToWorldPos(objectPos);
    float3 worldNormal = UnityObjectToWorldNormal(objectNormal);
    float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
    float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

    float4 clipPos = UnityObjectToClipPos(float4(objectPos, 1.0));

    float attenuation = CalculateLightAttenuation(objectPos, worldPos, clipPos);

    UnityGI gi;
    UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
    gi.indirect.diffuse = 0;
    gi.indirect.specular = 0;
    gi.light.color = _LightColor0.rgb * attenuation;
    gi.light.dir = worldLightDir;

#ifdef UNITY_PASS_FORWARDBASE

    UnityGIInput giInput;
    UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
    giInput.light = gi.light;
    giInput.worldPos = worldPos;
    giInput.worldViewDir = worldViewDir;
    giInput.atten = attenuation;
    giInput.lightmapUV = 0.0;
    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
        half3 sh = 0;
        #ifdef VERTEXLIGHT_ON
            sh += Shade4PointLights(
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, worldPos, worldNormal);
        #endif
        sh = ShadeSHPerVertex(worldNormal, sh);
        giInput.ambient = sh;
    #else
        giInput.ambient.rgb = 0.0;
    #endif
    giInput.probeHDR[0] = unity_SpecCube0_HDR;
    giInput.probeHDR[1] = unity_SpecCube1_HDR;
    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
        giInput.boxMin[0] = unity_SpecCube0_BoxMin;
    #endif
    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
        giInput.boxMax[0] = unity_SpecCube0_BoxMax;
        giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
        giInput.boxMax[1] = unity_SpecCube1_BoxMax;
        giInput.boxMin[1] = unity_SpecCube1_BoxMin;
        giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
    #endif
    LightingStandard_GI(surfaceOutput, giInput, gi);

#endif

    output.color = LightingStandard(surfaceOutput, worldViewDir, gi);
    output.color.rgb += surfaceOutput.Emission;
    output.color.a = 0.0;
    output.color = CalculateFog(objectPos, clipPos, output.color);
    UNITY_OPAQUE_ALPHA(output.color.a);

    output.clipDepth = clipPos.z / clipPos.w;

    return output;
}

fixed4 ShadowCasterFragment(Varyings input) : SV_Target
{
    float3 objectPos;
    float3 objectNormalUnused;
    float materialUnused;
    bool hit = FragmentRaycast(input, objectPos, objectNormalUnused, materialUnused);
    clip(hit ? 1.0 : -1.0);

    // Has to be called `v` because `TRANSFER_SHADOW_CASTER` sucks
    struct
    {
        float4 vertex;
    } v;
    v.vertex = float4(objectPos, 1.0);

    struct
    {
        V2F_SHADOW_CASTER;
    } output;
    TRANSFER_SHADOW_CASTER(output);

    SHADOW_CASTER_FRAGMENT(output);
}
