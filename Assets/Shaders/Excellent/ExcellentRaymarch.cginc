
#include "../Common/ELDistanceFunctions.cginc"
#include "../Common/ELMathUtilities.cginc"
#include "../Common/ELRaymarchBase.cginc"
#include "StarnestBase.cginc"
#include "UnityCG.cginc"

uniform float4 _Colour1;
uniform float _Metallic1;
uniform float _Glossiness1;

float sdStarPrism(float3 objectPos, float scale)
{
    objectPos.xy = pModRotate(objectPos.xy, UNITY_HALF_PI);
    objectPos.xy = pModPolar(objectPos.xy, 5.0);
    objectPos -= float3(0.1, 0.0, 0.0);
    objectPos.xy = pModRotate(objectPos.xy, -UNITY_HALF_PI);

    objectPos /= scale;
    return sdTriPrism(objectPos, float2(0.1, 0.25)) * scale;
}

float2 ELMap(float3 objectPos)
{
    float rotation = _Time[1] * 25.0;
    objectPos = ELRotateAroundYInDegrees(objectPos, rotation);

    float2 exterior = float2(opS(
        sdStarPrism(objectPos, 2.3),
        sdRoundedCylinder(objectPos.xzy, 0.23, 0.05, 0.1)), 1.0);

    float2 interior = float2(
        sdCylinder(objectPos.xzy, float2(0.4, 0.08)), 0.0);

    return opU_mat(exterior, interior);
}           

void ELDecodeMaterial(ELRaymarchBaseVertexOutput input, float material, inout SurfaceOutputStandard output)
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
        float3 worldRayDir = UnityObjectToWorldNormal(input.objectRayDir);
        float4 colour = Starnest(worldRayDir);
        output.Emission = colour.rgb;
        output.Alpha = colour.a;
    }
}
