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

module game.script.missionlist;

import std.path;
import std.string;

import game.game;

import game.script.missionreader;
import game.script.missionreadergta1;
import game.script.missionreadergta2;
import game.script.script;

import util.console;


public enum MissionType : ubyte {
    UNKNOWN,
    MAIN,
    BONUS,
    MULTIPLAYER
}


public struct Mission {
    string name;
    string cityName;
    MissionType type;

    string mapName;
    string styleName;
    string audioName;

    Script script;
}


public final class MissionList {

    private Mission[] _missions;

    
    this() {
        MissionReader reader;
        CVar cvarBasePath = CVars.get("g_basedir");

        const string path = buildPath("base", cvarBasePath.strVal);
        if (gameMode == GameMode.GTA1) {
            reader = new MissionReaderGTA1(path);
        } else if (gameMode == GameMode.GTA2) {
            reader = new MissionReaderGTA2(path);
        }

        _missions = reader.getMissions();
    }

    public Mission getMission(const uint index) {
        if (index >= _missions.length) {
            throw new Exception(format("Mission index '%d' does not exist.", index));
        }
        return _missions[index];
    }

}