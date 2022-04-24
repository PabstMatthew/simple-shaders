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
    vec4 shadowLightColor = texture2D(shadowcolor0, shadowCoord.xy);

#ifndef SHADOWS_COLOR
    // If we don't want shadow color, average the color to grayscale.
    shadowLightColor.rgb = vec3((shadowLightColor.r + shadowLightColor.g + shadowLightColor.b)/3.0);
#endif // !SHADOWS_COLOR

    // Mix the transparency of this block into the shadow light color, so it will affect the shadow strength.
    shadowLightColor.rgb = mix(vec3(1.0), shadowLightColor.rgb, shadowLightColor.a);
#else
    // For non-transparent shadows, just check if any block is obscuring the light.
    float shadowLightMultiplier = facingAwayFromLight ? 
                                        (1.0-SHADOWS_STRENGTH) : 
                                        getShadowLightMultiplier(shadowtex0, shadowCoord.xyz);
#endif // SHADOWS_TRANSPARENCY

    // We're in shadow if we are facing away from the light, or the skylight will be dimmed.
    bool inShadow = facingAwayFromLight || (inRange && shadowLightMultiplier < 1.0);
    light.y *= shadowLightMultiplier;

#ifdef SHADOWS_TRANSPARENCY
    // If we're not in full opaque shadow, but we're in translucent shadow, change the shadow's color.
    bool inTransShadow = inRange && 
                         transShadowLightMultiplier < 1.0 &&
                         (!inShadow || transShadowLightMultiplier < shadowLightMultiplier);
    fragColor.rgb *= inTransShadow ? shadowLightColor.rgb : vec3(1.0);
#endif // SHADOWS_TRANSPARENCY
#endif // SHADOWS

    // Diffuse lighting.
    //light.y *= facingAwayFromLight ? 1.0 : lightDot;

    // Add lightmap contribution.
    vec3 lightColor = texture2D(lightmap, light).rgb;

    gl_FragColor = fragColor * vec4(lightColor, 1.0);
}