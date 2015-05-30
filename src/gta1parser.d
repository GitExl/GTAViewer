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

module game.script.gta1parser;

import std.stdio;
import std.string;
import std.conv;
import std.path;

import game.script.gta1tokenizer;
import game.script.gta1commands;
import game.script.gta1initcommands;
import game.script.gta1script;

import util.vector3;


private enum Mode : ubyte {
    MISSION_SEARCH,
    MISSION_INIT,
    MISSION
}


public final class GTA1Parser {

    private Token[] _tokens;
    private uint _index;

    private GTA1Script[] _scripts;


    this(Token[] tokens) {
        _tokens = tokens;

        GTA1Script script;
        Mode mode = Mode.MISSION_SEARCH;
        int line = 0;

        Token token = getToken();
        while (token.type != TokenType.EOF) {

            // Not in a mission block yet, check for one.
            if (mode == Mode.MISSION_SEARCH) {
                if (token.type == TokenType.BRACKET_OPEN) {
                    const uint textIndex = getIntegerToken();
                    skipToken(TokenType.BRACKET_CLOSE);

                    skipUntil(TokenType.INTEGER);
                    skipToken(TokenType.INTEGER);

                    const string mapName = baseName(toLower(getStringToken()));
                    
                    // Skip what seems to be unused info.
                    skipToken(TokenType.INTEGER);
                    skipToken(TokenType.NEWLINE);
                    skipToken(TokenType.INTEGER);
                    skipToken(TokenType.INTEGER);
                    skipToken(TokenType.INTEGER);
                    skipToken(TokenType.INTEGER);
                    skipToken(TokenType.INTEGER);
                    skipToken(TokenType.INTEGER);

                    script = new GTA1Script(mapName, textIndex);

                    mode = Mode.MISSION_INIT;
                }

            // Mission initialization.
            } else if (mode == Mode.MISSION_INIT) {
                skipWhitespace();

                line = getIntegerToken();

                // Start mission script.
                if (line == -1) {
                    mode = Mode.MISSION;

                // Initialization commands.
                } else {
                    if (peekToken().type == TokenType.INTEGER) {
                        skipToken(TokenType.INTEGER);
                    }
                    skipToken(TokenType.BRACE_OPEN);

                    GTA1InitCommand cmd;
                    cmd.line = line;
                    cmd.pos.x = getIntegerToken();
                    cmd.pos.y = getIntegerToken();
                    cmd.pos.z = getIntegerToken();
                    skipToken(TokenType.BRACE_CLOSE);
                    
                    const string cmdName = getStringToken();
                    try {
                        cmd.index = to!GTA1InitCommandIndex(cmdName);
                    } catch (ConvException) {
                        throw new Exception(format("Line %d, column %d: unknown initialization command '%s'.", currentLine, currentColumn, cmdName));
                    }

                    // Parameters.
                    for (int paramIndex = 0; paramIndex < cmd.params.length; paramIndex++) {
                        if (peekToken().type == TokenType.NEWLINE) {
                            break;
                        }
                        cmd.params[paramIndex] = getIntegerToken();
                    }
                    if (peekToken().type != TokenType.NEWLINE) {
                        throw new Exception(format("Line %d: too may parameters for initialization command.", currentLine));
                    }

                    script.addInitCommand(line, cmd);
                }

            // Mission script.
            } else if (mode == Mode.MISSION) {
                skipWhitespace();

                line = getIntegerToken();

                // Terminate mission script.
                if (line == -1) {
                    _scripts ~= script;
                    script = null;
                    mode = Mode.MISSION_SEARCH;
                
                // Mission script commands.
                } else {
                    GTA1Command cmd;
                    cmd.line = line;
                    
                    const string cmdName = getStringToken();
                    try {
                        cmd.index = to!GTA1CommandIndex(cmdName);
                    } catch (ConvException) {
                        throw new Exception(format("Line %d, column %d: unknown command '%s'.", currentLine, currentColumn, cmdName));
                    }

                    // Parameters.
                    for (int paramIndex = 0; paramIndex < cmd.params.length; paramIndex++) {
                        if (peekToken().type == TokenType.NEWLINE) {
                            break;
                        }
                        cmd.params[paramIndex] = getIntegerToken();
                    }
                    if (peekToken().type != TokenType.NEWLINE) {
                        throw new Exception(format("Line %d: too may parameters for command.", currentLine));
                    }

                    script.addCommand(line, cmd);
                }
            }

            token = getToken();
        }
    }

    private void skipAmount(const uint amount) {
        if (_index + amount >= _tokens.length) {
            _index = _tokens.length - 1;
        } else {
            _index += amount;
        }
    }

    private void skipUntil(const TokenType type) {
        while (getToken().type != type) {}
        _index--;
    }

    private void skipWhitespace() {
        while (getToken().type == TokenType.NEWLINE) {}
        _index--;
    }

    private Token peekToken() {
        return _tokens[_index];
    }

    private Token getToken() {
        return _tokens[_index++];
    }

    private int getIntegerToken() {
        Token token = getToken();
        if (token.type != TokenType.INTEGER) {
            throw new Exception(format("Line %d, column %d: Expected %s.", token.line, token.column, getTokenTypeName(TokenType.INTEGER)));
        }
        return token.value.integer;
    }

    private string getStringToken() {
        Token token = getToken();
        if (token.type != TokenType.STRING) {
            throw new Exception(format("Line %d, column %d: Expected %s.", token.line, token.column, getTokenTypeName(TokenType.STRING)));
        }
        return token.value.str;
    }

    private void skipToken(const TokenType type) {
        Token token = getToken();
        if (token.type != type) {
            throw new Exception(format("Line %d, column %d: Expected %s.", token.line, token.column, getTokenTypeName(type)));
        }
    }

    @property private uint currentLine() {
        return _tokens[_index - 1].line;
    }

    @property private uint currentColumn() {
        return _tokens[_index - 1].column;
    }

    @property public GTA1Script[] scripts() {
        return _scripts;
    }

}