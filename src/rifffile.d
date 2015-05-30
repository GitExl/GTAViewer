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

module util.rifffile;

import std.stdio;
import std.string;
import std.conv;

import util.binaryfile;
import util.log;


public struct Chunk {
    char[4] name;
    uint size;
    uint offset;
}


public final class RIFFFile {

    private BinaryFile _file;
    private char[4] _type;
    private ushort _versionNum;
    private Chunk[] _chunks;
    private uint[string] _chunkNames;


    this(BinaryFile file) {
        _file = file;
        _type = cast(char[])_file.readBytes(4);
        _versionNum = _file.readUShort();

        while (_file.offset < _file.size) {
            Chunk chunk;
            chunk.name = cast(char[])_file.readBytes(4);
            chunk.size = _file.readUInt();
            chunk.offset = _file.offset;

            _chunks ~= chunk;
            _chunkNames[to!string(chunk.name)] = _chunks.length - 1;

            _file.seek(chunk.offset + chunk.size);
        }
    }

    public Chunk getChunk(const string name) {
        if (name !in _chunkNames) {
            throw new Exception(format("RIFF file '%s' does not contain chunk '%s'.", _file.name, name));
        }

        const Chunk chunk = _chunks[_chunkNames[name]];
        _file.seek(chunk.offset);

        return chunk;
    }

    public void listChunks() {
        Log.write(Color.DEBUG, "Listing chunks for '%s':", _file.name);
        foreach (ref Chunk chunk; _chunks) {
            Log.write(Color.DEBUG, "%s  %d %d", chunk.name, chunk.size, chunk.offset);
        }
    }

    public bool contains(const string name) {
        return (name in _chunkNames) !is null;
    }

    public void close() {
        _file.close();
        _file = null;
    }

    @property public char[4] type() {
        return _type;
    }

    @property public ushort versionNum() {
        return _versionNum;
    }

    @property public BinaryFile file() {
        return _file;
    }

}