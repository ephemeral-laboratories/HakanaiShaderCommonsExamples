
#include "Packages/garden.ephemeral.shader.commons/ELDistanceFunctions.cginc"
#include "Packages/garden.ephemeral.shader.commons/ELGeometry.cginc"
#include "Packages/garden.ephemeral.shader.commons/ELMathUtilities.cginc"
#include "Packages/garden.ephemeral.shader.commons/ELRaymarchBase.cginc"
#include "StarnestBase.cginc"
#include "UnityCG.cginc"

uniform float4 _Colour1;
uniform float _Metallic1;
uniform float _Glossiness1;

float sdStarPrism(float3 objectPos, float scale)
{
    objectPos.xy = pModRotate(objectPos.xy, UNITY_HALF_PI);
    pModPolar(objectPos.xy, 5.0);
    objectPos -= float3(0.1, 0.0, 0.0);
    objectPos.xy = pModRotate(objectPos.xy, -UNITY_HALF_PI);

    objectPos /= scale;
    return sdTriPrism(objectPos, float2(0.1, 0.25)) * scale;
}

// implementing method declared in `ELRaymarchCommon.cginc`
void ELBoundingBox(out float3 boxMin, out float3 boxMax)
{
    boxMin = float3(-0.5, -0.5, -0.5);
    boxMax = float3( 0.5,  0.5,  0.5);
}

// implementing method declared in `ELRaymarchCommon.cginc`
float2 ELMap(float3 objectPos)
{
    float rotation = _Time[1] * 25.0;
    objectPos = ELRotateAroundYInDegrees(objectPos, rotation);

    float2 exterior = float2(opS(
        sdStarPrism(objectPos, 2.3),
        sdRoundedCylinder(objectPos.xzy, 0.23, 0.05, 0.1)), 1.0);

    float2 interior = float2(
        sdCylinder(objectPos.xzy, float2(0.4, 0.08)), 0.0);

    return opU(exterior, interior);
}           

// Implementing function defined in `ELRaycastBase.cginc`
void ELDecodeMaterial(ELRaycastBaseFragmentInput input, float material, inout SurfaceOutputStandard output)
{
    if (material > 0.5)
    {
        output.Albedo = _Colour1.rgb;
        output.Metallic = _Metallic1;
        output.Smoothness = _Glossiness1;
        output.Alpha = _Colour1.a;
    }
    else
    {
        float3 worldRayDir = UnityObjectToWorldNormal(input.objectRayDirection);
        float4 colour = Starnest(worldRayDir);
        output.Emission = colour.rgb;
        output.Alpha = colour.a;
    }
}
