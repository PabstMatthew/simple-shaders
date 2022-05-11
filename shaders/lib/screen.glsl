#ifndef SCREEN_GLSL
#define SCREEN_GLSL

#define diagonal3(mat) vec3((mat)[0].x, (mat)[1].y, (mat)[2].z)
#define projMAD(mat, v) (diagonal3(mat) * (v) + (mat)[3].xyz)

uniform float near;

/*
 * screenPos: screen-space position in UV-coordinates
 */
vec3 screenToView(vec2 screenPos, sampler2D depthTex, mat4 projectionInverse) {
    vec3 screen = vec3(screenPos, -texture2D(depthTex, screenPos).r);
    screen = screen * 2.0 - 1.0;
    vec4 viewPos = projectionInverse * vec4(screen, 1.0);
    return viewPos.xyz / viewPos.w;
}

/*
 * viewPos: view-space position in NDC
 */
vec3 viewToScreen(vec3 viewPos, mat4 projection) {
    vec4 screenPos = projection * vec4(viewPos, 1.0);
    screenPos.xyz /= screenPos.w;
    screenPos.xyz = screenPos.xyz * 0.5 + 0.5;
    screenPos.z *= -1.0;
    return screenPos.xyz;
    /*
    return (diagonal3(projection) * viewPos + projection[3].xyz) / -viewPos.z * 0.5 + 0.5;
    */
}

#endif // SCREEN_GLSL
