#version 330

precision mediump float;

layout(location = 0) in vec3 vertexPos;
layout(location = 1) in vec2 vertexUV;
layout(location = 2) in float vertexOpacity;
layout(location = 3) in float vertexDarken;
layout(location = 4) in float vertexIndex;

out mediump vec2 uv;
out lowp float opacity;
out lowp float darken;

layout(std140) uniform ShaderData {
  uniform mat4 vp;
  vec4 ambientColor;
  uniform mat4 matrices[224];
};


void main(void) {
  gl_Position = vp * matrices[int(vertexIndex)] * vec4(vertexPos, 1);
  uv = vertexUV;
  opacity = vertexOpacity;
  darken = vertexDarken;
}
