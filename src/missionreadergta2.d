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

module game.script.missionreadergta2;

import std.stdio;
import std.file;
import std.path;
import std.algorithm;
import std.string;

import game.game;

import game.script.missionlist;
import game.script.missionreader;
import game.script.gta2script;

import util.log;


public final class MissionReaderGTA2 : MissionReader {

    this(const string baseDir) {
        readSequence(baseDir, buildPath(baseDir, "test1.seq"));
        
        // Read MMP files.
        string[] files;
        foreach (DirEntry entry; dirEntries(baseDir, SpanMode.breadth)) {
            if (!endsWith(entry.name, ".mmp")) {
                continue;
            }
            files ~= entry.name;
        }
        sort(files);
        foreach (string name; files) {
            readSequence(baseDir, name);
            _missions[_missions.length - 1].type = MissionType.MULTIPLAYER;
        }
    }

    private void readSequence(const string baseDir, const string fileName) {
        Mission mission;

        Log.write(Color.NORMAL, "Reading GTA 2 sequence '%s'...", fileName);
        
        const string input = cast(string)read(fileName);
        foreach (string line; input.splitter('\n')) {
            ptrdiff_t index = line.indexOf('=');
            if (index >= 0) {
                const string key = strip(line[0..index]);
                const string value = strip(line[index + 1..$]);
                
                if (key == "MainOrBonus") {
                    if (value == "MAIN") {
                        mission.type = MissionType.MAIN;
                    } else if (value == "BONUS") {
                        mission.type = MissionType.BONUS;
                    } else {
                        throw new Exception(format("Unknown MainOrBonus value '%s'.", value));
                    }
                
                } else if (key == "GMPFile") {
                    if (gameDemo) {
                        mission.mapName = stripExtension(value) ~ "demo" ~ extension(value);
                    } else {
                        mission.mapName = value;
                    }

                } else if (key == "STYFile") {
                    mission.styleName = value;

                } else if (key == "SCRFile") {
                    string scriptName;
                    if (gameDemo) {
                        scriptName = stripExtension(value) ~ "demo" ~ extension(value);
                    } else {
                        scriptName = value;
                    }
                    mission.script = new GTA2Script(buildPath(baseDir, scriptName));

                } else if (key == "Description") {
                    mission.name = value;
                    mission.cityName = "Anywhere";

                    if (gameDemo) {
                        mission.audioName = "audio/bil";
                    } else {
                        const string styleName = mission.styleName[0..mission.styleName.length - 4];
                        mission.audioName = format("audio/%s", styleName);
                    }

                    _missions ~= mission;
                    mission = mission.init;

                }
            }
        }
    }

}