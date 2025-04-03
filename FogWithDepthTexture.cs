using UnityEngine;
using System.Collections;

// ��������������Ч����ű�
public class FogWithDepthTexture : PostEffectsBase
{

    public Shader fogShader;           // ��Ч��ɫ��
    private Material fogMaterial = null; // ���ɵ���Ч����

    // �������Լ������ȷ����������ɫ��ƥ��
    public Material material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
        }
    }

    private Camera myCamera;           // ��ǰ������������
    public Camera camera
    {
        get
        {
            if (myCamera == null)
            {
                myCamera = GetComponent<Camera>(); // ��ȡ���ص������
            }
            return myCamera;
        }
    }

    private Transform myCameraTransform; // ������任�������
    public Transform cameraTransform
    {
        get
        {
            if (myCameraTransform == null)
            {
                myCameraTransform = camera.transform; // ��ȡ������ı任���
            }
            return myCameraTransform;
        }
    }

    [Range(0.0f, 3.0f)]
    public float fogDensity = 1.0f;     // ��Ũ��ϵ����0-3�ɵ���

    public Color fogColor = Color.white; // ����ɫ��Ĭ�ϰ�ɫ��
    public float fogStart = 0.0f;       // ��Ч��ʼ����
    public float fogEnd = 2.0f;         // ��Ч��������

    // ����ʱ��������������������
    void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    // ������Ⱦ���ķ���
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            // ������׶���ĽǷ�����������
            Matrix4x4 frustumCorners = Matrix4x4.identity;

            // ��ȡ���������
            float fov = camera.fieldOfView;
            float near = camera.nearClipPlane;
            float aspect = camera.aspect;

            // ������ü�����
            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
            Vector3 toRight = cameraTransform.right * halfHeight * aspect; // �����ҷ���ƫ��
            Vector3 toTop = cameraTransform.up * halfHeight;               // �����Ϸ���ƫ��

            // �����ĸ��ǵ㷽����������׼��
            Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;  // ��������ϵ��
            topLeft.Normalize();
            topLeft *= scale;  // ��׼��������

            Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;

            Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;

            // ������׶�����߾���ÿ�д洢һ���ǵ㷽��
            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            // ���ݲ�������ɫ��
            material.SetMatrix("_FrustumCornersRay", frustumCorners); // ��׶������
            material.SetFloat("_FogDensity", fogDensity);             // ��Ũ��
            material.SetColor("_FogColor", fogColor);                // ����ɫ
            material.SetFloat("_FogStart", fogStart);                 // ����ʼ����
            material.SetFloat("_FogEnd", fogEnd);                     // ���������

            // ִ�к�����Ⱦ
            Graphics.Blit(src, dest, material);
        }
        else
        {
            // �޲���ʱֱ�Ӹ���Դ����
            Graphics.Blit(src, dest);
        }
    }
}