//--------------------------------------------------------------------------------------
// 
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------

// the lighting equations in this code have been taken from https://www.3dgep.com/texturing-lighting-directx-11/
// with some modifications by David White

//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
cbuffer ConstantBuffer : register( b0 )
{
	matrix World;
	matrix View;
	matrix Projection;
	float4 vOutputColor;
}

Texture2D txDiffuse : register(t0);
Texture2D txNormal : register(t1);
Texture2D txParallax : register(t2);
SamplerState samLinear : register(s0);


#define MAX_LIGHTS 1
// Light types.
#define DIRECTIONAL_LIGHT 0
#define POINT_LIGHT 1
#define SPOT_LIGHT 2

struct _Material
{
	float4  Emissive;       // 16 bytes
							//----------------------------------- (16 byte boundary)
	float4  Ambient;        // 16 bytes
							//------------------------------------(16 byte boundary)
	float4  Diffuse;        // 16 bytes
							//----------------------------------- (16 byte boundary)
	float4  Specular;       // 16 bytes
							//----------------------------------- (16 byte boundary)
	float   SpecularPower;  // 4 bytes
	bool    UseTexture;  
	int     choice;

	/*bool    UseTexture;     
	bool    UseNormal;
	bool    UseParallax;*/

	float2  Padding;        // 8 bytes
							//----------------------------------- (16 byte boundary)
};  // Total:               // 80 bytes ( 5 * 16 )

cbuffer MaterialProperties : register(b1)
{
	_Material Material;
};

struct Light
{
	float4      Position;               // 16 bytes
										//----------------------------------- (16 byte boundary)
	float4      Direction;              // 16 bytes
										//----------------------------------- (16 byte boundary)
	float4      Color;                  // 16 bytes
										//----------------------------------- (16 byte boundary)
	float       SpotAngle;              // 4 bytes
	float       ConstantAttenuation;    // 4 bytes
	float       LinearAttenuation;      // 4 bytes
	float       QuadraticAttenuation;   // 4 bytes
										//----------------------------------- (16 byte boundary)
	int         LightType;              // 4 bytes
	bool        Enabled;                // 4 bytes
	int2        Padding;                // 8 bytes
										//----------------------------------- (16 byte boundary)
};  // Total:                           // 80 bytes (5 * 16)

cbuffer LightProperties : register(b2)
{
	float4 EyePosition;                 // 16 bytes
										//----------------------------------- (16 byte boundary)
	float4 GlobalAmbient;               // 16 bytes
										//----------------------------------- (16 byte boundary)
	Light Lights[MAX_LIGHTS];           // 80 * 8 = 640 bytes
}; 

//--------------------------------------------------------------------------------------
struct VS_INPUT
{
    float4 Pos : POSITION;
	float3 Norm : NORMAL;
	float2 Tex : TEXCOORD0;
	float3 tangent : TANGENT;
	float3 binormal : BINORMAL;
};

struct QuadVS_Output
{
	float4 Pos : SV_POSITION;
	float2 Tex : TEXCOORD0;
};

struct PS_INPUT
{
    float4 Pos : SV_POSITION;
	float4 worldPos : POSITION;
	float3 Norm : NORMAL;
	float3 NormTS : NORMAL2;
	float2 Tex : TEXCOORD0;
	float3 tangent : TANGENT;
	float3 binormal : BINORMAL;
	float3 eyeVectorTS : POSITION2;
	float3 lightVectorTS : POSITION3;
	float3 posTS: POSITION4;
	float3 eyePosTS: POSITION5;
};

struct QuadVS_Input
{
	float4 Pos : SV_POSITION;
	float2 Tex : TEXCOORD0;
};


	/***********************************************
	MARKING SCHEME: TANGENT SPACE
	DESCRIPTION: THE FUNCTION THAT IS USED TO TRANSFORM VECTORS TO TANGENT SPACE
	***********************************************/
float3 VectorToTangentSpace(float3 vectorV, float3x3 TBN_inv)
{
	float3 tangentSpaceNormal = normalize(mul(vectorV, TBN_inv));
	tangentSpaceNormal.x = tangentSpaceNormal.x * 2.0f - 1.0f;
	tangentSpaceNormal.y = tangentSpaceNormal.y * 2.0f - 1.0f;
	tangentSpaceNormal.z = -tangentSpaceNormal.z;
	return tangentSpaceNormal.xyz;
}

float4 DoDiffuse(Light light, float3 L, float3 N)
{
	float NdotL = max(0, dot(N, L));
	return light.Color * NdotL;
}

float4 DoSpecular(Light lightObject, float3 vertexToEye, float3 lightDirectionToVertex, float3 Normal)
{
	float4 lightDir = float4(normalize(-lightDirectionToVertex),1);
	vertexToEye = normalize(vertexToEye);

	float lightIntensity = saturate(dot(Normal, lightDir));
	float4 specular = float4(0, 0, 0, 0);
	if (lightIntensity > 0.0f)
	{
		float3  reflection = normalize(2 * lightIntensity * Normal - lightDir);
		specular = pow(saturate(dot(reflection, vertexToEye)), Material.SpecularPower); // 32 = specular power
	}

	return specular;
}

float DoAttenuation(Light light, float d)
{
	return 1.0f / (light.ConstantAttenuation + light.LinearAttenuation * d + light.QuadraticAttenuation * d * d);
}

struct LightingResult
{
	float4 Diffuse;
	float4 Specular;
};

LightingResult DoPointLight(Light light, float3 vertexToEye, float4 vertexPos, float3 N, float3 lightVectorTS)
{
	LightingResult result;

	float3 LightDirectionToVertex = (light.Position - vertexPos).xyz;
	float distance = length(LightDirectionToVertex);
	LightDirectionToVertex = LightDirectionToVertex / distance;

    float3 vertexToLight = light.Position + (light.Direction * distance);
	distance = length(vertexToLight);

	float attenuation = DoAttenuation(light, distance);
	attenuation = 1;


    result.Diffuse = DoDiffuse(light, -lightVectorTS, N) * attenuation;
	result.Specular = DoSpecular(light, vertexToEye, LightDirectionToVertex, N) * attenuation;

	return result;
}

float3x3 computeTBNMatrixB(float3 unitNormal, float3 tangent, float3 binorm)
{
	//clone of function above, but it accepts the binormals as well
	//instead of calculating them on the fly, because they're already computed
	//in the DrawableGameObject.cpp
	//this function is used for the code taken from tutorial (cube binormals)
    float3 N = unitNormal;
    float3 T = normalize(tangent - dot(tangent, N) * N);
	//this time you have to make sure the binormal is orthogonal as well 
    float3 B = normalize(binorm - dot(binorm, tangent) * tangent);

    float3x3 TBN = float3x3(T, B, N);

    return TBN;
}

float3 CalcBumpMap(float2 texCoords)
{
    float3 bumpMap;
    bumpMap = txNormal.Sample(samLinear, texCoords).rgb;
	
    bumpMap.x = (-bumpMap.x * 2.0f) + 1.0f;
    bumpMap.y = (-bumpMap.y * 2.0f) + 1.0f;
    bumpMap.z = -bumpMap.z;
	
    return bumpMap;
}

LightingResult ComputeLighting(float4 vertexPos, float3 N, float3 lightVectorTS, float3 eyeVectorTS)
{
	float3 vertexToEye = eyeVectorTS - vertexPos;

	LightingResult totalResult = { { 0, 0, 0, 0 },{ 0, 0, 0, 0 } };

	[unroll]
	for (int i = 0; i < MAX_LIGHTS; ++i)
	{
		LightingResult result = { { 0, 0, 0, 0 },{ 0, 0, 0, 0 } };

		if (!Lights[i].Enabled)
			continue;

        result = DoPointLight(Lights[i], vertexToEye, vertexPos, N, lightVectorTS);

		totalResult.Diffuse += result.Diffuse;
		totalResult.Specular += result.Specular;
	}

	totalResult.Diffuse = saturate(totalResult.Diffuse);
	totalResult.Specular = saturate(totalResult.Specular);

	return totalResult;
}

	/***********************************************
	MARKING SCHEME: PARALLAX MAPPING
	DESCRIPTION: SIMPLE PARALLAX MAPPING USING LAYERS AND THE PREVIOUS TEX COORDS
	***********************************************/
float2 ParallaxMapping(float2 texcoords, float3 viewDir)
{
	float height_scale = 0.05f;
	float height = txParallax.Sample(samLinear, texcoords).x;
	float2 p = viewDir.xy * (height * height_scale);
	p.y = -p.y;
	return texcoords - p;
}

	/***********************************************
	MARKING SCHEME: PARALLAX MAPPING
	DESCRIPTION: PARALLAX STEEP MAPPING USING LAYERS AND THE PREVIOUS TEX COORDS
	***********************************************/
float2 ParallaxSteepMapping(float2 texCoords, float3 viewDir)
{
	//Determine the number of layers from angle between V and N
	float minLayers = 5;
	float maxLayers = 20;

	float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0, 0, 1), viewDir)));

	//calculate height of each layer
	float layerHeight = 1.0f / numLayers;
	//set initial depth of current layer to 0
	float currentLayerHeight = 0.0f;

	//shift of texture coordinates for each iteration
	//current texture coords
	float height_scale = 0.1f;
	float2 p = viewDir.xy * height_scale;
	float2 deltaTexCoords = p / numLayers;

	float2 currentTexCoords = texCoords;

	float2 dx = ddx(texCoords);
	float2 dy = ddy(texCoords);

	float heightFromTexture = txParallax.SampleGrad(samLinear, currentTexCoords, dx, dy);

	while (heightFromTexture > currentLayerHeight)
	{
		currentLayerHeight += layerHeight;
		currentTexCoords -= deltaTexCoords;

		heightFromTexture = txParallax.SampleGrad(samLinear, currentTexCoords, dx, dy);
	}

	return currentTexCoords;
}

	/***********************************************
	MARKING SCHEME: PARALLAX MAPPING
	DESCRIPTION: PARALLAX OCCLUSION MAPPING USING LAYERS AND THE PREVIOUS TEX COORDS
	***********************************************/
float2 ParallaxOcclusionMapping(float2 texCoords, float3 normal, float3 viewDir)
{
    int minLayers = 5;
    int maxLayers = 20;
    float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0, 0, 1), viewDir)));
    float layerHeight = 1.0f / numLayers;
    float currentLayerHeight = 0.0f;
	
    float height_scale = 0.2f;
    viewDir.z = -viewDir.z;
    float2 p = height_scale * viewDir.xy;
	
    float2 deltaTexCoords = p / numLayers;
    float2 currentTexCoords = texCoords;

    float2 dx = ddx(texCoords);
    float2 dy = ddy(texCoords);

    float heightFromTexture = txParallax.Sample(samLinear, currentTexCoords).x;
	
    while (heightFromTexture > currentLayerHeight)
    {
        currentTexCoords -= deltaTexCoords;
        heightFromTexture = txParallax.SampleGrad(samLinear, currentTexCoords, dx, dy).x;
        currentLayerHeight += layerHeight;
    }

    float2 previousTexCoords = currentTexCoords + deltaTexCoords;

    float nextH = heightFromTexture - currentLayerHeight;
    float prevH = txParallax.Sample(samLinear, previousTexCoords).x - currentLayerHeight + layerHeight;

    float weight = nextH / (nextH - prevH);

    float2 finalTexCoords = previousTexCoords * weight + currentTexCoords * (1.0 - weight);
	
    return finalTexCoords;
}

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
PS_INPUT VS( VS_INPUT input )
{
	//Transform to World Space
    PS_INPUT output = (PS_INPUT)0;
    output.Pos = mul( input.Pos, World );
	output.worldPos = output.Pos;
    output.Pos = mul(mul(output.Pos, View), Projection);
	
    output.Norm = mul(input.Norm, (float3x3) World).xyz;
    output.tangent = mul(input.tangent, (float3x3) World).xyz;
    output.binormal = mul(input.binormal, (float3x3) World).xyz;
	
	output.Tex = input.Tex;
	
	/***********************************************
	MARKING SCHEME: Tangent Space
	DESCRIPTION: CREATING THE TBN MATRIX TO TRANSPOSE FROM WORLD SPACE TO TANGENT SPACE AND USING THIS IN THE FUNCTION CREATED
	***********************************************/
	
    float3x3 TBN_inv = transpose(float3x3(normalize(input.tangent), normalize(input.binormal), normalize(input.Norm)));

    float3 lightPosWorld = mul(Lights[0].Position, World);
    output.posTS = mul(output.worldPos.xyz, TBN_inv);
    output.lightVectorTS = mul(lightPosWorld.xyz, TBN_inv);
    output.eyeVectorTS = mul(EyePosition.xyz, World);
    output.eyePosTS = mul(normalize(EyePosition - output.worldPos).xyz, TBN_inv);

    return output;
}

QuadVS_Output QuadVS(QuadVS_Input Input)
{
	QuadVS_Output output;
	output.Pos = Input.Pos;
	output.Tex = Input.Tex;
	return output;
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------

float4 PS(PS_INPUT IN) : SV_TARGET
{
    float3 vertexToLight = normalize(Lights[0].Position - IN.worldPos).xyz;
    float3 vertexToEye = normalize(EyePosition - IN.worldPos).xyz;
	
    float3x3 TBN_inv = transpose(float3x3(normalize(IN.tangent), normalize(IN.binormal), normalize(IN.Norm)));
	
    float3 vertexToLightTS = mul(vertexToLight, TBN_inv);
    float3 vertexToEyeTS = mul(vertexToEye, TBN_inv);

	if (Material.choice == 0)
	{
	/***********************************************
	MARKING SCHEME: Normal Mapping
	DESCRIPTION: Map sampling, normal value decompression, transformation to tangent space
	***********************************************/

		//Normal Mapping is now enabled always throughout the application this is kept in to keep the original Module handin marking scheme areas the same.
		
        LightingResult lit = ComputeLighting(IN.worldPos, normalize(CalcBumpMap(IN.Tex)), vertexToLightTS, vertexToEyeTS);
		float4 texColor = { 1, 1, 1, 1 };


		float4 emissive = Material.Emissive;
		float4 ambient = Material.Ambient * GlobalAmbient;
		float4 diffuse = Material.Diffuse * lit.Diffuse;
		float4 specular = Material.Specular * lit.Specular;

		if (Material.UseTexture)
		{
			texColor = txDiffuse.Sample(samLinear, IN.Tex);
		}

		float4 finalColor = (emissive + ambient + diffuse + specular) * texColor;

		return finalColor;
	}
	else if (Material.choice == 1)
	{

		
		//float3 viewDir = normalize(EyePosition - IN.worldPos);
		float2 texCoords = ParallaxSteepMapping(IN.Tex, vertexToEyeTS);

		if (texCoords.x >= 1.0 || texCoords.y >= 1.0 || texCoords.x <= 0.0 || texCoords.y <= 0.0)
			discard;
		
        LightingResult lit = ComputeLighting(IN.worldPos, normalize(CalcBumpMap(texCoords)), vertexToLightTS, vertexToEyeTS);
		float4 texColor = { 1, 1, 1, 1 };


		float4 emissive = Material.Emissive;
		float4 ambient = Material.Ambient * GlobalAmbient;
		float4 diffuse = Material.Diffuse * lit.Diffuse;
		float4 specular = Material.Specular * lit.Specular;

		if (Material.UseTexture)
		{
			texColor = txDiffuse.Sample(samLinear, texCoords);
		}

		float4 finalColor = (emissive + ambient + diffuse + specular) * texColor;

		return finalColor;
	}
	else if (Material.choice == 2)
	{
		//float3 viewDir = normalize(EyePosition.xyz - IN.worldPos.xyz);
        float2 texCoords = ParallaxOcclusionMapping(IN.Tex, IN.Norm, vertexToEyeTS);

		if (texCoords.x > 1.0 || texCoords.y > 1.0 || texCoords.x < 0.0 || texCoords.y < 0.0)
			discard;
		
        LightingResult lit = ComputeLighting(IN.worldPos, normalize(CalcBumpMap(texCoords)), vertexToLightTS, vertexToEyeTS);
		float4 texColor = { 1, 1, 1, 1 };


		float4 emissive = Material.Emissive;
		float4 ambient = Material.Ambient * GlobalAmbient;
		float4 diffuse = Material.Diffuse * lit.Diffuse;
		float4 specular = Material.Specular * lit.Specular;

		if (Material.UseTexture)
		{
			texColor = txDiffuse.Sample(samLinear, texCoords);
		}

		float4 finalColor = (emissive + ambient + diffuse + specular) * texColor;

		return finalColor;
	}
    LightingResult lit = ComputeLighting(IN.worldPos, normalize(CalcBumpMap(IN.Tex)), vertexToLightTS, vertexToEyeTS);
	float4 texColor = { 1, 1, 1, 1 };


	float4 emissive = Material.Emissive;
	float4 ambient = Material.Ambient * GlobalAmbient;
	float4 diffuse = Material.Diffuse * lit.Diffuse;
	float4 specular = Material.Specular * lit.Specular;

	if (Material.UseTexture)
	{
		texColor = txDiffuse.Sample(samLinear, IN.Tex);
	}

	float4 finalColor = (emissive + ambient + diffuse + specular) * texColor;

	return finalColor;
}

//--------------------------------------------------------------------------------------
// PSSolid - render a solid color
//--------------------------------------------------------------------------------------
float4 PSSolid(PS_INPUT input) : SV_Target
{
	return vOutputColor;
}

float4 QuadPS(QuadVS_Output Input) : SV_TARGET
{
	float4 vColor;
	vColor = txDiffuse.Sample(samLinear, Input.Tex);
	return vColor;
}