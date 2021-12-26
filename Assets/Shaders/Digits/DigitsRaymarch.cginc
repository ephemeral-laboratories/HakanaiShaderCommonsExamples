
#include "Packages/garden.ephemeral.shader.commons/ELDistanceFunctions.cginc"
#include "Packages/garden.ephemeral.shader.commons/ELGeometry.cginc"
#include "Packages/garden.ephemeral.shader.commons/ELMathUtilities.cginc"
#include "Packages/garden.ephemeral.shader.commons/ELRaymarchBase.cginc"
#include "UnityCG.cginc"

uniform float4 _Colour1;
uniform float _Metallic1;
uniform float _Glossiness1;

uniform float _HeightScale;

static float wireRadius = 0.1;

float sdDigit0(float3 objectPos)
{
    return sdEllipse(objectPos.xy, float2(0.4, 0.6));
}

float sdDigit1(float3 objectPos)
{
    return udLineSegment(objectPos, float2(0.0, -0.6), float2(0.0, 0.6));
}

float sdDigit2(float3 objectPos)
{
    float2 p1 = objectPos.xy - float2(0.0, 0.2);
    return opU(
        udArc(p1, 0.4, UNITY_PI),
        udBezier(objectPos.xy, float2(0.4, 0.2), float2(0.4, -0.2), float2(-0.4, -0.6)),
        udLineSegment(objectPos.xy, float2(-0.4, -0.6), float2(0.4, -0.6)));
}

float sdDigit3(float3 objectPos)
{
    float2 p1 = objectPos.xy - float2(0.0, -0.2);
    pRotateHalf(p1);
    return opU(
        udLineSegment(objectPos.xy, float2(-0.4, 0.6), float2(0.4, 0.6)),
        udLineSegment(objectPos.xy, float2(0.4, 0.6), float2(0.0, 0.2)),
        udArc(p1, 0.4, UNITY_PI * 1.5));
}

float sdDigit4(float3 objectPos)
{
    return opU(
        udLineSegment(objectPos.xy, float2(-0.2, 0.6), float2(-0.4, -0.2)),
        udLineSegment(objectPos.xy, float2(-0.4, -0.2), float2(0.4, -0.2)),
        udLineSegment(objectPos.xy, float2(0.2, 0.6), float2(0.2, -0.6)));
}

float sdDigit5(float3 objectPos)
{
    float2 p2 = objectPos.xy - float2(0.0, -0.2);
    pRotateHalf(p2);
    return opU(
        udLineSegment(objectPos.xy, float2(-0.4, 0.6), float2(0.4, 0.6)),
        udLineSegment(objectPos.xy, float2(-0.4, 0.6), float2(-0.2, 0.146410161514)), // (√3-1)/5
        udArc(p2, 0.4, UNITY_PI * 1.5 + asin(0.5)));
}

float sdDigit6(float3 objectPos)
{
    float2 p1 = objectPos.xy - float2(0.4, -0.2);
    pRotateQuarter(p1);
    return opU(
        sdCircle(objectPos.xy + float2(0.0, 0.2), 0.4),
        udBezier(objectPos.xy, float2(-0.4, -0.2), float2(-0.4, 0.6), float2(0.2, 0.6)));
}

float sdDigit7(float3 objectPos)
{
    return opU(
        udLineSegment(objectPos.xy, float2(-0.4, 0.6), float2(0.4, 0.6)),
        udLineSegment(objectPos.xy, float2(0.4, 0.6), float2(-0.2, -0.6)));
}

float sdDigit8(float3 objectPos)
{
    return opU(
        sdCircle(objectPos.xy + float2(0.0, -0.325), 0.275),
        sdCircle(objectPos.xy + float2(0.0, 0.275), 0.325));
}

float sdDigit9(float3 objectPos)
{
    float2 p1 = objectPos.xy - float2(-0.4, 0.2);
    pRotateBackQuarter(p1);
    return opU(
        sdCircle(objectPos.xy + float2(0.0, -0.2), 0.4),
        udBezier(objectPos.xy, float2(0.4, 0.2), float2(0.4, -0.6), float2(-0.2, -0.6)));
}

float sdDigitX(float3 objectPos)
{
    float2 p1 = objectPos.xy + float2(0.0, 0.2);
    pRotateQuarter(p1);
    return opU(
        udLineSegment(objectPos.xy, float2(-0.4, 0.6), float2(0.0, 0.2)),
        udArc(p1, 0.4, UNITY_PI * 1.5));
}

float sdDigitE(float3 objectPos)
{
    float2 p1 = objectPos.xy + float2(0.0, -0.325);
    pRotateQuarter(p1);
    float2 p2 = objectPos.xy + float2(0.0, 0.275);
    pRotateQuarter(p2);
    return opU(
        udArc(p1, 0.275, UNITY_PI),
        udArc(p2, 0.325, UNITY_PI * 1.5));
}

float sdDigitPlaceholder(float3 objectPos)
{
    return udPoint(objectPos - 0.5);
}

float sdDigit(float3 objectPos, uint digit)
{
    float d;

    switch (digit)
    {
        case  0: d = sdDigit0(objectPos); break;
        case  1: d = sdDigit1(objectPos); break;
        case  2: d = sdDigit2(objectPos); break;
        case  3: d = sdDigit3(objectPos); break;
        case  4: d = sdDigit4(objectPos); break;
        case  5: d = sdDigit5(objectPos); break;
        case  6: d = sdDigit6(objectPos); break;
        case  7: d = sdDigit7(objectPos); break;
        case  8: d = sdDigit8(objectPos); break;
        case  9: d = sdDigit9(objectPos); break;
        case 10: d = sdDigitX(objectPos); break;
        case 11: d = sdDigitE(objectPos); break;
        default: d = sdDigitPlaceholder(objectPos); break;
    }

    return length(float2(d, objectPos.z)) - wireRadius;
}

float sdDigit(float3 objectPos, float digit)
{
    uint digitHere = (uint) floor(digit);
    uint digitNext = (digitHere + 1) % 12;
    float ratio = frac(digit);
    return lerp(sdDigit(objectPos, digitHere), sdDigit(objectPos, digitNext), ratio);
}

// Implementing function defined in `ELRaymarchCommon.cginc`
void ELBoundingBox(out float3 corner1, out float3 corner2)
{
    corner1 = float3(-0.5, -0.75 / 12.0, -wireRadius);
    corner2 = float3(0.5, 0.75 / 12.0, wireRadius);
}

// Implementing function defined in `ELRaymarchCommon.cginc`
float2 ELMap(float3 objectPos)
{
    objectPos.x += 0.5 * 0.08 * 11.0;
    float cell = pModInterval1(objectPos.x, 0.08, 0.0, 11.0);
    cell += _Time[1];
    cell = fmod(cell, 12.0);
    objectPos *= 15.0;
    float d = sdDigit(objectPos, cell);
    if (cell > 0)
    {
        d = min(d, sdDigit(objectPos + float3(1.2, 0.0, 0.0), cell - 1));
    }
    if (cell < 11)
    {
        d = min(d, sdDigit(objectPos - float3(1.2, 0.0, 0.0), cell + 1));
    }
    d /= 15.0;

    return float2(d, 0.0);
}           

// Implementing function defined in `ELRaycastBase.cginc`
void ELDecodeMaterial(ELRaycastBaseFragmentInput input, float material, inout SurfaceOutputStandard output)
{
    output.Albedo = _Colour1.rgb;
    output.Metallic = _Metallic1;
    output.Smoothness = _Glossiness1;
    output.Alpha = _Colour1.a;
}
