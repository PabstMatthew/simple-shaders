#version 150
#include "shaders.settings"

out vec2 texCoord;

void main() {
    texCoord = (gl_TextureMatrix[0]*gl_MultiTexCoord0).st;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
