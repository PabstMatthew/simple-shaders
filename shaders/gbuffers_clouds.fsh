#version 330
#include "shaders.settings"
#include "lib/fog.glsl"

uniform sampler2D texture;
uniform float fogStart;
uniform float fogEnd;
uniform float fogDensity;
uniform vec3 fogColor;

in vec2 texCoord;
in float dist;
in vec4 glColor;

void main() {
#if CLOUDS_TYPE == 1
    // The default Minecraft cloud shader.
    vec4 color = texture2D(texture, texCoord.st)*glColor;
    gl_FragData[0] = linear_fog(color, dist, fogStart, fogEnd, vec4(fogColor, 1.0-fogDensity));
    gl_FragData[1] = vec4(1.0);
    gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);
    gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
#else
    discard;
#endif // CLOUDS_TYPE
}
