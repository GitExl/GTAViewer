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

module audio.source;

import std.stdio;
import std.string;

import derelict.openal.al;

import audio.audio;
import audio.buffer;

import util.vector3;


public enum AudioSourceType : ubyte {
    SINGLE,
    LOOPING
}

public enum AudioSourceState : ubyte {
    PLAYING,
    STOPPED,
    PAUSED,
    INITIAL
}


public final class AudioSource {

    private ALuint _id;

    private AudioSourceType _type;


    this(const AudioSourceType type) {
        _type = type;

        alGetError();
        alGenSources(1, &_id);
        const ALint error = alGetError();
        if (error != AL_NO_ERROR) {
            throw new Exception(format("Cannot allocate OpenAL source. Error %d.", error));
        }

        setPitch(1.0);
        setGain(1.0);
        setPosition(Vector3(0, 0, 0));
        setVelocity(Vector3(0, 0, 0));
        setLooping(false);

        alSourcef(_id, AL_MAX_DISTANCE, MAX_AUDIO_DISTANCE);
        alSourcef(_id, AL_REFERENCE_DISTANCE, MIN_AUDIO_DISTANCE);
    }

    ~this() {
        alSourcei(_id, AL_BUFFER, 0);
        alDeleteSources(1, &_id);
    }

    public void setPitch(const float pitch) {
        alSourcef(_id, AL_PITCH, pitch);
    }

    public void setGain(const float gain) {
        alSourcef(_id, AL_GAIN, gain);
    }

    public void setPosition(const Vector3 pos) {
        alSource3f(_id, AL_POSITION, pos.x, pos.y, pos.z);
    }

    public void setVelocity(const Vector3 vel) {
        alSource3f(_id, AL_VELOCITY, vel.x, vel.y, vel.z);
    }

    public void setLooping(const bool looping) {
        alSourcei(_id, AL_LOOPING, looping ? AL_TRUE : AL_FALSE);
    }

    public AudioSourceState getState() {
        ALenum state;
        alGetSourcei(_id, AL_SOURCE_STATE, &state);

        switch (state) {
            case AL_PLAYING: return AudioSourceState.PLAYING;
            case AL_STOPPED: return AudioSourceState.STOPPED;
            case AL_INITIAL: return AudioSourceState.INITIAL;
            case AL_PAUSED: return AudioSourceState.PAUSED;
            default:
                throw new Exception(format("Unknown audio source state '%d'.", state));
        }
    }

    public void bindBuffer(AudioBuffer buffer) {
        alSourcei(_id, AL_BUFFER, buffer.id);
    }

    public void play() {
        alSourcePlay(_id);
    }

    public void pause() {
        alSourcePause(_id);
    }

    public void stop() {
        alSourceStop(_id);
    }

    @property public AudioSourceType type() {
        return _type;
    }

}