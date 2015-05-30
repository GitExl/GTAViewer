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

import std.stdio;
import std.string;

import derelict.sdl2.sdl;

import game.game;
import game.gamestate;

import util.timer;
import util.console;
import util.log;

import cvars;


private immutable uint MAX_TICKSKIP = 5;

private immutable uint TICKRATE = 25;
private immutable ulong TICKTIME = 1000000 / TICKRATE;

private immutable string CONFIG_FILENAME = "data/config.json";


private bool running;
private ubyte* keys;

private ulong renderStart;
private ulong renderEnd;

private ulong updateStart;
private ulong updateEnd;

private ulong nextTick;
private ulong nextFrame;

private Game cGame;

private CVar cvarFramerateLimit;
private CVar cvarVSync;


int main(string[] argv) {

    registerCVars();
    CVars.load(CONFIG_FILENAME);

    cvarFramerateLimit = CVars.get("r_frameratelimit");
    cvarVSync = CVars.get("r_vsync");

    DerelictSDL2.load();

    SDL_version sdlVersionCompiled;
    SDL_version sdlVersionLinked;
    
    SDL_VERSION(&sdlVersionCompiled);
    SDL_GetVersion(&sdlVersionLinked);

    Log.write(Color.NORMAL, "SDL (compile) %d.%d.%d", sdlVersionCompiled.major, sdlVersionCompiled.minor, sdlVersionCompiled.patch); 
    Log.write(Color.NORMAL, "SDL (link)    %d.%d.%d", sdlVersionLinked.major, sdlVersionLinked.minor, sdlVersionLinked.patch);

    SDL_Init(0);

    timerInit();

    ulong counter;
    uint loopCount;

    double interpolation = 0.0f;

    // Determine framerate control settings.
    ulong renderTime;
    if (cvarFramerateLimit.intVal && !cvarVSync.intVal) {
        renderTime = 1000000 / cvarFramerateLimit.intVal;
        Log.write(Color.NORMAL, "Limiting framerate to %d FPS.", cvarFramerateLimit.intVal);
    } else {
        if (cvarVSync.intVal) {
            Log.write(Color.NORMAL, "VSync enabled.");
        }
        renderTime = 0;
    }

    cGame = new Game();

    nextTick = timerGetCounter();
    nextFrame = timerGetCounter();
    
    running = true;
    for(;;) {
        // Execute ticks until we have caught up with the next tick time.
        // If many ticks were missed, do not try and catch up to all of them without rendering.
        loopCount = 0;
        while (running && timerGetCounter() > nextTick && loopCount < MAX_TICKSKIP) {
            loopCount++;

            updateKeys();

            updateStart = timerGetCounter();
            cGame.input(keys);
            cGame.update(1.0f / TICKRATE);
            updateEnd = timerGetCounter();

            // Keep track of when the next tick must occur.
            nextTick += TICKTIME;
        }

        if (running == false) {
            break;
        }

        // Render a frame if there is time to render a full frame before the next tick.
        if (renderTime) {
            if (nextFrame < nextTick) {
            
                // Wait until we have to render the next frame.
                counter = timerGetCounter();
                if (cast(long)nextFrame - cast(long)counter > 0) {
                    timerWait(nextFrame - counter);
                }

                // Calculate the time of the next frame, and what position to interpolate the current frame at.
                nextFrame = timerGetCounter() + renderTime;
                render();
            }
        } else {
            render();
        }
    }

    cGame.destroy();
    CVars.save(CONFIG_FILENAME);

    SDL_Quit();
    
    return 0;
}

private void render() {
    const ulong counter = timerGetCounter();
    const double interpolation = cast(double)(counter + TICKTIME - nextTick) / cast(double)TICKTIME;

    renderStart = timerGetCounter();
    cGame.render(interpolation);
    renderEnd = timerGetCounter();

    //Log.write(Color.DEBUG, "R: %.2f ms, U: %.2f ms", (renderEnd - renderStart) / 1000.0, (updateEnd - updateStart) / 1000.0);
}

private void updateKeys() {
    SDL_Event event;

    while(SDL_PollEvent(&event)) {
        switch (event.type) {
            case SDL_QUIT:
                running = false;
                break;
            default:
                break;
        }
    }

    keys = SDL_GetKeyboardState(null);

    if (keys[SDL_SCANCODE_ESCAPE] == true) {
        running = false;
    }
}