#version 330

precision mediump float;

in mediump vec3 uvw;
in lowp float brightness;

out lowp vec4 color;

layout(std140) uniform ShaderData {
  uniform mat4 mvp;
  vec4 ambientColor;
  uint remap[2048];
};

uniform sampler2DArray samplerBlockTextures;


void main() {
  color = texture(samplerBlockTextures, uvw);
  if (color.a < 0.25) {
    discard;
  }
  color *= vec4(brightness, brightness, brightness, 1.0) * ambientColor;
}
