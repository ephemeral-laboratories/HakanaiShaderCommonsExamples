Shader "Ephemeral Laboratories/Fluttering Heart"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        _Color ("Albedo", Color) = (1.0, 1.0, 1.0, 1.0)
        _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
        _Glossiness ("Glossiness", Range(0.0, 1.0)) = 0.0
        _Bounds ("Bounds", Range(0.045454545, 0.5)) = 0.045454545
        _SpinSpeed ("Spin Speed", Range(0.0, 50.0)) = 0.0
        _ThrobSpeed ("Throb Speed", Range(0.0, 50.0)) = 0.0
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
            Name "FORWARD_BACK"
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front
            
            Stencil
            {
                Ref 50
                Comp always
                Pass replace
                ZFail replace
            }

            CGPROGRAM
            #pragma vertex ELRaycastBaseVertex
            #pragma fragment ELRaycastFragment
            #pragma multi_compile _ VERTEXLIGHT_ON
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma target 4.0
            #include "Fluttering Heart.cginc"
            ENDCG
        }

        Pass
        {
            Name "FORWARD_FRONT"
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            Blend SrcAlpha OneMinusSrcAlpha

            Stencil
            {
                Ref 50
                Comp Equal
                Pass Zero
            }

            CGPROGRAM
            #pragma vertex ELRaycastBaseVertex
            #pragma fragment ELRaycastFragment
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma target 4.0
            #include "Fluttering Heart.cginc"
            ENDCG
        }

        Pass
        {
            Name "FORWARDADD_BACK"
            Tags
            {
                "LightMode" = "ForwardAdd"
            }

            Blend SrcAlpha One
            ZWrite Off
            Cull Front

            Stencil
            {
                Ref 50
                Comp Always
                Pass Replace
                ZFail replace
            }

            CGPROGRAM
            #pragma vertex ELRaycastBaseVertex
            #pragma fragment ELRaycastFragment
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma target 4.0
            #include "Fluttering Heart.cginc"
            ENDCG
        }

        Pass
        {
            Name "FORWARDADD_FRONT"
            Tags
            {
                "LightMode" = "ForwardAdd"
            }

            Blend SrcAlpha One
            ZWrite Off

            Stencil
            {
                Ref 50
                Comp equal
                Pass zero
            }

            CGPROGRAM
            #pragma vertex ELRaycastBaseVertex
            #pragma fragment ELRaycastFragment
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma target 4.0
            #include "Fluttering Heart.cginc"
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
            #pragma fragment ELRaycastShadowCasterFragment
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma multi_compile_shadowcaster
            #pragma target 4.0
            #include "Fluttering Heart.cginc"
            ENDCG
        }
    }

    Fallback "None"
}
