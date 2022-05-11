#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL
#include "/lib/filter.glsl"
#include "/lib/light.glsl"

/*
 * Gets the factor to distort shadows by.
 * Here, I'm using distance, so that closer shadows will be 
 * rendered with higher resolution to reduce perspective aliasing.
 */
float distortFactor(vec2 v) {
    float dist = length(v);
    return SHADOWS_DISTORTION_MAGNITUDE * dist + SHADOWS_MIN_DISTORTION_FACTOR;
}

/*
 * Applies the shadow perspective distortion. Used in the shadowmap rendering pass.
 */
vec4 distortShadowCoord(vec4 v) {
    vec4 res = v;
    float distortion = distortFactor(v.xy);
    res.xy /= distortion;
    res.z *= 0.5;
    return res;
}

/*
 * Percentage-closer filtering shadows.
 * Samples points within a circle around `coords` to blur shadows.
 * If SHADOWS_TYPE==2, will use these samples to soften shadows.
 *  shadowmap: a depthmap.
 *  coords: shadow coords in NDC. x and y are used to index the shadowmap, and z is used for the depth test.
 */
float pcf(sampler2D shadowmap, vec3 coords) {
    // Shrink the sample radius as distance from the origin increases.
    // This accounts for the shadow distortion, to avoid bias issues further away.
    float minSmooth = 0.001;
    float maxSmooth = 64.0;
    float scale = max(0.04, dot(coords.xy*2.0-1.0, coords.xy*2.0-1.0));
    float radius = maxSmooth / (1.0+1.0/minSmooth*scale) / shadowMapResolution;
    // Check samples.
    float inShadow = 0.0;
    float depthSum = 0.0;
    for (float i = 0.0001; i < 2*PI; i += (2.0*PI)/SHADOWS_SAMPLES) {
        vec2 offCoords = vec2(coords.x + radius*cos(i), coords.y + radius*sin(i));
        float depth = texture2D(shadowmap, offCoords).r;
#if SHADOWS_TYPE == 2
        inShadow += (depth < coords.z) ? 1.0 : 0.0;
#else
        depthSum += depth;
#endif
    }

#if SHADOWS_TYPE == 2
    // For soft shadows, calculate the shadow strength based on how many samples were in shadows.
    float strength = inShadow / SHADOWS_SAMPLES;
    float lightMultiplier = (1.0-(SHADOWS_STRENGTH * strength));
    return lightMultiplier;
#else
    float depth = depthSum / SHADOWS_SAMPLES;
    return (depth < coords.z) ? SHADOWS_MAX_ATTEN : 1.0;
#endif
}

float getShadowLightMultiplier(sampler2D shadowmap, vec3 coords) {
#if SHADOWS_TYPE == 1 || SHADOWS_TYPE == 2
    return pcf(shadowmap, coords);
#else
    float depth = texture2D(shadowmap, coords.xy).r;
    return (depth < coords.z) ? SHADOWS_MAX_ATTEN : 1.0;
#endif // SHADOWS_TYPE
}

/*
 * Get the factor light should be multiplied to account for shadows.
 * Also takes diffuse lighting into account.
 */
vec3 getShadowAttenuation(vec4 shadowCoord, float lightDot,
        sampler2D opaqueDepthMap, sampler2D transDepthMap, sampler2D shadowColorMap) {

    bool facingAwayFromLight = lightDot < 0.01;
    float diffuseAttenuation = getDiffuseAttenuation(lightDot);
    // Increases shadow bias for surfaces that are grazed by the light.
    float bias = max((1.0-lightDot) * SHADOWS_BIAS_MAX, SHADOWS_BIAS_MIN);
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
    float opaqueDepth = texture2D(opaqueDepthMap, shadowCoord.xy).r;
    float shadowLightMultiplier = facingAwayFromLight ? 
                                        SHADOWS_MAX_ATTEN : 
                                        getShadowLightMultiplier(opaqueDepthMap, shadowCoord.xyz);
    // We're in shadow if we are facing away from the light, or the skylight will be dimmed.
    bool inOpaqueShadow = facingAwayFromLight || (inRange && opaqueDepth < shadowCoord.z);
#if SHADOWS_TYPE == 1
    inOpaqueShadow = inOpaqueShadow || (inRange && shadowLightMultiplier < 1.0);
#endif
    // Second, the translucent shadowmap is checked to see if there's a transluscent block obscuring the light.
    float transDepth = texture2D(transDepthMap, shadowCoord.xy).r;
    bool inTransShadow = inRange && transDepth < shadowCoord.z;
    vec4 shadowColor = texture2D(shadowColorMap, shadowCoord.xy);

#if SHADOWS_TYPE == 2
    // If smooth shadows are in use, prefer translucent shadows over weak shadows.
    inOpaqueShadow = inOpaqueShadow && 
        !(inTransShadow && shadowColor.a != 1.0 && shadowLightMultiplier > SHADOWS_MAX_ATTEN);
#endif

    // Don't do translucent shadows on top of opaque shadows.
    inTransShadow = inTransShadow && !inOpaqueShadow;
    if (inOpaqueShadow) {
        return vec3(shadowLightMultiplier*diffuseAttenuation);
    } else if (inTransShadow) {
#ifndef SHADOWS_COLOR
        // If we don't want shadow color, average the color to grayscale.
        shadowColor.rgb = vec3((shadowColor.r + shadowColor.g + shadowColor.b)/3.0);
#endif // !SHADOWS_COLOR
        // Mix the transparency of this block into the shadow light color, so it will affect the shadow strength.
        shadowColor.rgb = mix(vec3(1.0), shadowColor.rgb, shadowColor.a)*diffuseAttenuation;
        return shadowColor.rgb; 
    } else {
        return vec3(diffuseAttenuation);
    }
#else // SHADOWS_TRANSPARENCY
    // For non-transparent shadows, just check if any block is obscuring the light.
    float shadowLightMultiplier = facingAwayFromLight ? 
                                        SHADOWS_MAX_ATTEN :
                                        getShadowLightMultiplier(transDepthMap, shadowCoord.xyz);
    bool inShadow = facingAwayFromLight || (inRange && shadowLightMultiplier < 1.0);
    return (inShadow) ? vec3(shadowLightMultiplier) : vec3(diffuseAttenuation);
#endif // !SHADOWS_TRANSPARENCY
}

#endif // SHADOWS_GLSL
