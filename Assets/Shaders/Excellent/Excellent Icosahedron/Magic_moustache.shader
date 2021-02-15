Shader "Ephemeral Laboratories/Magic moustache"
{
    Properties
    {
        _Colour ("_Colour", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Pivot ("Pivot", Vector) = (0.0,0.0,0.0,0.0)
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "TransparentCutout"
            "Queue" = "AlphaTest"
        }
        LOD 200
        
        CGPROGRAM
        #pragma surface Surface Standard vertex:vert addshadow fullforwardshadows
        #pragma target 4.0
        #include "../../Common/ELMathUtilities.cginc"
        sampler2D _MainTex;
        float4 _Pivot;

        struct Input
        {
            float2 uv_MainTex;
        };
        void vert(inout appdata_full v, out Input o) 
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            float rotation = _Time[1] * 25.0;
            v.vertex.xyz -= _Pivot.xyz;
            v.vertex.xyz = ELRotateAroundYInDegrees(v.vertex.xyz, -rotation);
            v.vertex.xyz += _Pivot.xyz;

            v.normal.xyz = ELRotateAroundYInDegrees(v.normal.xyz, -rotation);
        }

        half _Glossiness;
        half _Metallic;
        fixed4 _Colour;

		bool IsInMirror()
		{
		    return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
		}

        void Surface(Input IN, inout SurfaceOutputStandard output)
        {
        	if (!IsInMirror())
        	{
        		discard;
        	}
            float rotation = _Time[1] * 25.0;
            fixed4 colour = tex2D(_MainTex, IN.uv_MainTex) * _Colour;
            output.Albedo = colour.rgb;
            output.Metallic = _Metallic;
            output.Smoothness = _Glossiness;
            output.Alpha = colour.a;
        }
        ENDCG
    }
    FallBack "None"
}
