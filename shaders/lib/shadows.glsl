
float distortFactor(vec2 v) {
    float dist = abs(v.x) + abs(v.y);
    return SHADOWS_DISTORTION_MAGNITUDE * dist + SHADOWS_MIN_DISTORTION_FACTOR;
}

vec4 distortShadowCoord(vec4 v) {
    vec4 res = v;
    float distortion = distortFactor(v.xy);
    res.xy /= distortion;
    return res;
}

vec4 distortAndNormalizeShadowCoord(vec4 v) {
    vec4 res = v;
    res /= res.w;
    float distortion = distortFactor(v.xy);
    res.xy /= distortion;
    res.xyz = res.xyz * 0.5 + 0.5;
    res.z -= SHADOWS_BIAS * distortion;
    return res;
}

float pcss(sampler2D shadowmap, vec3 coords) {
    const float texelSize = 1.0 / shadowMapResolution;
    const float bias = (SHADOWS_SAMPLES % 2 == 0) ? 0.5 : 0.0;
    const float lo = -SHADOWS_SAMPLES/2.0 + bias;
    const float hi = lo + SHADOWS_SAMPLES - 1.0;
    int inShadow = 0;
    for (float x = lo; x <= hi; x += 1.0) {
        for (float y = lo; y <= hi; y += 1.0) {
            vec2 offCoords = vec2(coords.x + x*texelSize, coords.y + y*texelSize);
            float depth = texture2D(shadowmap, offCoords).r;
            inShadow += (depth < coords.z) ? 1 : 0;
        }
    }
    float totalSamples = SHADOWS_SAMPLES * SHADOWS_SAMPLES;
    float strength = inShadow*1.0/totalSamples;
    float lightMultiplier = (1.0-(SHADOWS_STRENGTH * strength));
    return (inShadow > 0) ? lightMultiplier : 1.0;
}

float pcf(sampler2D shadowmap, vec3 coords) {
    const float texelSize = 1.0 / shadowMapResolution;
    const float bias = (SHADOWS_SAMPLES % 2 == 0) ? 0.5 : 0.0;
    const float lo = -SHADOWS_SAMPLES/2.0 + bias;
    const float hi = lo + SHADOWS_SAMPLES - 1.0;
    float sum = 0.0;
    for (float x = lo; x <= hi; x += 1.0) {
        for (float y = lo; y <= hi; y += 1.0) {
            vec2 offCoords = vec2(coords.x + x*texelSize, coords.y + y*texelSize);
            float depth = texture2D(shadowmap, offCoords).r;
            sum += depth;
        }
    }
    float totalSamples = SHADOWS_SAMPLES * SHADOWS_SAMPLES;
    float depth = sum / totalSamples;
    return (depth < coords.z) ? (1.0-SHADOWS_STRENGTH) : 1.0;
}

float getShadowLightMultiplier(sampler2D shadowmap, vec3 coords) {
#if SHADOWS_TYPE == 1
    return pcf(shadowmap, coords);
#elif SHADOWS_TYPE == 2
    return pcss(shadowmap, coords);
#else
    float depth = texture2D(shadowmap, coords.xy).r;
    return (depth < coords.z) ? 1.0-SHADOWS_STRENGTH : 1.0;
#endif // SHADOWS_TYPE
}

