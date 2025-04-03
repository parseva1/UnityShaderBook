Shader "Unity Shaders Book/Chapter 13/Fog With Depth Texture" {
    Properties {
        _MainTex ("基础纹理 (RGB)", 2D) = "white" {}         // 场景原始渲染纹理
        _FogDensity ("雾浓度", Float) = 1.0                 // 雾效浓度系数
        _FogColor ("雾颜色", Color) = (1, 1, 1, 1)         // 雾效颜色
        _FogStart ("雾起始高度", Float) = 0.0              // 雾效起始高度
        _FogEnd ("雾结束高度", Float) = 1.0                // 雾效结束高度
    }
    SubShader {
        CGINCLUDE
        
        #include "UnityCG.cginc"  // 包含Unity CG库
        
        // 来自C#脚本传递的视锥角射线矩阵（每行存储一个角点方向）
        float4x4 _FrustumCornersRay;
        
        // 纹理属性
        sampler2D _MainTex;       // 主纹理（场景原始画面）
        half4 _MainTex_TexelSize; // 主纹理的像素尺寸信息
        sampler2D _CameraDepthTexture; // 摄像机深度纹理
        
        // 雾效参数
        half _FogDensity;          // 雾浓度系数
        fixed4 _FogColor;          // 雾颜色
        float _FogStart;           // 雾起始高度
        float _FogEnd;             // 雾结束高度
        
        // 顶点着色器输出结构
        struct v2f {
            float4 pos : SV_POSITION;    // 裁剪空间位置
            half2 uv : TEXCOORD0;       // 原始UV坐标
            half2 uv_depth : TEXCOORD1; // 用于深度采样的UV坐标
            float4 interpolatedRay : TEXCOORD2; // 插值后的视线射线
        };
        
        // 顶点着色器
        v2f vert(appdata_img v) {
            v2f o;
            o.pos = mul(UNITY_MATRIX_MVP, v.vertex); // 转换到裁剪空间
            
            o.uv = v.texcoord;          // 传递原始UV
            o.uv_depth = v.texcoord;   // 初始化深度UV
            
            // 处理平台差异：DirectX与OpenGL的UV方向差异
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y; // 翻转Y轴坐标
            #endif
            
            // 根据UV区域确定视锥角索引（将屏幕分为四个象限）
            int index = 0;
            if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
                index = 0; // 左下
            } else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
                index = 1; // 右下
            } else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
                index = 2; // 右上
            } else {
                index = 3; // 左上
            }

            // 再次处理平台差异导致的索引反转
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                index = 3 - index; // 反转索引顺序
            #endif
            
            // 获取对应角点的视线射线方向
            o.interpolatedRay = _FrustumCornersRay[index];
                     
            return o;
        }
        
        // 片段着色器
        fixed4 frag(v2f i) : SV_Target {
            // 从深度纹理获取线性深度值（Eye Space）
            float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
            
            // 计算世界坐标：摄像机位置 + 深度值 * 视线方向
            float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
                        
            // 计算基于高度的雾浓度（在起始和结束高度之间插值）
            float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
            // 应用浓度系数并限制在[0,1]范围
            fogDensity = saturate(fogDensity * _FogDensity);
            
            // 采样原始颜色
            fixed4 finalColor = tex2D(_MainTex, i.uv);
            // 根据雾浓度混合颜色
            finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
            
            return finalColor;
        }
        
        ENDCG
        
        Pass {
            // 渲染设置：禁用深度测试/写入，始终渲染
            ZTest Always Cull Off ZWrite Off
                    
            CGPROGRAM  
            
            #pragma vertex vert   // 指定顶点着色器
            #pragma fragment frag // 指定片段着色器
              
            ENDCG  
        }
    } 
    FallBack Off  // 无备选Shader
}