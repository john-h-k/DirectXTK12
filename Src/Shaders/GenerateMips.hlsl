// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//
// http://go.microsoft.com/fwlink/?LinkID=615561
// http://create.msdn.com/en-US/education/catalog/sample/stock_effects

#include "Structures.fxh"
#include "RootSig.fxh"

SamplerState Sampler       : register(s0);
Texture2D<float4> SrcMip   : register(t0);
RWTexture2D<float4> OutMip : register(u0);

cbuffer MipConstants : register(b0)
{
    float2 InvOutTexelSize; // texel size for OutMip (NOT SrcMip)
    uint SrcMipIndex;
}

float4 Mip(uint2 coord)
{
    float2 uv = (coord.xy + 0.5) * InvOutTexelSize;
    return SrcMip.SampleLevel(Sampler, uv, SrcMipIndex);
}

float3 SRGBToLinear(float3 c)
{
    return c < 0.04045 ? c / 12.92 : pow(abs(c) + 0.055, 2.4);
}

float4 SRGBToLinear(float4 c)
{
    return float4(SRGBToLinear(c.rgb), c.a);
}

float3 LinearToSRGB(float3 c)
{
    return c < 0.003131 ? 12.92 * c : 1.055 * pow(abs(c), 1.0 / 2.4) - 0.055;
}

float4 LinearToSRGB(float4 c)
{
    return float4(LinearToSRGB(c.rgb), c.a);
}

[RootSignature(GenerateMipsRS)]
// Workaround for NVidia bug: some driver versions don't handle SV_DispatchThreadID correctly.
[numthreads(8, 8, 1)]
void main(uint3 Gid : SV_GroupID, uint3 GTid : SV_GroupThreadID)
{
    uint3 DTid = Gid * uint3(8,8,1) + GTid;
    OutMip[DTid.xy] = Mip(DTid.xy);
}

[RootSignature(GenerateMipsRS)]
// Workaround for NVidia bug: some driver versions don't handle SV_DispatchThreadID correctly.
[numthreads(8, 8, 1)]
void DegammaInPlace(uint3 Gid : SV_GroupID, uint3 GTid : SV_GroupThreadID)
{
    uint3 DTid = Gid * uint3(8,8,1) + GTid;
    OutMip[DTid.xy] = SRGBToLinear(OutMip[DTid.xy]);
}

[RootSignature(GenerateMipsRS)]
// Workaround for NVidia bug: some driver versions don't handle SV_DispatchThreadID correctly.
[numthreads(8, 8, 1)]
void RegammaInPlace(uint3 Gid : SV_GroupID, uint3 GTid : SV_GroupThreadID)
{
    uint3 DTid = Gid * uint3(8,8,1) + GTid;
    OutMip[DTid.xy] = LinearToSRGB(OutMip[DTid.xy]);
}
