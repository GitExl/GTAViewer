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

module game.entities.entity;

import audio.source;

import game.style.style;

import game.audiobank;
import game.spritetextures;

import util.vector3;
import util.color;


public enum EntityFlags : ushort {
    NONE = 0x0,
    INVISIBLE = 0x1,
    DISABLED = 0x2,
    NO_SHADOW = 0x4,
}

public enum EntityClass : ubyte {
    OBSTACLE,
    DECORATION,
    VEHICLE,
    POWERUP,
    PED,
    PROJECTILE,
}


public struct EntityType {
    string name;
    EntityClass classId;

    ushort width;
    ushort height;
    ushort depth;

    SpriteFrameIndex baseFrame;
    SpriteFrameIndex frameCount;

    ubyte weight;
    ushort aux;
    EntityFlags flags;
}


public class Entity {

    protected Vector3 _position;

    protected SpriteFrameIndex _baseFrame;
    protected SpriteFrameIndex _frame;
    protected SpriteFrameIndex _frameCount;

    protected SpriteTexture* _spriteTexture;

    protected AudioSource _audioSource;
    protected SoundIndex _sound;
    protected SoundType _soundType;

    protected ubyte _remap;
    protected HSL _hsl;
    
    protected EntityFlags _flags;
    
    protected ushort _width;
    protected ushort _height;
    protected ushort _depth;
    protected ubyte _weight;

    protected float _rotation = 0.0;
    protected float _pitch = 0.0;
    protected float _roll = 0.0;


    public this() {
    }

    public void initializeFromType(EntityType type) {
        _width = type.width;
        _height = type.height;
        _depth = type.depth;
        _weight = type.weight;
        _flags = type.flags;
        _baseFrame = type.baseFrame;
        _frameCount = type.frameCount;
    }

    public void update(const double delta) {
    }

    @property public SpriteFrameIndex baseFrame() {
        return _baseFrame;
    }

    @property public SpriteFrameIndex frameCount() {
        return _frameCount;
    }

    @property public SpriteFrameIndex frame() {
        return _frame;
    }

    @property public void frame(const SpriteFrameIndex frame) {
        _frame = frame;
    }

    @property public EntityFlags flags() {
        return _flags;
    }

    @property public void flags(const EntityFlags flags) {
        _flags = flags;
    }

    @property public ref Vector3 position() {
        return _position;
    }

    @property public void position(const Vector3 position) {
        _position = position;
    }

    @property public ubyte remap() {
        return _remap;
    }

    @property public void remap(const ubyte remap) {
        _remap = remap;
    }

    @property public HSL hsl() {
        return _hsl;
    }

    @property public void hsl(const HSL hsl) {
        _hsl = hsl;
    }

    @property public float rotation() {
        return _rotation;
    }

    @property public void rotation(const float rotation) {
        _rotation = rotation;
    }

    @property public float pitch() {
        return _pitch;
    }

    @property public void pitch(const float pitch) {
        _pitch = pitch;
    }

    @property public float roll() {
        return _roll;
    }

    @property public void roll(const float roll) {
        _roll = roll;
    }

    @property public uint deltaMask() {
        return 0;
    }

    @property public SpriteTexture* spriteTexture() {
        return _spriteTexture;
    }

    @property public void spriteTexture(SpriteTexture* spriteTexture) {
        _spriteTexture = spriteTexture;
    }

    @property public PaletteIndex palette(const SpriteFrame frame) {
        return frame.palette;
    }


    // Sound
    @property public AudioSource audioSource() {
        return _audioSource;
    }

    @property public void audioSource(AudioSource source) {
        _audioSource = source;
    }

    @property public SoundIndex sound() {
        return _sound;
    }

    @property public void sound(SoundIndex sound) {
        _sound = sound;
    }

    @property public SoundType soundType() {
        return _soundType;
    }

    @property public void soundType(const SoundType type) {
        _soundType = type;
    }
}
