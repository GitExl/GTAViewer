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

module game.map.mapreadergta2;

import std.stdio;
import std.string;
import std.path;

import game.map.block;
import game.map.map;
import game.map.mapreader;

import game.style.style;

import game.entities.entity;
import game.entities.typenames;

import util.binaryfile;
import util.vector3;
import util.rifffile;


private struct BlockColumn {
    ubyte height;
    ubyte offset;
    uint[] blocks;
}


public class MapReaderGTA2 : MapReader {

    private string _fileName;
    private RIFFFile _riff;
    private string[EntityTypeIndex] _entityTypeNames;

    private static immutable MapCoord MAP_WIDTH = 256;
    private static immutable MapCoord MAP_HEIGHT = 256;
    private static immutable MapCoord MAP_DEPTH = 8;


    this(BinaryFile file) {
        super(file);
        _fileName = file.name;
    }

    override public void readHeader() {
        _riff = new RIFFFile(_file);

        if (_riff.type != "GBMP") {
            throw new Exception(format("'%s' is not a GTA 2 map file.", _file.name));
        }
        if (_riff.versionNum != 500) {
            throw new Exception(format("Invalid or unsupported GTA 2 map file version '%d'.", _riff.versionNum));
        }
    }

    override public Block[][][] readBlockData() {
        const Chunk chunk = _riff.getChunk("DMAP");
        BinaryFile file = _riff.file;

        // Read block column offsets.
        uint[][] columnTypes = new uint[][](MAP_WIDTH, MAP_HEIGHT);
        for (MapCoord y = 0; y < MAP_HEIGHT; y++) {
            for (MapCoord x = 0; x < MAP_WIDTH; x++) {
                columnTypes[x][y] = file.readUInt() * 4;
            }
        }

        // Read block column data.
        const uint columnEnd = file.offset + (file.readUInt() * 4);
        const uint startOffset = file.offset;
        BlockColumn[uint] columns;
        while (file.offset < columnEnd) {
            const uint offset = file.offset - startOffset;

            BlockColumn column;
            column.height = file.readUByte();
            column.offset = file.readUByte();
            file.skip(2);

            column.blocks = new uint[column.height - column.offset];
            foreach (ref uint columnd; column.blocks) {
                columnd = file.readUInt();
            }

            columns[offset] = column;
        }

        // Read block types.
        const uint blockCount = file.readUInt();
        Block[] blockTypes = new Block[blockCount];
        foreach (ref Block block; blockTypes) {
            block.flags = BlockFlags.NONE;

            foreach (FaceIndex index, ref BlockFace face; block.faces) {
                ushort bits = file.readUShort();

                face.texture = bits & 0x3FF;

                if (index == FaceIndex.LID) {
                    switch ((bits >> 10) & 0x3) {
                        default:
                        case 0:
                            break;
                        case 1:
                            face.flags |= BlockFaceFlags.SHADE0;
                            break;
                        case 2:
                            face.flags |= BlockFaceFlags.SHADE1;
                            break;
                        case 3:
                            face.flags |= BlockFaceFlags.SHADE0;
                            face.flags |= BlockFaceFlags.SHADE1;
                            break;
                    }
                    
                } else {
                    if (bits & 0x400) {
                        face.flags |= BlockFaceFlags.WALL;
                    }
                    if (bits & 0x800) {
                        face.flags |= BlockFaceFlags.BULLET_WALL;
                    }
                    face.brightness = 1.0;
                }

                if (bits & 0x1000) {
                    face.flags |= BlockFaceFlags.DOUBLESIDED;
                }
                if (bits & 0x2000) {
                    face.flags |= BlockFaceFlags.FLIP;
                }
                
                face.rotation = (360.0 - (((bits >> 14) & 0x3) * 90.0)) % 360.0;
            }

            block.directions = cast(BlockDirection)file.readUByte();

            const ubyte shapeBits = file.readUByte();
            block.shape = cast(BlockShape)((shapeBits >> 2) & 0x3F);
            
            // Treat "Above block slope" shape as a plain block.
            if (block.shape == BlockShape.SLOPE_ABOVE) {
                block.shape = BlockShape.CUBE;
            }

            // Map block types to common types.
            block.type = cast(BlockType)(shapeBits & 0x3);
            if (block.type == BlockType.WATER) {
                block.type = BlockType.ROAD;
            } else if (block.type == BlockType.ROAD) {
                block.type = BlockType.PAVEMENT;
            } else if (block.type == BlockType.PAVEMENT) {
                block.type = BlockType.FIELD;
            }

            // Convert 4-sided diagonal block shapes to 3-sided ones.
            if (block.shape >= 49 && block.shape <= 52 && block.faces[FaceIndex.LID].texture == 1023) {
                block.shape += 15;
            }

            // Throw away special block shape indicator textures.
            foreach (ref BlockFace face; block.faces) {
                if (face.texture == 1023) {
                    face.texture = 0;
                }
            }
        }

        // Decompress entire map from column data.
        Block[][][] blocks = new Block[][][](MAP_WIDTH, MAP_HEIGHT, MAP_DEPTH);
        for (MapCoord y = 0; y < MAP_HEIGHT; y++) {
            for (MapCoord x = 0; x < MAP_WIDTH; x++) {
                const BlockColumn column = columns[columnTypes[x][y]];

                foreach (int index, uint blockIndex; column.blocks) {
                    blocks[x][y][index + column.offset] = blockTypes[blockIndex];
                }
            }
        }

        return blocks;
    }

    override public MapEntity[] readMapEntities(TypeNames!EntityTypeIndex typeNames) {
        if (!_riff.contains("MOBJ")) {
            MapEntity[] entities;
            return entities;
        }

        const Chunk chunk = _riff.getChunk("MOBJ");
        BinaryFile file = _riff.file;

        MapEntity[] mapEntities;
        for (int index = 0; index < chunk.size / 6; index++) {
            MapEntity mapEntity;

            mapEntity.position.x = (file.readUShort() / 128.0) * BLOCK_SIZE;
            mapEntity.position.y = (file.readUShort() / 128.0) * BLOCK_SIZE;

            mapEntity.rotation = (file.readUByte() / 255.0) * 360.0;
            mapEntity.entityType = typeNames.getName(file.readUByte());

            mapEntity.classId = EntityClass.OBSTACLE;
            
            mapEntities ~= mapEntity;
        }

        return mapEntities;
    }

    override public Route[] readRoutes() {
        Route[] routes;

        return routes;
    }

    override public Location[] readLocations() {
        Location[] locations;

        return locations;
    }

    override public Zone[] readZones() {
        const Chunk chunk = _riff.getChunk("ZONE");
        BinaryFile file = _riff.file;

        Zone[] zones;
        const uint endOffset = file.offset + chunk.size;
        while (file.offset < endOffset) {
            Zone zone;

            zone.type = cast(ZoneType)file.readUByte();
            zone.x = file.readUByte();
            zone.y = file.readUByte();
            zone.width = file.readUByte();
            zone.height = file.readUByte();

            const ubyte length = file.readUByte();
            zone.name = file.readString(length);

            zones ~= zone;
        }

        return zones;
    }

    override public Light[] readLights() {
        Light[] lights;

        if (!_riff.contains("LGHT")) {
            return lights;
        }

        const Chunk chunk = _riff.getChunk("LGHT");
        BinaryFile file = _riff.file;
        
        const uint endOffset = file.offset + chunk.size;
        while (file.offset < endOffset) {
            Light light;

            light.color.b = file.readUByte();
            light.color.g = file.readUByte();
            light.color.r = file.readUByte();           
            light.color.a = file.readUByte();

            light.x = file.readUShort() / 128.0;
            light.y = file.readUShort() / 128.0;
            light.z = file.readUShort() / 128.0;

            light.radius = file.readUShort() / 128.0;
            light.intensity = file.readUByte() / 255.0;
            
            light.timeRandom = file.readUByte() * 0.04;
            light.timeOn = file.readUByte() * 0.04;
            light.timeOff = file.readUByte() * 0.04;

            lights ~= light;
        }

        return lights;
    }

    override public Animation[] readAnimations() {
        Animation[] animations;

        if (!_riff.contains("ANIM")) {
            return animations;
        }

        const Chunk chunk = _riff.getChunk("ANIM");
        BinaryFile file = _riff.file;

        const uint endOffset = file.offset + chunk.size;
        while (file.offset < endOffset) {
            Animation animation;

            animation.textureIndex = file.readUShort();
            animation.delay = file.readUByte() * 0.04;
            file.skip(1);
            
            const ubyte frameCount = file.readUByte();
            file.skip(1);
            animation.frames = new BlockTextureIndex[frameCount];
            foreach (ref BlockTextureIndex texture; animation.frames) {
                texture = file.readUShort();
            }

            animations ~= animation;
        }

        return animations;
    }

    override public JunctionNetwork readJunctionNetwork() {
        JunctionNetwork network;

        if (!_riff.contains("RGEN")) {
            return network;
        }

        const Chunk chunk = _riff.getChunk("RGEN");
        BinaryFile file = _riff.file;

        file.seek(chunk.offset + chunk.size - 6);
        const uint junctionCount = file.readUShort();
        const uint segmentHCount = file.readUShort();
        const uint segmentVCount = file.readUShort();
        file.seek(chunk.offset);

        network.junctions.length = junctionCount;
        network.segments.length = segmentHCount + segmentVCount + 1;

        // Read junctions. Links are ignored, they are built from segment info instead.
        foreach (ref Junction junction; network.junctions) {
            file.skip(8);
            
            junction.type = cast(JunctionType)file.readUInt();

            junction.x1 = file.readUByte();
            junction.y1 = file.readUByte();
            junction.x2 = file.readUByte();
            junction.y2 = file.readUByte();
        }
        file.skip((545 - junctionCount) * 16);

        // Read horizontal segments and assign them to junctions.
        foreach (ushort index, ref Segment segment; network.segments[0..segmentHCount]) {
            segment.junction1 = file.readUShort();
            segment.junction2 = file.readUShort();
            
            segment.x1 = file.readUByte();
            segment.y1 = file.readUByte();
            segment.x2 = file.readUByte();
            segment.y2 = file.readUByte();

            network.junctions[segment.junction1].segmentEast = index;
            network.junctions[segment.junction2].segmentWest = index;
        }
        file.skip((545 - segmentHCount) * 8);

        // Read vertical segments and assign them to junctions.
        foreach (ushort index, ref Segment segment; network.segments[segmentHCount + 1..$]) {
            segment.junction1 = file.readUShort();
            segment.junction2 = file.readUShort();
            
            segment.x1 = file.readUByte();
            segment.y1 = file.readUByte();
            segment.x2 = file.readUByte();
            segment.y2 = file.readUByte();

            network.junctions[segment.junction1].segmentNorth = cast(ushort)(index + segmentHCount);
            network.junctions[segment.junction2].segmentSouth = cast(ushort)(index + segmentHCount);
        }
        file.skip((545 - segmentVCount) * 8);

        return network;
    }

    private string getEntityTypeName(const EntityTypeIndex modelId) {
        if (modelId !in _entityTypeNames) {
            throw new Exception(format("Entity type model id '%d' is not known.", modelId));
        }

        return _entityTypeNames[modelId];
    }

    override @property public MapCoord width() {
        return MAP_WIDTH;
    }

    override @property public MapCoord height() {
        return MAP_HEIGHT;
    }

    override @property public MapCoord depth() {
        return MAP_DEPTH;
    }
}
