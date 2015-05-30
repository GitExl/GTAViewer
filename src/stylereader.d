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

module game.style.stylereader;

import game.map.block;

import game.style.style;

import game.entities.entity;
import game.entities.vehicle;
import game.entities.typenames;

import util.binaryfile;
import util.color;


public abstract class StyleReader {

    protected BinaryFile _file;


    this(BinaryFile file) {
        _file = file;
    }

    public abstract void readHeader();
    public abstract BlockTexture[] readBlockTextures();
    public abstract Animation[] readAnimations();
    public abstract Palette[] readPalettes();
    public abstract VirtualPalette[] readVirtualPalettes();
    public abstract void readEntityTypes(ref EntityType[string] entityTypes, TypeNames!EntityTypeIndex entityTypeNames);
    public abstract VehicleType[] readVehicleTypes();
    public abstract SpriteFrame[] readSpriteFrames();
    public abstract Font[] readFonts();
    public abstract ushort[] readPaletteBases();

    @property public abstract ushort blockTexturePaletteCount();
    @property public abstract BlockTextureIndex sideTextureCount();

}
