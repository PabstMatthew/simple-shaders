#ifndef LIGHT_GLSL
#define LIGHT_GLSL
#include "/lib/screen.glsl"

// The maximum value of the dot product between the main light and an upward-facing normal.
// This is used to normalize the brightness of the main light, 
// so that light is not decreased at noon.
const float maxLightDot = cos(sunPathRotation/180*3.14);

float getDiffuseAttenuation(float lightDot) {
    return 1.0 - (SHADOWS_STRENGTH*(1.0 - lightDot/maxLightDot));
}

/*
 * Computes SSAO attenuation by randomly sampling a hemisphere around a point.
 *  screenCoords: position of a point on the screen in UV coordinates.
 *                depth is stored in the z-component.
 *  normal: the normal vector at this point in view-space coordinates
 *  projection: the gbuffer projection matrix.
 *  projectionInverse: the gbuffer projection inverse matrix.
 *  depthTex: a texture containing the depth of points on the screen.
 *  noiseTex: a texture containing random noise.
 */
float getSSAO(vec3 screenCoords, vec3 normal, 
        mat4 projection, mat4 projectionInverse, 
        sampler2D depthTex, sampler2D noiseTex) {

    vec3 viewCoords = screenToView(screenCoords, projectionInverse);
    vec2 seed = screenCoords.xy;
    vec3 noise = vec3(texture2D(noiseTex, seed).x);
    noise = noise* 2.0 - 1.0;
    // Calculate the TBN matrix used to scale random noise vectors;
    vec3 tangent = normalize(noise - normal * dot(noise, normal));
    vec3 binormal = cross(normal, tangent);
    mat3 tbn = mat3(tangent, binormal, normal);
    // Use a larger sampling radius for points that are close to the camera.
    float radius = max(SSAO_RADIUS_MIN, SSAO_RADIUS_MAX*screenCoords.z);
    // Use a smaller bias for surfaces glanced by the view direction.
    float normalDotEye = abs(normal.z);
    float bias = max(SSAO_BIAS_MIN, SSAO_BIAS_MAX*screenCoords.z);
    // Take random samples in a hemisphere around this point.
    float occlusion = 0.0;
    for (int i = 0; i < SSAO_SAMPLES; i++) {
        // Come up with a random noise vector.
        noise = vec3(texture2D(noiseTex, seed).x);
        noise.xy = noise.xy * 2.0 - 1.0;
        noise *= radius;
        seed += noise.xy;
        // Find the corresponding point in screen-space.
        vec3 offCoords = viewCoords + tbn*noise; 
        vec3 offCoordsScreen = viewToScreen(offCoords, projection);
        offCoordsScreen.z = texture2D(depthTex, offCoordsScreen.xy).r;
        // Check if this random point occludes the original one.
        // If so, scale the contribution by the depth difference.
        float occluded = (offCoordsScreen.z > 0.0 && offCoordsScreen.z-bias > screenCoords.z) ? 1.0 : 0.0;
        float intensity = smoothstep(1.0, 0.0, abs(screenCoords.z-offCoordsScreen.z));
        occluded *= intensity; 
        occlusion += occluded;
    }
    occlusion /= SSAO_SAMPLES;
    occlusion = occlusion*SSAO_CONTRAST;
    occlusion = clamp(occlusion, 0.0, 1.0);
    return 1.0 - SHADOWS_STRENGTH*occlusion;
}

#endif // LIGHT_GLSL
