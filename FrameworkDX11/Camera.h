#pragma once
#include <Windows.h>
#include <d3d11.h>
#include <DirectXMath.h>
#include "Structures.h"
#include <string>

class Camera
{
public:
	Camera(XMFLOAT4 position, XMFLOAT4 at, XMFLOAT4 up, int windowWidth, int windowHeight, FLOAT nearDepth, FLOAT farDepth, float movementSpeed, CameraType type, string name);

	~Camera();

	CameraS camera;

	void SetViewMatrix();
	void SetProjMatrix();

	XMFLOAT4X4 GetView();
	XMFLOAT4X4 GetProjection();

	XMFLOAT4 GetPos();
	XMFLOAT4 GetAt();
	XMFLOAT4 GetUp();

	void AdjustRotation(float x, float y, float z);

	void Move(float movementSpeed, Direction direction);
	void Rotate(float rotateAmountX, float rotateAmountY);

private:

};

