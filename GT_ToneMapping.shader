Shader "Hidden/PostProcess/GTToneMapping"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 100
        ZWrite Off
        Cull Off

        Pass
        {
            Name "GTToneMappingPass"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            SAMPLER(sampler_BlitTexture);

            // --- Gran Turismo Tonemapping Math ---
            float W_f(float x, float e0, float e1)
            {
                float a = saturate((x - e0) / (e1 - e0));
                return a * a * (3.0 - 2.0 * a);
            }

            float H_f(float x, float e0, float e1)
            {
                return saturate((x - e0) / (e1 - e0));
            }

            float GranTurismoTonemapper(float x)
            {
                const float P = 1.0, a = 1.0, m = 0.22, l = 0.4, c = 1.33, b = 0.0;
                float l0 = ((P - m) * l) / a;
                float S0 = m + l0;
                float S1 = m + a * l0;
                float C2 = (a * P) / (P - S1);
                float w0_x = 1.0 - W_f(x, 0.0, m);
                float w2_x = H_f(x, S0, S1);
                float w1_x = 1.0 - w0_x - w2_x;
                float T_x = m * pow(abs(x / m), c) + b;
                float L_x = m + a * (x - m);
                float S_x = P - (P - S1) * exp(-(C2 * (x - S0)) / P);
                return T_x * w0_x + L_x * w1_x + S_x * w2_x;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // Now that sampler_BlitTexture is declared, this line will compile correctly.
                half4 col = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_BlitTexture, input.texcoord);

                col.r = GranTurismoTonemapper(col.r);
                col.g = GranTurismoTonemapper(col.g);
                col.b = GranTurismoTonemapper(col.b);

                return col;
            }
            ENDHLSL
        }
    }
}
