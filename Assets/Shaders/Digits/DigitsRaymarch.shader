Shader "Ephemeral Laboratories/Raymarch/Digits"
{
    Properties
    {
        _Colour1 ("Albedo 1", Color) = (1.0, 1.0, 1.0, 1.0)
        _Metallic1 ("Metallic 1", Range(0.0, 1.0)) = 0.0
        _Glossiness1 ("Glossiness 1", Range(0.0, 1.0)) = 0.0
        _HeightScale ("Height Scale", Range(0.5, 2.0)) = 1.0
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
        Cull Front

        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex ELRaycastBaseVertex
            #pragma geometry ELGeometryCube
            #pragma fragment ELRaycastFragment
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma target 4.0
            #include "DigitsRaymarch.cginc"
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
            #pragma vertex ELRaycastBaseVertex
            #pragma geometry ELGeometryCube
            #pragma fragment ELRaycastFragment
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma target 4.0
            #include "DigitsRaymarch.cginc"
            ENDCG
        }

        Pass
        {
            Name "META"
            Tags
            {
                "LightMode" = "Meta"
            }
            ZWrite On
            ZTest LEqual

            CGPROGRAM
            #pragma vertex ELRaycastBaseVertex
            #pragma geometry ELGeometryCube
            #pragma fragment ELRaycastFragment
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma multi_compile_shadowcaster
            #pragma target 4.0
            #include "DigitsRaymarch.cginc"
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
            #pragma vertex ELRaycastBaseVertex
            #pragma geometry ELGeometryCube
            #pragma fragment ELRaycastShadowCasterFragment
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma multi_compile_shadowcaster
            #pragma target 4.0
            #include "DigitsRaymarch.cginc"
            ENDCG
        }
    }

    Fallback "None"
}
