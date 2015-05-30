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

module game.style.stylereadergta1;

import std.stdio;
import std.string;

import game.style.style;
import game.style.stylereader;

import game.map.block;

import game.delta;

import game.entities.entity;
import game.entities.vehicle;
import game.entities.typenames;

import util.binaryfile;
import util.color;


private immutable uint BLOCKTEXTURE_REMAP_COUNT = 4;


private struct Chunk {
    uint offset;
    uint size;
    uint realSize;
}

private struct SpriteCounts {
    SpriteFrameIndex arrows;
    SpriteFrameIndex boats;
    SpriteFrameIndex buses;
    SpriteFrameIndex cars;
    SpriteFrameIndex objects;
    SpriteFrameIndex peds;
    SpriteFrameIndex tanks;
    SpriteFrameIndex trafficLights;
    SpriteFrameIndex trains;
    SpriteFrameIndex bikes;
    SpriteFrameIndex wideCars;
    SpriteFrameIndex ex;
}


public final class StyleReaderGTA1 : StyleReader {

    private Chunk[string] _chunks;
    private uint _currentChunkOffset;

    private BlockTextureIndex _sideTextureCount;
    private BlockTextureIndex _lidTextureCount;
    private BlockTextureIndex _auxTextureCount;

    private uint _tilePaletteSize;
    private uint _spritePaletteSize;
    private uint _remapPaletteSize;
    private uint _fontPaletteSize;

    private SpriteCounts _spriteCounts;


    this(BinaryFile file) {
        super(file);
    }

    override public void readHeader() {
        const uint ver = _file.readUInt();
        if (ver != 336) {
            throw new Exception(format("Invalid or unsupported GTA 1 style file version '%d'.", ver));
        }

        _currentChunkOffset = 16 * 4;

        uint sideTextureSize = _file.readUInt();
        uint lidTextureSize = _file.readUInt();
        uint auxTextureSize = _file.readUInt();
        addChunk("TEXTURES", sideTextureSize + lidTextureSize + auxTextureSize, 16384);
        _sideTextureCount = cast(BlockTextureIndex)(sideTextureSize / 4096);
        _lidTextureCount = cast(BlockTextureIndex)(lidTextureSize / 4096);
        _auxTextureCount = cast(BlockTextureIndex)(auxTextureSize / 4096);

        addChunk("ANIMS", _file.readUInt(), 0);

        addChunk("CLUTS", _file.readUInt(), 65536);
        _tilePaletteSize = _file.readUInt();
        _spritePaletteSize = _file.readUInt();
        _remapPaletteSize = _file.readUInt();
        _fontPaletteSize = _file.readUInt();

        addChunk("VIRTUALPALETTES", _file.readUInt(), 0);
        addChunk("ENTITYTYPES", _file.readUInt(), 0);
        addChunk("VEHICLETYPES", _file.readUInt(), 0);
        addChunk("SPRITETYPES", _file.readUInt(), 0);
        addChunk("SPRITES", _file.readUInt(), 0);
        addChunk("SPRITECOUNTS", _file.readUInt(), 0);

        readSpriteCounts();
    }

    private void addChunk(const string name, const uint size, const uint pad) {
        uint realSize;
        if (pad && (size % pad)) {
            realSize = size + (pad - (size % pad));
        } else {
            realSize = size;
        }

        _chunks[name] = Chunk(_currentChunkOffset, size, realSize);
        _currentChunkOffset += realSize;
    }

    override public BlockTexture[] readBlockTextures() {
        Chunk chunk = _chunks["TEXTURES"];
        _file.seek(chunk.offset);

        // Read all texture data at once.
        const ubyte[] texturePages = _file.readBytes(chunk.realSize);

        BlockTexture[] blockTextures;
        for (int index = 0; index < _sideTextureCount + _lidTextureCount + _auxTextureCount; index++) {
            BlockTexture texture;

            const uint pageIndex = index / 16;
            const uint offsetX = (index % 16) % 4;
            const uint offsetY = (index % 16) / 4;
        
            uint offset = (pageIndex * 65536) + (offsetY * 16384) + offsetX * 64;
            uint dataIndex;

            for (int y = 0; y < BLOCKTEXTURE_DIMENSION; y++) {
                texture.data[dataIndex..dataIndex + BLOCKTEXTURE_DIMENSION] = texturePages[offset..offset + BLOCKTEXTURE_DIMENSION];
                dataIndex += 64;
                offset += 256;
            }

            blockTextures ~= texture;
        }

        // Duplicate block textures for each remap.
        BlockTexture[] concatBlockTextures;
        for (int index = 0; index < BLOCKTEXTURE_REMAP_COUNT; index++) {
            concatBlockTextures ~= blockTextures;
        }

        return concatBlockTextures;
    }
    
    private struct SpriteDelta {
        uint frameIndex;
        uint deltaIndex;
        ushort length;
        uint ptr;
    }

    override public SpriteFrame[] readSpriteFrames() {
        Chunk chunk = _chunks["SPRITETYPES"];
        _file.seek(chunk.offset);

        SpriteFrame[] spriteFrames;
        SpriteDelta[] deltas;
        const uint endOffset = chunk.offset + chunk.realSize;

        while (_file.offset < endOffset) {
            SpriteFrame frame;

            frame.width = _file.readUByte();
            frame.height = _file.readUByte();

            const ubyte deltaCount = _file.readUByte();

            _file.skip(3);

            frame.palette = PaletteIndex(PaletteType.SPRITE, _file.readUShort());
            
            const ubyte offsetX = _file.readUByte();
            const ubyte offsetY = _file.readUByte();
            const ushort pageIndex = _file.readUShort();
            frame.ptr = (pageIndex * 65536) + (offsetY * 256) + offsetX;

            for (int index = 0; index < deltaCount; index++) {
                SpriteDelta delta;

                delta.frameIndex = spriteFrames.length;
                delta.deltaIndex = index;
                delta.length = _file.readUShort();

                const ubyte deltaOffsetX = _file.readUByte();
                const ubyte deltaOffsetY = _file.readUByte();
                const ushort deltaPageIndex = _file.readUShort();
                delta.ptr = (deltaPageIndex * 65536) + (deltaOffsetY * 256) + deltaOffsetX;

                deltas ~= delta;
            }

            spriteFrames ~= frame;
        }

        Chunk dataChunk = _chunks["SPRITES"];
        _file.seek(dataChunk.offset);
        ubyte[] spriteData = _file.readBytes(dataChunk.realSize);
        foreach (ref SpriteFrame frame; spriteFrames) {
            frame.image.length = frame.width * frame.height;

            // Extract the sprite image from a page into a simple data array.
            uint offset;
            uint pageOffset = frame.ptr;
            while (offset < frame.image.length) {
                frame.image[offset..offset + frame.width] = spriteData[pageOffset..pageOffset + frame.width];
                pageOffset += 256;
                offset += frame.width;
            }
        }

        // Copy and fix up deltas.
        foreach (SpriteDelta spriteDelta; deltas) {
            if (spriteDelta.length == 0) {
                continue;
            }

            ubyte[] data = spriteData[spriteDelta.ptr..spriteDelta.ptr + spriteDelta.length];
            if (data.length) {
                Delta delta = new Delta(data, spriteFrames[spriteDelta.frameIndex].width);
                delta.makeNonPaged(256);

                spriteFrames[spriteDelta.frameIndex].deltas[spriteDelta.deltaIndex] = delta;
            }
        }

        return spriteFrames;
    }

    override public VehicleType[] readVehicleTypes() {
        Chunk chunk = _chunks["VEHICLETYPES"];
        _file.seek(chunk.offset);

        VehicleType[] vehicleTypes;
        const uint endOffset = chunk.offset + chunk.realSize;

        while (_file.offset < endOffset) {
            VehicleType veh;

            veh.name = format("GTA1Car%.3d", vehicleTypes.length);
            veh.flags |= VehicleFlags.RECYCLE | VehicleFlags.CANNOT_JUMP_OVER;

            veh.width = _file.readShort();
            veh.height = _file.readShort();
            veh.depth = _file.readShort();

            veh.sprite = cast(SpriteFrameIndex)(_file.readShort() + _spriteCounts.arrows + _spriteCounts.boats + _spriteCounts.buses);
            veh.spriteCount = 1;

            veh.physics1.weight = _file.readShort();
            veh.physics1.speedMax = _file.readShort();
            veh.physics1.speedMin = _file.readShort();
            veh.physics1.acceleration = _file.readShort();
            veh.physics1.braking = _file.readShort();
            veh.physics1.grip = _file.readShort();
            veh.physics1.handling = _file.readShort();

            veh.remapsHSL = new HSL[12];
            foreach (ref HSL remap; veh.remapsHSL) {
                remap = HSL(_file.readShort(), _file.readShort(), _file.readShort());
            }

            // Skip 8-bit remaps.
            _file.skip(12);

            veh.kind = cast(VehicleKind)_file.readUByte();
            veh.model = _file.readUByte();
            
            veh.physics1.turning = _file.readUByte();

            veh.damageFactor = _file.readUByte() / 100.0;
            
            veh.value = new uint[4];
            foreach (ref uint value; veh.value) {
                value = _file.readUShort() * 1000;
            }
            
            veh.physics1.centerMassX = _file.readByte();
            veh.physics1.centerMassY = _file.readByte();
            veh.physics1.momentInertia = _file.readInt();

            veh.physics1.mass = _file.readInt() / 65536.0;
            veh.physics1.thrustGear1 = _file.readInt() / 65536.0;
            veh.physics1.tireAdhesionX = _file.readInt() / 65536.0;
            veh.physics1.tireAdhesionY = _file.readInt() / 65536.0;
            
            veh.physics1.handBrakeFriction = _file.readInt() / 65536.0;
            veh.physics1.footBrakeFriction = _file.readInt() / 65536.0;
            veh.physics1.frontBrakeBias = _file.readInt() / 65536.0;
            
            veh.physics1.turnRatio = _file.readShort();
            veh.physics1.driveWheelOffset = _file.readShort();
            veh.physics1.steeringWheelOffset = _file.readShort();

            veh.physics1.backEndSlide = _file.readInt() / 65536.0;
            veh.physics1.handBrakeSlide = _file.readInt() / 65536.0;

            if (_file.readUByte()) {
                veh.flags |= VehicleFlags.IS_CONVERTIBLE;
            }

            veh.engineType = _file.readUByte();
            veh.radioType = _file.readUByte();
            veh.hornType = _file.readUByte();
            veh.soundFunction = _file.readUByte();
            if (_file.readUByte()) {
                veh.flags |= VehicleFlags.SOUND_FASTCHANGE;
            }
            
            veh.doors.length = _file.readShort();
            foreach (ref VehicleDoor door; veh.doors) {
                door.relX = _file.readShort();
                door.relY = _file.readShort();
                door.entityTypeIndex = _file.readShort();
                door.deltaIndex = _file.readShort();
            }

            vehicleTypes ~= veh;
        }

        return vehicleTypes;
    }

    override public void readEntityTypes(ref EntityType[string] entityTypes, TypeNames!EntityTypeIndex typeNames) {
        Chunk chunk = _chunks["ENTITYTYPES"];
        _file.seek(chunk.offset);

        const uint endOffset = chunk.offset + chunk.realSize;
        EntityTypeIndex index;
        while (_file.offset < endOffset) {
            const string name = typeNames.getName(index);
            EntityType entityType;
            if (name in entityTypes) {
                entityType = entityTypes[name];
            } else {
                throw new Exception(format("Cannot augment unknown GTA1 entity type '%s'.", name));
            }

            _file.skip(2);
            entityType.width = _file.readUShort();
            _file.skip(2);
            entityType.height = _file.readUShort();
            _file.skip(2);
            entityType.depth = _file.readUShort();

            entityType.baseFrame = _file.readUShort();
            entityType.baseFrame += cast(SpriteFrameIndex)(_spriteCounts.arrows + _spriteCounts.boats + _spriteCounts.buses + _spriteCounts.cars);

            entityType.weight = _file.readUByte();
            _file.skip(1);
            entityType.aux = _file.readUShort();

            const byte status = _file.readByte();
            if (status == 1) {
                entityType.classId = EntityClass.DECORATION;
            } else if (status == 2) {
                entityType.classId = EntityClass.OBSTACLE;
            } else if (status == 3) {
                entityType.classId = EntityClass.DECORATION;
                entityType.flags |= EntityFlags.INVISIBLE;
            }
            
            // Skip entity breaking up data, it is not used.
            const ubyte breakCount = _file.readUByte();
            _file.skip(2 * breakCount);

            entityTypes[name] = entityType;
            index++;
        }
    }

    override public VirtualPalette[] readVirtualPalettes() {
        Chunk chunk = _chunks["VIRTUALPALETTES"];
        _file.seek(chunk.offset);

        VirtualPalette[] palettes = new VirtualPalette[chunk.realSize / 2];
        foreach (ref VirtualPalette mapValue; palettes) {
            mapValue = _file.readUShort();
        }

        // Swap block texture palettes so they are in remap order.
        const int textureCount = _sideTextureCount + _lidTextureCount + _auxTextureCount;
        const ushort[] blockPaletteMap = palettes[0..blockTexturePaletteCount].dup;
        for (int blockPaletteIndex = 0; blockPaletteIndex < textureCount; blockPaletteIndex++) {
            for (int remapIndex = 0; remapIndex < BLOCKTEXTURE_REMAP_COUNT; remapIndex++) {
                palettes[blockPaletteIndex + remapIndex * textureCount] = blockPaletteMap[blockPaletteIndex * BLOCKTEXTURE_REMAP_COUNT + remapIndex];
            }
        }

        return palettes;
    }

    override public Palette[] readPalettes() {
        Chunk chunk = _chunks["CLUTS"];
        _file.seek(chunk.offset);

        const uint count = chunk.realSize / 1024;
        Palette[] palettes = new Palette[count];

        // Read palettes.
        // These are stored in 64k pages, with 64 palettes per page. Each 256 bytes contains a row of 64 RGBA entries,
        // one for each of that page's 64 palettes. Every page has 256 rows, one for each entry for each of that
        // page's 64 palettes.
        ubyte[] data = _file.readBytes(chunk.realSize);
        const uint pageCount = chunk.realSize / 65536;
        uint i;
        for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
            for (int entryIndex = 0; entryIndex < 256; entryIndex++) {
                for (int palIndex = 0; palIndex < 64; palIndex++) {
                    palettes[palIndex + pageIndex * 64].colors[entryIndex] = RGBA(data[i + 2], data[i + 1], data[i + 0], data[i + 3]);
                    i += 4;
                }
            }
        }

        // Trim unused palettes.
        palettes.length = chunk.size / 1024;

        return palettes;
    }

    override public Animation[] readAnimations() {
        Chunk chunk = _chunks["ANIMS"];
        _file.seek(chunk.offset);

        Animation[] anims;
        const ubyte count = _file.readUByte();

        for (uint animIndex = 0; animIndex < count; animIndex++) {
            Animation anim;

            anim.textureIndex = _file.readUByte();
            if (_file.readUByte()) {
                anim.textureIndex += _sideTextureCount;
            }
            anim.delay = _file.readUByte() * 0.04;
            
            const ubyte frameCount = _file.readUByte();
            anim.frames = new BlockTextureIndex[frameCount + 1];
            anim.frames[0] = anim.textureIndex;
            for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
                anim.frames[frameIndex + 1] = cast(BlockTextureIndex)(_file.readUByte() + _sideTextureCount + _lidTextureCount);
            }

            anims ~= anim;
        }

        // Duplicate animations for each block texture remap.
        Animation[] concatAnims;
        const uint textureCount = _sideTextureCount + _lidTextureCount + _auxTextureCount;
        for (int index = 0; index < BLOCKTEXTURE_REMAP_COUNT; index++) {
            foreach (Animation anim; anims) {
                anim.textureIndex += index * textureCount;

                foreach (ref BlockTextureIndex frame; anim.frames) {
                    frame += index * textureCount;
                }

                concatAnims ~= anim;
            }
        }

        return concatAnims;
    }

    private void readSpriteCounts() {
        Chunk chunk = _chunks["SPRITECOUNTS"];
        _file.seek(chunk.offset);

        _spriteCounts.arrows = _file.readUShort();
        _file.skip(2);
        _spriteCounts.boats = _file.readUShort();
        _file.skip(2);
        _spriteCounts.buses = _file.readUShort();
        _spriteCounts.cars = _file.readUShort();
        _spriteCounts.objects = _file.readUShort();
        _spriteCounts.peds = _file.readUShort();
        _file.skip(2);
        _spriteCounts.tanks = _file.readUShort();
        _spriteCounts.trafficLights = _file.readUShort();
        _spriteCounts.trains = _file.readUShort();
        _file.skip(2);
        _spriteCounts.bikes = _file.readUShort();
        _file.skip(2);
        _file.skip(2);
        _spriteCounts.wideCars = _file.readUShort();
        _spriteCounts.ex = _file.readUShort();
        _file.skip(2);
        _file.skip(2);
        _file.skip(2);
    }

    override public Font[] readFonts() {
        Font[] fonts;
        
        return fonts;
    }

    override public ushort[] readPaletteBases() {
        ushort[] bases = new ushort[8];

        bases[PaletteType.TILE] = 0;
        bases[PaletteType.SPRITE] = cast(ushort)(blockTexturePaletteCount);
        bases[PaletteType.VEHICLE] = cast(ushort)(blockTexturePaletteCount);
        bases[PaletteType.PED] = 0;
        bases[PaletteType.CODE_ENTITY] = 0;
        bases[PaletteType.MAP_ENTITY] = 0;
        bases[PaletteType.USER_ENTITY] = 0;
        bases[PaletteType.FONT] = 0;

        return bases;
    }

    @property override public ushort blockTexturePaletteCount() {
        return cast(ushort)(_tilePaletteSize / 1024);
    }

    @property override public BlockTextureIndex sideTextureCount() {
        return _sideTextureCount;
    }
}