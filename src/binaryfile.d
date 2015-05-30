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

module util.binaryfile;

import std.stdio;
import std.string;
import std.bitmanip;
import std.file;


public final class BinaryFile {

    private string _name;
    private ubyte[] _data;
    private uint _offset;


    this(const string fileName) {
        _name = fileName;
        _data = cast(ubyte[])read(fileName);
    }

    public void seek(const uint offset) {
        _offset = offset;
    }

    public void skip(const uint bytes) {
        _offset += bytes;
    }

    public string readNullString(const uint length) {
        ubyte[] buffer = _data[_offset.._offset + length];
        _offset += length;

        int nullIndex = length;
        for (int index = 0; index < length; index++) {
            if (buffer[index] == 0) {
                nullIndex = index;
                break;
            }
        }

        return cast(string)buffer[0..nullIndex];
    }

    public string readString(const uint length) {
        ubyte[] buffer = _data[_offset.._offset + length];
        _offset += length;

        return cast(string)buffer[0..length];
    }

    public ubyte[] readBytes(const uint amount) {
        ubyte[] buffer = _data[_offset.._offset + amount];
        _offset += amount;
        return buffer;
    }

    public ubyte readUByte() {
        ubyte[1] buffer = _data[_offset];
        _offset += 1;
        return buffer[0];
    }

    public ushort readUShort() {
        ubyte[2] buffer = _data[_offset.._offset + 2];
        _offset += 2;
        return littleEndianToNative!ushort(buffer[0..2]);
    }

    public uint readUInt() {
        ubyte[4] buffer = _data[_offset.._offset + 4];
        _offset += 4;
        return littleEndianToNative!uint(buffer[0..4]);
    }

    public byte readByte() {
        byte[1] buffer = _data[_offset];
        _offset += 1;
        return buffer[0];
    }

    public short readShort() {
        ubyte[2] buffer = _data[_offset.._offset + 2];
        _offset += 2;
        return littleEndianToNative!short(buffer[0..2]);
    }

    public int readInt() {
        ubyte[4] buffer = _data[_offset.._offset + 4];
        _offset += 4;
        return littleEndianToNative!int(buffer[0..4]);
    }

    public void close() {
        _data.length = 0;
        _offset = 0;
    }

    @property public bool eof() {
        return (_offset >= _data.length);
    }

    @property public uint offset() {
        return _offset;
    }

    @property public uint size() {
        return _data.length;
    }

    @property public string name() {
        return _name;
    }
}