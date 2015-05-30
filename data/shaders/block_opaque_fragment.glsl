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
  vec4 sample = texture(samplerBlockTextures, uvw);
  color = vec4(sample.r, sample.g, sample.b, 1.0) * vec4(brightness, brightness, brightness, 1.0) * ambientColor;
}
