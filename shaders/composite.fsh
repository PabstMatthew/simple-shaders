#version 330
#include "shaders.settings"

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gnormal;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform vec3 shadowLightPosition;

#include "lib/screen.glsl"

in vec2 texCoord;

void main() {
    float depth = texture2D(gdepth, texCoord).r;
    vec3 screenPos = vec3(texCoord, depth);
    vec3 viewPos = screenToView(screenPos);
    vec3 normal = texture2D(gnormal, texCoord).xyz;

    gl_FragData[0] = texture2D(gcolor, texCoord);
}
