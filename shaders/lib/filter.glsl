#ifndef FILTER_GLSL
#define FILTER_GLSL

ivec2 normToPixelCoords(sampler2D tex, vec2 coords) {
    vec2 texSize = textureSize(tex, 0).xy;
    return ivec2(coords * texSize);
}

float textureMean(sampler2D tex, ivec2 c0, ivec2 c1) {
    vec2 texSize = vec2(1.0)/textureSize(tex, 0).xy;
    float sum = 0.0;
    for (int x = c0.x; x <= c1.x; x++) {
        for (int y = c0.y; y <= c1.y; y++) {
            sum += texelFetch(tex, ivec2(x,y), 0).r;
            /*
            vec2 c = vec2(x*texSize.x, y*texSize.y);
            sum += texture2D(tex, c).r;
            */
        }
    }
    float numSamples = (c1.x-c0.x+1)*(c1.y-c0.y+1);
    return sum / numSamples;
}

#endif // FILTER_GLSL
