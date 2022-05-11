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
float getSSAO(vec2 screenCoords, vec3 normal, 
        mat4 projection, mat4 projectionInverse, 
        sampler2D depthTex, sampler2D noiseTex) {

    vec3 viewCoords = screenToView(screenCoords, depthTex, projectionInverse);
    vec2 seed = screenCoords;
    vec3 noise = texture2D(noiseTex, seed).xyz;
    noise = noise * 2.0 - 1.0;
    // Calculate the TBN matrix used to scale random noise vectors;
    vec3 tangent = normalize(noise - normal * dot(noise, normal));
    vec3 binormal = cross(normal, tangent);
    mat3 tbn = mat3(tangent, binormal, normal);
    // Use a larger sampling radius for points that are close to the camera.
    float depth = texture2D(depthTex, screenCoords).r;
    float radius = mix(SSAO_RADIUS_MIN, SSAO_RADIUS_MAX, depth);
    // Use a smaller bias for surfaces glanced by the view direction.
    float normalDotEye = abs(normal.z);
    float bias = mix(SSAO_BIAS_MIN, SSAO_BIAS_MAX, depth);
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
        float offDepth = texture2D(depthTex, offCoordsScreen.xy).r;
        // Check if this random point occludes the original one.
        // If so, scale the contribution by the depth difference.
        float occluded = (offDepth > 0.0 && offDepth < 0.9 && offDepth-bias > depth) ? 1.0 : 0.0;
        float intensity = smoothstep(1.0, 0.0, abs(offDepth-depth));
        occluded *= intensity; 
        occlusion += occluded;
    }
    occlusion /= SSAO_SAMPLES;
    occlusion = occlusion*SSAO_CONTRAST;
    occlusion = clamp(occlusion, 0.0, 1.0);
    return 1.0 - SHADOWS_STRENGTH*occlusion;
}

vec3 getReflection(vec2 screenCoords, vec3 normal,
        mat4 projection, mat4 projectionInverse,
        sampler2D transDepthTex, sampler2D opaqueDepthTex) {
    float maxDistance = 100.0;
    float resolution = 1.0;
    float thickness = 0.1;
    vec2 texSize = textureSize(transDepthTex, 0).xy;

    // viewspace normal is correct
    vec3 viewCoords = screenToView(screenCoords, transDepthTex, projectionInverse);
    vec3 reflection = normalize(reflect(viewCoords, normal));
    /*
    if (reflection.z >= 0.0) {
        // Reflected ray is headed back towards the camera, so it's unlikely to hit anything.
        return vec3(0.0);
    }
    */

    // Beginning and ending view coordinates of the ray.
    vec3 startView = viewCoords;
    vec3 endView = viewCoords + reflection*maxDistance;

    // Beginning and ending screen coordinates of the ray.
    vec3 startScreen = viewToScreen(startView, projection);
         startScreen.xy *= texSize;
    vec3 endScreen = viewToScreen(endView, projection);
         endScreen.xy *= texSize;

    // Vector from start to end screen coordinates.
    float dX = endScreen.x-startScreen.x;
    float dY = endScreen.y-startScreen.y;

    // Computes a delta s.t. the larger coordinate will increment by one screen pixel per iteration.
    float useX = abs(dX) >= abs(dY) ? 1.0 : 0.0;
    float delta = mix(abs(dY), abs(dX), useX) * clamp(resolution, 0.0, 1.0);

    // Ray march from the starting position.
    vec2 curScreen = startScreen.xy;
    vec2 increment = vec2(dX, dY) / max(delta, 0.001);
    for (int i = 0; i < min(int(delta), 100000); i++) {
        curScreen += increment;
        bool inRange = curScreen.x > 0.0 &&
                       curScreen.x < texSize.x &&
                       curScreen.y > 0.0 &&
                       curScreen.y < texSize.y;
        if (!inRange) {
            return vec3(-1.0);
        }
        vec2 uv = curScreen / texSize;
        float geometryDepth = texture2D(opaqueDepthTex, uv).x;
        float t =
            mix((curScreen.y - startScreen.y) / dY,
                (curScreen.x - startScreen.x) / dX, 
                useX
            );
        t = clamp(t, 0.0, 1.0);
        float screenDepth = startView.z*endView.z / mix(endView.z, startView.z, t);
        float diff = geometryDepth - screenDepth;
        if (diff > 0.0 && diff < thickness) {
            return vec3(uv, 0.0);
        }
    }
    return vec3(-1.0);
}

#endif // LIGHT_GLSL
