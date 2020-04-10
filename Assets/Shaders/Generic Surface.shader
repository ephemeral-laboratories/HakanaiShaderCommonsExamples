Shader "Ephemeral Laboratories/Generic Surface"
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

        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "ELScuttledUnityLighting.cginc"

            struct Varyings
            {
                float4 vertex           : SV_POSITION;
                float3 objectNormal     : NORMAL;
                float4 color            : COLOR;
                float2 uv               : TEXCOORD0;
                float4 objectPos        : TEXCOORD1;
                UNITY_FOG_COORDS(2)
            };

            Varyings Vertex(appdata_full input)
            {
                Varyings output;
                output.vertex = UnityObjectToClipPos(input.vertex);
                output.objectNormal = input.normal;
                output.color = input.color;
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                output.objectPos = input.vertex;
                UNITY_TRANSFER_FOG(output, output.vertex);
                return output;
            }

            fixed4 Fragment(Varyings input) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, input.uv) * _Color;

                SurfaceOutputStandard output = ELInitSurfaceOutput(input.objectNormal);
                output.Albedo = col.rgb;
                output.Alpha = col.a;
                output.Metallic = _Metallic;
                output.Smoothness = _Glossiness;
                return ELSurfaceFragment(output, input.objectPos, input.objectNormal);
            }
            ENDCG
        }
    }
}
