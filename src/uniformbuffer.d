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

module render.uniformbuffer;

import std.stdio;

import derelict.opengl;


public final class UniformBuffer(T) {
    
    private GLuint[BUFFER_COUNT] _id;
    private int _currentBuffer;

    private static immutable BUFFER_COUNT = 1;


    public this() {
        glGenBuffers(BUFFER_COUNT, &_id[0]);
        
        for (int buffer = 0; buffer < BUFFER_COUNT; buffer++) {
            glBindBuffer(GL_UNIFORM_BUFFER, _id[buffer]);
            glBufferData(GL_UNIFORM_BUFFER, T.sizeof, null, GL_STREAM_DRAW);
        }
    }

    public void update(const T data) {
        _currentBuffer = (_currentBuffer + 1) % BUFFER_COUNT;
        
        glBindBuffer(GL_UNIFORM_BUFFER, _id[_currentBuffer]);
        T* dest = cast(T*)glMapBufferRange(GL_UNIFORM_BUFFER, 0, T.sizeof, GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_BUFFER_BIT);
        *dest = data;
        glUnmapBuffer(GL_UNIFORM_BUFFER);
    }

    public void bindBase(const GLint blockIndex) {
        glBindBufferBase(GL_UNIFORM_BUFFER, blockIndex, _id[_currentBuffer]);
    }

}
