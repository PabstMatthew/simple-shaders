#version 150
#include "shaders.settings"

uniform sampler2D texture;

in vec2 texCoord;
in vec4 glColor;

void main() {
#ifdef SHADOWS
    gl_FragColor = texture2D(texture, texCoord) * glColor;
#endif // SHADOWS
}
