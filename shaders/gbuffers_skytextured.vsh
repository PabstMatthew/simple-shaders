#version 150
#include "shaders.settings"

out vec2 texCoord;
out vec4 glColor;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
    glColor = gl_Color;
}
