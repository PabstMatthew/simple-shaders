#version 150
#include "shaders.settings"

uniform sampler2D texture;

in vec2 texCoord;
in vec4 glColor;

void main() {
    vec4 color = texture2D(texture, texCoord);
    gl_FragColor = color;
}