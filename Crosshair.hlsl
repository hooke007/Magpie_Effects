//!MAGPIE EFFECT
//!VERSION 4

//!PARAMETER
//!LABEL Red
//!DEFAULT 0
//!MIN 0
//!MAX 255
//!STEP 1
int red;

//!PARAMETER
//!LABEL Green
//!DEFAULT 255
//!MIN 0
//!MAX 255
//!STEP 1
int green;

//!PARAMETER
//!LABEL Blue
//!DEFAULT 0
//!MIN 0
//!MAX 255
//!STEP 1
int blue;

//!PARAMETER
//!LABEL Opacity
//!DEFAULT 255
//!MIN 0
//!MAX 255
//!STEP 1
int opacity;

//!PARAMETER
//!LABEL Size
//!DEFAULT 24
//!MIN 1
//!MAX 100
//!STEP 1
float size;

//!PARAMETER
//!LABEL Thickness
//!DEFAULT 5
//!MIN 0.5
//!MAX 20
//!STEP 0.5
float thickness;

//!PARAMETER
//!LABEL Center Gap
//!DEFAULT 4
//!MIN 0
//!MAX 50
//!STEP 1
float centerGap;

//!PARAMETER
//!LABEL Shape
//!DEFAULT 0
//!MIN 0
//!MAX 4
//!STEP 1
int shape;

//!TEXTURE
Texture2D INPUT;

//!TEXTURE
Texture2D OUTPUT;

//!SAMPLER
//!FILTER LINEAR
SamplerState sam;

//!PASS 1
//!STYLE PS
//!IN INPUT
//!OUT OUTPUT

float SdBox(float2 p, float2 halfSize) {
	float2 d = abs(p) - halfSize;
	return length(max(d, 0)) + min(max(d.x, d.y), 0);
}

float SdCross(float2 p, float armSize, float gap, float lineThickness) {
	float halfArm = max((armSize - gap) * 0.5, 0);
	float armCenter = (armSize + gap) * 0.5;
	float2 halfSize = float2(halfArm, lineThickness * 0.5);
	float d = SdBox(p - float2(armCenter, 0), halfSize);
	d = min(d, SdBox(p - float2(-armCenter, 0), halfSize));
	d = min(d, SdBox(p - float2(0, armCenter), halfSize.yx));
	d = min(d, SdBox(p - float2(0, -armCenter), halfSize.yx));
	return d;
}

float GetShapeDistance(float2 p) {
	if (shape == 0) {
		return SdCross(p, size, min(centerGap, size), thickness);
	}
	if (shape == 1) {
		const float INV_SQRT2 = 0.70710678118;
		float2 rotated = float2(p.x + p.y, p.y - p.x) * INV_SQRT2;
		return SdCross(rotated, size, min(centerGap, size), thickness);
	}
	if (shape == 2) {
		return length(p) - size;
	}
	if (shape == 3) {
		return abs(length(p) - size) - thickness * 0.5;
	}
	// Shape 4: square outline.
	return abs(max(abs(p.x), abs(p.y)) - size) - thickness * 0.5;
}

float4 Pass1(float2 pos) {
	float2 outputSize = float2(GetOutputSize());
	float2 pixelPos = pos / GetOutputPt();
	float2 p = pixelPos - outputSize * 0.5;
	float shapeDistance = GetShapeDistance(p);
	// Derivative intrinsics such as fwidth are unavailable in Magpie's cs_5_0 path.
	float aa = 0.5;
	float coverage = 1 - smoothstep(-aa, aa, shapeDistance);

	float4 color = INPUT.SampleLevel(sam, pos, 0);
	float3 crosshairColor = float3(red, green, blue) / 255.0;
	float alpha = (opacity / 255.0) * coverage;
	color.rgb = lerp(color.rgb, crosshairColor, alpha);
	return color;
}

