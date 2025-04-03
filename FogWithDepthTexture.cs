using UnityEngine;
using System.Collections;

// 基于深度纹理的雾效后处理脚本
public class FogWithDepthTexture : PostEffectsBase
{

    public Shader fogShader;           // 雾效着色器
    private Material fogMaterial = null; // 生成的雾效材质

    // 材质属性检查器：确保材质与着色器匹配
    public Material material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
        }
    }

    private Camera myCamera;           // 当前摄像机组件缓存
    public Camera camera
    {
        get
        {
            if (myCamera == null)
            {
                myCamera = GetComponent<Camera>(); // 获取挂载的摄像机
            }
            return myCamera;
        }
    }

    private Transform myCameraTransform; // 摄像机变换组件缓存
    public Transform cameraTransform
    {
        get
        {
            if (myCameraTransform == null)
            {
                myCameraTransform = camera.transform; // 获取摄像机的变换组件
            }
            return myCameraTransform;
        }
    }

    [Range(0.0f, 3.0f)]
    public float fogDensity = 1.0f;     // 雾浓度系数（0-3可调）

    public Color fogColor = Color.white; // 雾颜色（默认白色）
    public float fogStart = 0.0f;       // 雾效起始距离
    public float fogEnd = 2.0f;         // 雾效结束距离

    // 启用时设置摄像机生成深度纹理
    void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    // 后处理渲染核心方法
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            // 构造视锥体四角方向向量矩阵
            Matrix4x4 frustumCorners = Matrix4x4.identity;

            // 获取摄像机参数
            float fov = camera.fieldOfView;
            float near = camera.nearClipPlane;
            float aspect = camera.aspect;

            // 计算近裁剪面半高
            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
            Vector3 toRight = cameraTransform.right * halfHeight * aspect; // 计算右方向偏移
            Vector3 toTop = cameraTransform.up * halfHeight;               // 计算上方向偏移

            // 计算四个角点方向向量并标准化
            Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;  // 计算缩放系数
            topLeft.Normalize();
            topLeft *= scale;  // 标准化并缩放

            Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;

            Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;

            // 构建视锥角射线矩阵（每行存储一个角点方向）
            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            // 传递参数到着色器
            material.SetMatrix("_FrustumCornersRay", frustumCorners); // 视锥角射线
            material.SetFloat("_FogDensity", fogDensity);             // 雾浓度
            material.SetColor("_FogColor", fogColor);                // 雾颜色
            material.SetFloat("_FogStart", fogStart);                 // 雾起始距离
            material.SetFloat("_FogEnd", fogEnd);                     // 雾结束距离

            // 执行后处理渲染
            Graphics.Blit(src, dest, material);
        }
        else
        {
            // 无材质时直接复制源纹理
            Graphics.Blit(src, dest);
        }
    }
}