#version 330
#include "shaders.settings"
#include "lib/color.glsl"

uniform sampler2D texture;

in vec2 texCoord;
in vec4 glColor;

void main() {
    vec4 color = texture2D(texture, texCoord)*glColor;
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(1.0);
    gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);
    gl_FragData[3] = vec4(0.0, getBrightness(color.rgb), 0.0, 1.0);
}
