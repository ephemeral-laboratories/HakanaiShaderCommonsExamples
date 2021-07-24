

#include "../Common/ELColorConversions.cginc"
#include "../Common/ELDistanceFunctions.cginc"
#include "../Common/ELGeometry.cginc"
#include "../Common/ELMathUtilities.cginc"
#include "../Common/ELRaymarchBase.cginc"
#include "UnityCG.cginc"

// #define FRACTAL_ORDER 9
#define FRACTAL_ORDER 6

float4 _Colour;
float4 _TintColour;
float _TintMultiplier;
float _HueRotationRate;
//float _Metallic;
float _Smoothness;
float _Animate;

// implementing method declared in `ELRaymarchCommon.cginc`
void ELBoundingBox(out float3 boxMin, out float3 boxMax)
{
    boxMin = float3(-0.5, -0.5, -0.5);
    boxMax = float3( 0.5,  0.5,  0.5);
}


/**
 * Computes the maximum component from the given vector.
 *
 * @param vec the input vector.
 * @return the max component.
 */
inline float maxcomp(in float3 vec)
{
    return max(vec.x, max(vec.y, vec.z));
}

/**
 * Computes the minimum component from the given vector.
 *
 * @param vec the input vector.
 * @return the min component.
 */
inline float mincomp(in float3 vec)
{
    return min(vec.x, min(vec.y, vec.z));
}

/**
 * Zero-safe alternative to `sign`.
 *
 * @param value the value.
 * @return 1 if value >= 0, otherwise -1.
 */
inline float sgn(in float value)
{
    return value >= 0 ? 1 : -1;
}

/**
 * Zero-safe alternative to `sign`.
 *
 * @param value the value.
 * @return the result of applying `sgn(float)` to all components.
 */
inline float3 sgn(in float3 vec)
{
    return float3(sgn(vec.x), sgn(vec.y), sgn(vec.z));
}

inline float maxcompLength(in float3 vec)
{
    return maxcomp(abs(vec));
}

// Distance from box's origin to its wall
#define CUBE_SIZE 0.5

/**
 * Computes the distance to a box centred at (0,0)
 * with `CUBE_SIZE` distance from origin to walls.
 *
 * @param position the position, in box coordinates.
 * @return if outside the box, the positive distance from the box;
 *         if inside the box, negative;
 *         zero when precisely on the boundary.
 */
float distanceToBox(in float3 position)
{
    // Distances will contain the distance from the wall on each axis, negative if inside the box.
    float3 distances = abs(position) - CUBE_SIZE;

    // The maxcomp(distances) part is here to account for the case where you're inside the box
    // and just ensures you get a negative result.
    // length(max(distances, 0.0)) gives you the exact distance to the box when you're outside it.
    return min(maxcomp(distances), length(max(distances, 0.0)));
}

//TODO: repeat forever would require an additional structure of settings

static const float3x3 animationMatrix = float3x3( 0.60, 0.00, 0.80,
                                                  0.00, 1.00, 0.00,
                                                 -0.80, 0.00, 0.60);

// implementing method declared in `ELRaymarchCommon.cginc`
float2 ELMap(float3 objectPos)
{
    float animationFactor = smoothstep(-0.1, 0.1, -cos(0.1 * _Time[1])) * _Animate;
    float animationOffset = 1.5 * sin(0.01 * _Time[1]) * _Animate;

    float2 result = float2(distanceToBox(objectPos), 0);

    objectPos = abs(objectPos);
    float s = 1.0;

    for (uint m = 1; m <= FRACTAL_ORDER; m++)
    {
        objectPos = lerp(objectPos, mul(animationMatrix, objectPos + animationOffset), animationFactor);

        // Rescale so that we're computing distances against a -0.5 ~ +0.5 cube again
        // If inside the hole, component is distance from the wall of the hole on that axis
        // If inside the object, component is negative
        float3 a = frac(objectPos * s) - CUBE_SIZE;
        s *= 3.0;
        float3 r = abs(0.5 - 3.0 * abs(a));
        // Each of the components of `d` is positive if at least one of the input components was positive.
        // i.e., you get a negative result if both components are negative.
        float3 d = max(r.xyz, r.yzx);
        // If any of those got a negative result, then the entire result is negative.
        float newDistance = (mincomp(d) - 0.5) / s;

        if (newDistance > result.x)
        {
            result.x = newDistance;
            result.y = m;
        }
    }

    return result;
}

// Implementing function defined in `ELRaycastBase.cginc`
void ELDecodeMaterial(ELRaycastBaseFragmentInput input, float material, inout SurfaceOutputStandard output)
{
    float4 colour = saturate(lerp(_Colour, _TintColour, _TintMultiplier * material / FRACTAL_ORDER));

    // Hue rotation
    float3 temp = ELRGBtoHSV(colour.rgb);
    temp.r = frac(temp.r + _HueRotationRate * _Time);
    temp = ELHSVtoRGB(temp);
    colour = float4(temp, colour.a);

    output.Albedo = colour.rgb;
    output.Alpha = colour.a;

    output.Metallic = _Metallic;
    output.Smoothness = _Smoothness;
}
