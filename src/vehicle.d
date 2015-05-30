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

module game.entities.vehicle;

import std.stdio;

import game.entities.entity;

import game.style.style;

import util.color;


public alias ubyte VehicleModel;


public struct VehicleDoor {
    short relX;
    short relY;
    short entityTypeIndex;
    short deltaIndex;
}

public enum VehicleKind : ubyte {
    BUS = 0,
    TRUCK_CAB = 1,
    TRUCK_TRAILER = 2,
    MOTORBIKE = 3,
    CAR = 4,
    TRAIN = 8,
    UNKNOWN9 = 9,
    UNKNOWN13 = 13,
    UNKNOWN14 = 14,
    GTA2 = 255
}

public enum VehicleFlags : ushort {
    IS_CONVERTIBLE = 0x1,
    SOUND_FASTCHANGE = 0x2,
    CANNOT_JUMP_OVER = 0x4,
    HAS_EMERGENCY_LIGHTS = 0x8,
    HAS_ROOF_LIGHTS = 0x10,
    ARTIC_CAB = 0x20,
    ARTIC_TRAILER = 0x40,
    HAS_HIRE_LIGHTS = 0x80,
    HAS_ROOF_DECAL = 0x100,
    HAS_REAR_EMERGENCY_LIGHTS = 0x200,
    CAN_CRUSH_CARS = 0x400,
    HAS_POPUP_HEADLIGHTS = 0x800,
    TURBO = 0x1000,
    RECYCLE = 0x2000
}

public struct VehicleType {
    string name;

    VehicleKind kind;
    VehicleFlags flags;
    VehicleModel model;
    SpriteFrameIndex sprite;
    SpriteFrameIndex spriteCount;
    SpriteFrameIndex wreckSprite;

    ushort width;
    ushort height;
    ushort depth;
    
    HSL[] remapsHSL;
    ubyte[] remaps;

    uint[] value;

    ubyte passengerCount;
    ubyte rating;

    float damageFactor;

    ubyte engineType;
    ubyte radioType;
    ubyte hornType;

    ubyte soundFunction;

    VehiclePhysicsGTA1 physics1;
    VehiclePhysicsGTA2 physics2;
    
    VehicleDoor[] doors;
}

public struct VehiclePhysicsGTA1 {
    
    // Vehicle speed is clamped to these values.
    short speedMax;
    short speedMin;

    // Generic handling attributes. ???
    short acceleration;
    short braking;
    short grip;
    short handling;
    ubyte turning;

    // Total weight of this vehicle. Units?
    ushort weight;

    // Center of mass, offset from center of vehicle, for torque.
    byte centerMassX;
    byte centerMassY;

    // Inertia, usually calculated from mass and dimensions.
    int momentInertia;

    // Mass of this vehicle.
    float mass;

    // Thrust output in 1st gear. Are there other gears?
    float thrustGear1;

    // How much friction tires have with the ground in both axes? Probably a multiplier of some base friction amount.
    float tireAdhesionX;
    float tireAdhesionY;

    // The friction applied by various braking systems.
    float handBrakeFriction;
    float footBrakeFriction;

    // How is braking power divided between forward\backward wheels? 1.0 is front, 0.0 is back?
    float frontBrakeBias;

    // How quick turning is, how sharp corners are made.
    short turnRatio;

    // Y offset from the center of the vehicle to where the wheels are.
    short driveWheelOffset;
    short steeringWheelOffset;

    float backEndSlide;
    float handBrakeSlide;
}

public struct VehiclePhysicsGTA2 {
    byte steeringWheelOffset;
    byte driveWheelOffset;
    byte frontWindowOffset;
    byte rearWindowOffset;

    float mass;
    float frontDriveBias;
    float frontMassBias;
    float brakeFriction;
    float turnIn;
    float turnRatio;
    float rearStability;
    float handbrakeSlide;
    float thrust;
    float maxSpeed;
    float antiStrength;
    float skidThreshold;
    float gear1Multi;
    float gear2Multi;
    float gear3Multi;
    float gear2Speed;
    float gear3Speed;
}


public final class EntityVehicle : Entity {

    private VehicleType* _vehicleType;
    private uint _deltaMask;


    this(VehicleType* vehicle) {
        super();

        _width = vehicle.width;
        _height = vehicle.height;
        _depth = vehicle.depth;
        _weight = 0;
        _baseFrame = vehicle.sprite;
        _frameCount = 1;
        
        _vehicleType = vehicle;
    }

    @property public VehicleModel model() {
        return _vehicleType.model;
    }

    public void enableDelta(const uint index) {
        _deltaMask |= (1 << index);
        _spriteTexture = null;
    }

    public void disableDelta(const uint index) {
        _deltaMask &= ~(1 << index);
        _spriteTexture = null;
    }

    public void enableDeltaMask(const uint mask) {
        _deltaMask |= mask;
        _spriteTexture = null;
    }

    public void disableDeltaMask(const uint mask) {
        _deltaMask &= ~mask;
        _spriteTexture = null;
    }

    override @property public uint deltaMask() {
        return _deltaMask;
    }

    public void setVehicleRemap(const ubyte index) {
        _remap = _vehicleType.remaps[index];
    }

    override @property public PaletteIndex palette(const SpriteFrame frame) {
        if (_vehicleType.remaps.length == 0 || _remap == 0xFF || _remap == 0) {
            return frame.palette;
        }
        return PaletteIndex(PaletteType.VEHICLE, _remap);
    }

}
