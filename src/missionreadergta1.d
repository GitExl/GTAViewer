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

module game.script.missionreadergta1;

import std.stdio;
import std.file;
import std.path;
import std.string;
import std.conv;

import game.script.missionlist;
import game.script.missionreader;
import game.script.gta1script;
import game.script.gta1parser;
import game.script.gta1tokenizer;

import game.strings;

import util.binaryfile;
import util.log;


public final class MissionReaderGTA1 : MissionReader {

    this(const string baseDir) {
        string[] missionPaths = [
            buildPath(baseDir, "mission.ini"),
            buildPath(baseDir, "missuke.ini"),
            buildPath(baseDir, "missuk.ini")
        ];

        string fileName;
        foreach (string path; missionPaths) {
            if (exists(path)) {
                fileName = path;
                break;
            }
        }
        if (!fileName.length) {
            throw new Exception(format("Cannot find a mission script in GTA1 base directory '%s'.", baseDir));
        }

        Log.write(Color.NORMAL, "Reading GTA 1 mission script '%s'...", fileName);
        GTA1Tokenizer tokenizer = new GTA1Tokenizer(fileName);
        GTA1Parser parser = new GTA1Parser(tokenizer.tokens);

        // Iterate over the parsed scripts and fill in missing information.
        foreach (int index, GTA1Script script; parser.scripts) {
            Mission mission;

            mission.name = Strings.get(format("mission%s", to!string(script.textIndex)));
            
            // Hackish way to detect multiplayer maps.
            if (script.textIndex > 999) {
                mission.type = MissionType.MULTIPLAYER;
            } else {
                mission.type = MissionType.MAIN;
            }
            
            // Read map header.
            BinaryFile map = new BinaryFile(buildPath(baseDir, script.mapName));
            map.skip(4);
            ubyte styleIndex = map.readUByte();
            const ubyte audioBankIndex = map.readUByte();
            map.close();

            // FOr uk1961, detect if the differently named style file exists.
            string expansionStyle = format("sty%.3d.g24", styleIndex);
            if (exists(buildPath(baseDir, expansionStyle))) {
                mission.styleName = expansionStyle;
            } else {
                mission.styleName = format("style%.3d.g24", styleIndex);
            }

            mission.audioName = format("audio/level%.3d", audioBankIndex + 1);
            mission.mapName = script.mapName;
            mission.cityName = Strings.get(format("city%d", styleIndex - 1));

            mission.script = script;

            _missions ~= mission;
        }
    }

}