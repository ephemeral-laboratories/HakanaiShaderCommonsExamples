
#include "../Common/ELDistanceFunctions.cginc"
#include "../Common/ELGeometry.cginc"
#include "../Common/ELMathUtilities.cginc"
#include "../Common/ELRaymarchBase.cginc"
#include "UnityCG.cginc"

uniform float4 _Colour1;
uniform float _Metallic1;
uniform float _Glossiness1;

uniform float _HeightScale;

static float wireRadius = 0.1;

float sdDigit(float3 objectPos, float digit)
{
    float d2;

    // TODO: Digit morphing
    switch ((uint) floor(digit))
    {
        case 0:
        {
            d2 = sdEllipse(objectPos.xy, float2(0.4, 0.6));
            break;
        }

        case 1:
            d2 = sdLineSegment(objectPos, float2(0.0, -0.6), float2(0.0, 0.6));
            break;

        case 2:
        {
            float2 p1 = objectPos.xy - float2(0.0, 0.2);
            d2 = opU(
                sdArc(p1, 0.4, UNITY_PI),
                sdBezier(objectPos.xy, float2(0.4, 0.2), float2(0.4, -0.2), float2(-0.4, -0.6)),
                sdLineSegment(objectPos.xy, float2(-0.4, -0.6), float2(0.4, -0.6))
            );
            break;
        }

        case 3:
        {
            float2 p1 = objectPos.xy - float2(0.0, -0.2);
            pRotateHalf(p1);
            d2 = opU(
                sdLineSegment(objectPos.xy, float2(-0.4, 0.6), float2(0.4, 0.6)),
                sdLineSegment(objectPos.xy, float2(0.4, 0.6), float2(0.0, 0.2)),
                sdArc(p1, 0.4, UNITY_PI * 1.5)
            );
            break;
        }

        case 4:
        {
            d2 = opU(
                sdLineSegment(objectPos.xy, float2(-0.2, 0.6), float2(-0.4, -0.2)),
                sdLineSegment(objectPos.xy, float2(-0.4, -0.2), float2(0.4, -0.2)),
                sdLineSegment(objectPos.xy, float2(0.2, 0.6), float2(0.2, -0.6))
            );
            break;
        }

        case 5:
        {
            float2 p2 = objectPos.xy - float2(0.0, -0.2);
            pRotateHalf(p2);
            d2 = opU(
                sdLineSegment(objectPos.xy, float2(-0.4, 0.6), float2(0.4, 0.6)),
                sdLineSegment(objectPos.xy, float2(-0.4, 0.6), float2(-0.2, 0.146410161514)), // (√3-1)/5
                sdArc(p2, 0.4, UNITY_PI * 1.5 + asin(0.5))
            );
            break;
        }

        case 6:
        {
            float2 p1 = objectPos.xy - float2(0.4, -0.2);
            pRotateQuarter(p1);
            d2 = opU(
                sdCircle2(objectPos.xy + float2(0.0, 0.2), 0.4),
                sdBezier(objectPos.xy, float2(-0.4, -0.2), float2(-0.4, 0.6), float2(0.2, 0.6))
            );
            break;
        }

        case 7:
        {
            d2 = opU(
                sdLineSegment(objectPos.xy, float2(-0.4, 0.6), float2(0.4, 0.6)),
                sdLineSegment(objectPos.xy, float2(0.4, 0.6), float2(-0.2, -0.6))
            );
            break;
        }

        case 8:
        {
            d2 = opU(
                sdCircle2(objectPos.xy + float2(0.0, -0.325), 0.275),
                sdCircle2(objectPos.xy + float2(0.0, 0.275), 0.325)
            );
            break;
        }

        case 9:
        {
            float2 p1 = objectPos.xy - float2(-0.4, 0.2);
            pRotateBackQuarter(p1);
            d2 = opU(
                sdCircle2(objectPos.xy + float2(0.0, -0.2), 0.4),
                sdBezier(objectPos.xy, float2(0.4, 0.2), float2(0.4, -0.6), float2(-0.2, -0.6))
            );
            break;
        }

        case 10:
        {
            float2 p1 = objectPos.xy + float2(0.0, 0.2);
            pRotateQuarter(p1);
            d2 = opU(
                sdLineSegment(objectPos.xy, float2(-0.4, 0.6), float2(0.0, 0.2)),
                sdArc(p1, 0.4, UNITY_PI * 1.5)
            );
            break;
        }

        case 11:
        {
            float2 p1 = objectPos.xy + float2(0.0, -0.325);
            pRotateQuarter(p1);
            float2 p2 = objectPos.xy + float2(0.0, 0.275);
            pRotateQuarter(p2);
            d2 = opU(
                sdArc(p1, 0.275, UNITY_PI),
                sdArc(p2, 0.325, UNITY_PI * 1.5)
            );
            break;
        }

        default:
            return sdSphere(objectPos, 0.5);
    }

    return length(float2(d2, objectPos.z)) - wireRadius;
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
    uint cell = (uint) pModInterval1(objectPos.x, 0.08, 0.0, 11.0);
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
