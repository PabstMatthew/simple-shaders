
/*
 * screenPos: vector with components in [0,1]
 */
vec3 screenToView(vec3 screenPos) {
    screenPos = screenPos * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * vec4(screenPos, 1.0);
    return viewPos.xyz * viewPos.w;
}

