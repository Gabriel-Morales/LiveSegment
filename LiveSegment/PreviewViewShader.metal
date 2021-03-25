//
//  PreviewViewShader.metal
//  LiveSegment
//
//  Created by Gabriel Morales on 3/16/21.
//

#include <metal_stdlib>
using namespace metal;

struct VertexDataPixel {
    // Mapping of quad to texture
    vector_float4 pixelCoordinates;
};

struct VertexDataTex {
    // normalized positioning of the texture (texture space)
    vector_float2 textureCoordinates;
};

struct FragmentInformation {
    
    // automatically interpolated texture given the vertex data.
    float4 pixelPosition [[ position ]];
    
    float2 textureCoordinate;
};

vertex FragmentInformation vertexPassthroughShader(const device VertexDataPixel *vtx_data [[ buffer(0) ]], const device VertexDataTex *vtx_tex [[ buffer(1) ]], unsigned int vid [[ vertex_id ]]) {
    
    FragmentInformation fragment_info;
    fragment_info.pixelPosition = vtx_data[vid].pixelCoordinates;
    fragment_info.textureCoordinate = vtx_tex[vid].textureCoordinates;
    
    return fragment_info;
}

fragment float4 fragmentPassthroughShader(FragmentInformation frag_info [[stage_in]], texture2d<float> tex [[texture(0)]], sampler s [[ sampler(0) ]]) {
    return tex.sample(s, frag_info.textureCoordinate);
}
