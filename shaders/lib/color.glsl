
vec4 RGB2YCoCg(vec4 c) {
    return vec4(0.25*c.r+0.5*c.g+0.25*c.b, 0.5*c.r-0.5*c.b +0.5, -0.25*c.r+0.5*c.g-0.25*c.b +0.5, c.a);
}

