#pragma once

/**
 * Converts polar coordinates to cartesian coordinates.
 *
 * @param r the radius.
 * @param theta the angle.
 * @return the X-Y coordinates.
 */
float2 ELPolarToCartesian(float r, float theta)
{
    float2 sin_cos;
    sincos(theta, sin_cos[1], sin_cos[0]);
    return sin_cos * r;
}

/**
 * Calculates the inverse of a matrix.
 * Probably causes the universe to implode if the input matrix has no inverse.
 * If this eats literally all your cats I am not responsible.
 *
 * @param input the input matrix.
 * @return its inverse.
 */
float4x4 ELMatrixInverse(float4x4 input)
{
    #define minor(a, b, c) determinant(float3x3(input.a, input.b, input.c))

    float4x4 cofactors = float4x4(
        minor(_22_23_24, _32_33_34, _42_43_44),
       -minor(_21_23_24, _31_33_34, _41_43_44),
        minor(_21_22_24, _31_32_34, _41_42_44),
       -minor(_21_22_23, _31_32_33, _41_42_43),

       -minor(_12_13_14, _32_33_34, _42_43_44),
        minor(_11_13_14, _31_33_34, _41_43_44),
       -minor(_11_12_14, _31_32_34, _41_42_44),
        minor(_11_12_13, _31_32_33, _41_42_43),

        minor(_12_13_14, _22_23_24, _42_43_44),
       -minor(_11_13_14, _21_23_24, _41_43_44),
        minor(_11_12_14, _21_22_24, _41_42_44),
       -minor(_11_12_13, _21_22_23, _41_42_43),

       -minor(_12_13_14, _22_23_24, _32_33_34),
        minor(_11_13_14, _21_23_24, _31_33_34),
       -minor(_11_12_14, _21_22_24, _31_32_34),
        minor(_11_12_13, _21_22_23, _31_32_33));

   #undef minor
   return transpose(cofactors) / determinant(input);
}
