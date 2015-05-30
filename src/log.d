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

module util.log;

import std.stdio;

import core.sys.windows.windows;


/**
* Color bits for character attributes.
* See <a href="http://msdn.microsoft.com/en-us/library/windows/desktop/ms682088%28v=vs.85%29.aspx#_win32_character_attributes">MSDN</a> for
* more information about these attributes.
*/  
public enum ColorBits : ushort {
    FOREGROUND_BLUE = 1,
    FOREGROUND_GREEN = 2,
    FOREGROUND_RED = 4,
    FOREGROUND_INTENSE = 8,
    BACKGROUND_BLUE = 16,
    BACKGROUND_GREEN = 32,
    BACKGROUND_RED = 64,
    BACKGROUND_INTENSE = 128
}

/// Predefined colors.
public enum Color : ushort {
    NORMAL  = 0xFFFF,
    ERROR   = ColorBits.FOREGROUND_RED | ColorBits.FOREGROUND_INTENSE,
    WARNING = ColorBits.FOREGROUND_RED | ColorBits.FOREGROUND_GREEN   | ColorBits.FOREGROUND_INTENSE,
    DEBUG   = ColorBits.FOREGROUND_INTENSE,
}


public final class Log {

    /// A handle to the current console instance.
    private static HANDLE _consoleHandle;

    /// Stored console buffer configuration.
    private static CONSOLE_SCREEN_BUFFER_INFO _bufferInfo;


    static this() {
        _consoleHandle = GetStdHandle(STD_OUTPUT_HANDLE);

        // Store the console buffer configuration for later restoration.
        GetConsoleScreenBufferInfo(_consoleHandle, &_bufferInfo);
    }

    public static void write(Ushort, Char, A...)(in Ushort color, in Char[] fmt, A args) {
        if (color != 0xFFFF) {
            SetConsoleTextAttribute(_consoleHandle, color);
        }
        writefln(fmt, args);
        if (color != 0xFFFF) {
            SetConsoleTextAttribute(_consoleHandle, _bufferInfo.wAttributes);
        }
    }

}
