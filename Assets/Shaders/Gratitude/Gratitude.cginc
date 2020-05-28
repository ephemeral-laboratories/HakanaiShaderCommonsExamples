#ifndef GRATITUDE_CGINC
#define GRATITUDE_CGINC

#include "../Common/ELMathUtilities.cginc"
#include "../Common/ELUnityUtilities.cginc"
#include "../Common/ELDistanceFunctions.cginc"
#include "../Common/ELScuttledUnityLighting.cginc"
#include "../Common/ELRaymarchBase.cginc"

#define TORUS_SCALE 0.25
float Map(float3 pos)
{
    pos.x = abs(pos.x);
    return opU(
        sdCapsule(pos, float3(0.35, -0.1, 0.0), float3(0.35, 0.1, 0.0), 0.025),
        sdTorus((pos - float3(0.15, 0.0, 0.0)).xzy / TORUS_SCALE, float2(0.4, 0.1)) * TORUS_SCALE);
}

float4 Fragment(ELRaycastBaseFragmentInput input, bool frontFace : SV_IsFrontFace) : SV_Target
{
    ELRay ray = ELGetRay(input);

    // Refract the ray if viewing through the front face.
    if (frontFace)
    {
        ray.dir = refract(ray.dir, input.objectNormal, 1.05);
    }

    // Code here inspired by: https://www.shadertoy.com/view/ll2SRy

    // Parameters common to any translucent raymarch
    #define MAX_LAYERS 200
    #define ITERATIONS 200
    #define MAX_T 10.0

    // Parameters specific to our accumulation logic
    // Surface distance threshold. Smaller values give sharper result.
    static const float thresholdDist = 0.005;
    static const float colorDensity = 0.2;

    // Accumulators
    float color = 0.0;
    uint layers = 0;

    // Lots of duplicated code here, but the map and accumulation logic is always different.
    // Is there a good way to clean it up?

	for (uint iteration = 0; iteration < ITERATIONS; iteration++)
    {
        // This one's worth making a branch because an early abort can save GPU time.
        UNITY_BRANCH
        if (layers > MAX_LAYERS || color > 1.0 || ray.t > MAX_T)
        {
            break;
        }

        float mapResult = Map(ray.pos);

        // Are we near the border of the shape?
        // The 15/16 here is a mystery to me at the moment.
        float normalisedDist = (thresholdDist - abs(mapResult) * 15.0 / 16.0) / thresholdDist;
        if (normalisedDist > 0.0)
        {
            normalisedDist = smoothstep(0.0, 1.0, normalisedDist);
            // Simulated exponential drop-off
            float attenuation = 1.0 / (1.0 + ray.t * ray.t * 0.25);
            color += normalisedDist * attenuation * colorDensity;
            layers++;
        }

        // Arbitrary magic numbers again.
        ELAdvanceRay(ray, max(abs(mapResult) * 0.7, thresholdDist * 1.5));
	}

    color = clamp(color, 0.0, 1.0);

    SurfaceOutputStandard surfaceOutput = ELInitSurfaceOutput(input.objectNormal);
    surfaceOutput.Smoothness = 1.0 - color;
    surfaceOutput.Alpha = 0.4;
    return ELSurfaceFragment(surfaceOutput, input.objectPos, input.objectNormal);
}

#endif