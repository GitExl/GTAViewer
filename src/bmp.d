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

module util.bmp;

import std.stdio;
import std.file;


private align(1) struct BMPHeader {
    align(1):
        ubyte[2] magic;
        uint fileSize;
        ubyte[4] reserved;
        uint imageOffset;
}

private align(1) struct DIBHeader {
    align(1):
        uint headerSize;
        int imageWidth;
        int imageHeight;
        ushort colorPlanes;
        ushort bpp;
        uint compression;
        uint imageSize;
        int dpiX;
        int dpiY;
        uint colorsUsed;
        uint importantColorsUsed;
}


public void writeBMP32(const string fileName, const uint width, const uint height, ubyte[] image) {
    
    // Flip image data vertically.
    ubyte[] imageData = new ubyte[image.length];
    int destOffset = 0;
    int srcOffset = width * (height - 1) * 4;
    for (int y = height - 1; y >= 0; y--) {
        for (int x = 0; x < width; x++) {
            imageData[destOffset + 0] = image[srcOffset + 0];
            imageData[destOffset + 1] = image[srcOffset + 1];
            imageData[destOffset + 2] = image[srcOffset + 2];
            imageData[destOffset + 3] = image[srcOffset + 3];
            destOffset += 4;
            srcOffset += 4;
        }
        srcOffset -= width * 2 * 4;
    }

    BMPHeader header;
    header.magic = [0x42, 0x4D];
    header.fileSize = BMPHeader.sizeof + DIBHeader.sizeof + imageData.length;
    header.imageOffset = BMPHeader.sizeof + DIBHeader.sizeof;

    DIBHeader dib;
    dib.headerSize = DIBHeader.sizeof;
    dib.imageWidth = width;
    dib.imageHeight = height;
    dib.colorPlanes = 1;
    dib.bpp = 32;
    dib.compression = 0;
    dib.imageSize = 0;
    dib.dpiX = 96;
    dib.dpiY = 96;
    dib.colorsUsed = 0;
    dib.importantColorsUsed = 0;

    File output = File(fileName, "wb");
    fwrite(&header, header.sizeof, 1, output.getFP());
    fwrite(&dib, dib.sizeof, 1, output.getFP());
    fwrite(&imageData[0], imageData.length, 1, output.getFP());
    output.close();
}