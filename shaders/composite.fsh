#version 330
#include "shaders.settings"
#include "lib/screen.glsl"
#include "lib/light.glsl"

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gnormal;

uniform sampler2D noisetex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform vec3 shadowLightPosition;

in vec2 texCoord;
in vec2 lightCoord;

void main() {
    float depth = texture2D(gdepth, texCoord).r;
    vec3 screenPos = vec3(texCoord, depth);
    vec3 normal = texture2D(gnormal, texCoord).xyz;
    normal = normalize(normal*2.0-1.0);
    vec4 color = texture2D(gcolor, texCoord);

#ifdef SSAO
    // Pass SSAO attenuation into composite (colortex3).
    float ssaoAtten = getSSAO(screenPos, normal, gbufferProjection, gbufferProjectionInverse, gdepth, noisetex);
    gl_FragData[3] = vec4(ssaoAtten);
#endif

    // Pass information to the next composite shader.
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(depth);
    gl_FragData[2] = texture2D(gnormal, texCoord);
}
