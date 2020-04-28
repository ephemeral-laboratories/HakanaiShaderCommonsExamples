Shader "Ephemeral Laboratories/Gratitude"
{
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
            "DisableBatching" = "True"
        }

        LOD 200
        ZWrite Off

        Pass
        {
            // Interior viewed from outside
            Name "FORWARD_FOR_INTERIOR_1"
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha

            Stencil
            {
                Ref 9
                Comp always
                Pass replace
            }

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment FragmentForInterior
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma target 4.0
            #include "Gratitude.cginc"
            ENDCG
        }

        Pass
        {
            // Interior viewed from inside
            Name "FORWARD_FOR_INTERIOR_2"
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            Cull Front
            Blend SrcAlpha OneMinusSrcAlpha

            Stencil
            {
                Ref 9
                Comp notequal
            }

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment FragmentForInterior
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma target 4.0
            #include "Gratitude.cginc"
            ENDCG
        }
    }

    Fallback "None"
}
