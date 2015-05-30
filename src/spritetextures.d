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

module game.spritetextures;

import std.stdio;
import std.algorithm;
import std.string;
import std.conv;

import game.game;
import game.delta;

import game.style.style;

import render.enums;
import render.texture;

import util.packnode;
import util.rectangle;
import util.color;
import util.console;
import util.fasthash;
import util.bmp;
import util.log;


public struct SpriteTexture {
    SpriteFrameIndex baseFrame;
    ushort palette;
    HSL hsl;
    uint deltaMask;

    Texture texture;
    SubTexture[] subTextures;
}

public struct SpriteRef {
    SpriteFrameIndex baseFrame;
    SpriteFrameIndex frameCount;
    ushort palette;
    HSL hsl;
    uint deltaMask;
}

public struct SubTexture {
    float u;
    float v;
}

private struct SortRect {
    int width;
    int height;
    
    SpriteFrameIndex spriteFrameIndex;
    int subTextureIndex;

    int x;
    int y;
}


public final class SpriteTextures {

    private Style _style;
    private SpriteTexture*[ulong] _spriteTextures;

    private CVar _cvarSpriteMipMaps;
    private CVar _cvarDumpSpriteTextures;

    private static immutable uint NODE_PADDING = 1;
    private static immutable ulong HASH_SEED = 0xDEADBEEFDEADBEEF;


    this(Style style) {
        _cvarSpriteMipMaps = CVars.get("r_spritemipmaps");
        _cvarDumpSpriteTextures = CVars.get("r_dumpspritetextures");
        _style = style;
    }

    public SpriteTexture* add(const SpriteRef spriteRef) {
        assert(spriteRef.frameCount > 0);

        SpriteTexture* spriteTexture = new SpriteTexture;
        spriteTexture.baseFrame = spriteRef.baseFrame;
        spriteTexture.palette = spriteRef.palette;
        spriteTexture.hsl = spriteRef.hsl;
        spriteTexture.deltaMask = spriteRef.deltaMask;

        // Generate rectangles for the sprite frames.
        SortRect[] rects = new SortRect[spriteRef.frameCount];
        for (SpriteFrameIndex frameIndex = spriteRef.baseFrame; frameIndex < spriteRef.baseFrame + spriteRef.frameCount; frameIndex++) {
            const SpriteFrame frame = _style.getSpriteFrame(frameIndex);
            rects[frameIndex - spriteRef.baseFrame] = SortRect(frame.width, frame.height, frameIndex, frameIndex - spriteRef.baseFrame);
        }

        // Pack rectangles into a single square area.
        const uint size = pack(rects);

        // Generate the texture data for the sprite.
        ubyte[] textureData = generateTexture(spriteTexture, rects, spriteRef.deltaMask, size);
        Texture texture = new Texture(size, InternalTextureFormat.RGBA, TextureFormat.BGRA);
        texture.mipmapLevels = cast(int)_cvarSpriteMipMaps.intVal;
        texture.anisotropy = 0;
        texture.generate(textureData);
        spriteTexture.texture = texture;

        // Generate subtextures.
        const float texMod = (1.0 / texture.size);
        spriteTexture.subTextures = new SubTexture[spriteRef.frameCount];
        foreach (SortRect rect; rects) {
            spriteTexture.subTextures[rect.subTextureIndex] = SubTexture(
                texMod * (rect.x + NODE_PADDING),
                texMod * (rect.y + NODE_PADDING),
            );
        }

        return spriteTexture;
    }

    // Pack rectangles to fit inside a single texture.
    // If there is not enough room, the texture size is increased and packing restarts.
    private uint pack(ref SortRect[] rects) {
        if (rects.length == 1) {
            const uint frameSize = max(rects[0].width + NODE_PADDING * 2, rects[0].height + NODE_PADDING * 2);
            uint size = 32;
            while (size < frameSize) {
                size *= 2;
            }

            return size;
        }

        uint size = 32;
        bool repeat = true;
        PackNode* node;

        rects.sort!("max(a.width, a.height) > max(b.width, b.height)", SwapStrategy.unstable);

        // TODO: Object pool for PackNodes
        while (repeat) {
            PackNode* root = new PackNode(size, size);
    
            foreach (ref SortRect rect; rects) {
                node = null;
                repeat = false;
                while (node is null) {
                    node = root.insert(rect.width + NODE_PADDING * 2, rect.height + NODE_PADDING * 2);
                    if (node is null) {
                        repeat = true;
                        size *= 2;
                        if (size == 2048) {
                            Log.write(Color.WARNING, "Using 2048x2048 texture for sprite.");
                        } else if (size >= 4096) {
                            throw new Exception("Sprite texture too big!");
                        }
                        break;
                    } else {
                        rect.x = node.rectangle.x1;
                        rect.y = node.rectangle.y1;
                        break;
                    }
                }

                if (repeat) {
                    break;
                }
            }
        }

        return size;
    }

    private ubyte[] generateTexture(SpriteTexture* spriteTexture, SortRect[] rects, uint deltaMask, const uint size) {
        ubyte[] data = new ubyte[](size * size * 4);

        // Get modified palette to use for the image.
        Palette palette = _style.getLogicalPalette(spriteTexture.palette);
        if (spriteTexture.hsl.h || spriteTexture.hsl.s || spriteTexture.hsl.l) {
            palette.adjust(spriteTexture.hsl);
        }

        foreach (int frameIndex, ref SortRect rect; rects) {
            SpriteFrame frame = _style.getSpriteFrame(rect.spriteFrameIndex);
            
            const uint x = rect.x + NODE_PADDING;
            const uint y = rect.y + NODE_PADDING;

            // Get image data with deltas applied.
            ubyte[] image;
            if (deltaMask) {
                image = frame.image.dup;
                uint flag = 1;
                foreach (int index, Delta delta; frame.deltas) {
                    if (deltaMask & flag && delta !is null) {
                        delta.applyTo(image);
                    }
                    flag *= 2;
                }
            } else {
                image = cast(ubyte[])frame.image;
            }

            // Copy palettized image data to texture.
            uint textureOffset = y * (size * 4) + x * 4;
            uint stride = (size - frame.width) * 4;
            uint offset = 0;
            for (uint srcY = 0; srcY < frame.height; srcY++) {
                for (uint srcX = 0; srcX < frame.width; srcX++) {
                    const ubyte pixel = image[offset];
                    if (pixel) {
                        data[textureOffset + 0] = palette.colors[pixel].b;
                        data[textureOffset + 1] = palette.colors[pixel].g;
                        data[textureOffset + 2] = palette.colors[pixel].r;
                        data[textureOffset + 3] = 0xFF;
                    }

                    offset += 1;
                    textureOffset += 4;
                }
                textureOffset += stride;
            }
        }

        if (_cvarDumpSpriteTextures.intVal) {
            writeBMP32(format("spritetextures/%s_%.4d_%.4d.bmp", to!string(gameMode), spriteTexture.baseFrame, spriteTexture.palette), size, size, data);
        }

        return data;
    }

    public SpriteTexture* get(const SpriteRef spriteRef) {
        SpriteTexture* spriteTexture;

        const ulong hash = fasthash64(&spriteRef, SpriteRef.sizeof, HASH_SEED);
        if (hash in _spriteTextures) {
            spriteTexture = _spriteTextures[hash];
        } else {
            spriteTexture = add(spriteRef);
            _spriteTextures[hash] = spriteTexture;
        }

        return spriteTexture;
    }

    @property public uint padding() {
        return NODE_PADDING;
    }

}