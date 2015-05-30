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

module game.style.stylereadergta2;

import std.string;
import std.stdio;
import std.path;
import std.algorithm;

import game.style.style;
import game.style.stylereader;

import game.map.block;

import game.entities.entity;
import game.entities.vehicle;
import game.entities.typenames;

import game.strings;
import game.delta;

import util.gciparser;
import util.binaryfile;
import util.rifffile;
import util.color;


private struct DeltaIndex {
    SpriteFrameIndex frameIndex;
    ubyte deltaCount;
    ushort[MAX_SPRITE_DELTAS] deltaSizes;
}

private struct SpriteBase {
    SpriteFrameIndex cars;
    SpriteFrameIndex peds;
    SpriteFrameIndex codeEntities;
    SpriteFrameIndex mapEntities;
    SpriteFrameIndex user;
    SpriteFrameIndex fonts;
}


public final class StyleReaderGTA2 : StyleReader {

    private RIFFFile _riff;

    private SpriteBase _spriteBase;


    this(BinaryFile file) {
        super(file);
    }

    override public void readHeader() {
        _riff = new RIFFFile(_file);

        if (_riff.type != "GBST") {
            throw new Exception(format("'%s' is not a GTA 2 style file.", _file.name));
        }
        if (_riff.versionNum != 700) {
            throw new Exception(format("Invalid or unsupported GTA 2 style file version '%d'.", _riff.versionNum));
        }

        readSpriteBase();
    }

    override public BlockTexture[] readBlockTextures() {
        const Chunk chunk = _riff.getChunk("TILE");
        BinaryFile file = _riff.file;

        const ubyte[] data = file.readBytes(chunk.size);
        BlockTexture[] blockTextures;
        for (int index = 0; index < chunk.size / 4096; index++) {
            BlockTexture texture;

            const uint pageIndex = index / 16;
            const uint offsetX = (index % 16) % 4;
            const uint offsetY = (index % 16) / 4;
        
            uint offset = (pageIndex * 65536) + (offsetY * 16384) + offsetX * 64;
            uint dataIndex;

            for (int y = 0; y < BLOCKTEXTURE_DIMENSION; y++) {
                texture.data[dataIndex..dataIndex + BLOCKTEXTURE_DIMENSION] = data[offset..offset + BLOCKTEXTURE_DIMENSION];
                dataIndex += 64;
                offset += 256;
            }

            blockTextures ~= texture;
        }
        
        // Read material types.
        const Chunk specChunk = _riff.getChunk("SPEC");
        BlockTextureMaterial mat = cast(BlockTextureMaterial)1;
        BlockTextureIndex textureIndex;
        uint endOffset = file.offset + specChunk.size;
        while (file.offset < endOffset) {
            textureIndex = file.readUShort();
            if (textureIndex == 0) {
                mat += 1;
                continue;
            }

            blockTextures[textureIndex].material = mat;
        }

        return blockTextures;
    }

    override public SpriteFrame[] readSpriteFrames() {
        BinaryFile file = _riff.file;
        
        // Read sprite graphics.
        const Chunk dataChunk = _riff.getChunk("SPRG");        
        const ubyte[] spriteData = file.readBytes(dataChunk.size);

        // Read sprite types.
        const Chunk chunk = _riff.getChunk("SPRX");
        SpriteFrame[] spriteFrames = new SpriteFrame[chunk.size / 8];
        foreach (ushort index, ref SpriteFrame frame; spriteFrames) {
            const uint ptr = file.readUInt();

            frame.width = file.readUByte();
            frame.height = file.readUByte();
            frame.palette = PaletteIndex(PaletteType.SPRITE, index);
            file.skip(2);

            // Assign sprite data.
            uint offset;
            uint pageOffset = ptr;
            frame.image.length = frame.width * frame.height;
            while (offset < frame.image.length) {
                frame.image[offset..offset + frame.width] = spriteData[pageOffset..pageOffset + frame.width];
                pageOffset += 256;
                offset += frame.width;
            }
        }

        // Read delta index.
        const Chunk deltaChunk = _riff.getChunk("DELX");
        const uint endOffset = file.offset + deltaChunk.size;
        DeltaIndex[] deltas;
        while (file.offset < endOffset) {
            DeltaIndex delta;
            delta.frameIndex = file.readUShort();
            delta.deltaCount = file.readUByte();
            file.skip(1);
            
            for (int index = 0; index < delta.deltaCount; index++) {
                delta.deltaSizes[index] = file.readUShort();
            }

            deltas ~= delta;
        }

        // Read delta store.
        const Chunk storeChunk = _riff.getChunk("DELS");
        foreach (DeltaIndex delta; deltas) {
            foreach (int index, ushort size; delta.deltaSizes) {
                if (!size) {
                    continue;
                }

                ubyte[] data = file.readBytes(size);
                if (data.length) {
                    Delta spriteDelta = new Delta(data, spriteFrames[delta.frameIndex].width);
                    spriteDelta.makeNonPaged(256);

                    spriteFrames[delta.frameIndex].deltas[index] = spriteDelta;
                }
            }
        }

        // Mirror deltas 5 - 14 to 22 - 31.
        foreach (ref SpriteFrame frame; spriteFrames) {
            for (int index = 5; index < 15; index++) {
                frame.deltas[index + 17] = mirrorDelta(frame, frame.deltas[index]);
            }
        }
        
        return spriteFrames;
    }

    private Delta mirrorDelta(const SpriteFrame frame, Delta src) {   
        if (src is null) {
            return null;
        }

        ubyte[] image = new ubyte[frame.width * frame.height];
        ubyte[] mask =  new ubyte[frame.width * frame.height];
        src.applyTo(image);
        src.applyMaskTo(mask);

        // Flip the delta image and mask.
        for (uint offset = 0; offset < image.length; offset += frame.width) {
            reverse(image[offset..offset + frame.width]);
            reverse(mask[offset..offset + frame.width]);
        }

        // Return a new delta created from an image and mask.
        return new Delta(image, mask, frame.width);
    }

    override public VehicleType[] readVehicleTypes() {
        const Chunk chunk = _riff.getChunk("CARI");
        BinaryFile file = _riff.file;

        VehicleType[] vehicleTypes;
        SpriteFrameIndex spriteIndex;
        const uint endOffset = file.offset + chunk.size;
        while (file.offset < endOffset) {
            VehicleType veh;

            veh.kind = VehicleKind.GTA2;
            veh.model = file.readUByte();
            veh.sprite = spriteIndex;
            veh.spriteCount = file.readUByte() + 1;
            spriteIndex += veh.spriteCount - 1;
            veh.width = file.readUByte();
            veh.height = file.readUByte();
            veh.remaps.length = file.readUByte();
            veh.passengerCount = file.readUByte();
            veh.wreckSprite = file.readUByte();
            veh.rating = file.readUByte();
            
            veh.physics2.steeringWheelOffset = file.readByte();
            veh.physics2.driveWheelOffset = file.readByte();
            veh.physics2.frontWindowOffset = file.readByte();
            veh.physics2.rearWindowOffset = file.readByte();

            const ubyte flags1 = file.readUByte();
            if (flags1 & 0x1) {
                veh.flags |= VehicleFlags.CANNOT_JUMP_OVER;
            }
            if (flags1 & 0x2) {
                veh.flags |= VehicleFlags.HAS_EMERGENCY_LIGHTS;
            }
            if (flags1 & 0x4) {
                veh.flags |= VehicleFlags.HAS_ROOF_LIGHTS;
            }
            if (flags1 & 0x8) {
                veh.flags |= VehicleFlags.ARTIC_CAB;
            }
            if (flags1 & 0x10) {
                veh.flags |= VehicleFlags.ARTIC_TRAILER;
            }
            if (flags1 & 0x20) {
                veh.flags |= VehicleFlags.HAS_HIRE_LIGHTS;
            }
            if (flags1 & 0x40) {
                veh.flags |= VehicleFlags.HAS_ROOF_DECAL;
            }
            if (flags1 & 0x80) {
                veh.flags |= VehicleFlags.HAS_REAR_EMERGENCY_LIGHTS;
            }

            const ubyte flags2 = file.readUByte();
            if (flags2 & 0x1) {
                veh.flags |= VehicleFlags.CAN_CRUSH_CARS;
            }
            if (flags2 & 0x2) {
                veh.flags |= VehicleFlags.HAS_POPUP_HEADLIGHTS;
            }

            foreach (ref ubyte remap; veh.remaps) {
                remap = file.readUByte();
            }

            veh.doors.length = file.readUByte();
            foreach (ref VehicleDoor door; veh.doors) {
                door.relX = file.readByte();
                door.relY = file.readByte();
            }

            veh.name = Strings.get(format("car%d", veh.model));

            vehicleTypes ~= veh;
        }

        // Read vehicle handling data from nyc.gci
        const string gciPath = buildPath(dirName(_riff.file.name), "nyc.gci");
        GCIParser parser = new GCIParser(gciPath);

        GCIValue val = parser.parse();
        if (val.type != GCIType.STRING) {
            throw new Exception("Invalid GCI file.");
        }

        GCIValue vehicleName;
        while (vehicleName.type != GCIType.EOF) {
            vehicleName = parser.parse();
            if (vehicleName.type == GCIType.EOF) {
                break;
            }

            GCIValue model = parser.parse();
            parser.parse();

            foreach (ref VehicleType veh; vehicleTypes) {
                if (veh.model == model.value.integer) {
                    if (parser.parse().value.integer == 1) {
                        veh.flags |= VehicleFlags.TURBO;
                    }
                    parser.parse();
                    veh.value.length = 1;
                    veh.value[0] = parser.parse().value.integer;
                    parser.parse();
                    parser.parse();
                    parser.parse();
                    veh.physics2.mass = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.frontDriveBias = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.frontMassBias = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.brakeFriction = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.turnIn = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.turnRatio = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.rearStability = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.handbrakeSlide = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.thrust = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.maxSpeed = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.antiStrength = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.skidThreshold = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.gear1Multi = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.gear2Multi = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.gear3Multi = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.gear2Speed = parser.parse().value.floating;
                    parser.parse();
                    veh.physics2.gear3Speed = parser.parse().value.floating;
                    parser.parse();

                    break;
                }
            }
        }

        // Read vehicle recycle info.
        const Chunk recycleChunk = _riff.getChunk("RECY");
        const uint endRecycleOffset = file.offset + recycleChunk.size;
        while (file.offset < endRecycleOffset) {
            const ubyte model = file.readUByte();
            if (model == 0xFF) {
                break;
            }

            foreach (ref VehicleType veh; vehicleTypes) {
                if (veh.model == model) {
                    veh.flags |= VehicleFlags.RECYCLE;
                    break;
                }
            }
        }
        
        return vehicleTypes;
    }

    override public void readEntityTypes(ref EntityType[string] entityTypes, TypeNames!EntityTypeIndex typeNames) {
        const Chunk chunk = _riff.getChunk("OBJI");
        BinaryFile file = _riff.file;

        for (int index = 0; index < chunk.size / 2; index++) {
            const ubyte modelId = file.readUByte();
            
            const string name = typeNames.getName(modelId);
            EntityType entityType;
            if (name in entityTypes) {
                entityType = entityTypes[name];
            } else {
                throw new Exception(format("Cannot augment unknown GTA2 entity type %d:%s.", modelId, name));
            }

            entityType.frameCount = file.readUByte();            
            entityTypes[name] = entityType;
        }
    }

    override public VirtualPalette[] readVirtualPalettes() {
        const Chunk chunk = _riff.getChunk("PALX");
        BinaryFile file = _riff.file;

        VirtualPalette[] palettes = new VirtualPalette[16384];
        foreach (ref VirtualPalette index; palettes) {
            index = _file.readUShort();
        }
        
        return palettes;
    }

    override public Palette[] readPalettes() {
        const Chunk chunk = _riff.getChunk("PPAL");
        BinaryFile file = _riff.file;

        Palette[] palettes = new Palette[chunk.size / 1024];

        // Read palettes.
        // These are stored in 64k pages, with 64 palettes per page. Each 256 bytes contains a row of 64 RGBA entries,
        // one for each of that page's 64 palettes. Every page has 256 rows, one for each entry for each of that
        // page's 64 palettes.
        ubyte[] data = _file.readBytes(chunk.size);
        const uint pageCount = chunk.size / 65536;
        uint i;
        for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
            for (int entryIndex = 0; entryIndex < 256; entryIndex++) {
                for (int palIndex = 0; palIndex < 64; palIndex++) {
                    palettes[palIndex + pageIndex * 64].colors[entryIndex] = RGBA(data[i + 2], data[i + 1], data[i + 0], data[i + 3]);
                    i += 4;
                }
            }
        }

        return palettes;
    }

    override public ushort[] readPaletteBases() {
        const Chunk chunk = _riff.getChunk("PALB");
        BinaryFile file = _riff.file;

        ushort total;
        ushort[] bases = new ushort[8];
        foreach (ref ushort base; bases) {
            base = total;
            total += file.readUShort();
        }
        
        return bases;
    }

    private void readSpriteBase() {
        const Chunk chunk = _riff.getChunk("SPRB");
        BinaryFile file = _riff.file;

        _spriteBase.cars = file.readUShort();
        _spriteBase.peds = file.readUShort();
        _spriteBase.codeEntities = file.readUShort();
        _spriteBase.mapEntities = file.readUShort();
        _spriteBase.user = file.readUShort();
        _spriteBase.fonts = file.readUShort();
    }

    override public Font[] readFonts() {
        const Chunk chunk = _riff.getChunk("FONB");
        BinaryFile file = _riff.file;

        Font[] fonts;
        fonts.length = file.readUShort();
        foreach (ref Font font; fonts) {
            font.firstFrame = file.readUShort(); // TODO: Adjust fron font base sprite value here.
            font.frameCount = 31; // TODO: This should be known.
        }

        return fonts;
    }

    override public Animation[] readAnimations() {
        Animation[] animations;
      
        return animations;
    }

    @property override public ushort blockTexturePaletteCount() {
        return 0;
    }

    @property override public BlockTextureIndex sideTextureCount() {
        return 0;
    }
}