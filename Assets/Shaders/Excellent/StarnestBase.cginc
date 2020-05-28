
#include "UnityCG.cginc"

#define iterations 17
#define formuparam 0.53

#define volsteps 20
#define stepsize 0.1

#define zoom   0.800
#define tile   0.850
#define speed  0.010 

#define brightness 0.0015
#define darkmatter 0.300
#define distfading 0.730
#define saturation 0.850

#define SCROLL float4(1.3, 1.0, 0.6, 0.01)

// float2x2 rotationMatrix(float theta)
// {
//     float sinTheta, cosTheta;
//     sincos(theta, sinTheta, cosTheta);
//     return float2x2(cosTheta, sinTheta, -sinTheta, cosTheta);
// }

float3 mod(float3 x, float3 y)
{
    return x - y * floor(x / y);
}

float4 Starnest(float3 worldRayDir)
{
    float3 from = float3(1.0, 0.5, 0.5);

    float time = _Time[1];
    from += SCROLL.xyz * SCROLL.w * time;

    float s = 0.1;
    float fade = 1.0;
    float3 v = float3(0.0, 0.0, 0.0);
    for (uint r = 0; r < volsteps; r++)
    {
        float3 p = from + s * normalize(worldRayDir) * 0.5;
        p = abs(tile.xxx - mod(p, (tile * 2.0).xxx)); // tiling fold
        float pa = 0.0;
        float a = 0.0;
        for (uint i = 0; i < iterations; i++)
        { 
            p = abs(p) / dot(p, p) - formuparam; // the magic formula
            float lenP = length(p);
            a += abs(lenP - pa); // absolute sum of average change
            pa = lenP;
        }
        float dm = max(0.0, darkmatter - a * a * 0.001); //dark matter
        a *= a * a; // add contrast
        if (r > 6)
        {
            fade *= 1.0 - dm; // dark matter, don't render near
        }
        //v += float3(dm, dm * 0.5, 0.0);
        v += fade;
        v += float3(s, s * s, s * s * s * s) * a * brightness * fade; // coloring based on distance
        fade *= distfading; // distance fading
        s += stepsize;
    }
    v = lerp(length(v).xxx, v, saturation); //color adjust
    v *= 0.01;
    v = GammaToLinearSpace(v);
    v.rgb = clamp(v.rgb, 0.0, 5.0);
    return float4(v, 1.0);
}
