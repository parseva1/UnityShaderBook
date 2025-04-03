Shader "Unity Shaders Book/Chapter 13/Fog With Depth Texture" {
    Properties {
        _MainTex ("�������� (RGB)", 2D) = "white" {}         // ����ԭʼ��Ⱦ����
        _FogDensity ("��Ũ��", Float) = 1.0                 // ��ЧŨ��ϵ��
        _FogColor ("����ɫ", Color) = (1, 1, 1, 1)         // ��Ч��ɫ
        _FogStart ("����ʼ�߶�", Float) = 0.0              // ��Ч��ʼ�߶�
        _FogEnd ("������߶�", Float) = 1.0                // ��Ч�����߶�
    }
    SubShader {
        CGINCLUDE
        
        #include "UnityCG.cginc"  // ����Unity CG��
        
        // ����C#�ű����ݵ���׶�����߾���ÿ�д洢һ���ǵ㷽��
        float4x4 _FrustumCornersRay;
        
        // ��������
        sampler2D _MainTex;       // ����������ԭʼ���棩
        half4 _MainTex_TexelSize; // ����������سߴ���Ϣ
        sampler2D _CameraDepthTexture; // ������������
        
        // ��Ч����
        half _FogDensity;          // ��Ũ��ϵ��
        fixed4 _FogColor;          // ����ɫ
        float _FogStart;           // ����ʼ�߶�
        float _FogEnd;             // ������߶�
        
        // ������ɫ������ṹ
        struct v2f {
            float4 pos : SV_POSITION;    // �ü��ռ�λ��
            half2 uv : TEXCOORD0;       // ԭʼUV����
            half2 uv_depth : TEXCOORD1; // ������Ȳ�����UV����
            float4 interpolatedRay : TEXCOORD2; // ��ֵ�����������
        };
        
        // ������ɫ��
        v2f vert(appdata_img v) {
            v2f o;
            o.pos = mul(UNITY_MATRIX_MVP, v.vertex); // ת�����ü��ռ�
            
            o.uv = v.texcoord;          // ����ԭʼUV
            o.uv_depth = v.texcoord;   // ��ʼ�����UV
            
            // ����ƽ̨���죺DirectX��OpenGL��UV�������
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y; // ��תY������
            #endif
            
            // ����UV����ȷ����׶������������Ļ��Ϊ�ĸ����ޣ�
            int index = 0;
            if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
                index = 0; // ����
            } else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
                index = 1; // ����
            } else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
                index = 2; // ����
            } else {
                index = 3; // ����
            }

            // �ٴδ���ƽ̨���쵼�µ�������ת
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                index = 3 - index; // ��ת����˳��
            #endif
            
            // ��ȡ��Ӧ�ǵ���������߷���
            o.interpolatedRay = _FrustumCornersRay[index];
                     
            return o;
        }
        
        // Ƭ����ɫ��
        fixed4 frag(v2f i) : SV_Target {
            // ����������ȡ�������ֵ��Eye Space��
            float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
            
            // �����������꣺�����λ�� + ���ֵ * ���߷���
            float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
                        
            // ������ڸ߶ȵ���Ũ�ȣ�����ʼ�ͽ����߶�֮���ֵ��
            float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
            // Ӧ��Ũ��ϵ����������[0,1]��Χ
            fogDensity = saturate(fogDensity * _FogDensity);
            
            // ����ԭʼ��ɫ
            fixed4 finalColor = tex2D(_MainTex, i.uv);
            // ������Ũ�Ȼ����ɫ
            finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
            
            return finalColor;
        }
        
        ENDCG
        
        Pass {
            // ��Ⱦ���ã�������Ȳ���/д�룬ʼ����Ⱦ
            ZTest Always Cull Off ZWrite Off
                    
            CGPROGRAM  
            
            #pragma vertex vert   // ָ��������ɫ��
            #pragma fragment frag // ָ��Ƭ����ɫ��
              
            ENDCG  
        }
    } 
    FallBack Off  // �ޱ�ѡShader
}