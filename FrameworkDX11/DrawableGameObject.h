#pragma once

#include <d3d11_1.h>
#include <d3dcompiler.h>
#include <directxcolors.h>
#include <DirectXCollision.h>
#include "DDSTextureLoader.h"
#include "resource.h"
#include <iostream>
#include "structures.h"


using namespace DirectX;

struct SimpleVertex
{
	XMFLOAT3 Pos;
	XMFLOAT3 Normal;
	XMFLOAT2 TexCoord;
	XMFLOAT3 tangent;
	XMFLOAT3 biTangent;
};
class DrawableGameObject
{
public:
	DrawableGameObject();
	~DrawableGameObject();

	void cleanup();

	HRESULT								initMesh(ID3D11Device* pd3dDevice, ID3D11DeviceContext* pContext);
	void								update(float t);
	void								draw(ID3D11DeviceContext* pContext);
	ID3D11Buffer*						getVertexBuffer() { return m_pVertexBuffer; }
	ID3D11Buffer*						getIndexBuffer() { return m_pIndexBuffer; }
	ID3D11ShaderResourceView**			getTextureResourceView() { return &m_pTextureResourceView; 	}
	void SetTextureResourceView(ID3D11ShaderResourceView* textureRV) { m_pTextureResourceView = textureRV; };
	XMFLOAT4X4*							getTransform() { return &m_World; }
	ID3D11SamplerState**				getTextureSamplerState() { return &m_pSamplerLinear; }
	void SetMaterialConstantBuffer(ID3D11DeviceContext* pContext) { pContext->UpdateSubresource(m_pMaterialConstantBuffer, 0, nullptr, &m_material, 0, 0); };
	ID3D11Buffer*						getMaterialConstantBuffer() { return m_pMaterialConstantBuffer;}
	void								setPosition(XMFLOAT3 position);

	void CalculateTangentBinormalLH(SimpleVertex v0, SimpleVertex v1, SimpleVertex v2, XMFLOAT3& normal, XMFLOAT3& tangent, XMFLOAT3& binormal);
	void CalculateModelVectors(SimpleVertex* vertices, int vertexCount);

	MaterialPropertiesConstantBuffer	m_material;
private:
	
	XMFLOAT4X4							m_World;

	ID3D11Buffer*						m_pVertexBuffer;
	ID3D11Buffer*						m_pIndexBuffer;
	ID3D11ShaderResourceView*			m_pTextureResourceView;
	ID3D11ShaderResourceView*			m_pNormalTextureResourceView;
	ID3D11ShaderResourceView*			m_pDisplacementTextureResourceView;
	ID3D11SamplerState *				m_pSamplerLinear;
	ID3D11Buffer*						m_pMaterialConstantBuffer = nullptr;
	XMFLOAT3							m_position;
};

