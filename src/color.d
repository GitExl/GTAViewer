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

module util.color;

import std.stdio;
import std.algorithm;


public struct RGBA {
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a;

    this(const ubyte vr, const ubyte vg, const ubyte vb, const ubyte va) {
        r = vr;
        g = vg;
        b = vb;
        a = va;
    }

    this(const float vr, const float vg, const float vb, const float va) {
        r = cast(ubyte)(vr * 255.0);
        g = cast(ubyte)(vg * 255.0);
        b = cast(ubyte)(vb * 255.0);
        a = cast(ubyte)(va * 255.0);
    }
}

public struct HSL {
    float h = 0.0;
    float s = 0.0;
    float l = 0.0;

    this(const float vh, const float vs, const float vl) {
        h = vh;
        s = vs;
        l = vl;
    }

    this(const short vh, const short vs, const short vl) {
        h = cast(float)vh;
        s = cast(float)vs;
        l = cast(float)vl;
    }
}

public struct Palette {
    RGBA[256] colors;

    public void adjust(const HSL hsl) {
        foreach (int index, ref RGBA color; colors) {
            HSL c = RGBAtoHSL(color);

            c.h = (c.h + hsl.h) % 360.0;
            c.s = (c.s + hsl.s) % 100.0;
            c.l = (c.l + hsl.l) % 100.0;
            
            colors[index] = HSLtoRGBA(c);
        }
    }
}


public HSL RGBAtoHSL(const RGBA color) {
    const float r = color.r / 255.0;
    const float g = color.g / 255.0;
    const float b = color.b / 255.0;

    const float cmax = max(r, g, b);
    const float cmin = min(r, g, b);
    
    float h = 0.0;
    float s = 0.0;
    const float l = (cmax + cmin) / 2.0;

    if (cmax == cmin) {
        h = 0.0;
        s = 0.0;
    } else {
        float d = cmax - cmin;
        s = l > 0.5 ? d / (2.0 - cmax - cmin) : d / (cmax + cmin);
        
        if (cmax == r) {
            h = (g - b) / d + (g < b ? 6.0 : 0.0);
        }
        if (cmax == g) {
            h = (b - r) / d + 2.0;
        }
        if (cmax == b) {
            h = (r - g) / d + 4.0;
        }
        h /= 6.0;
    }

    return HSL(h * 360.0, s * 100.0, l * 100.0);
}

private float hue2rgb(const float p, const float q, float t) pure {
    if (t < 0.0) {
        t += 1.0;
    }
    if (t > 1.0) {
        t -= 1.0;
    }

    if (t < 1.0 / 6.0) {
        return p + (q - p) * 6.0 * t;
    }
    if (t < 1.0 / 2.0) {
        return q;
    }
    if (t < 2.0 / 3.0) {
        return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
    }

    return p;
}

public RGBA HSLtoRGBA(const HSL color) {
    const float h = color.h / 360.0;
    const float s = color.s / 100.0;
    const float l = color.l / 100.0;

    if (s == 0.0) {
        return RGBA(l, l, l, 0.0);
    }

    const float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
    const float p = 2.0 * l - q;

    return RGBA(
        hue2rgb(p, q, h + 1.0 / 3.0),
        hue2rgb(p, q, h),
        hue2rgb(p, q, h - 1.0 / 3.0),
        0.0
    );
}
