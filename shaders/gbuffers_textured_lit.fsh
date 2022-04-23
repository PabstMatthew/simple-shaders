#version 150
#include "shaders.settings"
#include "lib/shadows.glsl"

uniform sampler2D texture;
uniform sampler2D lightmap;

uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

uniform vec3 shadowLightPosition;

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
    bool facingAwayFromLight = lightDot < 0.0;

#ifdef SHADOWS
    // Check if we're in shadow.
    bool inRange = 
        shadowCoord.x >= 0.0 &&
        shadowCoord.x <= 1.0 &&
        shadowCoord.y >= 0.0 &&
        shadowCoord.y <= 1.0;
#ifdef SHADOWS_COLOR
    float shadowLightMultiplier = (facingAwayFromLight) ? (1.0-SHADOWS_STRENGTH) : getShadowLightMultiplier(shadowtex1, shadowCoord.xyz);
    float transShadowLightMultiplier = getShadowLightMultiplier(shadowtex0, shadowCoord.xyz);
    vec4 shadowLightColor = texture2D(shadowcolor0, shadowCoord.xy);
    shadowLightColor.rgb = mix(vec3(1.0), shadowLightColor.rgb, shadowLightColor.a);
#else
    float shadowLightMultiplier = (facingAwayFromLight) ? (1.0-SHADOWS_STRENGTH) : getShadowLightMultiplier(shadowtex0, shadowCoord.xyz);
#endif // SHADOWS_COLOR
    bool inShadow = facingAwayFromLight || (inRange && shadowLightMultiplier < 1.0);
    light.y *= shadowLightMultiplier;
#ifdef SHADOWS_COLOR
    bool inTransShadow = !inShadow && inRange && transShadowLightMultiplier < 1.0;
    fragColor.rgb *= inTransShadow ? shadowLightColor.rgb : vec3(1.0);
#endif // SHADOWS_COLOR
#endif // SHADOWS

    // Diffuse lighting.
    //light.y *= facingAwayFromLight ? 1.0 : lightDot;

    // Add lightmap contribution.
    vec3 lightColor = texture2D(lightmap, light).rgb;

    gl_FragColor = fragColor * vec4(lightColor, 1.0);
}
