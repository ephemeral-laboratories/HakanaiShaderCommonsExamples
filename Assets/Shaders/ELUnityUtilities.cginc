#pragma once

#include "UnityCG.cginc"
#include "ELMathUtilities.cginc"

/**
 * Transforms a position in world space to object space.
 *
 * @param worldPos the position in world space.
 * @return its position in object space.
 */
float3 ELWorldToObjectPos(float3 worldPos)
{
    return mul(unity_WorldToObject, float4(worldPos, 1.0)).xyz;
}

/**
 * Transforms a direction in world space to object space.
 *
 * @param worldDir the direction in world space.
 * @return its position in object space.
 */
float3 ELWorldToObjectNormal(float3 worldDir)
{
    return mul(unity_WorldToObject, float4(worldDir, 0.0)).xyz;
}

/**
 * Transforms a position in object space to world space.
 *
 * @param objectPos the position in object space.
 * @return its position in world space.
 */
float3 ELObjectToWorldPos(float3 objectPos)
{
    return mul(unity_ObjectToWorld, float4(objectPos, 1.0)).xyz;
}

/**
 * Transforms a position in clip space to object space.
 *
 * @param clipPos the position in clip space.
 * @return its position in object space.
 */
float3 ELClipToObjectPos(float4 clipPos)
{
    return mul(unity_WorldToObject, mul(ELMatrixInverse(UNITY_MATRIX_VP), clipPos)).xyz;
}
