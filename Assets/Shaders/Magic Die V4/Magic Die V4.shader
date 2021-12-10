Shader "Ephemeral Laboratories/Magic Die V4"
{
    Properties
    {
        _MainTex ("Albedo Map", 2D) = "white" {}
        [HDR]
        _Color ("Albedo Tint", Color) = (1.0, 1.0, 1.0, 1.0)

        [Space(20)]
        _NormalMap ("Normal Map", 2D) = "bump" {}

        [Space(20)]
        _MetallicTex ("Metallic/Smoothness Map", 2D) = "white" {}
        _Metallic ("Metallic", Range(0, 1)) = 0.0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5

        [Space(20)]
        _EmissionMap ("Emission Map", 2D) = "white" {}
        [HDR]
        _EmissionColor ("Emission Color", Color) = (0.2, 0.0, 0.2, 1.0)

        [Space(20)]
        _BallAlbedo ("Ball Albedo", Color) = (1.0, 0.0, 1.0, 1.0)
        [HDR]
        _BallEmission ("Ball Emission", Color) = (0.2, 0.0, 0.2, 1.0)
        _BallMetallic ("Ball Metallic", Range(0, 1)) = 0.0
        _BallSmoothness ("Ball Smoothness", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "Queue" = "AlphaTest"
            "RenderType" = "TransparentCutout"
            "IgnoreProjector" = "True"
            "DisableBatching" = "True"
        }

        LOD 200
        Cull Back

        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma target 4.0
            #include "Magic Die V4.cginc"
            ENDCG
        }

        Pass
        {
            Name "FORWARDADD"
            Tags
            {
                "LightMode" = "ForwardAdd"
            }

            Blend SrcAlpha One
            ZWrite Off

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma target 4.0
            #include "Magic Die V4.cginc"
            ENDCG
        }

        Pass
        {
            Name "SHADOWCASTER"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment ShadowCasterFragment
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma multi_compile_shadowcaster
            #pragma target 4.0
            #include "Magic Die V4.cginc"
            ENDCG
        }
    }

    Fallback "None"
}
