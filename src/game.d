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

module game.game;

import std.stdio;
import std.path;
import std.string;

import game.gamestate;
import game.gamestate_level;
import game.strings;

import game.script.missionlist;

import render.renderer;

import audio.audio;

import util.console;
import util.log;


public enum GameMode : ubyte {
    NONE,
    GTA1,
    GTA2
}

public GameMode gameMode = GameMode.NONE;
public bool gameDemo = false;


public final class Game {
    
    private Renderer _renderer;
    private Audio _audio;
    
    private GameState[] _states;
    
    private MissionList _missions;

    private CVar _cvarMission;
    private CVar _cvarBaseDir;
    private CVar _cvarLanguage;


    this() {
        _cvarMission = CVars.get("g_mission");
        _cvarBaseDir = CVars.get("g_basedir");
        _cvarLanguage = CVars.get("g_language");

        _renderer = new Renderer();
        _audio = new Audio();

        // Determine game mode.
        switch (toLower(_cvarBaseDir.strVal)) {
            case "gta1":
            case "uk":
            case "uk1961":
                gameMode = GameMode.GTA1;
                gameDemo = false;
                Log.write(Color.NORMAL, "Running in GTA 1 mode.");
                break;
            case "gta1demo":
            case "gta1demo3dfx":
            case "gta1demoects":
                gameMode = GameMode.GTA1;
                gameDemo = true;
                Log.write(Color.NORMAL, "Running in GTA 1 demo mode.");
                break;
            case "gta2":
                gameMode = GameMode.GTA2;
                gameDemo = false;
                Log.write(Color.NORMAL, "Running in GTA 2 mode.");
                break;
            case "gta2demo":
                gameMode = GameMode.GTA2;
                gameDemo = true;
                Log.write(Color.NORMAL, "Running in GTA 2 demo mode.");
                break;
            default:
                Log.write(Color.WARNING, "Unrecognized base directory '%s'. Defaulting to GTA 1 mode.", _cvarBaseDir.strVal);
                gameMode = GameMode.GTA1;
                gameDemo = false;
                break;
        }

        // Read string table.
        const string langFile = getLanguageFile(_cvarLanguage.strVal);
        Strings.load(buildPath("base", _cvarBaseDir.strVal, langFile));

        // Build mission list.
        _missions = new MissionList();
        Mission mission = _missions.getMission(cast(uint)_cvarMission.intVal);

        _states ~= new GameStateLevel(this, mission);
    }

    public void destroy() {
        _renderer.destroy();
    }

    public void input(ubyte* keys) {
        foreach_reverse (GameState state; _states) {
            if (state.isEnabled) {
                state.input(keys);
                break;
            }
        }
    }

    public void update(const double delta) {
        foreach (GameState state; _states) {
            if (state.isEnabled) {
                state.update(delta);
            }
        }
    }

    public void render(const double lerp) {
        _renderer.start();
        _renderer.clear();

        foreach (GameState state; _states) {
            if (state.isEnabled) {
                state.render(lerp);
            }
        }

        _renderer.end();
    }

    private string getLanguageFile(const string code) {
        if (gameMode == GameMode.GTA1 && _cvarBaseDir.strVal == "uk") {
            switch (_cvarLanguage.strVal) {
                case "en": return "enguk.fxt";
                case "de": return "geruk.fxt";
                case "it": return "itauk.fxt";
                case "fr": return "freuk.fxt";
                default:
                    throw new Exception(format("Unknown GTA 1 language code '%s'.", code));
            }

        } else if (gameMode == GameMode.GTA1 && _cvarBaseDir.strVal == "uk1961") {
            return "enguke.fxt";

        } else if (gameMode == GameMode.GTA1) {
            switch (_cvarLanguage.strVal) {
                case "en": return "english.fxt";
                case "de": return "german.fxt";
                case "it": return "italian.fxt";
                case "fr": return "french.fxt";
                default:
                    throw new Exception(format("Unknown GTA 1 language code '%s'.", code));
            }

        } else if (gameMode == GameMode.GTA2) {
            switch (_cvarLanguage.strVal) {
                case "en": return "e.gxt";
                case "de": return "g.gxt";
                case "it": return "i.gxt";
                case "fr": return "f.gxt";
                case "es": return "s.gxt";
                case "ja": return "j.gxt";
                default:
                    throw new Exception(format("Unknown GTA 2 language code '%s'.", code));
            }
        }

        throw new Exception("Invalid gamemode.");
    }

    @property public Renderer renderer() {
        return _renderer;
    }

    @property public Audio audio() {
        return _audio;
    }
}
