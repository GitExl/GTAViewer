#version 330

precision mediump float;

in mediump vec2 uv;
in lowp float opacity;
in lowp float darken;

out lowp vec4 color;

layout(std140) uniform ShaderData {
  uniform mat4 vp;
  vec4 ambientColor;
  uniform mat4 matrices[224];
};

uniform sampler2D samplerSpriteTexture;


void main() {
  color = texture(samplerSpriteTexture, uv);
  if (color.a < 0.25) {
    discard;
  }
  color *= vec4(darken, darken, darken, opacity);
  color *= ambientColor;
}
