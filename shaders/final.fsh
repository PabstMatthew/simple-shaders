#version 150

in vec2 texcoord;
uniform sampler2D gcolor;

void main() {
    vec2 point = texcoord;
    vec3 color = texture2D(gcolor, point).rgb;
    
    float c = (color.r + color.g + color.b) / 3.0;
    color.r = c;
    color.g = c;
    color.b = c;

    gl_FragColor = vec4(color, 1.0);
}
