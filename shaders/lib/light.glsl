#ifndef LIGHT_GLSL
#define LIGHT_GLSL

// The maximum value of the dot product between the main light and an upward-facing normal.
// This is used to normalize the brightness of the main light, 
// so that light is not decreased at noon.
const float maxLightDot = cos(sunPathRotation/180*3.14);

float getDiffuseAttenuation(float lightDot) {
    return 1.0 - (SHADOWS_STRENGTH*(1.0 - lightDot/maxLightDot));
}

#endif // LIGHT_GLSL
