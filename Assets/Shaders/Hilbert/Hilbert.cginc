
#include "Packages/garden.ephemeral.shader.commons/ELDistanceFunctions.cginc"
#include "Packages/garden.ephemeral.shader.commons/ELGeometry.cginc"
#include "Packages/garden.ephemeral.shader.commons/ELMathUtilities.cginc"
#include "Packages/garden.ephemeral.shader.commons/ELRaymarchBase.cginc"
#include "UnityCG.cginc"
// #include "Hilbert2D.cginc"
#include "Hilbert3D.cginc"

// Commenting out uniforms already defined for us in headers. Leaving here for documentation.
//uniform float4 _Color;
//uniform float _Metallic;
//uniform float _Glossiness;

// implementing method declared in `ELRaymarchCommon.cginc`
void ELBoundingBox(out float3 boxMin, out float3 boxMax)
{
    boxMin = float3(-0.5, -0.5, -0.5);
    boxMax = float3( 0.5,  0.5,  0.5);
}

// implementing method declared in `ELRaymarchCommon.cginc`
float2 ELMap(float3 objectPos)
{
    // float d = sdHilbert2D(objectPos);
    float d = sdHilbert3D(objectPos);
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
