/*
 * Copyright (c) 2017, NVIDIA CORPORATION. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include "cudaNormalize.h"
#include "cudaVector.h"


// gpuNormalize
template <typename T>
__global__ void gpuNormalize( T* input, T* output, int width, int height, float scaling_factor, float max_input )
{
	const int x = blockIdx.x * blockDim.x + threadIdx.x;
	const int y = blockIdx.y * blockDim.y + threadIdx.y;

	if( x >= width || y >= height )
		return;

	const T px = input[ y * width + x ];

	output[y*width+x] = make_vec<T>(px.x * scaling_factor,
							  px.y * scaling_factor,
							  px.z * scaling_factor,
							  alpha(px, max_input) * scaling_factor);
}

template<typename T>
cudaError_t launchNormalizeRGB( T* input, const float2& input_range,
						  T* output, const float2& output_range,
						  size_t  width,  size_t height )
{
	if( !input || !output )
		return cudaErrorInvalidDevicePointer;

	if( width == 0 || height == 0  )
		return cudaErrorInvalidValue;

	const float multiplier = output_range.y / input_range.y;

	// launch kernel
	const dim3 blockDim(32,8);
	const dim3 gridDim(iDivUp(width,blockDim.x), iDivUp(height,blockDim.y));

	gpuNormalize<T><<<gridDim, blockDim>>>(input, output, width, height, multiplier, input_range.y);

	return CUDA(cudaGetLastError());
}


// cudaNormalizeRGB
cudaError_t cudaNormalizeRGB( float3* input, const float2& input_range,
						float3* output, const float2& output_range,
						size_t  width,  size_t height )
{
	return launchNormalizeRGB<float3>(input, input_range, output, output_range, width, height);
}


// cudaNormalizeRGBA
cudaError_t cudaNormalizeRGBA( float4* input, const float2& input_range,
						 float4* output, const float2& output_range,
						 size_t  width,  size_t height )
{
	return launchNormalizeRGB<float4>(input, input_range, output, output_range, width, height);
}





