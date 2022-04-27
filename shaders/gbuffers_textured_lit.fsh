#version 330
#include "shaders.settings"
uniform sampler2D noisetex;

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
in vec4 vShadowCoord;
in vec4 glColor;
in vec3 normal;

void main() {
    vec4 fragColor = texture2D(texture, texCoord) * glColor;
    vec2 light = lightCoord;

    // Compute dot product of normal with light position for lighting uses.
    float lightDot = dot(normalize(shadowLightPosition), normal);
    bool facingAwayFromLight = lightDot < 0.005;

#ifdef SHADOWS
    vec4 shadowCoord = vShadowCoord;
    float bias = (1.0-abs(lightDot)) * SHADOWS_BIAS;
    shadowCoord.z -= bias;
    // Are we within the shadowmap?
    bool inRange = 
        shadowCoord.x >= 0.0 &&
        shadowCoord.x <= 1.0 &&
        shadowCoord.y >= 0.0 &&
        shadowCoord.y <= 1.0;

#ifdef SHADOWS_TRANSPARENCY
    // Transparent shadows are a bit different than normal shadows.
    // First, the opaque shadowmap is checked to see if an opaque block is obscuring the light.
    float shadowLightMultiplier = facingAwayFromLight ? 
                                        (1.0-SHADOWS_STRENGTH) : 
                                        getShadowLightMultiplier(shadowtex1, shadowCoord.xyz);
    // Second, the translucent shadowmap is checked to see if there's a transluscent block obscuring the light.
    float transShadowLightMultiplier = getShadowLightMultiplier(shadowtex0, shadowCoord.xyz);
    vec4 shadowColor = texture2D(shadowcolor0, shadowCoord.xy);
#ifndef SHADOWS_COLOR
    // If we don't want shadow color, average the color to grayscale.
    shadowColor.rgb = vec3((shadowColor.r + shadowColor.g + shadowColor.b)/3.0);
#endif // !SHADOWS_COLOR

    // Mix the transparency of this block into the shadow light color, so it will affect the shadow strength.
    shadowColor.rgb = mix(vec3(1.0), shadowColor.rgb, shadowColor.a);
    float shadowColorBrightness = (shadowColor.r + shadowColor.g + shadowColor.b) / 3.0;
    // We're in shadow if we are facing away from the light, or the skylight will be dimmed.
    bool inShadow = facingAwayFromLight || (inRange && shadowLightMultiplier < 1.0);
    bool inTransShadow = inRange && !inShadow && transShadowLightMultiplier < 1.0;
    fragColor.rgb *= inTransShadow ? shadowColor.rgb : vec3(1.0);
    light.y *= (inShadow) ? shadowLightMultiplier : 1.0;
#else
    // For non-transparent shadows, just check if any block is obscuring the light.
    float shadowLightMultiplier = facingAwayFromLight ? 
                                        (1.0-SHADOWS_STRENGTH) : 
                                        getShadowLightMultiplier(shadowtex0, shadowCoord.xyz);
    bool inShadow = facingAwayFromLight || (inRange && shadowLightMultiplier < 1.0);
    light.y *= (inShadow) ? shadowLightMultiplier : 1.0;
#endif // SHADOWS_TRANSPARENCY
#endif // SHADOWS

    // Diffuse lighting.
    vec3 lightPos = (gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz;
    //light.y *= facingAwayFromLight ? 1.0 : lightDot/maxLightDot;

    // Add lightmap contribution.
    vec3 lightColor = texture2D(lightmap, light).rgb;

    gl_FragData[0] = fragColor * vec4(lightColor, 1.0);
    gl_FragData[1] = vec4(gl_FragCoord.z*gl_FragCoord.w);
    gl_FragData[2] = vec4(normal, 1.0);
}
