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

module game.script.gta2script;

import std.stdio;
import std.string;
import std.conv;

import game.gamestate_level;
import game.audiobank;

import game.entities.entity;
import game.entities.vehicle;

import game.map.map;

import game.style.style;

import game.script.script;
import game.script.gta2commands;
import game.script.gta2entities;

import util.binaryfile;
import util.vector3;
import util.convert;
import util.color;
import util.log;


private enum CommandFlags : ushort {
    NONE = 0x0,
    EXEC = 0x1, // Delay execution of next command until next tick?
}

private align(1) struct Command {
    ushort pointerIndex;
    GTA2Command type;
    ushort nextPointerIndex;
    ushort flags;
}


public final class GTA2Script : Script {

    private string _fileName;

    private string[uint] _strings;
    private ushort[] _pointers;
    private ubyte[] _script;

    private GameStateLevel _state;
    private Style _style;
    private Map _map;

    private EntityVehicle[uint] _vehicles;
    private Entity[uint] _sounds;

    private static int INVALID_Z = 4177920;


    this(const string fileName) {
        _fileName = fileName;
    }

    private void read() {
        Log.write(Color.NORMAL, "Reading mission script '%s'...", _fileName);

        BinaryFile file = new BinaryFile(_fileName);

        // Pointers to script commands.
        _pointers = new ushort[6000];
        foreach (ref ushort ptr; _pointers) {
            ptr = file.readUShort();
        }

        // GTA2 demo format has some unknown data after pointers.
        if (file.size == 84156) {
            file.skip(1500);
        }

        // Script command data.
        _script = file.readBytes(65536);

        // Read string table.
        // String data type is not used.
        uint endOffset = file.offset + file.readUShort();
        while (file.offset < endOffset) {
            const uint id = file.readUInt();
            file.skip(4);
            const ubyte length = file.readUByte();

            _strings[id] = file.readNullString(length);
        }

        Log.write(Color.NORMAL, "%d strings.", _strings.length);
    }
   
    public override void init(GameStateLevel state, Style style, Map map) {
        _state = state;
        _style = style;
        _map = map;

        read();

        void* paramsOffset;
        foreach (ushort ptr; _pointers) {
            if (ptr == 0) {
                continue;
            }

            const Command cmd = *cast(Command*)(&_script[0] + ptr);
            paramsOffset = &_script[0] + ptr + Command.sizeof;

            //Log.write(Color.DEBUG, "[GTA2] %-5d %-25s %-5d %s", cmd.pointerIndex, to!string(cmd.type), cmd.nextPointerIndex, (cmd.flags & CommandFlags.EXEC) ? "EXEC" : "");

            switch (cmd.type) {
                case GTA2Command.PARKED_CAR_DECSET_2D:
                case GTA2Command.PARKED_CAR_DECSET_2D_STR:
                case GTA2Command.PARKED_CAR_DECSET_3D:
                case GTA2Command.PARKED_CAR_DECSET_3D_STR:
                case GTA2Command.CAR_DECSET_2D:
                case GTA2Command.CAR_DECSET_2D_STR:
                case GTA2Command.CAR_DECSET_3D:
                case GTA2Command.CAR_DECSET_3D_STR:
                case GTA2Command.CAR_DEC:
                case GTA2Command.CREATE_CAR_3D:
                case GTA2Command.CREATE_CAR_3D_STR:
                case GTA2Command.CREATE_CAR_2D:
                case GTA2Command.CREATE_CAR_2D_STR:
                case GTA2Command.CREATE_GANG_CAR1:
                case GTA2Command.CREATE_GANG_CAR2:
                case GTA2Command.CREATE_GANG_CAR3:
                case GTA2Command.CREATE_GANG_CAR4:
                    scriptSpawnCar(cmd, paramsOffset);
                    break;

                case GTA2Command.OBJ_DEC:
                case GTA2Command.CREATE_OBJ_3D_INT:
                case GTA2Command.OBJ_DECSET_3D:
                case GTA2Command.OBJ_DECSET_3D_STR:
                case GTA2Command.OBJ_DECSET_3D_INT:
                case GTA2Command.CREATE_OBJ_2D_STR:
                case GTA2Command.OBJ_DECSET_2D:
                case GTA2Command.OBJ_DECSET_2D_STR:
                case GTA2Command.OBJ_DECSET_2D_INT:
                    scriptSpawnObject(cmd, paramsOffset);
                    break;

                case GTA2Command.GENERATOR_DEC:
                case GTA2Command.GENERATOR_DECSET1:
                case GTA2Command.GENERATOR_DECSET2:
                case GTA2Command.GENERATOR_DECSET3:
                case GTA2Command.GENERATOR_DECSET4:
                    scriptSpawnGenerator(cmd, paramsOffset);
                    break;

                case GTA2Command.SOUND_DECSET:
                case GTA2Command.CREATE_SOUND:
                    scriptSpawnSound(cmd, paramsOffset);
                    break;

                case GTA2Command.LIGHT_DEC:
                case GTA2Command.LIGHT_DECSET1:
                case GTA2Command.LIGHT_DECSET2:
                case GTA2Command.CREATE_LIGHT1:
                case GTA2Command.CREATE_LIGHT2:
                    scriptSpawnLight(cmd, paramsOffset);
                    break;

                case GTA2Command.SET_AMBIENT:
                    scriptSetAmbient(cmd, paramsOffset);
                    break;

                case GTA2Command.PLAYER_PED:
                    scriptPlayerPed(cmd, paramsOffset);
                    break;

                case GTA2Command.SET_SHADING_LEV:
                    scriptShadingLevel(cmd, paramsOffset);
                    break;

                case GTA2Command.PUT_CAR_ON_TRAILER:
                    scriptCarOnTrailer(cmd, paramsOffset);
                    break;

                case GTA2Command.SET_CAR_GRAPHIC:
                    scriptSetCarGraphic(cmd, paramsOffset);
                    break;

                case GTA2Command.LEVELEND:
                    break;

                default:
                    break;
            }

            if (cmd.type == GTA2Command.LEVELEND) {
                break;
            }
        }
    }

    public override void run() {
    }

    private Vector3 getMapPos(const int x, const int y, const int z) {
        return Vector3((x / 16384.0) * 64.0, (y / 16384.0) * 64.0, (z / 16384.0) * 64.0);
    }


    private align(1) struct ParamsShadingLevel {
        ushort unknown;
        ushort level;
    }

    private void scriptShadingLevel(const Command cmd, const void* paramsOffset) {
        ParamsShadingLevel* params = cast(ParamsShadingLevel*)paramsOffset;

        _state.setShadingLevel(cast(ubyte)params.level);
    }


    private align(1) struct ParamsCarTrailer {
        ushort car;
        ushort trailer;
    }

    private void scriptCarOnTrailer(const Command cmd, const void* paramsOffset) {
        ParamsCarTrailer* params = cast(ParamsCarTrailer*)paramsOffset;

        EntityVehicle vehicle = _vehicles[params.car];
        EntityVehicle trailer = _vehicles[params.trailer];

        vehicle.position = trailer.position;
        vehicle.position.z += 0.01;
        vehicle.rotation = (trailer.rotation + 180) % 360;
    }


    private align(1) struct ParamsLight {
        ushort varName;
		short unknown;
		int x;
        int y;
        int z;
		ubyte red;
        ubyte green;
        ubyte blue;
		ubyte pad;
		int radius;
		ubyte intensity;
		ubyte timeOn;
		ubyte timeOff;
		ubyte timeRandom;
    }

    private void scriptSpawnLight(const Command cmd, const void* paramsOffset) {
        ParamsLight* params = cast(ParamsLight*)paramsOffset;

        const Vector3 pos = getMapPos(params.x, params.y, params.z);

        Light light;
        light.color = RGBA(params.red, params.green, params.blue, 255);
        light.x = pos.x;
        light.y = pos.y;
        light.z = pos.z;
        light.radius = params.radius / 16384.0;
        light.intensity = params.intensity / 255.0;

        // Only these commands specify the last 3 parameters.
        if (cmd.type == GTA2Command.LIGHT_DECSET1 ||
            cmd.type == GTA2Command.LIGHT_DECSET2 ||
            cmd.type == GTA2Command.CREATE_LIGHT2) {
                light.timeOn = params.timeOn;
                light.timeOff = params.timeOff;
                light.timeRandom = params.timeRandom;
        }

        _map.addLight(light);
    }


    private align(1) struct ParamsCar {
        ushort varName;
		ushort unknown;
		int x;
        int y;
        int z;
		ushort rotation;
		short remap;
		ushort carModel;
		ushort trailerModel; // 0xFFFF if no trailer, 0xFFFE if MINI_CAR.
    }

    private void scriptSpawnCar(const Command cmd, const void* paramsOffset) {
        ParamsCar* params = cast(ParamsCar*)paramsOffset;

        if (params.trailerModel == 0xFFFE) {
            // MINI_CAR
        } else if (params.trailerModel != 0xFFFF) {
            // TRAILER
        }

        Vector3 pos = getMapPos(params.x, params.y, params.z);
        if (cmd.type == GTA2Command.PARKED_CAR_DECSET_2D || cmd.type == GTA2Command.CAR_DECSET_2D) {
            pos.z = _map.getSpawnZ(cast(MapCoord)pos.x, cast(MapCoord)pos.y);
        }
        _vehicles[cmd.pointerIndex] = cast(EntityVehicle)_map.spawnVehicle(_style, cast(VehicleModelIndex)params.carModel, pos, flipRotation(params.rotation), cast(ubyte)params.remap);
    }


    private align(1) struct ParamsObject {
        ushort varName;
		ushort unknown;
		int x;
        int y;
        int z;
		GTA2ScriptEntity entityId;
		ushort rotation;
	}

    private void scriptSpawnObject(const Command cmd, const void* paramsOffset) {
        ParamsObject* params = cast(ParamsObject*)paramsOffset;

        Vector3 pos = getMapPos(params.x, params.y, params.z);
        if (cmd.type == GTA2Command.OBJ_DECSET_2D ||
            cmd.type == GTA2Command.CREATE_OBJ_2D_STR ||
            cmd.type == GTA2Command.OBJ_DECSET_2D_STR ||
            cmd.type == GTA2Command.OBJ_DECSET_2D_INT) {
            pos.z = _map.getSpawnZ(cast(MapCoord)pos.x, cast(MapCoord)pos.y);
        }

        _map.spawn(_style, _style.getEntityTypeName(params.entityId), pos, flipRotation(params.rotation));
    }


    private align(1) struct ParamsAmbient {
		int level;
        ushort time;
    }

    private void scriptSetAmbient(const Command cmd, const void* paramsOffset) {
        ParamsAmbient* params = cast(ParamsAmbient*)paramsOffset;

        const float brightness = params.level / 16384.0;
        _state.ambientColor = [brightness, brightness, brightness, 1.0];
    }


    private align(1) struct ParamsGenerator {
		ushort unknown1;
		ushort unknown2;
		int x;
        int y;
        int z;
		ushort rotation;
		GTA2ScriptEntity entityId;
		ushort minDelay;
		ushort maxDelay;
		ushort ammoAmount;
    }

    private void scriptSpawnGenerator(const Command cmd, const void* paramsOffset) {
        ParamsGenerator* params = cast(ParamsGenerator*)paramsOffset;

        const Vector3 pos = getMapPos(params.x, params.y, params.z);
        _map.spawn(_style, _style.getEntityTypeName(params.entityId), pos, flipRotation(params.rotation));
    }


    private align(1) struct ParamsPlayerPed {
        ushort unknown1;
		ushort unknown2;
		int x;
        int y;
        int z;
		ushort rotation;
		short remap;
    }

    private void scriptPlayerPed(const Command cmd, const void* paramsOffset) {
        ParamsPlayerPed* params = cast(ParamsPlayerPed*)paramsOffset;

        Vector3 pos = getMapPos(params.x, params.y, params.z);
        if (params.z == INVALID_Z) {
            pos.z = _map.getSpawnZ(cast(MapCoord)pos.x, cast(MapCoord)pos.y);
        }
        pos.z += 960;
        _state.camera.set(pos);
    }


    private align(1) struct ParamsSound {
		ushort varName;
		ushort unknown;
		int x;
        int y;
        int z;
		ubyte soundId;
		ubyte playType;
    }

    private void scriptSpawnSound(const Command cmd, const void* paramsOffset) {
        ParamsSound* params = cast(ParamsSound*)paramsOffset;

        const Vector3 pos = getMapPos(params.x, params.y, params.z);
        Entity sound = _map.spawn(_style, "ScriptSound", pos, 0);
        
        sound.sound = params.soundId + 135;
        if (params.playType == 0) {
            sound.soundType = SoundType.LOOP;
        } else {
            sound.soundType = SoundType.ONCE;
        }
        
        _sounds[cmd.pointerIndex] = sound;

        //writefln("Sound %d (type %d) at %.1f, %.1f, %.1f.", params.soundId, params.playType, pos.x, pos.y, pos.z);
    }

    /*private static immutable string[uint] SEQUENCE_NAMES = [
        0: "",    
        1: "WIND",
        2: "SKID",
        3: "NIGHT_CLUB",
        4: "BAR",
        5: "GENERATOR_RUMBLE",
        6: "WORKSHOP",
        7: "VAT",
        8: "CHURCH_SINGING",
        9: "TEMPLE_CHANT",
        10: "INDUSTRIAL_HIGH",
        11: "HUMAN_ABATTOIR",
        12: "FUNNY_FARM",
        13: "BANK_ALARM",
        14: "INDUSTRIAL_LOW",
        15: "PORTA_LOO",
        16: "WATERFALL",
        17: "CRICKETS",
        18: "PRISON",
        19: "PRISON_ALARM",
        20: "GANG_DUMPED",
        21: "SMUG_LAUGH",
        22: "PRISON_YARD",
        23: "PRISON_RIOT",
        24: "GANG_LOCKED_IN_BUS",
        25: "SHOPPING_MALL",
        26: "CLOCK_TOWER",
        27: "YEEHA_BOMB",
        28: "BOWLING_ALLEY",
        29: "CROWD_NOISE",
        30: "FAN_NOISE",
        31: "GENERATOR_LOSE_POWER",
        32: "SCREAM",
        33: "BOMB_TICK",
        34: "BOMB_TICK_SHIT",
        35: "DETECTED_MUMBLE",
        36: "KRISHNA_CHANT",
        37: "CRYING",
        38: "ROCKET_LAUNCH_FAIL_CLICK",
        39: "ROCKET_FAIL_LAUGH",
        40: "POISONED",
        41: "POWER_PLANT",
        42: "MUMBLE",
        43: "JAZZ_CLUB",
        44: "COUNTRY_CLUB",
        45: "PYLON",
        46: "DISGRACELAND",
        47: "BAR_2",
        48: "STRIP_CLUB",
        49: "TEMPLE_2",
        50: "GARAGE_OPEN",
        51: "GARAGE_CLOSE",
        52: "LET_ME_OUT"
    ];*/

    private align(1) struct ParamsCarGraphic {
		ushort varName;
		ushort unknown;
		ushort graphicId;
    }

    private void scriptSetCarGraphic(const Command cmd, const void* paramsOffset) {
        ParamsCarGraphic* params = cast(ParamsCarGraphic*)paramsOffset;

        _vehicles[params.varName].disableDeltaMask(0xFFC00);
        if (params.graphicId > 0) {
            _vehicles[params.varName].enableDelta(params.graphicId + 11);
        }
    }

}