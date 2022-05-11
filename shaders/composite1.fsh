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

#ifdef SSAO
    // Filter SSAO attenuation to smooth out the noise.
    int filterSize = textureSize(composite, 0).y / SSAO_FILTER_SCALE_FACTOR;
    ivec2 pixelCoords = normToPixelCoords(composite, texCoord);
    float ssaoAtten = weightedTextureMean(composite, pixelCoords-filterSize, pixelCoords+filterSize);
    float depth = texture2D(gdepth, texCoord).r;
    bool sky = depth == 1.0;
    color.rgb *= (normal.w > 0.1 && !sky) ? ssaoAtten : 1.0;
#endif

    gl_FragData[0] = color;
}
