#ifndef FILTER_GLSL
#define FILTER_GLSL

ivec2 normToPixelCoords(sampler2D tex, vec2 coords) {
    vec2 texSize = textureSize(tex, 0).xy;
    return ivec2(coords * texSize);
}

float textureMean(sampler2D tex, ivec2 c0, ivec2 c1) {
    float sum = 0.0;
    for (int x = c0.x; x <= c1.x; x++) {
        for (int y = c0.y; y <= c1.y; y++) {
            sum += texelFetch(tex, ivec2(x,y), 0).r;
        }
    }
    float numSamples = (c1.x-c0.x+1)*(c1.y-c0.y+1);
    return sum / numSamples;
}

float weightedTextureMean(sampler2D tex, ivec2 c0, ivec2 c1) {
    float sum = 0.0;
    float maxSum = 0.0;
    float xMid = (c1.x+c0.x+1)/2.0;
    float yMid = (c1.y+c0.y+1)/2.0;
    int yLen = c1.x-c0.x+1;
    for (int x = c0.x; x <= c1.x; x++) {
        for (int y = c0.y; y <= c1.y; y++) {
            float weight = 0.5/abs(xMid-x)*abs(yMid-y);
            maxSum += weight;
            sum += weight*texelFetch(tex, ivec2(x,y), 0).r;
        }
    }
    float numSamples = (c1.x-c0.x+1)*(c1.y-c0.y+1);
    return sum / maxSum;
}

#endif // FILTER_GLSL
