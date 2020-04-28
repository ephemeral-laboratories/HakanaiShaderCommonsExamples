#ifndef GRATITUDE_CGINC
#define GRATITUDE_CGINC

#include "Common/ELMathUtilities.cginc"
#include "Common/ELUnityUtilities.cginc"
#include "Common/ELDistanceFunctions.cginc"
#include "Common/ELScuttledUnityLighting.cginc"

#define TORUS_SCALE 0.25
float vmap(float3 p)
{
    p.x = abs(p.x);
    return opU(
        sdCapsule(p, float3(0.35, -0.1, 0.0), float3(0.35, 0.1, 0.0), 0.025),
        sdTorus((p - float3(0.15, 0.0, 0.0)).xzy / TORUS_SCALE, float2(0.4, 0.1)) * TORUS_SCALE);
}
struct AppData
{
    float4 vertex   : POSITION;
    float3 normal   : NORMAL;
    float4 tangent  : TANGENT;
    float4 color    : COLOR;
};
struct Varyings
{
    float4 pos              : SV_POSITION;
    float4 grabPos          : TEXCOORD0;
    float4 objectPos        : TEXCOORD1;
    float3 objectNormal     : NORMAL;
    float3 objectRayStart   : TEXCOORD2;
    float3 objectRayDir     : TEXCOORD3;
};
uniform sampler2D _GrabTex;
uniform float4 _GrabTex_TexelSize;
Varyings Vertex(AppData input)
{
    Varyings output;
    UNITY_INITIALIZE_OUTPUT(Varyings, output);
    output.pos = UnityObjectToClipPos(input.vertex);
    output.grabPos = ComputeGrabScreenPos(output.pos);
    output.objectPos = input.vertex;
    output.objectNormal = input.normal;
    if (UNITY_MATRIX_P[3][3] == 1.0)
    {
        output.objectRayDir = ELWorldToObjectNormal(-UNITY_MATRIX_V[2].xyz);
        output.objectRayStart = input.vertex - normalize(output.objectRayDir);
    }
    else
    {
        output.objectRayStart = ELWorldToObjectPos(UNITY_MATRIX_I_V._m03_m13_m23);
        output.objectRayDir = input.vertex - output.objectRayStart;
    }
    return output;
}
float4 FragmentForInterior(Varyings input, bool frontFace : SV_IsFrontFace) : SV_Target
{
    float3 rd = normalize(input.objectRayDir);
    float3 ro = input.objectRayStart;
    float col = 0.0;
    float3 sp;
	float t = 0.0;
    float layers = 0.0;
    float d;
    float aD;
    if (frontFace)
    {
        rd = refract(rd, input.objectNormal, 1.05);
    }
    float thD = 0.005;
#define MAX_LAYERS 200
#define ITERATIONS 200
	for (int i = 0; i < ITERATIONS; i++)
    {
        if (layers > MAX_LAYERS || col.x > 1.0 || t > 10.0)
        {
            break;
        }
        sp = ro + rd * t;
        d = vmap(sp);
        aD = (thD - abs(d) * 15.0 / 16.0) / thD;
        if (aD > 0.0)
        {
            col += aD * aD * (3.0 - 2.0 * aD) / (1.0 + t * t * 0.25) * 0.2;
            layers++;
        }
        t += max(abs(d) * 0.7, thD * 1.5);
	}
    col = clamp(col, 0.0, 1.0);
    SurfaceOutputStandard surfaceOutput;
    UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, surfaceOutput);
    surfaceOutput.Normal = UnityObjectToWorldNormal(input.objectNormal);
    surfaceOutput.Smoothness = 1.0 - col;
    surfaceOutput.Occlusion = 1.0;
    surfaceOutput.Alpha = 0.4;
    return ELSurfaceFragment(surfaceOutput, input.objectPos, input.objectNormal);
}

#endif