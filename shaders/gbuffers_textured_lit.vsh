#version 330
#include "shaders.settings"
uniform sampler2D noisetex;

#include "/lib/shadows.glsl"

uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform mat3 normalMatrix;

out vec2 texCoord;
out vec2 lightCoord;
out vec4 vShadowCoord;
out vec4 glColor;
out vec3 normal;
out float depth;

void main() {
    texCoord = (gl_TextureMatrix[0]*gl_MultiTexCoord0).st;
    lightCoord = (gl_TextureMatrix[1]*gl_MultiTexCoord1).st;
    glColor = gl_Color;
    normal = normalize(normalMatrix * gl_Normal);
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;

#ifdef SHADOWS
    // Calculate position of shadow relative to the main light.
    vShadowCoord = shadowProjection * (shadowModelView * gl_Vertex);
    vShadowCoord = distortAndNormalizeShadowCoord(vShadowCoord);
#endif
}
