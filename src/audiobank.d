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

module game.audiobank;

import std.stdio;

import derelict.openal.al;

import audio.buffer;

import game.game;

import util.binaryfile;
import util.log;


public struct AudioChunk {
    int sampleRateVariation;
    int loopStart;
    int loopEnd;

    AudioBuffer buffer;
}


public enum SoundType : ubyte {
    NONE,
    LOOP,
    ONCE
}


public alias SoundIndex = ushort;


public final class AudioBank {

    private AudioChunk[] _audioChunks;


    this(const string baseName) {
        Log.write(Color.NORMAL, "Reading audio bank '%s'...", baseName);

        BinaryFile headerFile = new BinaryFile(baseName ~ ".sdt");
        BinaryFile dataFile = new BinaryFile(baseName ~ ".raw");

        AudioChunk chunk;
        while (!headerFile.eof) {
            int offset = headerFile.readInt();
            int length = headerFile.readInt();
            int sampleRate = headerFile.readInt();

            if (gameMode == GameMode.GTA2) {
                chunk.sampleRateVariation = headerFile.readInt();
                chunk.loopStart = headerFile.readInt() / 2;
                chunk.loopEnd = headerFile.readInt();
                if (chunk.loopEnd == -1) {
                    chunk.loopEnd = length / 2;
                }
            }

            dataFile.seek(offset);
            ubyte[] data = dataFile.readBytes(length);
            const ALenum format = (data.length % 2) ? AL_FORMAT_MONO8 : AL_FORMAT_MONO16;
            chunk.buffer = new AudioBuffer(data, format, sampleRate);
            
            _audioChunks ~= chunk;
        }

        Log.write(Color.NORMAL, "%d audio chunks.", _audioChunks.length);
    }

    public AudioChunk* getChunk(const uint index) {
        return &_audioChunks[index];
    }
}