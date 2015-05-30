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

module game.delta;

import std.stdio;


// GTA delta data format:
// 1 byte: delta x offset inside sprite rectangle
// 1 byte: delta y offset inside sprite rectangle
// while inside delta data range:
//   1 byte: number of pixels (n)
//   n bytes: pixel data
//   if end of data range reached, break
//   1 byte: number of bytes to skip. skipping an entire row will skip > sprite.width, because
//     they are meant to be stored in 256x256 pages.
//   1 byte: 0x00

public class Delta {
    
    private ubyte[] _data;

    private uint _imageWidth;


    // Creates a new delta from raw data.
    this(const ubyte[] data, const uint imageWidth) {
        _imageWidth = imageWidth;
        _data = data.dup;
    }
    
    // Creates a new delta from a mask and image.
    this(const ubyte[] image, const ubyte[] mask, const uint imageWidth) {
        _imageWidth = imageWidth;
        _data.length = 0;

        uint offset = 0;
        while (offset < image.length) {
            
            // Count the pixels to skip.
            const uint skipStart = offset;
            while (!mask[offset++] && offset < mask.length) {}
            if (offset >= mask.length) {
                break;
            }
            offset--;

            // Add starting x, y.
            const uint skip = offset - skipStart;
            if (_data.length == 0) {
                _data ~= [cast(ubyte)(skip % imageWidth), cast(ubyte)(skip / imageWidth)];

            // Add skip instruction.
            } else {
                _data ~= [cast(ubyte)skip, 0];

            }

            // Count pixels to draw.
            const uint dataStart = offset;
            while (mask[offset++] && offset < mask.length) {}
            offset--;

            // Add pixels to draw.
            const uint dataEnd = offset;
            _data ~= cast(ubyte)(dataEnd - dataStart);
            _data ~= image[dataStart..dataEnd];
        }
    }

    // Makes this delta's skip instructions take into account that the target image is not stored in a page with other sprites.
    public void makeNonPaged(const uint pageSize) {
        uint offset = 2;

        while (offset < _data.length) {
            offset += _data[offset++];

            if (offset >= _data.length) {
                break;
            }

            // If the delta's skip command would go beyond the sprite's width,
            // transform it to be in the bounds of the sprite width instead of the page width.
            if (_data[offset] >= _imageWidth) {
                _data[offset] -= pageSize - _imageWidth;
            }
            offset += 2;
        }
    }

    // Applies this delta to an image.
    public void applyTo(ref ubyte[] image) {
        uint destOffset = _data[1] * _imageWidth + _data[0];
        uint offset = 2;

        while (offset < _data.length) {
            const ubyte pixels = _data[offset++];
            image[destOffset..destOffset + pixels] = _data[offset..offset + pixels];
            offset += pixels;
            destOffset += pixels;

            if (offset >= _data.length) {
                break;
            }

            destOffset += _data[offset];
            offset += 2;
        }
    }

    // Returns this delta's mask image, where non-0 pixels are pixels that are present in the delta information.
    public void applyMaskTo(ref ubyte[] mask) {
        uint destOffset = _data[1] * _imageWidth + _data[0];
        uint offset = 2;

        while (offset < _data.length) {
            const ubyte pixels = _data[offset++];
            mask[destOffset..destOffset + pixels] = 0xFF;
            offset += pixels;
            destOffset += pixels;

            if (offset >= _data.length) {
                break;
            }

            destOffset += _data[offset];
            offset += 2;
        }
    }
        
}