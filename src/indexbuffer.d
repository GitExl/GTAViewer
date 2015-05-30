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

module render.indexbuffer;

import std.algorithm;

import derelict.opengl3.gl3;

import render.enums;


public final class IndexBuffer {

    private GLuint _id;

    private PrimitiveType _primitiveType;
    private BufferUsage _usage;
    private int _subBufferCount;

    private GLushort[][] _data;
    private size_t[] _offsets;
    private size_t[] _sizes;
    private size_t[] _startIndices;
    

    this(const PrimitiveType primitiveType, const int subBufferCount, const BufferUsage usage) {
        _primitiveType = primitiveType;
        _usage = usage;
        _subBufferCount = subBufferCount;

        _offsets = new size_t[_subBufferCount];
        _sizes = new size_t[_subBufferCount];
        _data = new GLushort[][](_subBufferCount);
        _startIndices = new size_t[_subBufferCount];
    }

    ~this() {
        glDeleteBuffers(1, &_id);
    }

    public void add(const GLushort[] data, const int subBufferIndex, const size_t startIndex) {
        foreach (GLushort value; data) {
            _data[subBufferIndex] ~= cast(GLushort)(value + startIndex);
        }
    }

    public void setStartIndex(const int subBufferIndex, const size_t index) {
        _startIndices[subBufferIndex] = index;
    }

    public void generate() {
        if (_id != 0) {
            throw new Exception("Attempted to generate an already generated index buffer.");
        }

        glGenBuffers(1, &_id);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _id);

        // Calculate the total size of the buffer.
        size_t size;
        foreach (GLushort[] data; _data) {
            size += data.length * GLushort.sizeof;
        }
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, size, null, _usage);

        // Remap sub-buffer indices to start at the proper index.
        foreach (int subBuffer, GLushort[] data; _data) {
            foreach (ref GLushort index; data) {
                index += _startIndices[subBuffer];
            }
        }

        // Compute subbuffer offsets and sizes, and store data into the buffer object.
        size_t offset;
        foreach (int index, GLushort[] data; _data) {
            _offsets[index] = offset;
            _sizes[index] = data.length;
            
            if (data.length) {
                glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, offset, data.length * GLushort.sizeof, &data[0]);
            }

            offset += data.length * GLushort.sizeof;
        }
    }

    public void clear() {
        _data.length = 0;
    }

    public void bind() {
        if (_id == 0) {
            throw new Exception("Attempted to bind index buffer before generating.");
        }
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _id);
    }

    public void draw(const int subBufferIndex) {
        glDrawElements(_primitiveType, _sizes[subBufferIndex], GL_UNSIGNED_SHORT, cast(void*)_offsets[subBufferIndex]);
    }
}