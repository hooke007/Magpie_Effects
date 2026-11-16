// 移植自 ReShade 的 Clarity.fx

//!MAGPIE EFFECT
//!VERSION 4


//!PARAMETER
//!LABEL Radius
//!DEFAULT 3
//!MIN 0
//!MAX 4
//!STEP 1
int ClarityRadius;

//!PARAMETER
//!LABEL Offset
//!DEFAULT 2
//!MIN 1
//!MAX 5
//!STEP 1
float ClarityOffset;

//!PARAMETER
//!LABEL Blend Mode
//!DEFAULT 2
//!MIN 0
//!MAX 6
//!STEP 1
int ClarityBlendMode;

//!PARAMETER
//!LABEL Blend If Dark
//!DEFAULT 50
//!MIN 0
//!MAX 255
//!STEP 5
int ClarityBlendIfDark;

//!PARAMETER
//!LABEL Blend If Light
//!DEFAULT 205
//!MIN 0
//!MAX 255
//!STEP 5
int ClarityBlendIfLight;

//!PARAMETER
//!LABEL View BlendIf Mask
//!DEFAULT 0
//!MIN 0
//!MAX 1
//!STEP 1
int ClarityViewBlendIfMask;

//!PARAMETER
//!LABEL Strength
//!DEFAULT 0.4
//!MIN 0
//!MAX 1
//!STEP 0.01
float ClarityStrength;

//!PARAMETER
//!LABEL Dark Intensity
//!DEFAULT 0.4
//!MIN 0
//!MAX 1
//!STEP 0.01
float ClarityDarkIntensity;

//!PARAMETER
//!LABEL Light Intensity
//!DEFAULT 0
//!MIN 0
//!MAX 1
//!STEP 0.01
float ClarityLightIntensity;

//!PARAMETER
//!LABEL View Mask
//!DEFAULT 0
//!MIN 0
//!MAX 1
//!STEP 1
int ClarityViewMask;


//!TEXTURE
Texture2D INPUT;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
Texture2D OUTPUT;

//!TEXTURE
//!WIDTH INPUT_WIDTH * 0.5
//!HEIGHT INPUT_HEIGHT * 0.5
//!FORMAT R8_UNORM
Texture2D ClarityTex;

//!TEXTURE
//!WIDTH INPUT_WIDTH * 0.5
//!HEIGHT INPUT_HEIGHT * 0.5
//!FORMAT R8_UNORM
Texture2D ClarityTex2;

//!TEXTURE
//!WIDTH INPUT_WIDTH * 0.25
//!HEIGHT INPUT_HEIGHT * 0.25
//!FORMAT R8_UNORM
Texture2D ClarityTex3;


//!SAMPLER
//!FILTER LINEAR
//!ADDRESS CLAMP
SamplerState sam;


//!COMMON

static const float3 LumaCoef = float3(0.32786885, 0.655737705, 0.0163934436);

// 对单通道纹理按 dir 方向做高斯模糊。
MF ClarityBlur(Texture2D<MF> tex, float2 pos, float2 dir) {
	float2 texelStep = GetInputPt() * ClarityOffset * dir;
	MF color = tex.SampleLevel(sam, pos, 0);

	if (ClarityRadius == 0) {
		float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
		float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };

		color *= weight[0];

		[loop]
		for (int i = 1; i < 4; ++i) {
			color += tex.SampleLevel(sam, pos + offset[i] * texelStep, 0) * weight[i];
			color += tex.SampleLevel(sam, pos - offset[i] * texelStep, 0) * weight[i];
		}
	}

	if (ClarityRadius == 1) {
		float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
		float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };

		color *= weight[0];

		[loop]
		for (int i = 1; i < 6; ++i) {
			color += tex.SampleLevel(sam, pos + offset[i] * texelStep, 0) * weight[i];
			color += tex.SampleLevel(sam, pos - offset[i] * texelStep, 0) * weight[i];
		}
	}

	if (ClarityRadius == 2) {
		float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
		float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };

		color *= weight[0];

		[loop]
		for (int i = 1; i < 11; ++i) {
			color += tex.SampleLevel(sam, pos + offset[i] * texelStep, 0) * weight[i];
			color += tex.SampleLevel(sam, pos - offset[i] * texelStep, 0) * weight[i];
		}
	}

	if (ClarityRadius == 3) {
		float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
		float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };

		color *= weight[0];

		[loop]
		for (int i = 1; i < 15; ++i) {
			color += tex.SampleLevel(sam, pos + offset[i] * texelStep, 0) * weight[i];
			color += tex.SampleLevel(sam, pos - offset[i] * texelStep, 0) * weight[i];
		}
	}

	if (ClarityRadius == 4) {
		float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
		float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };

		color *= weight[0];

		[loop]
		for (int i = 1; i < 18; ++i) {
			color += tex.SampleLevel(sam, pos + offset[i] * texelStep, 0) * weight[i];
			color += tex.SampleLevel(sam, pos - offset[i] * texelStep, 0) * weight[i];
		}
	}

	return color;
}


//!PASS 1
//!DESC Clarity Horizontal Blur
//!STYLE PS
//!IN INPUT
//!OUT ClarityTex

// 对原图 RGB 做水平高斯模糊并降采样到 0.5x，输出亮度（单通道）。
MF Pass1(float2 pos) {
	float2 texelStep = GetInputPt() * ClarityOffset * float2(1.0, 0.0);
	float3 color = INPUT.SampleLevel(sam, pos, 0).rgb;

	if (ClarityRadius == 0) {
		float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
		float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };

		color *= weight[0];

		[loop]
		for (int i = 1; i < 4; ++i) {
			color += INPUT.SampleLevel(sam, pos + offset[i] * texelStep, 0).rgb * weight[i];
			color += INPUT.SampleLevel(sam, pos - offset[i] * texelStep, 0).rgb * weight[i];
		}
	}

	if (ClarityRadius == 1) {
		float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
		float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };

		color *= weight[0];

		[loop]
		for (int i = 1; i < 6; ++i) {
			color += INPUT.SampleLevel(sam, pos + offset[i] * texelStep, 0).rgb * weight[i];
			color += INPUT.SampleLevel(sam, pos - offset[i] * texelStep, 0).rgb * weight[i];
		}
	}

	if (ClarityRadius == 2) {
		float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
		float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };

		color *= weight[0];

		[loop]
		for (int i = 1; i < 11; ++i) {
			color += INPUT.SampleLevel(sam, pos + offset[i] * texelStep, 0).rgb * weight[i];
			color += INPUT.SampleLevel(sam, pos - offset[i] * texelStep, 0).rgb * weight[i];
		}
	}

	if (ClarityRadius == 3) {
		float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
		float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };

		color *= weight[0];

		[loop]
		for (int i = 1; i < 15; ++i) {
			color += INPUT.SampleLevel(sam, pos + offset[i] * texelStep, 0).rgb * weight[i];
			color += INPUT.SampleLevel(sam, pos - offset[i] * texelStep, 0).rgb * weight[i];
		}
	}

	if (ClarityRadius == 4) {
		float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
		float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };

		color *= weight[0];

		[loop]
		for (int i = 1; i < 18; ++i) {
			color += INPUT.SampleLevel(sam, pos + offset[i] * texelStep, 0).rgb * weight[i];
			color += INPUT.SampleLevel(sam, pos - offset[i] * texelStep, 0).rgb * weight[i];
		}
	}

	return dot(color, LumaCoef);
}


//!PASS 2
//!DESC Clarity Vertical Blur
//!STYLE PS
//!IN ClarityTex
//!OUT ClarityTex2

MF Pass2(float2 pos) {
	return ClarityBlur(ClarityTex, pos, float2(0.0, 1.0));
}


//!PASS 3
//!DESC Clarity Horizontal Blur
//!STYLE PS
//!IN ClarityTex2
//!OUT ClarityTex3

MF Pass3(float2 pos) {
	return ClarityBlur(ClarityTex2, pos, float2(1.0, 0.0));
}


//!PASS 4
//!DESC Clarity Blend
//!STYLE PS
//!IN ClarityTex3, INPUT
//!OUT OUTPUT

MF4 Pass4(float2 pos) {
	// 对 0.25x 的亮度遮罩做最后一次垂直模糊
	MF color = ClarityBlur(ClarityTex3, pos, float2(0.0, 1.0));

	float3 orig = INPUT.SampleLevel(sam, pos, 0).rgb;
	float luma = dot(orig, LumaCoef);
	float3 chroma = orig / luma;

	float sharp = 1.0 - color;
	sharp = (luma + sharp) * 0.5;

	float sharpMin = lerp(0.0, 1.0, smoothstep(0.0, 1.0, sharp));
	float sharpMax = sharpMin;
	sharpMin = lerp(sharp, sharpMin, ClarityDarkIntensity);
	sharpMax = lerp(sharp, sharpMax, ClarityLightIntensity);
	sharp = lerp(sharpMin, sharpMax, step(0.5, sharp));

	if (ClarityViewMask) {
		orig = sharp;
		luma = sharp;
		chroma = 1.0;
	} else {
		if (ClarityBlendMode == 0) {
			// Soft Light
			sharp = lerp(2.0 * luma * sharp + luma * luma * (1.0 - 2.0 * sharp), 2.0 * luma * (1.0 - sharp) + pow(luma, 0.5) * (2.0 * sharp - 1.0), step(0.49, sharp));
		}

		if (ClarityBlendMode == 1) {
			// Overlay
			sharp = lerp(2.0 * luma * sharp, 1.0 - 2.0 * (1.0 - luma) * (1.0 - sharp), step(0.50, luma));
		}

		if (ClarityBlendMode == 2) {
			// Hard Light
			sharp = lerp(2.0 * luma * sharp, 1.0 - 2.0 * (1.0 - luma) * (1.0 - sharp), step(0.50, sharp));
		}

		if (ClarityBlendMode == 3) {
			// Multiply
			sharp = saturate(2.0 * luma * sharp);
		}

		if (ClarityBlendMode == 4) {
			// Vivid Light
			sharp = lerp(2.0 * luma * sharp, luma / (2.0 * (1.0 - sharp)), step(0.5, sharp));
		}

		if (ClarityBlendMode == 5) {
			// Linear Light
			sharp = luma + 2.0 * sharp - 1.0;
		}

		if (ClarityBlendMode == 6) {
			// Addition
			sharp = saturate(luma + (sharp - 0.5));
		}
	}

	if (ClarityBlendIfDark > 0 || ClarityBlendIfLight < 255 || ClarityViewBlendIfMask) {
		float ClarityBlendIfD = (ClarityBlendIfDark / 255.0) + 0.0001;
		float ClarityBlendIfL = (ClarityBlendIfLight / 255.0) - 0.0001;
		float mix = dot(orig, float3(0.333333, 0.333333, 0.333333));
		float mask = 1.0;

		if (ClarityBlendIfDark > 0) {
			mask = lerp(0.0, 1.0, smoothstep(ClarityBlendIfD - (ClarityBlendIfD * 0.2), ClarityBlendIfD + (ClarityBlendIfD * 0.2), mix));
		}

		if (ClarityBlendIfLight < 255) {
			mask = lerp(mask, 0.0, smoothstep(ClarityBlendIfL - (ClarityBlendIfL * 0.2), ClarityBlendIfL + (ClarityBlendIfL * 0.2), mix));
		}

		sharp = lerp(luma, sharp, mask);

		if (ClarityViewBlendIfMask) {
			sharp = mask;
			luma = mask;
			chroma = 1.0;
		}
	}

	orig = lerp(luma, sharp, ClarityStrength);
	orig *= chroma;

	return MF4(saturate(orig), 1.0);
}

