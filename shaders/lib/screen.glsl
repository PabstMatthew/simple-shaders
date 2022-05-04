#ifndef SCREEN_GLSL
#define SCREEN_GLSL

/*
 * screenPos: screen-space position in UV-coordinates
 */
vec3 screenToView(vec3 screenPos, mat4 gbufferProjectionInverse) {
    screenPos.z *= -1.0;
    screenPos = screenPos * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * vec4(screenPos, 1.0);
    return viewPos.xyz / viewPos.w;
}

/*
 * viewPos: view-space position in NDC
 */
vec3 viewToScreen(vec3 viewPos, mat4 gbufferProjection) {
    vec4 screenPos = gbufferProjection * vec4(viewPos, 1.0);
    screenPos.xyz /= screenPos.w;
    screenPos.z *= -1.0;
    return screenPos.xyz * 0.5 + 0.5;
}

#endif // SCREEN_GLSL
