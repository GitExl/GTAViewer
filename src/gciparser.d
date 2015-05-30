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

module util.gciparser;

import std.stdio;
import std.file;
import std.conv;


public enum GCIType : ubyte {
    INTEGER,
    FLOATING,
    STRING,
    EOF
}

public union GCIValueData {
    int integer;
    double floating;
    string str;
}

public struct GCIValue {
    GCIType type;
    GCIValueData value;
}

private enum CType : char {
    STRING_START = '{',
    STRING_END = '}',
    FLOATING = 'f',
    SPACE = ' ',
    CR = '\r',
    LF = '\n',
    TAB = '\t',
}


public final class GCIParser {

    private string _name;
    private char[] _text;
    private uint _index;
    

    this(string fileName) {
        _name = fileName;
        _text = cast(char[])read(_name);
    }

    public GCIValue parse() {
        GCIValue value;

        while (_index < _text.length) {
            const char c = _text[_index];
            
            // Strings.
            if (c == CType.STRING_START) {
                value.type = GCIType.STRING;
                value.value.str = parseString();
                return value;
            
            // Floating point values.
            } else if (c == CType.FLOATING) {
                value.type = GCIType.FLOATING;
                value.value.floating = parseFloat();
                return value;
            
            // Integer values.
            } else if (c >= 48 && c <= 57) {
                value.type = GCIType.INTEGER;
                value.value.integer = parseInteger();
                return value;
            }

            _index++;
        }

        value.type = GCIType.EOF;
        return value;
    }

    private string parseString() {
        string str;

        _index++;
        while (_index < _text.length) {
            const char c = _text[_index];

            if (c == CType.STRING_END) {
                return str;
            }

            str ~= c;
            _index++;
        }

        return str;
    }

    private float parseFloat() {
        string str;

        _index++;
        while (_index < _text.length) {
            const char c = _text[_index];

            if (isWhitespace(c)) {
                return to!float(str);
            }

            str ~= c;
            _index++;
        }
        
        return to!float(str);
    }

    private int parseInteger() {
        string str;

        while (_index < _text.length) {
            const char c = _text[_index];

            if (isWhitespace(c)) {
                return to!int(str);
            }

            str ~= c;
            _index++;
        }
        
        return to!int(str);
    }

    private bool isWhitespace(const char c) {
        return (c == CType.SPACE || c == CType.CR || c == CType.LF || c == CType.TAB);
    }

}