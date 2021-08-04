#include "../../Common/ELDistanceFunctions.cginc"
#include "../../Common/ELGeometry.cginc"
#include "../../Common/ELMathUtilities.cginc"
#include "../../Common/ELRaymarchBase.cginc"
#include "../../Excellent/StarnestBase.cginc"
#include "UnityCG.cginc"

uniform float4 _Colour1;
uniform float _Metallic1;
uniform float _Glossiness1;
uniform float _Bound;

float3 hmod(float3 a, float3 b)
{
    return frac(abs(a / b)) * abs(b);
}

float3 repeat(float3 pos, float3 span)
{
    return hmod(pos, span) - span * 0.5;
}

// Specialized implementations. You can use either or for the icosahedron and dodecahedron.

float sdIcosahedron2(float3 p, float r)
{
    const float q = (sqrt(5.0) + 3.0) / 2.0;
    const float3 n1 = normalize(float3(q, 1.0, 0.0));
    const float3 n2 = sqrt(3.0) / 3.0;

    p = abs(p / r);
    float a = dot(p, n1.xyz);
    float b = dot(p, n1.zxy);
    float c = dot(p, n1.yzx);
    float d = dot(p, n2.xyz) - n1.x;

    // turn into (...)/r  for weird refractive effects when you subtract this shape
    return max(max(max(a, b), c) - n1.x, d) * r;
}

float sdDodecahedron2(float3 p, float r)
{
    const float phi = (1.0 + sqrt(5.0)) * 0.5;
    const float3 n = normalize(float3(phi, 1.0, 0.0));

    p = abs(p / r);
    float a = dot(p, n.xyz);
    float b = dot(p, n.zxy);
    float c = dot(p, n.yzx);
    return (max(max(a, b), c) - n.x) * r;
}

float sdRoundBox9PatchField(float3 pos, float box, float radius, float offset, float smin)
{
    pos = repeat(pos, offset);
    // Smoothing help from pema99
    float3 dirs[7] =
    {
        float3( 0,  0,  0),
        float3( 0,  1,  0),
        float3( 0, -1,  0),
        float3( 1,  0,  0),
        float3(-1,  0,  0),
        float3( 0,  0,  1),
        float3( 0,  0, -1)
    };
    float m = 100000000;
    //For each of the 7 directions we want to smooth with a roundbox.
    for (int i = 0; i < 7; i++)
    {
        m = opSmoothUnion(m, sdRoundBox(pos + dirs[i] * offset, box, radius), smin);
    }
    return m;
}

float sdStarPrism(float3 objectPos, float scale)
{
    objectPos.xy = pModRotate(objectPos.xy, UNITY_HALF_PI);
    objectPos.xy = pModPolar(objectPos.xy, 5.0);
    objectPos -= float3(0.1, 0.0, 0.0);
    objectPos.xy = pModRotate(objectPos.xy, -UNITY_HALF_PI);

    objectPos /= scale;
    return sdTriPrism(objectPos, float2(0.1, 0.25)) * scale;
}

void ELBoundingBox(out float3 boxMin, out float3 boxMax)
{
    boxMin = float3(-_Bound, -_Bound, -_Bound);
    boxMax = float3( _Bound,  _Bound,  _Bound);
}

// Slightly larger geometry cube to encompass the entire raymarch.
[maxvertexcount(24)]
void ExcellentGeometryCube(line ELRaycastBaseVertexInput input[2], inout TriangleStream<ELRaycastBaseFragmentInput> triStream)
{
    static const float4 cv[8] = { float4(-_Bound, -_Bound, -_Bound, 1.0),
                                  float4(-_Bound, -_Bound,  _Bound, 1.0),
                                  float4(-_Bound,  _Bound, -_Bound, 1.0),
                                  float4(-_Bound,  _Bound,  _Bound, 1.0),
                                  float4( _Bound, -_Bound, -_Bound, 1.0),
                                  float4( _Bound, -_Bound,  _Bound, 1.0),
                                  float4( _Bound,  _Bound, -_Bound, 1.0),
                                  float4( _Bound,  _Bound,  _Bound, 1.0) };
    static const float t = 0.57735026916;
    static const float4 cn[8] = { float4(-t, -t, -t, 1.0),
                                  float4(-t, -t,  t, 1.0),
                                  float4(-t,  t, -t, 1.0),
                                  float4(-t,  t,  t, 1.0),
                                  float4( t, -t, -t, 1.0),
                                  float4( t, -t,  t, 1.0),
                                  float4( t,  t, -t, 1.0),
                                  float4( t,  t,  t, 1.0) };

    static const uint cf[24] = { 0, 1, 2, 3,    // left
                                 0, 2, 4, 6,    // front
                                 4, 6, 5, 7,    // right
                                 7, 3, 5, 1,    // back
                                 2, 3, 6, 7,    // top
                                 0, 4, 1, 5  }; // bottom

    ELRaycastBaseVertexInput output = input[0];
    for (int i = 0; i < 6; i++)
    {
        for (int j = 0; j < 4; j++)
        {
            float vi = cf[i * 4 + j];
            output.objectPos = cv[vi];
            output.objectNormal = cn[vi];
            triStream.Append(ELRaycastBaseVertex(output));
        }
        triStream.RestartStrip();
    }
}

float2 ELMap(float3 objectPos)
{
    float rotation = _Time[1] * 25.0;

    objectPos = ELRotateAroundYInDegrees(objectPos, rotation);
    float t = _Time.x;
    float a = 3.0 * UNITY_PI * t;
    float s = pow(sin(a), 2.0);
    float d1 = sdIcosahedron2(objectPos, 1.0);
    float d2 = sdRoundBox9PatchField(
        objectPos,
        0.1 - 0.1 * s,
        0.1 / length(objectPos * 2.0),
        0.2,
        0.15 * pow(s, 4.0));

    float2 exterior = float2(opS(
        sdStarPrism(objectPos, 2.3),
        sdRoundedCylinder(objectPos.xzy, 0.23, 0.05, 0.1)), 1.0);

    float2 interior = float2(
        sdCylinder(objectPos.xzy, float2(0.4, 0.08)), 0.0);
    float2 frame = float2(sdBoundingBox(objectPos.xyz, (float3) 1.2, 0.1), 1.0);

    float2 boundsX = float2(opSmoothIntersection(
        opS(sdIcosahedron2(objectPos, 0.20),
            sdDodecahedron2(objectPos,1.75)),
        lerp(d1, d2, s), s), s);
    boundsX = opI(boundsX, float2(sdIcosahedron2(objectPos, 1.0), s));
    return opU(frame, opU(boundsX, opU(exterior, interior)));
}

void ELDecodeMaterial(ELRaycastBaseFragmentInput input, float material, inout SurfaceOutputStandard output)
{
    float3 worldRayDir = UnityObjectToWorldNormal(input.objectRayDirection);
    float rt = pow(sin( 3 * UNITY_PI * frac(_Time.x)), 2.0);
    float s = sdRoundBox(repeat(input.objectPos, ELSmootherStep(2.0, 0.1, rt)), rt,0.45);
    float c = sdBox(repeat(input.objectPos, ELSmootherStep(6.0, 0.25, rt)), rt);
    float t = sdRoundBox(
        repeat(input.objectPos, 0.25),
        0.1 - 0.1 * rt,
        0.1 / length(input.objectPos * 2.0));
    float p = sdSphere(repeat(worldRayDir, 0.2), 3.5);
    float4 a = normalize(float4(1.0 / ELSmootherStep(s, t, rt), 1.0 / t, 1.0 / c,  1.0));
    float4 mat1Color = float4(
        a.x,
        a.y,
        a.z,
        a.w);
    float4 colour = Starnest(worldRayDir);

    output.Albedo = lerp(0.0,mat1Color.rgb, material);
    output.Metallic = lerp(0.0,_Metallic1, material);
    output.Smoothness = lerp(0.0, _Glossiness1, material);
    output.Alpha = lerp(colour.a, _Colour1.a, material);
    output.Emission = lerp(colour.rgb, 0.0, material);
}
