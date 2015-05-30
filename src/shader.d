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

module render.shader;

import std.stdio;
import std.file;
import std.string;
import std.path;
import std.conv;

import derelict.opengl3.gl3;

import util.log;


public enum ShaderType {
    VERTEX = GL_VERTEX_SHADER,
    FRAGMENT = GL_FRAGMENT_SHADER
}

public final class Shader {

    private ShaderType _type;
    private GLuint _id;
    private string _name;


    this(const string fileName, const ShaderType type) {
        _name = baseName(fileName, ".glsl");
        Log.write(Color.NORMAL, "Compiling %s shader %s...", to!string(type), _name);

        _id = glCreateShader(type);

        const(char)* code = readText(fileName).toStringz();
        glShaderSource(_id, 1, &code, null);
        glCompileShader(_id);
        
        GLint status;
        glGetShaderiv(_id, GL_COMPILE_STATUS, &status);
        if (status == GL_FALSE) {
            GLint logLength;
            glGetShaderiv(_id, GL_INFO_LOG_LENGTH, &logLength);
            
            char[] errorLog;
            if (logLength > 0) {
                errorLog = new char[logLength];
                glGetShaderInfoLog(_id, logLength, &logLength, &errorLog[0]);
            } else {
                errorLog = cast(char[])"Unknown error, no log information given.";
            }

            glDeleteShader(_id);

            throw new Exception(format("Cannot compile shader. %s", cast(char[])errorLog));
        }
    }

    ~this() {
        if (_id) {
            glDeleteShader(_id);
        }
    }

    @property
    public GLuint id() {
        return _id;
    }

    @property
    public string name() {
        return _name;
    }

}