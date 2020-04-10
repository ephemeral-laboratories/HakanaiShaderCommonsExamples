#pragma once

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"              // must be after `UnityPBSLighting` because Unity forgot to include it.
#include "UnityLightingCommon.cginc"
#include "UnityStandardCore.cginc"
#include "ELUnityUtilities.cginc"

/**
 * Wraps `UNITY_TRANSFER_SHADOW` and `UNITY_LIGHT_ATTENUATION` for abusing to use in fragment shader.
 *
 * @param objectPos the position of the vertex in object space.
 * @param worldPos the position of the vertex in world space.
 * @param clipPos the position of the vertex in clip space.
 * @return the light attenuation factor. (0.0 ~ 1.0)
 */
float ELCalculateLightAttenuation(float3 objectPos, float3 worldPos, float4 clipPos)
{
    // Has to be called `v` because `UNITY_TRANSFER_SHADOW` sucks
    struct
    {
        float3 vertex;
    } v;
    v.vertex = objectPos;

    struct
    {
        float4 pos;
        UNITY_SHADOW_COORDS(0)
    } o;
    o.pos = clipPos;
    UNITY_TRANSFER_SHADOW(o, float2(0.0, 0.0));

    UNITY_LIGHT_ATTENUATION(attenuation, o, worldPos);
    return attenuation;
}

/**
 * Wraps `UNITY_TRANSFER_FOG` and `UNITY_APPLY_FOG` for abusing to use in fragment shader.
 *
 * @param objectPos the position of the vertex in object space.
 * @param clipPos the position of the vertex in clip space.
 * @param color the base colour, fog not yet applied.
 * @return the new colour, with fog applied.
 */
float4 ELCalculateFog(float3 objectPos, float4 clipPos, float4 color)
{
    struct
    {
        float4 pos;
        UNITY_FOG_COORDS(0)
    } o;
    o.pos = clipPos;
    UNITY_TRANSFER_FOG(o, o.pos);

    UNITY_APPLY_FOG(o.fogCoord, color);
    return color;
}

/**
 * Initialises and returns a surface output structure.
 *
 * @param objectNormal the object normal.
 * @return the surface output structure.
 */
SurfaceOutputStandard ELInitSurfaceOutput(float3 objectNormal)
{
    SurfaceOutputStandard surfaceOutput;
    UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, surfaceOutput);
    surfaceOutput.Normal = UnityObjectToWorldNormal(objectNormal);
    surfaceOutput.Occlusion = 1.0;
    return surfaceOutput;
}

/**
 * Takes a surface output structure and computes the colour for the fragment in the same
 * way a surface shader would do it.
 *
 * I actually just wanted to write a surface shader, but it turns out you can't write to depth
 * from a surface shader. So here we're using as much as possible of the actual surface
 * shader / standard lighting code.
 *
 * @param surfaceOutput the surface output structure.
 * @param objectPos the position of the vertex in object space.
 * @param objectNormal the normal of the surface at the vertex in object space.
 * @return the colour for the fragment.
 */
float4 ELSurfaceFragment(SurfaceOutputStandard surfaceOutput, float3 objectPos, float3 objectNormal)
{
    float3 worldPos = ELObjectToWorldPos(objectPos);
    float3 worldNormal = UnityObjectToWorldNormal(objectNormal);
    float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
    float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

    float4 clipPos = UnityObjectToClipPos(float4(objectPos, 1.0));

    float attenuation = ELCalculateLightAttenuation(objectPos, worldPos, clipPos);

    UnityGI gi;
    UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
    gi.indirect.diffuse = 1.0;
    gi.indirect.specular = 1.0;
    gi.light.color = _LightColor0.rgb * attenuation;
    gi.light.dir = worldLightDir;

#ifdef UNITY_PASS_FORWARDBASE

    UnityGIInput giInput;
    UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
    giInput.light = gi.light;
    giInput.worldPos = worldPos;
    giInput.worldViewDir = worldViewDir;
    giInput.atten = attenuation;
    giInput.lightmapUV = 0.0;
    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
        half3 sh = 0;
        #ifdef VERTEXLIGHT_ON
            sh += Shade4PointLights(
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, worldPos, worldNormal);
        #endif
        sh = ShadeSHPerVertex(worldNormal, sh);
        giInput.ambient = sh;
    #else
        giInput.ambient.rgb = 0.0;
    #endif
    giInput.probeHDR[0] = unity_SpecCube0_HDR;
    giInput.probeHDR[1] = unity_SpecCube1_HDR;
    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
        giInput.boxMin[0] = unity_SpecCube0_BoxMin;
    #endif
    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
        giInput.boxMax[0] = unity_SpecCube0_BoxMax;
        giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
        giInput.boxMax[1] = unity_SpecCube1_BoxMax;
        giInput.boxMin[1] = unity_SpecCube1_BoxMin;
        giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
    #endif
    LightingStandard_GI(surfaceOutput, giInput, gi);

#endif

    float4 color = LightingStandard(surfaceOutput, worldViewDir, gi);
    color.rgb += surfaceOutput.Emission;
    color.a = 0.0;
    color = ELCalculateFog(objectPos, clipPos, color);

    UNITY_OPAQUE_ALPHA(color.a);

    return color;
}
