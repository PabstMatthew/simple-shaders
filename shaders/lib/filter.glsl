#ifndef FILTER_GLSL
#define FILTER_GLSL

ivec2 normToPixelCoords(sampler2D tex, vec2 coords) {
    vec2 texSize = textureSize(tex, 0).xy;
    return ivec2(coords * texSize);
}

vec3 textureMean(sampler2D tex, ivec2 c0, ivec2 c1) {
    vec3 sum = vec3(0.0);
    for (int x = c0.x; x <= c1.x; x++) {
        for (int y = c0.y; y <= c1.y; y++) {
            sum += texelFetch(tex, ivec2(x,y), 0).xyz;
        }
    }
    float numSamples = (c1.x-c0.x+1)*(c1.y-c0.y+1);
    return sum / numSamples;
}

vec3 weightedTextureMean(sampler2D tex, ivec2 c0, ivec2 c1) {
    vec3 sum = vec3(0.0);
    vec3 maxSum = vec3(0.0);
    float xMid = (c1.x+c0.x+1)/2.0;
    float yMid = (c1.y+c0.y+1)/2.0;
    for (int x = c0.x; x <= c1.x; x++) {
        for (int y = c0.y; y <= c1.y; y++) {
            float weight = 0.5/(abs(xMid-x)*abs(yMid-y));
            maxSum += weight;
            sum += weight*texelFetch(tex, ivec2(x,y), 0).xyz;
        }
    }
    return sum / maxSum;
}

#endif // FILTER_GLSL
