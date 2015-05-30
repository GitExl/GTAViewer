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

module util.vector3;

import util.binaryfile;


public struct Vector3 {
    float x = 0.0;
    float y = 0.0;
    float z = 0.0;

    public void readUByteFrom(BinaryFile file) {
        x = cast(float)file.readUByte();
        y = cast(float)file.readUByte();
        z = cast(float)file.readUByte();
    }

    public void readUShortFrom(BinaryFile file) {
        x = cast(float)file.readUShort();
        y = cast(float)file.readUShort();
        z = cast(float)file.readUShort();
    }

    bool opEquals(Vector3 other) {
        return (x == other.x && y == other.y && z == other.z);
    }

    void opOpAssign(string op)(Vector3 other) {
        mixin("x " ~ op ~ "= other.x;");
        mixin("y " ~ op ~ "= other.y;");
        mixin("z " ~ op ~ "= other.z;");
    }

    public Vector3 opBinary(string op)(const Vector3 l) if (op == "+" || op == "-") {
        mixin("return Vector3(x " ~ op ~ " l.x, y " ~ op ~ " l.y, z " ~ op ~ " l.z);");
    }

    public Vector3 opBinary(string op)(const real l) if (op == "*" || op == "/") {
        mixin("return Vector3(x " ~ op ~ " l, y " ~ op ~ " l, z " ~ op ~ " l);");
    }
}
