/*
    Copyright (c) 2015, Dennis Meuwissen
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
       list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    License does not apply to code and information found in the ./info directory.
*/

module render.spritebatch;

import std.stdio;
import std.algorithm;
import std.math;

import derelict.opengl3.gl3;

import render.texture;
import render.enums;
import render.program;
import render.shader;
import render.uniformbuffer;
import render.texturearray;

import util.vector3;
import util.matrix4;


public struct Sprite {
    Vector3 pos;
    
    int width;
    int height;

    Texture texture;
    float u;
    float v;

    float rotation;
    float opacity;
    float brightness;

    alias pos this;
}

private align(1) struct SpriteVertex {
    GLfloat x;
    GLfloat y;
    GLfloat z;
    GLfloat u;
    GLfloat v;
    GLfloat opacity;
    GLfloat brightness;
    GLfloat index;
}


private static immutable uint SPRITES_PER_BUFFER = 16;
private static immutable uint VERTICES_PER_SPRITE = 6;
private static immutable uint BUFFER_SIZE = SPRITES_PER_BUFFER * (SpriteVertex.sizeof * VERTICES_PER_SPRITE);


private align(1) struct ShaderData {
    Matrix4 vp;
    float[4] ambientColor;
    Matrix4[SPRITES_PER_BUFFER] matrices;
}


public final class SpriteBatch {
    
    private Sprite[] _sprites;
    private size_t _count;

    private uint _lastBatchCount;
    
    private Program _program;

    private GLuint _id;
    private SpriteVertex[SPRITES_PER_BUFFER * VERTICES_PER_SPRITE] _vertices;

    private UniformBuffer!ShaderData _uniforms;
    private GLuint _uniformsBlockIndex;
    private ShaderData _shaderData;
    private GLint _uSamplerSpriteTexture;

    private static immutable GLint UBO_BIND_POINT = 0;


    this() {
        _sprites.length = 128;

        glGenBuffers(1, &_id);
        glBindBuffer(GL_ARRAY_BUFFER, _id);
        glBufferData(GL_ARRAY_BUFFER, BUFFER_SIZE, null, GL_STREAM_DRAW);

        _program = new Program(
            new Shader("data/shaders/sprite_vertex.glsl", ShaderType.VERTEX),
            new Shader("data/shaders/sprite_fragment.glsl", ShaderType.FRAGMENT)
        );

        _uniforms = new UniformBuffer!ShaderData();
        _uniformsBlockIndex = _program.getUniformBlockIndex("ShaderData");
        _program.uniformBlockBinding(_uniformsBlockIndex, UBO_BIND_POINT);
        
        _uSamplerSpriteTexture = _program.getUniformLocation("samplerSpriteTexture");
        glUniform1i(_uSamplerSpriteTexture, 0);
    }

    public void add(Sprite sprite) {
        if (_count == _sprites.length) {
            _sprites.length = _sprites.length * 2;
        }

        _sprites[_count] = sprite;
        _count++;
    }

    public void draw() {
        if (!_count) {
            return;
        }

        // Sort by z, then texture
        sort!((a, b) {
            if (a.z == b.z) {
                return a.texture.id < b.texture.id;
            }
            return a.z < b.z;
        })(_sprites[0.._count]);

        _program.use();
        glEnable(GL_BLEND);

        glBindBuffer(GL_ARRAY_BUFFER, _id);

        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SpriteVertex.sizeof, cast(void*)SpriteVertex.x.offsetof);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, SpriteVertex.sizeof, cast(void*)SpriteVertex.u.offsetof);
        glVertexAttribPointer(2, 1, GL_FLOAT, GL_FALSE, SpriteVertex.sizeof, cast(void*)SpriteVertex.opacity.offsetof);
        glVertexAttribPointer(3, 1, GL_FLOAT, GL_FALSE, SpriteVertex.sizeof, cast(void*)SpriteVertex.brightness.offsetof);
        glVertexAttribPointer(4, 1, GL_FLOAT, GL_FALSE, SpriteVertex.sizeof, cast(void*)SpriteVertex.index.offsetof);

        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
        glEnableVertexAttribArray(2);
        glEnableVertexAttribArray(3);
        glEnableVertexAttribArray(4);

        _uniforms.bindBase(_uniformsBlockIndex);

        uint spritesCount;
        uint vertexIndex;
        Texture currentTexture;

        _lastBatchCount = 0;

        for (int index = 0; index < _count; index += spritesCount) {
            if (index + SPRITES_PER_BUFFER >= _count) {
                spritesCount = _count - index;
            } else {
                spritesCount = SPRITES_PER_BUFFER;
            }
            
            // Generate geometry and matrices for each sprite.
            vertexIndex = 0;
            currentTexture = _sprites[index].texture;
            const Matrix4 mI = matrix4Identity();
            foreach (int spriteIndex, ref Sprite sprite; _sprites[index..index + spritesCount]) {
                if (currentTexture !is sprite.texture) {
                    spritesCount = spriteIndex;
                    break;
                }

                const GLfloat su = (1.0 / currentTexture.size) * sprite.width;
                const GLfloat sv = (1.0 / currentTexture.size) * sprite.height;

                _vertices[vertexIndex + 0] = SpriteVertex( 0.5 * sprite.width, -0.5 * sprite.height, 0.0, sprite.u + su,  sprite.v + 0.0, sprite.opacity, sprite.brightness, spriteIndex);
                _vertices[vertexIndex + 1] = SpriteVertex(-0.5 * sprite.width, -0.5 * sprite.height, 0.0, sprite.u + 0.0, sprite.v + 0.0, sprite.opacity, sprite.brightness, spriteIndex);
                _vertices[vertexIndex + 2] = SpriteVertex( 0.5 * sprite.width,  0.5 * sprite.height, 0.0, sprite.u + su,  sprite.v + sv,  sprite.opacity, sprite.brightness, spriteIndex);
                _vertices[vertexIndex + 3] = SpriteVertex(-0.5 * sprite.width, -0.5 * sprite.height, 0.0, sprite.u + 0.0, sprite.v + 0.0, sprite.opacity, sprite.brightness, spriteIndex);
                _vertices[vertexIndex + 4] = SpriteVertex(-0.5 * sprite.width,  0.5 * sprite.height, 0.0, sprite.u + 0.0, sprite.v + sv,  sprite.opacity, sprite.brightness, spriteIndex);
                _vertices[vertexIndex + 5] = SpriteVertex( 0.5 * sprite.width,  0.5 * sprite.height, 0.0, sprite.u + su,  sprite.v + sv,  sprite.opacity, sprite.brightness, spriteIndex);
                vertexIndex += VERTICES_PER_SPRITE;

                const Matrix4 mR = matrix4RotateZ(mI, sprite.rotation * (PI / 180));
                const Matrix4 mT = matrix4Translate(mI, Vector3(sprite.x, sprite.y, sprite.z));
                _shaderData.matrices[spriteIndex] = matrix4Multiply(matrix4Multiply(mI, mT), mR);
            }

            // Write vertex data to buffer.
            SpriteVertex* dest = cast(SpriteVertex*)glMapBufferRange(GL_ARRAY_BUFFER, 0, spritesCount * VERTICES_PER_SPRITE * SpriteVertex.sizeof, GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_BUFFER_BIT);
            dest[0..spritesCount * VERTICES_PER_SPRITE] = _vertices[0..spritesCount * VERTICES_PER_SPRITE];
            glUnmapBuffer(GL_ARRAY_BUFFER);

            // Update shader data.
            _uniforms.update(_shaderData);

            // Draw with current batch texture.
            currentTexture.bind();
            glDrawArrays(GL_TRIANGLES, 0, spritesCount * VERTICES_PER_SPRITE);
            
            _lastBatchCount++;
        }

        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);
        glDisableVertexAttribArray(2);
        glDisableVertexAttribArray(3);
        glDisableVertexAttribArray(4);

        glBindBuffer(GL_ARRAY_BUFFER, 0);

        _count = 0;
    }

    @property public uint lastBatchCount() {
        return _lastBatchCount;
    }

    public void setAmbientColor(const float[4] color) {
        _shaderData.ambientColor = color;
    }

    public void setMatrix(const Matrix4 matrix) {
        _shaderData.vp = matrix;
    }

}