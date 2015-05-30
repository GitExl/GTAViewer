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

module game.strings;

import std.stdio;
import std.string;
import std.path;
import std.utf;
import std.algorithm;

import util.binaryfile;
import util.rifffile;
import util.log;


private struct Key {
    uint offset;
    string name;
}


public static final class Strings {

    private static string[string] _strings;

    
    public static load(const string fileName) {
        const string ext = toLower(extension(fileName));
        if (ext == ".fxt") {
            readFXT(fileName);
        } else if (ext == ".gxt") {
            readGXT(fileName);
        } else {
            throw new Exception(format("Strings file '%s' is of an unknown format.", fileName));
        }

        Log.write(Color.NORMAL, "Read %d strings.", _strings.length);
    }

    private static void readGXT(const string fileName) {
        Log.write(Color.NORMAL, "Reading GXT strings from '%s'...", fileName);

        BinaryFile file = new BinaryFile(fileName);
        RIFFFile riff = new RIFFFile(file);
        if (riff.type[0..3] != "GBL" || riff.versionNum != 0x64) {
            throw new Exception(format("Strings file '%s' is invalid.", fileName));
        }

        // Read keys and offsets.
        const Chunk chunk = riff.getChunk("TKEY");
        uint endOffset = file.offset + chunk.size;
        Key[] keys;
        while (file.offset < endOffset) {
            Key key;
            key.offset = file.readUInt();
            key.name = file.readNullString(8);

            keys ~= key;
        }

        // Read strings.
        const Chunk textChunk = riff.getChunk("TDAT");
        foreach (Key key; keys) {
            file.seek(textChunk.offset + key.offset);
            
            char[] text;
            while (!file.eof) {
                const ubyte c = file.readUByte();
                const ubyte m = file.readUByte();
                
                if (c == 0 && m == 0) {
                    break;
                }

                // Insert control characters directly into the string.
                if (m != 0) {
                    text ~= m;
                }
                text ~= c;
            }
                        
            _strings[key.name] = cast(string)text;
        }
    }

    private static void readFXT(const string fileName) {
        Log.write(Color.NORMAL, "Reading FXT strings from '%s'...", fileName);

        BinaryFile file = new BinaryFile(fileName);
        ubyte[] data = file.readBytes(file.size);

        // Detect GTA1 or GTA1 demo type from the first character, which should always be a '['.
        ubyte enc;
        byte offset;
        if (data[0] == 0xBF) {
            enc = 0x63;
            offset = -1;
        } else if (data[0] == 0xA6) {
            enc = 0x67;
            offset = 28;
        } else {
            throw new Exception("Cannot identify FXT file type.");
        }

        // Decrypt first 8 bytes.
        for (int i = 0; i < 8; i++) {
            data[i] = cast(ubyte)(data[i] - enc);
            enc <<= 1;
        }
        
        // "Decrypt" rest of file.
        for (int i = 0; i < data.length; i++) {
            data[i] += offset;
        }

        // Divide into lines.
        char[][] lines;
        uint start = 0;
        foreach (int index, char c; data) {
            if (c == 0) {
                lines ~= cast(char[])data[start..index];
                start = index + 1;
            }
        }

        // Parse lines.
        char[] key;
        char[] txt;
        foreach (char[] line; lines) {
            foreach (int index, char c; line) {
                if (c == ']') {
                    key = line[1..index];
                    txt = line[index + 1..$];
                    if (key.length) {
                        _strings[cast(string)key] = toUTF8(txt);
                    }
                    break;
                }
            }
        }
    }

    public static string get(const string key) {
        if (key !in _strings) {
            throw new Exception(format("Cannot find string key '%s'.", key));
        }

        return _strings[key];
    }

    public static void dump() {
        string[] keys = _strings.keys.dup;
        sort(keys);

        foreach (string key; keys) {
            Log.write(Color.DEBUG, "[%s] %s", key, _strings[key]);
        }
    }

}