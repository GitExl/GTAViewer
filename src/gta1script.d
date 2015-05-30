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

module game.script.gta1script;

import std.stdio;
import std.string;
import std.conv;

import game.gamestate_level;

import game.map.map;

import game.style.style;

import game.entities.entity;

import game.script.gta1tokenizer;
import game.script.gta1parser;
import game.script.gta1commands;
import game.script.gta1initcommands;
import game.script.script;

import util.vector3;
import util.convert;
import util.log;


public struct GTA1Command {
    uint line;
    GTA1CommandIndex index;
    int[6] params;
}

public struct GTA1InitCommand {
    uint line;
    Vector3 pos;
    GTA1InitCommandIndex index;
    int[6] params;
}


public final class GTA1Script : Script {
    
    private string _mapName;
    private uint _textIndex;
    
    private GTA1InitCommand[] _initCommands;
    private size_t[uint] _initCommandLines;

    private GTA1Command[] _commands;
    private size_t[uint] _commandLines;

    private GameStateLevel _state;
    private Style _style;
    private Map _map;


    this(const string mapName, const uint textIndex) {
        _mapName = mapName;
        _textIndex = textIndex;
    }

    public void addInitCommand(const uint line, const GTA1InitCommand cmd) {
        _initCommandLines[line] = _initCommands.length - 1;
        _initCommands ~= cmd;
    }

    public void addCommand(const uint line, const GTA1Command cmd) {
        _commandLines[line] = _commands.length - 1;
        _commands ~= cmd;
    }

    public override void init(GameStateLevel state, Style style, Map map) {
        _state = state;
        _style = style;
        _map = map;

        foreach (ref GTA1InitCommand cmd; _initCommands) {
            switch (cmd.index) {
                case GTA1InitCommandIndex.TELEPHONE:
                    map.spawn(style, "G1Phone", convertToPixels(cmd.pos), convertAngle(cmd.params[1]));
                    break;

                case GTA1InitCommandIndex.PARKED:
                    map.spawnVehicle(style, cast(VehicleModelIndex)cmd.params[0], convertToPixels(cmd.pos), convertAngle(cmd.params[1]), 0);
                    break;

                case GTA1InitCommandIndex.PARKED_PIXELS:
                    map.spawnVehicle(style, cast(VehicleModelIndex)cmd.params[0], flipZ(cmd.pos), convertAngle(cmd.params[1]), 0);
                    break;

                case GTA1InitCommandIndex.OBJECT:
                    map.spawn(style, style.getEntityTypeName(cast(EntityTypeIndex)cmd.params[0]), flipZ(cmd.pos), convertAngle(cmd.params[1]));
                    break;

                case GTA1InitCommandIndex.PLAYER:
                    Vector3 pos = convertToPixels(cmd.pos);
                    pos.z += 960;
                    state.camera.set(pos);
                    break;

                case GTA1InitCommandIndex.POWERUP:
                    Entity ent = map.spawnPowerup(style, getPowerupEntityName(cmd.params[0]), convertToPixels(cmd.pos), cmd.params[1]);
                    //ent.flags = cast(EntityFlags)(ent.flags | EntityFlags.DISABLED);

                    // This should not actually spawn the powerup, but is referred to from non-init script with POWERUP_ON\OFF
                    // non-init command POWERUP_ON removes disable flag. spawns crate if needed.
                    // POWERUP_OFF sets disable flag, removes crate??
                    /*if (cmd.params[0] != 14) {
                        _map.spawn(_style, "G1Crate", convertToPixels(cmd.pos), 0);
                    }*/
                    break;

                default:
                    //writefln("[GTA1] %d %s", cmd.line, to!string(cmd.index));
                    break;
            }
        }
    }

    public override void run() {
    }

    private string getPowerupEntityName(const uint index) {
        switch (index) {
            case 1: return "G1PowerupPistol";
            case 2: return "G1PowerupMachinegun";
            case 3: return "G1PowerupRocketLauncher";
            case 4: return "G1PowerupFlamethrower";
            case 6: return "G1PowerupLightning";
            case 9: return "G1PowerupCoin";
            case 10: return "G1PowerupShield";
            case 11: return "G1PowerupExtra";
            case 12: return "G1PowerupKey";
            case 13: return "G1PowerupHeart";
            case 14: return "G1PowerupInfo";
            case 15: return "G1PowerupHeart";
            default: throw new Exception(format("Unknown powerup type %d.", index));
        }
    }

    public void dump() {
        Log.write(Color.DEBUG, "MISSION %s %d", _mapName, _textIndex);

        Log.write(Color.DEBUG, "\nINIT");
        foreach (ref GTA1InitCommand cmd; _initCommands) {
            Log.write(Color.DEBUG, "%d (%.0f,%.0f,%.0f) %s %d %d %d %d %d", cmd.line, cmd.pos.x, cmd.pos.y, cmd.pos.z, cmd.index, cmd.params[0], cmd.params[1], cmd.params[2], cmd.params[3], cmd.params[4]);
        }

        Log.write(Color.DEBUG, "\nSCRIPT");
        foreach (ref GTA1Command cmd; _commands) {
            Log.write(Color.DEBUG, "%d %s %d %d %d %d %d", cmd.line, cmd.index, cmd.params[0], cmd.params[1], cmd.params[2], cmd.params[3], cmd.params[4]);
        }

        Log.write(Color.DEBUG, "\n");
    }

    @property public string mapName() {
        return _mapName;
    }

    @property public uint textIndex() {
        return _textIndex;
    }

}