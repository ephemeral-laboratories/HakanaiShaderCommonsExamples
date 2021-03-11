
#include "../Common/ELRaycastBase.cginc"
#include "../Common/ELIntersectionFunctions.cginc"


////////////////////////////////////////////////////////////////////////////////
// Input / Output Data Structures

struct FragmentInput
{
    // Stuff from ELRaycastBaseFragmentInput
    float4 pos              : SV_POSITION;
    float4 color            : COLOR;
    float4 grabPos          : TEXCOORD0;
    float4 objectPos        : TEXCOORD1;
    float3 objectNormal     : NORMAL;
    float3 objectRayOrigin   : TEXCOORD2;
    float3 objectRayDirection     : TEXCOORD3;
    float4 lmap : TEXCOORD4;
    half3 sh : TEXCOORD5;
    uint its : TEXCOORD6;
    // Our extra stuff
    float2 texcoord         : TEXCOORD7;
    float2 texcoordMetallic : TEXCOORD8;
    float2 texcoordNormal   : TEXCOORD9;
    float2 texcoordEmission : TEXCOORD10;
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
uniform float4 _BallAlbedo;
uniform float3 _BallEmission;
uniform float _BallMetallic;
uniform float _BallSmoothness;


////////////////////////////////////////////////////////////////////////////////
// Vertex Shader

FragmentInput Vertex(ELRaycastBaseVertexInput input)
{
    FragmentInput output;
    UNITY_INITIALIZE_OUTPUT(FragmentInput, output);

    (ELRaycastBaseFragmentInput) output = ELRaycastBaseVertex(input);

    output.texcoord = TRANSFORM_TEX(input.texcoord, _MainTex);
    output.texcoordMetallic = TRANSFORM_TEX(input.texcoord, _MetallicTex);
    output.texcoordNormal = TRANSFORM_TEX(input.texcoord, _NormalMap);
    output.texcoordEmission = TRANSFORM_TEX(input.texcoord, _EmissionMap);

    return output;
}


////////////////////////////////////////////////////////////////////////////////
// Fragment Shader

FragmentInput myInput;
uint face;

/**
 * Stashes custom stuff into global variables so that our overridden
 * functions can get at them without having to find even trickier ways
 * to pass them through multiple method calls.
 */
void StashGlobals(FragmentInput input)
{
    myInput = input;

    // Determine the face of the die which was hit by looking at the vertex colour.
    // I coloured the model systematically so that this could be written programmatically.
    // R=1, G=2, B=4, and add the values together.
    // e.g., cyan is green + blue, so it would be face 6.
    face = dot(input.color > 0.5 ? 1 : 0, uint3(1, 2, 4));
}

// Implementing function defined in `ELRaycastBase.cginc`
bool ELRaycast(ELRay ray, out float3 objectPos, out float3 objectNormal, out float material, out uint iterations, out float reach)
{
    iterations = 0;
    reach = 0.0;     
    if (face == 7)
    {
        // Hits the frame immediately
        objectPos = myInput.objectPos;
        objectNormal = myInput.objectNormal;
        material = 0.0;
        return true;
    }

    static const float sphereRadius = 0.00125;
    static const float k = 0.00275;
    static const float sphereRadius2 = sphereRadius * sphereRadius;
    static const float3 spherePositions[21] = {
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
    static const uint spherePositionOffsets[7] = {0, 0, 1, 3, 6, 10, 15};

    uint offset = spherePositionOffsets[face];
    float bestReach = 100.0;
    bool hit = false;
    for (uint i = 0; i < face; i++)
    {
        float3 sphereCentre = spherePositions[offset + i];

        if (ELSphereRayIntersect(sphereCentre, sphereRadius2, ray))
        {
            hit = true;
            if (ray.reach < bestReach)
            {
                objectPos = ray.position;
                // XXX: Could try delaying this until the end of the loop?
                objectNormal = normalize(objectPos - sphereCentre);
                material = 1.0;
                bestReach = ray.reach;
            }
        }
    }

    return hit;
}

// Implementing function defined in `ELRaycastBase.cginc`
void ELDecodeMaterial(ELRaycastBaseFragmentInput input, float material, inout SurfaceOutputStandard output)
{
    if (material > 0.5)
    {
        // XXX: I want to texture this better too some day, but smooth balls are nice too. uwu
        output.Albedo = _BallAlbedo.rgb;
        output.Alpha = _BallAlbedo.a;
        output.Emission = _BallEmission;
        output.Metallic = _BallMetallic;
        output.Smoothness = _BallSmoothness;
    }
    else
    {
        float4 albedo = tex2D(_MainTex, myInput.texcoord) * _Color;
        output.Albedo = albedo.rgb;
        output.Alpha = albedo.a;

        float4 metal = tex2D(_MetallicTex, myInput.texcoordMetallic);
        output.Metallic = metal.r * _Metallic;
        output.Smoothness = metal.a * _Smoothness;

        output.Normal = UnpackNormal(tex2D(_NormalMap, myInput.texcoordNormal));

        output.Emission = tex2D(_EmissionMap, myInput.texcoordEmission) * _EmissionColor;
    }
}

/**
 * Fragment shader for forward / forward add.
 *
 * @param input the fragment input structure.
 * @return the fragment output structure.
 */
ELRaycastBaseFragmentOutput Fragment(FragmentInput input)
{
    StashGlobals(input);
    return ELRaycastFragment((ELRaycastBaseFragmentInput) input);
}

/**
 * Fragment shader for shadow caster.
 *
 * @param input the fragment input structure.
 * @return the shadow caster fragment result.
 */
float4 ShadowCasterFragment(FragmentInput input) : SV_Target
{
    StashGlobals(input);
    return ELRaycastShadowCasterFragment((ELRaycastBaseFragmentInput) input);
}
