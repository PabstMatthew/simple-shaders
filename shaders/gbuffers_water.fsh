#version 330
#include "shaders.settings"
#include "/lib/shadows.glsl"
#include "/lib/light.glsl"

uniform sampler2D texture;
uniform sampler2D lightmap;

uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

uniform vec3 shadowLightPosition;

uniform mat4 gbufferModelViewInverse;

in vec2 texCoord;
in vec2 lightCoord;
in vec4 shadowCoord;
in vec4 glColor;
in vec3 normal;

void main() {
    vec4 fragColor = texture2D(texture, texCoord) * glColor;
    vec2 light = lightCoord;

    // Compute dot product of normal with light position for lighting uses.
    float lightDot = dot(normalize(shadowLightPosition), normal);
    lightDot = clamp(lightDot, 0.0, 1.0);

#ifdef SHADOWS
    fragColor.rgb *= getShadowAttenuation(shadowCoord, lightDot, shadowtex1, shadowtex0, shadowcolor0);
#else // SHADOWS
    // Diffuse lighting.
    light.y *= getDiffuseAttenuation(lightDot);
#endif // !SHADOWS

    // Add lightmap contribution.
    vec3 lightColor = texture2D(lightmap, light).rgb;
    fragColor.rgb *= lightColor;

    gl_FragData[0] = fragColor;
    gl_FragData[1] = vec4(gl_FragCoord.z*gl_FragCoord.w);
    gl_FragData[2] = vec4(normalize(normal*0.5+0.5), 0.0);
}
