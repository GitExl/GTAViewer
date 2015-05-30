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

module render.texture;

import std.stdio;

import derelict.opengl3.gl3;

import render.enums;

import util.console;


public final class Texture {

    private GLuint _size;
    private TextureFormat _pixelFormat;
    private InternalTextureFormat _internalFormat;

    private TextureFilter _filterMagnify = TextureFilter.LINEAR;
    private TextureFilter _filterMinify = TextureFilter.LINEAR;
    private GLuint _anisotropy = 0;
    private TextureWrapMode _wrapMode = TextureWrapMode.CLAMP;
    private GLuint _mipmapLevels = 0;

    private GLuint _id;


    this(const GLuint size, const InternalTextureFormat internalFormat, const TextureFormat pixelFormat) {
        _size = size;
        _internalFormat = internalFormat;
        _pixelFormat = pixelFormat;
        
        _anisotropy = cast(uint)CVars.get("r_anisotropy").intVal;
        const uint filterType = cast(uint)CVars.get("r_filter").intVal;
        switch (filterType) {
            default:
            case 0:
                _filterMagnify = TextureFilter.NEAREST;
                _filterMinify = TextureFilter.NEAREST;
                break;
            case 1:
                _filterMagnify = TextureFilter.LINEAR;
                _filterMinify = TextureFilter.LINEAR;
                break;
        }

        glGenTextures(1, &_id);
        
        bind();
        glTexStorage2D(GL_TEXTURE_2D, _mipmapLevels + 1, _internalFormat, _size, _size);
    }

    ~this() {
        glDeleteTextures(1, &_id);
    }

    public void generate(ubyte[] data) {        
        bind();
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _size, _size, _pixelFormat, GL_UNSIGNED_BYTE, &data[0]);

        if (_mipmapLevels > 0) {
            glGenerateMipmap(GL_TEXTURE_2D);

            if (_filterMinify == TextureFilter.NEAREST) {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
            } else if (_filterMinify == TextureFilter.LINEAR) {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
            }
        } else {
            if (_filterMinify == TextureFilter.NEAREST) {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            } else if (_filterMinify == TextureFilter.LINEAR) {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            }
        }

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _filterMagnify);
    
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _wrapMode);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _wrapMode);
        
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, _anisotropy);
    }

    private void update(ubyte[] data) {
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _size, _size, _pixelFormat, GL_UNSIGNED_BYTE, &data[0]);
    }

    public void bind() {
        glBindTexture(GL_TEXTURE_2D, _id);
    }

    @property public void wrapMode(const TextureWrapMode wrapMode) {
        _wrapMode = wrapMode;
    }

    @property public void anisotropy(const GLuint anisotropy) {
        _anisotropy = anisotropy;
    }

    @property public void filterMagnify(const TextureFilter filter) {
        _filterMagnify = filter;
    }

    @property public void filterMinify(const TextureFilter filter) {
        _filterMinify = filter;
    }

    @property public void mipmapLevels(const GLuint levels) {
        _mipmapLevels = levels;
    }

    @property public uint size() {
        return _size;
    }

    @property public GLint id() {
        return _id;
    }
}