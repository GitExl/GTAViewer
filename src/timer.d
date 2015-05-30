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

module util.timer;

import std.stdio;

import derelict.sdl2.sdl;


private ulong startTime;
private ulong endTime;

private double performanceFrequency;


public void timerInit() {
    performanceFrequency = cast(double)SDL_GetPerformanceFrequency();
}

public void timerStart() {
    startTime = timerGetCounter();
}

public ulong timerStop() {
    endTime = timerGetCounter();
    return endTime - startTime;
}

public void timerWait(const ulong delay) {
    static long fudge;

    // Suspend thread and measure how long the suspension lasted.
    ulong delayStart = timerGetCounter();
    if (cast(int)(delay - fudge) / 1000 < 0) {
        fudge -= 2;
        return;
    }
    SDL_Delay(cast(int)(delay - fudge) / 1000);
    long delayTime = timerGetCounter() - delayStart;

    // If the thread was suspended too long, wait less next time.
    if (delayTime > delay) {
        fudge += 8;

    // Busywait the remaining period.
    } else if (delayTime < delay) {
        delayStart = timerGetCounter();
        while(timerGetCounter() - delayStart < delay - delayTime) {
            SDL_Delay(0);
        }
        fudge -= 4;
    }
}

public ulong timerGetCounter() {
    return cast(ulong)((SDL_GetPerformanceCounter() / performanceFrequency) * 1000000);
}