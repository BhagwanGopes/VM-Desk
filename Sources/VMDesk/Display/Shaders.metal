#include <metal_stdlib>
using namespace metal;

/// Vertex shader input/output structures
struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

/// Simple vertex shader for fullscreen quad rendering
vertex VertexOut vertexShader(
    uint vertexID [[vertex_id]],
    constant float2 *positions [[buffer(0)]],
    constant float2 *texCoords [[buffer(1)]]
) {
    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = texCoords[vertexID];
    return out;
}

/// Fragment shader for rendering VM framebuffer texture
fragment float4 fragmentShader(
    VertexOut in [[stage_in]],
    texture2d<float> framebufferTexture [[texture(0)]],
    sampler textureSampler [[sampler(0)]]
) {
    // Sample the framebuffer texture
    float4 color = framebufferTexture.sample(textureSampler, in.texCoord);
    return color;
}

/// Fullscreen quad vertices (NDC coordinates)
constant float2 quadVertices[6] = {
    float2(-1.0, -1.0),  // Bottom-left
    float2( 1.0, -1.0),  // Bottom-right
    float2(-1.0,  1.0),  // Top-left
    float2( 1.0, -1.0),  // Bottom-right
    float2( 1.0,  1.0),  // Top-right
    float2(-1.0,  1.0)   // Top-left
};

/// Texture coordinates for fullscreen quad
constant float2 quadTexCoords[6] = {
    float2(0.0, 1.0),  // Bottom-left
    float2(1.0, 1.0),  // Bottom-right
    float2(0.0, 0.0),  // Top-left
    float2(1.0, 1.0),  // Bottom-right
    float2(1.0, 0.0),  // Top-right
    float2(0.0, 0.0)   // Top-left
};
