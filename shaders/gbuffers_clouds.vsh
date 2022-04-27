#version 330
#include "shaders.settings"
#include "lib/fog.glsl"

uniform int fogMode;

out vec2 texCoord;
out vec4 glColor;
out float dist;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
#if CLOUDS_TYPE == 1
    texCoord.st = (gl_TextureMatrix[0]*gl_MultiTexCoord0).st;
    glColor = gl_Color;
    dist = fog_distance(gl_ModelViewMatrix, gl_Vertex.xyz, fogMode);
#endif // CLOUDS_TYPE
}
