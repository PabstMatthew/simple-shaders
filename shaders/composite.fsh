#version 150
#include "shaders.settings"

uniform sampler2D gcolor;
uniform sampler2D shadowcolor0;

in vec2 texCoord;

void main() {
    gl_FragColor = texture2D(gcolor, texCoord);
}
