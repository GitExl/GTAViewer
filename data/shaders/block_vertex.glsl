#version 330

precision mediump float;

layout(location = 0) in vec3 vertexPos;
layout(location = 1) in vec2 vertexUV;
layout(location = 2) in float vertexTexture;
layout(location = 3) in float vertexBrightness;

out mediump vec3 uvw;
out lowp float brightness;

layout(std140) uniform ShaderData {
  uniform mat4 mvp;
  vec4 ambientColor;
  uint remap[2048];
};


void main(void) {
  gl_Position = mvp * vec4(vertexPos, 1);
  float textureIndex = remap[int(vertexTexture)];
  uvw = vec3(vertexUV.x, vertexUV.y, textureIndex);
  brightness = vertexBrightness;
}
