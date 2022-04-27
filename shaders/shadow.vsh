#version 330
#include "shaders.settings"
#include "/lib/shadows.glsl"

attribute vec4 mc_Entity;

out vec2 texCoord;
out vec4 glColor;

void main() {
#ifdef SHADOWS
    glColor = gl_Color;
    texCoord = (gl_TextureMatrix[0]*gl_MultiTexCoord0).st;

    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    gl_Position = distortShadowCoord(gl_Position);
#endif // SHADOWS
}
