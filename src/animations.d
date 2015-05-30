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

module game.animations;

import std.stdio;
import std.string;

import derelict.opengl3.gl3;

import game.style.style;

import game.map.block;


private struct LoadedAnim {
    BlockTextureIndex textureIndex;
    double delay;
    BlockTextureIndex[] frames;
    double counter;
    ushort frameIndex;

    this(Animation anim) {
        textureIndex = anim.textureIndex;
        delay = anim.delay;
        frames = anim.frames;
        frameIndex = 0;
        counter = delay;
    }
}


public final class Animations {

    private LoadedAnim[] _animations;
    private GLuint[MAX_BLOCKTEXTURE_INDICES * 4] _indices;


    public this(Style style) {
        foreach (Animation anim; style.getAnimations()) {
            _animations ~= LoadedAnim(anim);
        }

        // Build initial list of block texture indices.
        const int textureCount = style.getBlockTextures().length;
        if (textureCount > MAX_BLOCKTEXTURE_INDICES) {
            throw new Exception(format("Too many textures for animating. Maximum is %d.", MAX_BLOCKTEXTURE_INDICES));
        }
        for (uint index = 0; index < textureCount; index++) {
            _indices[index * 4] = index;
        }
    }

    public void update(const double delta) {
        foreach(ref LoadedAnim anim; _animations) {
            anim.counter -= delta;
            while (anim.counter <= 0.0) {
                anim.counter += anim.delay;
                
                anim.frameIndex++;
                if (anim.frameIndex >= anim.frames.length) {
                    anim.frameIndex = 0;
                }

                _indices[anim.textureIndex * 4] = anim.frames[anim.frameIndex];
            }
        }
    }

    public GLuint[] getIndices() {
        return _indices;
    }

}