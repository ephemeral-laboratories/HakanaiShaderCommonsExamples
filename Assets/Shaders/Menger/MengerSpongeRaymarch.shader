Shader "Ephemeral Laboratories/Raymarch/Menger Sponge"
{
    Properties
    {
        _Colour ("Colour", Color) = (1, 1, 1, 1)
        _TintColour ("Tint Colour", Color) = (0, 1, 0.8, 1)
        _TintMultiplier ("Tint Multiplier", Float) = 1.0
        _HueRotationRate ("Hue Rotation Rate", Float) = 0.0
        _Metallic ("Metallic", Range(0, 1)) = 0.0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5

        [Toggle]
        _Animate ("Animate", Float) = 0.0
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
            #define UNITY_PASS_FORWARDBASE
            #include "MengerSpongeRaymarch.cginc"
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
            #define UNITY_PASS_FORWARDADD
            #include "MengerSpongeRaymarch.cginc"
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
            #include "MengerSpongeRaymarch.cginc"
            ENDCG
        }

        Pass
        {
            Name "SHADOWCASTER"
            Tags
            {
                "LightMode" = "ShadowCaster"

                "Queue" = "Transparent"
                // "RenderType" = "Opaque"
            }
            // ZWrite On
            // ZTest LEqual

            CGPROGRAM
            #pragma vertex ELRaycastBaseVertex
            #pragma geometry ELGeometryCube
            #pragma fragment ELRaycastShadowCasterFragment
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma multi_compile_shadowcaster
            #pragma target 4.0
            #define UNITY_PASS_SHADOWCASTER
            #include "MengerSpongeRaymarch.cginc"
            ENDCG
        }
    }

    Fallback Off
}
