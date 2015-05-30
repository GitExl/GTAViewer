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

module game.script.gta1tokenizer;

import std.stdio;
import std.file;
import std.conv;
import std.traits;
import std.string;


public enum TokenType : ubyte {
    INTEGER,
    STRING,
    BRACE_OPEN,
    BRACE_CLOSE,
    BRACKET_OPEN,
    BRACKET_CLOSE,
    NEWLINE,
    EOF,
}


public union TokenValue {
    int integer;
    string str;
}

public struct Token {
    uint line;
    uint column;

    TokenType type;
    TokenValue value;
}


public final class GTA1Tokenizer {

    private char[] _input;
    private uint _index;
    private uint _line;
    private uint _column;

    private Token[] _tokens;


    this(const string fileName) {
        _input = cast(char[])readText(fileName);

        _line = 1;
        char[] str;
        while (_index < _input.length) {
            const char c = _input[_index];

            // Comment
            if (c == ';') {
                emitToken(str);
                str.length = 0;
                while (_input[_index] != '\n') {
                    _index++;
                    _line++;
                    _column = 0;
                }

            // Brackets
            } else if (c == '[') {
                emitToken(str);
                str.length = 0;
                emitToken(TokenType.BRACKET_OPEN);
            } else if (c == ']') {
                emitToken(str);
                str.length = 0;
                emitToken(TokenType.BRACKET_CLOSE);
            
            // Braces
            } else if (c == '(') {
                emitToken(str);
                str.length = 0;
                emitToken(TokenType.BRACE_OPEN);
            } else if (c == ')') {
                emitToken(str);
                str.length = 0;
                emitToken(TokenType.BRACE_CLOSE);

            // Separators
            } else if (c == ' ' || c == ',' || c == '\r' || c == '\t') {
                emitToken(str);
                str.length = 0;

                // Newlines
                if (c == '\r') {
                    if (_input[_index + 1] == '\n') {
                        emitToken(TokenType.NEWLINE);
                        _line++;
                        _column = 0;

                        _index++;
                    }
                }

            } else {
                str ~= c;

            }

            _index++;
            _column++;
        }

        emitToken(TokenType.EOF);
    }

    private bool isInteger(const char[] str) {
        if (!str.length) {
            return false;
        }

        foreach (char c; str) {
            if ((c < '0' || c > '9') && c != '-' && c != '.') {
                return false;
            }
        }

        return true;
    }

    private void emitToken(const char[] str) {
        if (!str.length) {
            return;
        }

        Token token;
        token.line = _line;
        token.column = _column - str.length;
        
        if (isInteger(str)) {
            token.type = TokenType.INTEGER;

            int pIndex = -1;
            foreach (int index, char c; str) {
                if (c == '.') {
                    pIndex = index;
                    break;
                }
            }

            // Split malformed integers into two integer tokens.
            if (pIndex != -1) {
                token.value.integer = to!int(str[0..pIndex - 1]);
                _tokens ~= token;

                token.column += pIndex;
                token.value.integer = to!int(str[pIndex + 1..$]);
            } else {
                token.value.integer = to!int(str);
            }
        } else {
            token.type = TokenType.STRING;
            token.value.str = to!string(str);
        }

        _tokens ~= token;
    }

    private void emitToken(const TokenType type) {
        Token token;
        token.type = type;
        token.line = _line;
        token.column = _column;
        _tokens ~= token;
    }

    @property public Token[] tokens() {
        return _tokens;
    }
}

public string getTokenTypeName(const TokenType type) {
    if (type == TokenType.BRACE_CLOSE) {
        return "closing brace";
    } else if (type == TokenType.BRACE_OPEN) {
        return "opening brace";
    } else if (type == TokenType.BRACKET_CLOSE) {
        return "closing bracket";
    } else if (type == TokenType.BRACKET_OPEN) {
        return "opening bracket";
    } else if (type == TokenType.INTEGER) {
        return "integer";
    } else if (type == TokenType.STRING) {
        return "string";
    } else if (type == TokenType.NEWLINE) {
        return "newline";
    } else if (type == TokenType.EOF) {
        return "end of file";
    }

    throw new Exception(format("No type name for token type %d.", type));
}