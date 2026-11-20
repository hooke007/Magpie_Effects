// Edge 移植自 https://github.com/jersobh/edge/blob/v0.15.1/shaders/edge_pass.comp.glsl

//!MAGPIE EFFECT
//!VERSION 4


//!PARAMETER
//!LABEL Sharpness
//!DEFAULT 0.6
//!MIN 0
//!MAX 1
//!STEP 0.01
float SHARP;

//!PARAMETER
//!LABEL Mode
//!DEFAULT 0
//!MIN 0
//!MAX 3
//!STEP 1
int MODE;

//!PARAMETER
//!LABEL Beautify
//!DEFAULT 0
//!MIN 0
//!MAX 1
//!STEP 1
int BTFY;


//!TEXTURE
Texture2D INPUT;

//!TEXTURE
Texture2D OUTPUT;

//!SAMPLER
//!FILTER LINEAR
SamplerState samLinear;


//!PASS 1
//!DESC Edge
//!STYLE PS
//!IN INPUT
//!OUT OUTPUT

static const float3 LUMA_COEFF = float3(0.2126, 0.7152, 0.0722);

float luma(float3 c) {
	return dot(c, LUMA_COEFF);
}

float3 sampleLod(float2 uv) {
	return INPUT.SampleLevel(samLinear, uv, 0).rgb;
}

float3 fetchPixel(int2 coord, int2 maxCoord) {
	return INPUT.Load(int3(clamp(coord, int2(0, 0), maxCoord), 0)).rgb;
}

// Beautify
float3 beautifyColor(float3 c) {
	if (BTFY != 0) {
		float y = luma(c);
		float sY = y + (y - 0.5) * (1.0 - abs(y - 0.5) * 2.0) * 0.08;
		float3 outc = c * (sY / max(y, 1e-4));

		float maxCh = max(outc.r, max(outc.g, outc.b));
		float minCh = min(outc.r, min(outc.g, outc.b));
		float sat = (maxCh - minCh) / max(maxCh, 1e-4);
		float satLift = clamp((1.0 - sat) * 0.10, 0.0, 0.12);
		c = lerp((float3)sY, outc, 1.0 + satLift);
	}
	return c;
}

// MODE 2: Nearest Neighbor
float3 edgeUpscaleNearest(float2 uv, float2 renderSize) {
	float2 p = uv * renderSize;
	int2 ipos = (int2)floor(p);
	int2 maxCoord = max((int2)(renderSize + 0.5) - 1, int2(0, 0));
	float3 c = fetchPixel(ipos, maxCoord);
	return beautifyColor(c);
}

// MODE 3: Competitive
float3 edgeUpscaleCompetitive(float2 uv, float2 renderSize, float sharp) {
	float2 p = uv * renderSize - 0.5;
	int2 ipos = (int2)floor(p);
	int2 maxCoord = max((int2)(renderSize + 0.5) - 1, int2(0, 0));

	float3 c00 = fetchPixel(ipos + int2(0, 0), maxCoord);
	float3 c10 = fetchPixel(ipos + int2(1, 0), maxCoord);
	float3 c01 = fetchPixel(ipos + int2(0, 1), maxCoord);
	float3 c11 = fetchPixel(ipos + int2(1, 1), maxCoord);

	float3 centerBilinear = sampleLod(uv);
	float3 minC = min(min(c00, c10), min(c01, c11));
	float3 maxC = max(max(c00, c10), max(c01, c11));

	if (sharp > 0.01) {
		float3 avg = (c00 + c10 + c01 + c11) * 0.25;
		float diff = luma(maxC) - luma(minC);
		float amp = clamp(diff * 4.0, 0.0, 1.0);
		centerBilinear = clamp(centerBilinear + (centerBilinear - avg) * (sharp * 0.50 * amp), minC, maxC);
	}
	return beautifyColor(centerBilinear);
}

// MODE 1: Perf
float3 edgeUpscalePerf(float2 uv, float2 renderSize, float sharp) {
	float2 p = uv * renderSize - 0.5;
	int2 ipos = (int2)floor(p);
	float2 f = p - (float2)ipos;
	int2 maxCoord = max((int2)(renderSize + 0.5) - 1, int2(0, 0));

	float3 c00 = fetchPixel(ipos + int2(0, 0), maxCoord);
	float3 c10 = fetchPixel(ipos + int2(1, 0), maxCoord);
	float3 c01 = fetchPixel(ipos + int2(0, 1), maxCoord);
	float3 c11 = fetchPixel(ipos + int2(1, 1), maxCoord);

	float l00 = luma(c00);
	float l10 = luma(c10);
	float l01 = luma(c01);
	float l11 = luma(c11);

	float dMain = abs(l11 - l00);
	float dAnti = abs(l01 - l10);
	float3 centerBilinear = sampleLod(uv);

	float3 diag;
	if (dMain > dAnti * 1.2) {
		float w = smoothstep(-0.5, 0.5, (f.x + f.y - 1.0) * 1.4);
		diag = lerp(c00, c11, w);
	} else if (dAnti > dMain * 1.2) {
		float w = smoothstep(-0.5, 0.5, (f.x - f.y) * 1.4);
		diag = lerp(c01, c10, w);
	} else {
		diag = centerBilinear;
	}

	float diagWeight = clamp(abs(dMain - dAnti) * 3.5, 0.0, 0.85);
	float3 outc = lerp(centerBilinear, diag, diagWeight);

	float3 minC = min(min(c00, c10), min(c01, c11));
	float3 maxC = max(max(c00, c10), max(c01, c11));
	outc = clamp(outc, minC, maxC);

	if (sharp > 0.01) {
		float3 avg = (c00 + c10 + c01 + c11) * 0.25;
		float diff = luma(maxC) - luma(minC);
		float amp = clamp(diff * 4.0, 0.0, 1.0);
		outc = clamp(outc + (outc - avg) * (sharp * 0.55 * amp), minC, maxC);
	}

	return beautifyColor(outc);
}

// MODE 0: Quality
float3 edgeUpscaleQuality(float2 uv, float2 renderSize, float scale, float sharp) {
	float2 texel = 1.0 / renderSize;
	float2 p = uv * renderSize - 0.5;
	int2 ipos = (int2)floor(p);
	float2 f = p - (float2)ipos;
	int2 maxCoord = max((int2)(renderSize + 0.5) - 1, int2(0, 0));

	float3 c00 = fetchPixel(ipos + int2(0, 0), maxCoord);
	float3 c10 = fetchPixel(ipos + int2(1, 0), maxCoord);
	float3 c01 = fetchPixel(ipos + int2(0, 1), maxCoord);
	float3 c11 = fetchPixel(ipos + int2(1, 1), maxCoord);

	float3 cT = sampleLod(((float2)ipos + float2(0.5, -0.5)) * texel);
	float3 cB = sampleLod(((float2)ipos + float2(0.5,  2.5)) * texel);
	float3 cL = sampleLod(((float2)ipos + float2(-0.5, 0.5)) * texel);
	float3 cR = sampleLod(((float2)ipos + float2( 2.5, 0.5)) * texel);

	float l00 = luma(c00), l10 = luma(c10);
	float l01 = luma(c01), l11 = luma(c11);
	float lT = luma(cT), lB = luma(cB);
	float lL = luma(cL), lR = luma(cR);

	float gx = ((l10 + l11) - (l00 + l01)) + (lR - lL) * 0.75;
	float gy = ((l01 + l11) - (l00 + l10)) + (lB - lT) * 0.75;
	float gradLen = sqrt(gx * gx + gy * gy);

	float dMain = abs(l11 - l00);
	float dAnti = abs(l01 - l10);

	float3 bilinear = lerp(lerp(c00, c10, f.x), lerp(c01, c11, f.x), f.y);
	float3 horizSharp = (c00 + c10) * 0.5 - (cL + cR) * 0.25;
	float3 vertSharp  = (c00 + c01) * 0.5 - (cT + cB) * 0.25;
	float3 cubic = bilinear + (horizSharp * (0.5 - abs(f.x - 0.5)) +
	                           vertSharp  * (0.5 - abs(f.y - 0.5))) * 0.45;

	float3 minC = min(min(c00, c10), min(c01, c11));
	float3 maxC = max(max(c00, c10), max(c01, c11));
	cubic = clamp(cubic, minC, maxC);

	float3 diag = cubic;
	if (dMain > dAnti * 1.15) {
		float w = smoothstep(-0.5, 0.5, (f.x + f.y - 1.0) * 1.4);
		diag = lerp(c00, c11, w);
	} else if (dAnti > dMain * 1.15) {
		float w = smoothstep(-0.5, 0.5, (f.x - f.y) * 1.4);
		diag = lerp(c01, c10, w);
	}
	float diagConf = clamp(abs(dMain - dAnti) * 4.0, 0.0, 1.0);
	float3 baseReconstructed = lerp(cubic, diag, diagConf * 0.65);

	float3 finalEdge = baseReconstructed;
	if (gradLen > 1e-4) {
		float2 norm = float2(gx, gy) / gradLen;
		float2 tangent = float2(-norm.y, norm.x);

		float stepDist = clamp(scale * 0.45, 0.70, 1.60);
		float2 offset = tangent * texel * stepDist;

		float3 tapPos = sampleLod(uv + offset);
		float3 tapNeg = sampleLod(uv - offset);
		float3 alongEdge = 0.5 * (tapPos + tapNeg);

		float edgeConf = clamp(gradLen * 3.5, 0.0, 1.0);
		finalEdge = lerp(baseReconstructed, alongEdge, edgeConf * 0.78);
		finalEdge = clamp(finalEdge, minC, maxC);
	}

	float lMin = luma(minC);
	float lMax = luma(maxC);
	float contrast = lMax - lMin;

	if (sharp > 0.01 && contrast > 0.01) {
		float casAmp = clamp(min(lMin, 1.0 - lMax) / max(contrast, 1e-4), 0.0, 1.0);
		float3 crossAvg = (c00 + c10 + c01 + c11) * 0.25;
		float3 highPass = finalEdge - crossAvg;
		float effectiveSharp = sharp * lerp(0.35, 0.75, casAmp);
		finalEdge = clamp(finalEdge + highPass * effectiveSharp, minC, maxC);
	}

	return beautifyColor(finalEdge);
}

// 缩小
float3 edgeDownsample(float2 uv, float2 renderSize, float sharp) {
	float2 texel = 1.0 / renderSize;
	float2 off = texel * 0.5;
	float3 s0 = sampleLod(uv + float2(-off.x, -off.y));
	float3 s1 = sampleLod(uv + float2( off.x, -off.y));
	float3 s2 = sampleLod(uv + float2(-off.x,  off.y));
	float3 s3 = sampleLod(uv + float2( off.x,  off.y));
	float3 avg = (s0 + s1 + s2 + s3) * 0.25;

	if (sharp > 0.01) {
		float3 minC = min(min(s0, s1), min(s2, s3));
		float3 maxC = max(max(s0, s1), max(s2, s3));
		float contrast = luma(maxC) - luma(minC);
		if (contrast > 0.01) {
			float3 highPass = avg - (minC + maxC) * 0.5;
			avg = clamp(avg + highPass * (sharp * 0.4), minC, maxC);
		}
	}
	return beautifyColor(avg);
}

// 1:1 原生分辨率
float3 edgeNative(float2 uv, float2 renderSize, float sharp) {
	float3 c = sampleLod(uv);
	if (sharp <= 0.01) {
		return beautifyColor(c);
	}

	float2 texel = 1.0 / renderSize;
	float3 north = sampleLod(uv + float2(0.0, -texel.y));
	float3 south = sampleLod(uv + float2(0.0,  texel.y));
	float3 west  = sampleLod(uv + float2(-texel.x, 0.0));
	float3 east  = sampleLod(uv + float2( texel.x, 0.0));

	float3 minC = min(c, min(min(north, south), min(west, east)));
	float3 maxC = max(c, max(max(north, south), max(west, east)));

	float lMin = luma(minC);
	float lMax = luma(maxC);
	float contrast = lMax - lMin;

	if (contrast > 0.01) {
		float casAmp = clamp(min(lMin, 1.0 - lMax) / max(contrast, 1e-4), 0.0, 1.0);
		float3 crossAvg = (north + south + west + east) * 0.25;
		float3 highPass = c - crossAvg;
		float effectiveSharp = sharp * lerp(0.40, 0.80, casAmp);
		c = clamp(c + highPass * effectiveSharp, minC, maxC);
	}
	return beautifyColor(c);
}

float4 Pass1(float2 pos) {
	float2 displaySize = max((float2)GetOutputSize(), 1.0);
	float2 renderSize = max((float2)GetInputSize(), 1.0);
	float sharp = clamp(SHARP, 0.0, 1.0);
	int mode = MODE;
	float2 uv = pos;

	float scale = max(displaySize.x / renderSize.x, displaySize.y / renderSize.y);

	float3 rgb;
	if (abs(renderSize.x - displaySize.x) <= 1.0 && abs(renderSize.y - displaySize.y) <= 1.0) {
		rgb = (mode == 2) ? sampleLod(uv) : edgeNative(uv, renderSize, sharp);
	} else if (renderSize.x > displaySize.x * 1.01) {
		rgb = edgeDownsample(uv, renderSize, sharp);
	} else if (mode == 3) {
		rgb = edgeUpscaleCompetitive(uv, renderSize, sharp);
	} else if (mode == 2) {
		rgb = edgeUpscaleNearest(uv, renderSize);
	} else if (mode == 1) {
		rgb = edgeUpscalePerf(uv, renderSize, sharp);
	} else {
		rgb = edgeUpscaleQuality(uv, renderSize, scale, sharp);
	}

	rgb = clamp(rgb, 0.0, 1.0);
	return float4(rgb, 1.0);
}

