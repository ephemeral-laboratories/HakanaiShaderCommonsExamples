Shader "Ephemeral Laboratories/Surface"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }

        LOD 200

        CGPROGRAM
        #pragma surface Surface Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void Surface(Input input, inout SurfaceOutputStandard output)
        {
            fixed4 color = tex2D(_MainTex, input.uv_MainTex) * _Color;
            output.Albedo = color.rgb;
            output.Metallic = _Metallic;
            output.Smoothness = _Glossiness;
            output.Alpha = color.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
