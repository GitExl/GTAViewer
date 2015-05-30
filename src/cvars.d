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

module cvars;

import util.console;


public void registerCVars() {
    // Game
    CVars.register("g_fov",          new CVar(35.0,   CVarFlags.ARCHIVE));
    CVars.register("g_basedir",      new CVar("gta1", CVarFlags.ARCHIVE));
    CVars.register("g_mission",      new CVar(0,      CVarFlags.ARCHIVE));
    CVars.register("g_language",     new CVar("en",   CVarFlags.ARCHIVE));
    CVars.register("g_dusk",         new CVar(0,      CVarFlags.ARCHIVE));

    // Render
    CVars.register("r_blockmipmaps",       new CVar(3,    CVarFlags.ARCHIVE));
    CVars.register("r_spritemipmaps",      new CVar(3,    CVarFlags.ARCHIVE));
    CVars.register("r_width",              new CVar(1280, CVarFlags.ARCHIVE));
    CVars.register("r_height",             new CVar(720,  CVarFlags.ARCHIVE));
    CVars.register("r_filter",             new CVar(1,    CVarFlags.ARCHIVE));
    CVars.register("r_anisotropy",         new CVar(16,   CVarFlags.ARCHIVE));
    CVars.register("r_aasamples",          new CVar(0,    CVarFlags.ARCHIVE));
    CVars.register("r_shadows",            new CVar(1,    CVarFlags.ARCHIVE));
    CVars.register("r_dumpblocktextures",  new CVar(0,    CVarFlags.ARCHIVE));
    CVars.register("r_dumpsprites",        new CVar(0,    CVarFlags.ARCHIVE));
    CVars.register("r_dumpspritetextures", new CVar(0,    CVarFlags.ARCHIVE));
    CVars.register("r_fullscreen",         new CVar(0,    CVarFlags.ARCHIVE));
    CVars.register("r_vsync",              new CVar(1,    CVarFlags.ARCHIVE));
    CVars.register("r_frameratelimit",     new CVar(60,   CVarFlags.ARCHIVE));

    // Audio
    CVars.register("a_maxsources",         new CVar(40,  CVarFlags.ARCHIVE));
    CVars.register("a_loopsourcesratio",   new CVar(0.5, CVarFlags.ARCHIVE));
    CVars.register("a_singlesourcesratio", new CVar(0.5, CVarFlags.ARCHIVE));
    CVars.register("a_dopplerfactor",      new CVar(1.0, CVarFlags.ARCHIVE));

    // Map
    CVars.register("m_border",     new CVar(2,  CVarFlags.ARCHIVE));
    CVars.register("m_sectorsize", new CVar(32, CVarFlags.ARCHIVE));
}
    