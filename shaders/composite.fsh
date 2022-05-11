#version 330
#include "shaders.settings"
#include "lib/screen.glsl"
#include "lib/light.glsl"
#include "lib/color.glsl"

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D composite;

uniform sampler2D noisetex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform vec3 shadowLightPosition;

in vec2 texCoord;
in vec2 lightCoord;

void main() {
    float depth = texture2D(gdepth, texCoord).r;
    vec3 normal = texture2D(gnormal, texCoord).xyz;
    normal = normalize(normal*2.0-1.0);
    vec4 color = texture2D(gcolor, texCoord);

    float ssaoAtten = 0.0;
    float brightness = 0.0;
#ifdef SSAO
    // Pass SSAO attenuation into composite (colortex3).
    ssaoAtten = getSSAO(texCoord, normal, gbufferProjection, gbufferProjectionInverse, gdepth, noisetex);
#endif

#ifdef BLOOM
    brightness = texture2D(composite, texCoord).y;
#endif
    /*
    bool sky = depth == 1.0;
    float transDepth = texture2D(composite, texCoord).x;
    bool trans = transDepth > 0.0;
    vec3 screenReflect = (trans && !sky) ? getReflection(texCoord, normal, gbufferProjection, gbufferProjectionInverse, composite, gdepth) : vec3(-1.0);
    bool inRange = 
        screenReflect.x > 0.0 &&
        screenReflect.x < 1.0 &&
        screenReflect.y > 0.0 &&
        screenReflect.y < 1.0;
    //color = (inRange) ? texture2D(gcolor, screenReflect.xy) : color;
    //color = (inRange) ? vec4(screenReflect, 1.0) : vec4(0.0);
    //color = vec4(screenToView(texCoord, gdepth, gbufferProjectionInverse).xy, 0.0, 1.0);
    //color = (trans) ? vec4(vec3(transDepth), 1.0) : color;
    //color = vec4(vec3(depth), 1.0);
    */

    // Pass information to the next composite shader.
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(depth);
    gl_FragData[2] = texture2D(gnormal, texCoord);
    gl_FragData[3] = vec4(ssaoAtten, brightness, 0.0, 1.0);
}
