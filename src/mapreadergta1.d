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

module game.map.mapreadergta1;

import std.stdio;
import std.string;
import std.json;
import std.file;
import std.conv;

import game.map.block;
import game.map.mapreader;
import game.map.map;

import game.entities.entity;
import game.entities.vehicle;
import game.entities.obstacle;
import game.entities.typenames;

import game.style.style;

import util.binaryfile;
import util.vector3;
import util.convert;


private struct BlockColumn {
    ushort height;
    ushort[] blocks;
}


private align(1) struct Header {
    uint ver;

    ubyte styleIndex;
    ubyte audioBankIndex;

    ushort unused;

    uint routeDataSize;
    uint entityDataSize;
    uint blockColumnDataSize;
    uint blockDataSize;
    uint zoneDataSize;
}


public class MapReaderGTA1 : MapReader {

    private Header _header;

    private string[EntityTypeIndex] _entityTypeNames;

    private static immutable uint HEADER_VERSION = 331;

    private static immutable MapCoord MAP_WIDTH = 256;
    private static immutable MapCoord MAP_HEIGHT = 256;
    private static immutable MapCoord MAP_DEPTH = 6;


    this(BinaryFile file) {
        super(file);
    }

    override public void readHeader() {
        _header.ver = _file.readUInt();
        _header.styleIndex = _file.readUByte();
        _header.audioBankIndex = _file.readUByte();

        _file.readUShort();

        _header.routeDataSize = _file.readUInt();
        _header.entityDataSize = _file.readUInt();
        _header.blockColumnDataSize = _file.readUInt();
        _header.blockDataSize = _file.readUInt();
        _header.zoneDataSize = _file.readUInt();
        
        // Validate version code.
        if (_header.ver != HEADER_VERSION) {
            throw new Exception(format("Invalid or unsupported GTA 1 map file version '%d'.", _header.ver));
        }
    }

    override public Block[][][] readBlockData() {

        // Read block column offsets.
        uint[][] columnOffsets = new uint[][](MAP_WIDTH, MAP_HEIGHT);
        for (MapCoord y = 0; y < MAP_HEIGHT; y++) {
            for (MapCoord x = 0; x < MAP_WIDTH; x++) {
                columnOffsets[x][y] = _file.readUInt();
            }
        }

        // Read block column data.
        const uint offsetBase = _file.offset;
        BlockColumn[][] columns = new BlockColumn[][](MAP_WIDTH, MAP_HEIGHT);
        for (MapCoord y = 0; y < MAP_HEIGHT; y++) {
            for (MapCoord x = 0; x < MAP_WIDTH; x++) {
                _file.seek(offsetBase + columnOffsets[x][y]);

                const int height = MAP_DEPTH - _file.readUShort();
                columns[x][y].height = cast(ushort)height;
                columns[x][y].blocks = new ushort[height];

                for (int index = 0; index < height; index++) {
                    columns[x][y].blocks[index] = _file.readUShort();
                }
            }
        }
        _file.seek(offsetBase + _header.blockColumnDataSize);

        // Read block types.
        const uint blockCount = _header.blockDataSize / 8;
        Block[] blockTypes = new Block[blockCount];
        foreach (ref Block block; blockTypes) {
            const ushort typeMap = _file.readUShort();
            const ubyte typeMapExt = _file.readUByte();
            const ubyte[] textureData = _file.readBytes(5);
            
            block.directions = cast(BlockDirection)(typeMap & 0xF);
            block.type = cast(BlockType)((typeMap >> 4) & 0x7);
            block.shape = cast(BlockShape)((typeMap >> 8) & 0x3F);
            
            
            const ubyte trafficFlags = typeMapExt & 0x7;
            if (trafficFlags & 0x1) {
                block.flags |= BlockFlags.TRAFFIC_LIGHT_1;
            }
            if (trafficFlags & 0x2) {
                block.flags |= BlockFlags.TRAFFIC_LIGHT_2;
            }
            if (trafficFlags & 0x4) {
                block.flags |= BlockFlags.TRAFFIC_LIGHT_3;
            }
            if (trafficFlags & 0x8) {
                block.flags |= BlockFlags.TRAFFIC_LIGHT_4;
            }

            block.lidTextureRemap = (typeMapExt >> 3) & 0x3;
            
            if (typeMapExt & 0x80) {
                block.flags |= BlockFlags.RAILWAY;
            }
            
            block.faces[FaceIndex.LEFT].texture = cast(BlockTextureIndex)textureData[0];
            block.faces[FaceIndex.RIGHT].texture = cast(BlockTextureIndex)textureData[1];
            block.faces[FaceIndex.TOP].texture = cast(BlockTextureIndex)textureData[2];
            block.faces[FaceIndex.BOTTOM].texture = cast(BlockTextureIndex)textureData[3];
            block.faces[FaceIndex.LID].texture = cast(BlockTextureIndex)textureData[4];

            // Rotation.
            const ubyte rotation = (typeMap >> 14) & 0x3;
            if (rotation == 1) {
                block.faces[FaceIndex.LID].rotation = 360.0 - 90.0;
            } else if (rotation == 2) {
                block.faces[FaceIndex.LID].rotation = 360.0 - 180.0;
            } else if (rotation == 3) {
                block.faces[FaceIndex.LID].rotation = 360.0 - 270.0;
            }

            // Flip top + bottom.
            if (typeMapExt & 0x20) {
                block.faces[FaceIndex.TOP].flags |= BlockFaceFlags.FLIP;
                block.faces[FaceIndex.BOTTOM].flags |= BlockFaceFlags.FLIP;
            }

            // Flip left + right.
            if (typeMapExt & 0x40) {
                block.faces[FaceIndex.LEFT].flags |= BlockFaceFlags.FLIP;
                block.faces[FaceIndex.RIGHT].flags |= BlockFaceFlags.FLIP;
            }

            // Flat.
            if (typeMap & 0x80) {
                block.faces[FaceIndex.TOP].flags |= BlockFaceFlags.FLAT;
                block.faces[FaceIndex.BOTTOM].flags |= BlockFaceFlags.FLAT;
                block.faces[FaceIndex.LEFT].flags |= BlockFaceFlags.FLAT;
                block.faces[FaceIndex.RIGHT].flags |= BlockFaceFlags.FLAT;
                block.faces[FaceIndex.LID].flags |= BlockFaceFlags.FLAT;
            }

            // Wall solidity.
            block.faces[FaceIndex.TOP].flags |= BlockFaceFlags.WALL | BlockFaceFlags.BULLET_WALL;
            block.faces[FaceIndex.BOTTOM].flags |= BlockFaceFlags.WALL | BlockFaceFlags.BULLET_WALL;
            block.faces[FaceIndex.LEFT].flags |= BlockFaceFlags.WALL | BlockFaceFlags.BULLET_WALL;
            block.faces[FaceIndex.RIGHT].flags |= BlockFaceFlags.WALL | BlockFaceFlags.BULLET_WALL;
        }

        // Decompress entire map from column data.
        Block[][][] blocks = new Block[][][](MAP_WIDTH, MAP_HEIGHT, MAP_DEPTH);
        for (MapCoord y = 0; y < MAP_HEIGHT; y++) {
            for (MapCoord x = 0; x < MAP_WIDTH; x++) {
                const int columnHeight = columns[x][y].height;
                const int startDepth = MAP_DEPTH - columnHeight;

                for (int depth = 0; depth < columnHeight; depth++) {
                    const int blockIndex = columns[x][y].blocks[depth];
                    blocks[x][y][MAP_DEPTH - 1 - (startDepth + depth)] = blockTypes[blockIndex];
                }
            }
        }

        return blocks;
    }

    override public MapEntity[] readMapEntities(TypeNames!EntityTypeIndex typeNames) {
        MapEntity[] mapEntities;
        ubyte routeIndex;

        for (int index = 0; index < _header.entityDataSize / 14; index++) {
            MapEntity mapEntity;

            mapEntity.position.readUShortFrom(_file);
            mapEntity.position.z = (MAP_DEPTH * 64) - mapEntity.position.z;
            const ubyte typeVal = _file.readUByte();
            
            const ubyte remap = _file.readUByte();
            if (remap >= 128) {
                mapEntity.classId = EntityClass.VEHICLE;
                mapEntity.vehicleModel = cast(VehicleModelIndex)typeVal;
                mapEntity.vehicleRemap = cast(ubyte)(remap - 128);
            } else {
                mapEntity.classId = EntityClass.OBSTACLE;
                mapEntity.entityType = typeNames.getName(typeVal);
                mapEntity.entityRemap = remap;
            }

            // Traffic light box entities use rotation as route index.
            const ushort rotation = _file.readUShort();
            if (mapEntity.entityType == "G1Junction1") {
                mapEntity.routeIndex = cast(ubyte)rotation;
                mapEntity.rotation = 0.0;
            } else {
                mapEntity.rotation = convertAngle(rotation);
            }

            mapEntity.pitch = convertAngle(_file.readUShort());
            mapEntity.roll = convertAngle(_file.readUShort());

            mapEntities ~= mapEntity;
        }

        return mapEntities;
    }

    override public Route[] readRoutes() {
        Route[] routes;
        uint offset;
        const uint routeOffsetBase = _file.offset;

        while (offset < routeOffsetBase + _header.routeDataSize) {
            const int vertexCount = _file.readUByte();

            Route route;
            route.type = cast(RouteType)_file.readUByte();
            route.vertices = new Vector3[vertexCount];
            for (int index; index < vertexCount; index++) {
                route.vertices[index].readUByteFrom(_file);
            }
            routes ~= route;

            offset = _file.offset;
        }

        return routes;
    }

    override public Location[] readLocations() {
        Location[] locations;

        locations ~= readLocationList(6, LocationType.POLICE_STATION);
        locations ~= readLocationList(6, LocationType.HOSPITAL);

        // Skip unused locations.
        _file.skip(3 * 6);
        _file.skip(3 * 6);

        locations ~= readLocationList(6, LocationType.FIRE_STATION);

        // Skip unused location.
        _file.skip(3 * 6);

        return locations;
    }

    private Location[] readLocationList(const uint amount, const LocationType type) {
        Location[] locations;

        for (int index = 0; index < amount; index++) {
            Location location;
            location.coordinates.readUByteFrom(_file);
            if (location.coordinates.x != 0 || location.coordinates.y != 0 || location.coordinates.z != 0) {
                location.type = type;
                locations ~= location;
            }
        }

        return locations;
    }

    override public Zone[] readZones() {
        Zone[] zones;
        uint offset;
        const uint zonesOffsetBase = _file.offset;

        while (offset < zonesOffsetBase + _header.zoneDataSize) {
            Zone zone;
            zone.type = ZoneType.NAVIGATION;
            zone.x = _file.readUByte();
            zone.y = _file.readUByte();
            zone.width = _file.readUByte();
            zone.height = _file.readUByte();
            zone.sampleIndex = _file.readUByte();
            zone.name = _file.readNullString(30);

            if (zone.x != 0 || zone.y != 0 || zone.width != 0 || zone.height != 0) {
                zones ~= zone;
            }
            
            offset = _file.offset;
        }

        return zones;
    }

    override public Light[] readLights() {
        Light[] lights;

        return lights;
    }

    override public Animation[] readAnimations() {
        Animation[] animations;

        return animations;
    }

    override public JunctionNetwork readJunctionNetwork() {
        JunctionNetwork junctionNetwork;

        return junctionNetwork;
    }

    @property override public MapCoord width() {
        return MAP_WIDTH;
    }

    @property override public MapCoord height() {
        return MAP_HEIGHT;
    }

    @property override public MapCoord depth() {
        return MAP_DEPTH;
    }
}
