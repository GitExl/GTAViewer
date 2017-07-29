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

module render.program;

import std.stdio;
import std.string;

import derelict.opengl;

import render.shader;

import util.log;


public final class Program {

    private GLuint _id;
    private Shader _shaderVertex;
    private Shader _shaderFragment;

    this(Shader shaderVertex, Shader shaderFragment) {
        Log.write(Color.NORMAL, "Linking '%s' & '%s' into shader program...", shaderVertex.name, shaderFragment.name);

        _id = glCreateProgram();
        _shaderVertex = shaderVertex;
        _shaderFragment = shaderFragment;
        
        glAttachShader(_id, shaderVertex.id);
        glAttachShader(_id, shaderFragment.id);
        glLinkProgram(_id);
 
        GLint status;
        GLint logLength;
        glGetProgramiv(_id, GL_LINK_STATUS, &status);
        if (status == GL_FALSE) {
            glGetProgramiv(_id, GL_INFO_LOG_LENGTH, &logLength);

            char[] errorLog;
            if (logLength > 0) {
                errorLog = new char[logLength];
                glGetProgramInfoLog(_id, logLength, null, &errorLog[0]);
            } else {
                 errorLog = cast(char[])"Unknown error message. No log info given.";
            }

            glDeleteProgram(_id);

            throw new Exception(format("Cannot link program. %s", cast(char[])errorLog));
        }
    }

    ~this() {
        if (_id) {
            glDeleteProgram(_id);
        }
    }

    public void use() {
        glUseProgram(_id);
    }

    public GLint getUniformLocation(const string name) {
        const(char)* n = name.toStringz();
        return glGetUniformLocation(_id, n);
    }

    public GLint getUniformBlockIndex(const string name) {
        const(char)* n = name.toStringz();
        return glGetUniformBlockIndex(_id, n);
    }

    public void uniformBlockBinding(const GLint blockIndex, const GLint bindingPoint) {
        glUniformBlockBinding(_id, blockIndex, bindingPoint);
    }

}