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

module audio.audio;

import std.stdio;
import std.string;
import std.conv;
import std.math;
import std.algorithm;

import derelict.openal.al;

import audio.source;

import util.vector3;
import util.console;
import util.log;


public immutable float MAX_AUDIO_DISTANCE = 64 * 8;
public immutable float MIN_AUDIO_DISTANCE = 32;


public final class Audio {

    private ALCdevice* _device;
    private ALCcontext* _context;

    private ALint _maxSourcesMono;
    private ALint _maxSourcesStereo;

    private string[] _deviceNames;

    private AudioSource[][2] _sources;

    private CVar _cvarMaxSources;
    private CVar _cvarLoopSourcesRatio;
    private CVar _cvarSingleSourcesRatio;
    private CVar _cvarDopplerFactor;


    this() {
        _cvarMaxSources = CVars.get("a_maxsources");
        _cvarLoopSourcesRatio = CVars.get("a_loopsourcesratio");
        _cvarSingleSourcesRatio = CVars.get("a_singlesourcesratio");
        _cvarDopplerFactor = CVars.get("a_dopplerfactor");

        DerelictAL.load();

        ALboolean enumeration = alcIsExtensionPresent(null, "ALC_ENUMERATION_EXT");
        if (enumeration == AL_FALSE) {
            throw new Exception("Cannot enumerate OpenAL devices.");
        }

        enumerateDeviceNames();
        foreach (string deviceName; _deviceNames) {
            Log.write(Color.NORMAL, "OpenAL device: '%s'", deviceName);
        }

        string defaultDeviceName = alString(alcGetString(null, ALC_DEFAULT_DEVICE_SPECIFIER));
        Log.write(Color.NORMAL, "Using default OpenAL device '%s'.", defaultDeviceName);

        ALCdevice* device;
        device = alcOpenDevice(alcGetString(null, ALC_DEFAULT_DEVICE_SPECIFIER));
        if (device is null) {
            throw new Exception("Could not open default OpenAL device.");
        }

        ALCcontext* context;
        context = alcCreateContext(device, null);
        if (!alcMakeContextCurrent(context)) {
            throw new Exception("Failed to make the OpenAL context current.");
        }

        // Determine maximum amount of sound sources.
        alcGetIntegerv(device, ALC_MONO_SOURCES, 1, &_maxSourcesMono);
        alcGetIntegerv(device, ALC_STEREO_SOURCES, 1, &_maxSourcesStereo);
        Log.write(Color.NORMAL, "OpenAL device supports %d mono sources and %d stereo sources.", _maxSourcesMono, _maxSourcesStereo);

        // Setup sound sources.
        int maxSources;
        if (_cvarMaxSources.intVal == -1) {
            maxSources = _maxSourcesMono;
        } else {
            maxSources = cast(int)(min(_cvarMaxSources.intVal, _maxSourcesMono));
        }
        const int loopCount = cast(int)floor(maxSources * _cvarLoopSourcesRatio.floatVal);
        for (int index = 0; index < loopCount; index++) {
            _sources[AudioSourceType.LOOPING] ~= new AudioSource(AudioSourceType.LOOPING);
        }

        const int singleCount = cast(int)floor(maxSources * _cvarSingleSourcesRatio.floatVal);
        for (int index = 0; index < singleCount; index++) {
            _sources[AudioSourceType.SINGLE] ~= new AudioSource(AudioSourceType.SINGLE);
        }

        Log.write(Color.NORMAL, "Using %d looping sources and %d single sources.", loopCount, singleCount);

        // Setup listener.
        setListenerPosition(Vector3(0, 0, 0));
        setListenerVelocity(Vector3(0, 0, 0));
        setListenerOrientation(Vector3(0, 0, -1), Vector3(0, 1, 0));
        setListenerGain(1.0);

        // Doppler settings.
        // Standard length of american family car = 4.5 meters.
        // Pixels per meter = 64 / 4.5 = 14.22.
        // Speed of sound = 343.6 m/s in 20C air.
        // Speed of sound * pixels per meter = speed of sound in pixels per second.
        alSpeedOfSound(4886.756);
        alDopplerFactor(_cvarDopplerFactor.floatVal);

        // Using linear distance model.
        alDistanceModel(AL_LINEAR_DISTANCE_CLAMPED);
    }

    ~this() {
        alcMakeContextCurrent(null);
        alcDestroyContext(_context);
        alcCloseDevice(_device);
    }

    public AudioSource getSource(const AudioSourceType type) {
        AudioSource source;

        if (_sources[type].length) {
            source = _sources[type][_sources[type].length - 1];
            _sources[type].length -= 1;
        } else {
            Log.write(Color.WARNING, "Out of '%s' audio sources.", to!string(type));
        }

        return source;
    }

    public void returnSource(AudioSource source) {
        _sources[source.type] ~= source;
    }

    public void setListenerGain(const float gain) {
        alListenerf(AL_GAIN, gain);
    }

    public void setListenerPosition(const Vector3 pos) {
        alListener3f(AL_POSITION, pos.x, pos.y, pos.z);
    }

    public void setListenerVelocity(const Vector3 vel) {
        alListener3f(AL_VELOCITY, vel.x, vel.y, vel.z);
    }

    public void setListenerOrientation(const Vector3 at, const Vector3 up) {
        const ALfloat[] values = [at.x, at.y, at.z, up.x, up.y, up.z];
        alListenerfv(AL_ORIENTATION, &values[0]);
    }

    private void enumerateDeviceNames() {
        const(char)* deviceString = alcGetString(null, ALC_DEVICE_SPECIFIER);
        
        char* pt = cast(char*)deviceString;
        uint start = 0;
        uint index = 0;
        while (pt) {
            if (*pt == 0) {
                if (start == index) {
                    break;
                }
                _deviceNames ~= cast(string)deviceString[start..index];
                start = index + 1;
            }
            pt++;
            index++;
        }
    }

    private string alString(const(char)* data) {
        uint index;
        char* pt = cast(char*) data;
        while (pt) {
            if (*pt == 0) {
                break;
            }
            pt++;
            index++;
        }

        if (index) {
            return cast(string)data[0..index];
        }

        return "";
    }
}