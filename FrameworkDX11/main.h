#pragma once

#include <windows.h>
#include <windowsx.h>
#include <d3d11_1.h>
#include <d3dcompiler.h>
#include <directxmath.h>
#include <directxcolors.h>
#include <DirectXCollision.h>
#include "DDSTextureLoader.h"
#include "resource.h"
#include <iostream>
#include <string>

#include "DrawableGameObject.h"
#include "structures.h"
#include "Camera.h"
#include "ImGui/imgui.h"
#include "ImGui/imgui_impl_win32.h"
#include "ImGui/imgui_impl_dx11.h"

#include <vector>

using namespace std;

typedef vector<DrawableGameObject*> vecDrawables;



//--------------------------------------------------------------------------------------
// Forward declarations
//--------------------------------------------------------------------------------------

class Application 
{
public:HRESULT		InitWindow(HINSTANCE hInstance, int nCmdShow);
	  HRESULT		InitDevice();
	  HRESULT		InitMesh();
	  HRESULT		InitWorld(int width, int height);
	  void		CleanupDevice();
	  void setupLightForRender();
	  void Update();
	  void		Render();

	  vector<DrawableGameObject*> drawablesVector;

private:
	//XMFLOAT4 g_EyePosition;

	HINSTANCE               g_hInst = nullptr;
	HWND                    g_hWnd = nullptr;
	D3D_DRIVER_TYPE         g_driverType = D3D_DRIVER_TYPE_NULL;
	D3D_FEATURE_LEVEL       g_featureLevel = D3D_FEATURE_LEVEL_11_0;
	ID3D11Device* g_pd3dDevice = nullptr;
	ID3D11Device1* g_pd3dDevice1 = nullptr;
	ID3D11Device1* g_pd3dDevice2 = nullptr;
	ID3D11DeviceContext* g_pImmediateContext = nullptr;
	ID3D11DeviceContext1* g_pImmediateContext1 = nullptr;
	ID3D11DeviceContext1* g_pImmediateContext2 = nullptr;
	IDXGISwapChain* g_pSwapChain = nullptr;
	IDXGISwapChain1* g_pSwapChain1 = nullptr;
	ID3D11RenderTargetView* g_pRenderTargetView = nullptr;
	ID3D11Texture2D* g_pDepthStencil = nullptr;
	ID3D11DepthStencilView* g_pDepthStencilView = nullptr;
	ID3D11VertexShader* g_pVertexShader = nullptr;

	ID3D11PixelShader* g_pPixelShader = nullptr;

	ID3D11InputLayout* g_pVertexLayout = nullptr;


	ID3D11Buffer* _pScreenQuadVB = nullptr;
	ID3D11Buffer* _pScreenQuadIB = nullptr;
	ID3D11InputLayout* _pQuadLayout = nullptr;
	ID3D11VertexShader* _pQuadVS = nullptr;
	ID3D11PixelShader* _pQuadPS = nullptr;

	D3D11_TEXTURE2D_DESC textureDesc;
	CD3D11_RENDER_TARGET_VIEW_DESC renderTargetViewDesc;
	D3D11_SHADER_RESOURCE_VIEW_DESC shaderResourceViewDesc;

	ID3D11ShaderResourceView* _pTextureRV = nullptr;

	ID3D11Texture2D* _pRTTRrenderTargetTexture = nullptr;
	ID3D11RenderTargetView* _pRTTRenderTargetView = nullptr;
	ID3D11ShaderResourceView* _pRTTShaderResourceView = nullptr;
	ID3D11DepthStencilView* _pRTTDepthStencilView = nullptr;

	ID3D11Buffer* g_pConstantBuffer = nullptr;

	ID3D11Buffer* g_pLightConstantBuffer = nullptr;

	XMMATRIX                g_View;
	XMMATRIX                g_Projection;

	int						g_viewWidth;
	int						g_viewHeight;

	DrawableGameObject		g_GameObject;
	DrawableGameObject		g_GameObjectFSQ;

	string currentView = "Light";
	string shaderType = "Normals";
	string textureType = "texture";
	bool fullscreenQuadRenderType = false;

	Camera* camera;

	POINT currentMouseMov = {};
	POINT lastMouseMov = {};
	float moveAmountX;
	float moveAmountY;
	float m_smoothing = 0.5f;
	float m_viewSensitivity = 0.65f;

	XMFLOAT4 LightPosition = XMFLOAT4(-3.0f, 0.0f, 0.0f, 1.0f);


};




