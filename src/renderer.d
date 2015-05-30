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

module render.renderer;

import std.stdio;
import std.string;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

import util.console;
import util.log;


public final class Renderer {

    private uint _width;
    private uint _height;

    private SDL_Window* _window;
    private SDL_GLContext _gl;

    private CVar _cvarFullscreen;
    private CVar _cvarVSync;


    this() {
        _cvarFullscreen = CVars.get("r_fullscreen");
        _cvarVSync = CVars.get("r_vsync");

        _width = cast(uint)CVars.get("r_width").intVal;
        _height = cast(uint)CVars.get("r_height").intVal;

        DerelictGL3.load();

        SDL_InitSubSystem(SDL_INIT_VIDEO);

        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
        SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, CVars.get("r_aasamples").intVal > 0 ? 1 : 0);
        SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, cast(uint)CVars.get("r_aasamples").intVal);

        // Create window.
        uint flags = SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL | SDL_WINDOW_ALLOW_HIGHDPI;

        // Fullscreen.
        if (_cvarFullscreen.intVal == 1) {
            Log.write(Color.NORMAL, "Running in %dx%d fullscreen mode.", _width, _height);
            flags |= SDL_WINDOW_FULLSCREEN;

        // Fullscreen, at desktop resolution.
        } else if (_cvarFullscreen.intVal == 2) {
            flags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
            
            SDL_DisplayMode desktopMode;
            SDL_GetDesktopDisplayMode(0, &desktopMode);

            _width = desktopMode.w;
            _height = desktopMode.h;

            Log.write(Color.NORMAL, "Running in %dx%d fullscreen windowed mode.", _width, _height);
        
        // Windowed mode.
        } else {
            Log.write(Color.NORMAL, "Running in %dx%d windowed mode.", _width, _height);

        }

        _window = SDL_CreateWindow(
            "GTA Test",
            SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
            width, height,
            flags
        );
        if (_window == null) {
            throw new Exception(format("Could not create window: %s", SDL_GetError()));
        }

        _gl = SDL_GL_CreateContext(_window);
        SDL_GL_SetSwapInterval(_cvarVSync.intVal ? 1 : 0);

        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClearDepth(1.0f);
        
        glDepthMask(GL_TRUE);
        glDepthFunc(GL_LEQUAL);
        glDepthRange(0.0f, 1.0f);

        glCullFace(GL_BACK);
        glFrontFace(GL_CCW);

        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glEnable(GL_DEPTH_TEST);
        glEnable(GL_CULL_FACE);

        GLVersion ver = DerelictGL3.reload();
        Log.write(Color.NORMAL, "Loaded OpenGL version %.1f.", ver / 10.0);
    }

    ~this() {
        SDL_GL_DeleteContext(_gl);
        SDL_DestroyWindow(_window);
    }

    public void start() {
    }

    public void end() {
        SDL_GL_SwapWindow(_window);
    }

    public void clear() {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }

    @property uint width() {
        return _width;
    }

    @property uint height() {
        return _height;
    }
}
