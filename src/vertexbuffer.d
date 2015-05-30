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

module render.vertexbuffer;

import derelict.opengl3.gl3;

import render.indexbuffer;
import render.enums;


public final class VertexBuffer(T) {

    private GLuint _id;
    
    private PrimitiveType _primitiveType;
    private BufferUsage _usage;
    private int _subBufferCount;

    private T[][] _data;
    private size_t[] _offsets;
    private size_t[] _sizes;
    
    private IndexBuffer _indexBuffer;
    private bool _isIndexed;


    this(const PrimitiveType primitiveType, const int subBufferCount, const BufferUsage usage, const bool isIndexed) {
        _primitiveType = primitiveType;
        _subBufferCount = subBufferCount;
        _usage = usage;
        _isIndexed = isIndexed;
       
        _offsets = new size_t[_subBufferCount];
        _sizes = new size_t[_subBufferCount];
        _data = new T[][](_subBufferCount);

        if (_isIndexed) {
            _indexBuffer = new IndexBuffer(_primitiveType, _subBufferCount, _usage);
        }
    }

    ~this() {
        glDeleteBuffers(1, &_id);
    }

    public void add(const T[] data, const int bufferIndex) {
        _data[bufferIndex] ~= data;
    }

    public void add(const T[] data, const GLushort[] indices, const int subBufferIndex) {
        _indexBuffer.add(indices, subBufferIndex, _data[subBufferIndex].length);
        add(data, subBufferIndex);
    }

    public void generate() {
        if (_id != 0) {
            throw new Exception("Attempted to generate an already generated vertex buffer.");
        }

        glGenBuffers(1, &_id);
        glBindBuffer(GL_ARRAY_BUFFER, _id);

        size_t size;
        foreach (T[] data; _data) {
            size += data.length * T.sizeof;
        }
        glBufferData(GL_ARRAY_BUFFER, size, null, _usage);

        size_t elementOffset = 0;
        size_t offset = 0;
        foreach (int index, T[] data; _data) {
            _offsets[index] = elementOffset;
            _sizes[index] = data.length;
            
            if (data.length) {
                glBufferSubData(GL_ARRAY_BUFFER, offset, data.length * T.sizeof, &data[0]);
            }

            offset += data.length * T.sizeof;
            elementOffset += data.length;
        }

        if (_isIndexed) {
            for (int subBufferIndex = 1; subBufferIndex < _subBufferCount; subBufferIndex++) {
                _indexBuffer.setStartIndex(subBufferIndex, _data[subBufferIndex - 1].length);
            }
            _indexBuffer.generate();
        }
    }

    public void clear() {
        _data.length = 0;
        if (_isIndexed) {
            _indexBuffer.clear();
        }
    }

    public void bind() {
        if (_id == 0) {
            throw new Exception("Attempted to bind vertex buffer before generating.");
        }
        glBindBuffer(GL_ARRAY_BUFFER, _id);

        if (_isIndexed) {
            _indexBuffer.bind();
        }
    }

    public void draw(const int subBufferIndex) {
        if (_isIndexed) {
            _indexBuffer.draw(subBufferIndex);
        } else {
            throw new Exception("VertexBuffer does not support drawing without indices!");
            //glDrawArray(_primitiveType, _indexBuffer.size(subBufferIndex), GL_UNSIGNED_INT, cast(void*)_indexBuffer.offset(subBufferIndex));
        }
    }

    @property public size_t size(const int subBufferIndex) {
        return _sizes[subBufferIndex];
    }

    @property public size_t offset(const int subBufferIndex) {
        return _offsets[subBufferIndex];
    }
}