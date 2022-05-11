#version 330
#include "shaders.settings"
#include "lib/screen.glsl"
#include "lib/light.glsl"
#include "lib/filter.glsl"

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D composite;

in vec2 texCoord;

void main() {
    vec4 color = texture2D(gcolor, texCoord);
    vec4 normal = texture2D(gnormal, texCoord);

    ivec2 pixelCoords = normToPixelCoords(composite, texCoord);
    ivec2 filterSize = textureSize(composite, 0).xy;
#ifdef SSAO
    // Filter SSAO attenuation to smooth out the noise.
    ivec2 ssaoFilterSize = filterSize / SSAO_FILTER_SCALE_FACTOR;
    float ssaoAtten = weightedTextureMean(composite, pixelCoords-ssaoFilterSize, pixelCoords+ssaoFilterSize).x;
    float depth = texture2D(gdepth, texCoord).r;
    bool sky = depth == 1.0;
    color.rgb *= (normal.w > 0.1 && !sky) ? ssaoAtten : 1.0;
#endif

#ifdef BLOOM
    // Blur light brightness.
    ivec2 bloomFilterSize = filterSize / BLOOM_FILTER_SCALE_FACTOR;
    float brightness = weightedTextureMean(composite, pixelCoords-bloomFilterSize, pixelCoords+bloomFilterSize).y;
    color.rgb *= (1.0+BLOOM_STRENGTH*brightness);
#endif

    gl_FragData[0] = color;
}
