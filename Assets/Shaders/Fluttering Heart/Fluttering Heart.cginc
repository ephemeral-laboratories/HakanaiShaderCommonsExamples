
#include "../Common/ELDistanceFunctions.cginc"
#include "../Common/ELGeometry.cginc"
#include "../Common/ELMathUtilities.cginc"
#include "../Common/ELRaymarchBase.cginc"
#include "UnityCG.cginc"

// Commenting out uniforms already defined for us in headers. Leaving here for documentation.
//uniform float4 _Color;
//uniform float _Metallic;
//uniform float _Glossiness;

uniform float _SpinSpeed;
uniform float _Bounds;

// https://www.iquilezles.org/www/articles/functions/functions.htm
float almostIdentity(float x, float m, float n)
{
    if (x > m)
    {
        return x;
    }
    float a = 2.0 * n - m;
    float b = 2.0 * m - 3.0 * n;
    float t = x / m;
    return (a * t + b) * t * t + n;
}

float rand(float n)
{
    return frac(sin(n) * 43758.5453123);
}

float noise(float2 n)
{
    static const float2 d = float2(0.0, 1.0);
    float2 b = floor(n);
    float2 f = smoothstep(float2(0.0, 0.0), float2(1.0, 1.0), frac(n));
	return lerp(lerp(rand(b), rand(b + d.yx), f.x), lerp(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float mod289(float x)
{
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 mod289(float4 x)
{
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 perm(float4 x)
{
    return mod289(((x * 34.0) + 1.0) * x);
}

float noise(float3 p)
{
    float3 a = floor(p);
    float3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    float4 b = a.xxyy + float4(0.0, 1.0, 0.0, 1.0);
    float4 k1 = perm(b.xyxy);
    float4 k2 = perm(k1.xyxy + b.zzww);

    float4 c = k2 + a.zzzz;
    float4 k3 = perm(c);
    float4 k4 = perm(c + 1.0);

    float4 o1 = frac(k3 * (1.0 / 41.0));
    float4 o2 = frac(k4 * (1.0 / 41.0));

    float4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    float2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float sd2DHeart(float2 objectPos, float radius)
{
    // Scale down 1.3 in Y
    float2 p = objectPos * float2(1.0, 1.3);

    // Heart is reflected in X
    p.x = abs(p.x);

    // Smooth out the sharp corners a bit
    p.x = almostIdentity(p.x, radius * 0.1, radius * 0.02);

    // Heart shape transform
    p.y -= p.x * sqrt(1.0 - p.x);

    float d = sdCircle(p, radius);

    // Largest scale above is 1.3 so usually you'd divide by 1.3 here,
    // but I only get a clean result if I go to 1.8. Returning smaller
    // distances hurts performance a bit, but better than overestimating
    // and cutting into the objects in the scene.
    d /= 1.8;

    return d;
}

float sdFlatHeart(float3 objectPos, float radius, float height)
{
    float d = sd2DHeart(objectPos.xy, radius);

    // Extrusion along Z
    float2 w = float2(d, abs(objectPos.z) - height);

    // w *= pow(0.5 + 0.5 * sin(UNITY_TWO_PI * _Time[1] + w.y / 250.0), 4.0);

    d = min(max(w.x, w.y), 0.0) + length(max(w, 0.0));

    return d;
}

float infiniteHeartField(float3 objectPos)
{
    static const float repetition = 11.0;
    static const float cellSize = 1.0 / repetition;

    float3 cellId = pMod3(objectPos, float3(cellSize, cellSize, cellSize));

    // Geometry for one cell in the repetition
    float3 randOffset = float3(
        lerp(-0.15 * cellSize, 0.15 * cellSize, noise(cellId + 0.1)),
        lerp(-0.15 * cellSize, 0.15 * cellSize, noise(cellId + 0.2)),
        lerp(-0.15 * cellSize, 0.15 * cellSize, noise(cellId + 0.3)));
    float randAngle = noise(cellId) * UNITY_TWO_PI;
    objectPos += randOffset;
    pRotate(objectPos.xz, randAngle + _Time[1] * _SpinSpeed);
    float d1 = sdFlatHeart(objectPos, 0.20 * cellSize, 0.02 * cellSize);
    float d2 = sdFlatHeart(objectPos, 0.18 * cellSize, 0.04 * cellSize);
    float d = opU(d1, d2);

    // Guard to prevent discontinuities between cells
    // Seen here: http://www.pouet.net/topic.php?which=7920&page=70
    // And here: http://mercury.sexy/hg_sdf/
    float guard = -sdBoxCheap(objectPos, float3(0.5, 0.5, 0.5) * cellSize);
    guard = abs(guard) + 0.25 * cellSize;
    d = min(d, guard);

    return d;
}

// Implementing function defined in `ELRaymarchCommon.cginc`
void ELBoundingBox(out float3 boxMin, out float3 boxMax)
{
    boxMin = float3(-_Bounds, -_Bounds, -_Bounds);
    boxMax = float3( _Bounds,  _Bounds,  _Bounds);
}

// Implementing function defined in `ELRaymarchCommon.cginc`
float2 ELMap(float3 objectPos)
{
    float d = opI(
        infiniteHeartField(objectPos),
        sdSphere(objectPos, _Bounds));

    return float2(d, 1.0);
}

// Implementing function defined in `ELRaycastBase.cginc`
void ELDecodeMaterial(ELRaycastBaseFragmentInput input, float material, inout SurfaceOutputStandard output)
{
    output.Albedo = _Color.rgb;
    output.Metallic = _Metallic;
    output.Smoothness = _Glossiness;
    output.Alpha = _Color.a;
}
