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

module game.map.map;

import std.string;
import std.stdio;
import std.path;
import std.math;

import game.game;

import game.style.style;

import game.entities.entity;
import game.entities.obstacle;
import game.entities.decoration;
import game.entities.powerup;
import game.entities.vehicle;
import game.entities.typenames;

import game.map.block;
import game.map.mapreader;
import game.map.mapreadergta1;
import game.map.mapreadergta2;
import game.map.mapprocessor;
import game.map.mapprocessorgta1;
import game.map.mapprocessorgta2;

import util.binaryfile;
import util.vector3;
import util.color;
import util.log;


public alias short MapCoord;


public enum RouteType : ubyte {
    POLICE = 0xFF
}

public struct Route {
    RouteType type;
    Vector3[] vertices;
}


public enum ZoneType : ubyte {
    GENERAL = 0,
    NAVIGATION = 1,
    TRAFFIC_LIGHT = 2,
    ARROW_BLOCKER = 5,
    RAILWAY_STATION = 6,
    BUS_STOP = 7,
    TRIGGER = 8,
    INFORMATION = 10,
    RAILWAY_STATION_ENTRY = 11,
    RAILWAY_STATION_EXIT = 12,
    RAILWAY_STOP = 13,
    GANG = 14,
    NAVIGATION_LOCAL = 15,
    RESTART = 16,
    RESTART_ARREST = 20
}

public struct Zone {
    ZoneType type;

    MapCoord x;
    MapCoord y;
    MapCoord width;
    MapCoord height;
    
    ubyte sampleIndex;
    string name;
}


public enum LocationType : ubyte {
    POLICE_STATION,
    HOSPITAL,
    FIRE_STATION
}

public struct Location {
    LocationType type;
    Vector3 coordinates;
}


public struct Light {
    RGBA color;
    float x;
    float y;
    float z;
    float radius;
    float intensity;
    float timeRandom;
	float timeOn;
	float timeOff;
}


public enum JunctionType : ubyte {
    UNKNOWN1 = 0,
    UNKNOWN2 = 1,
    UNKNOWN3 = 2,
}

public struct JunctionNetwork {
    Junction[] junctions;
    Segment[] segments;
}

public struct Junction {
    ushort segmentNorth;
    ushort segmentSouth;
    ushort segmentEast;
    ushort segmentWest;

    JunctionType type;

    MapCoord x1;
    MapCoord y1;
    MapCoord x2;
    MapCoord y2;
}

public struct Segment {
    ushort junction1;
    ushort junction2;

    MapCoord x1;
    MapCoord y1;
    MapCoord x2;
    MapCoord y2;
}


public struct MapEntity {
    EntityClass classId;

    string entityType;
    ubyte entityRemap;

    VehicleModelIndex vehicleModel;
    ubyte vehicleRemap;
    
    Vector3 position;
    float rotation;
    float pitch;
    float roll;

    ubyte routeIndex;

    alias position this;
}


public final class Map {

    private MapCoord _width;
    private MapCoord _height;
    private MapCoord _depth;

    private float[8] _shades;
    
    private Block[][][] _blocks;
    private MapEntity[] _mapEntities;
    private Entity[] _entities;
    private Route[] _routes;
    private Zone[] _zones;
    private Location[] _locations;
    private Light[] _lights;
    private Animation[] _animations;
    private JunctionNetwork _junctionNetwork;

    private MapProcessor _processor;
    

    this(const string fileName, TypeNames!EntityTypeIndex entityTypeNames) {
        MapReader reader;
        BinaryFile file = new BinaryFile(fileName);

        const string ext = extension(fileName).toLower();
        if (ext == ".cmp") {
            Log.write(Color.NORMAL, "Reading GTA 1 map '%s'...", file.name);
            reader = new MapReaderGTA1(file);
            _processor = new MapProcessorGTA1(this);

        } else if (ext == ".gmp") {
            Log.write(Color.NORMAL, "Reading GTA 2 map '%s'...", file.name);
            reader = new MapReaderGTA2(file);
            _processor = new MapProcessorGTA2(this);

        }

        reader.readHeader();

        _width = reader.width;
        _height = reader.height;
        _depth = reader.depth;

        _blocks = reader.readBlockData();
        _mapEntities = reader.readMapEntities(entityTypeNames);
        _routes = reader.readRoutes();
        _locations = reader.readLocations();
        _zones = reader.readZones();
        _lights = reader.readLights();
        _animations = reader.readAnimations();
        _junctionNetwork = reader.readJunctionNetwork();

        Log.write(Color.NORMAL, "%dx%dx%d blocks.", _width, _height, _depth);
        Log.write(Color.NORMAL, "%d map entities.", _mapEntities.length);
        Log.write(Color.NORMAL, "%d routes.", _routes.length);
        Log.write(Color.NORMAL, "%d locations.", _locations.length);
        Log.write(Color.NORMAL, "%d zones.", _zones.length);
        Log.write(Color.NORMAL, "%d lights.", _lights.length);
        Log.write(Color.NORMAL, "%d animations.", _animations.length);
        Log.write(Color.NORMAL, "%d junctions, %d segments.", _junctionNetwork.junctions.length, _junctionNetwork.segments.length);
        
        file.close();

        setShadingLevel(15);
    }

    public void spawnMapEntities(Style style) {
        Log.write(Color.NORMAL, "Spawning map entities...");

        Entity ent;
        foreach (MapEntity mapEntity; _mapEntities) {
            if (mapEntity.classId == EntityClass.OBSTACLE) {
                EntityObstacle obstacle = new EntityObstacle(style.getEntityType(mapEntity.entityType));
                ent = cast(Entity)obstacle;
                ent.remap = mapEntity.entityRemap;

            } else if (mapEntity.classId == EntityClass.POWERUP) {
                EntityPowerup powerup = new EntityPowerup(style.getEntityType(mapEntity.entityType), 0);
                ent = cast(Entity)powerup;

            } else if (mapEntity.classId == EntityClass.DECORATION) {
                EntityDecoration decoration = new EntityDecoration(style.getEntityType(mapEntity.entityType));
                ent = cast(Entity)decoration;
                ent.remap = mapEntity.entityRemap;

            } else if (mapEntity.classId == EntityClass.VEHICLE) {
                VehicleType* vehicleType = style.getVehicleType(mapEntity.vehicleModel);
                EntityVehicle vehicle = new EntityVehicle(vehicleType);
                if (gameMode == GameMode.GTA1 && mapEntity.vehicleRemap > 0) {
                    vehicle.hsl = vehicleType.remapsHSL[mapEntity.vehicleRemap - 1];
                }
                ent.remap = mapEntity.vehicleRemap;
                ent = cast(Entity)vehicle;

            } else {
                Log.write(Color.WARNING, "Unknown map entity class %d.", mapEntity.classId);
                continue;

            }

            ent.position = mapEntity.position;
            ent.rotation = mapEntity.rotation;
            ent.roll = mapEntity.roll;
            ent.pitch = mapEntity.pitch;

            _entities ~= ent;
        }
    }

    public Entity spawn(Style style, const string entityTypeName, const Vector3 pos, const float angle) {
        EntityType type = style.getEntityType(entityTypeName);

        Entity entity;
        if (type.classId == EntityClass.OBSTACLE) {
            EntityObstacle obstacle = new EntityObstacle(type);
            entity = cast(Entity)obstacle;

        } else if (type.classId == EntityClass.POWERUP) {
            EntityPowerup powerup= new EntityPowerup(type, 0);
            entity = cast(Entity)powerup;
            
        } else if (type.classId == EntityClass.DECORATION) {
            EntityDecoration decoration = new EntityDecoration(type);
            entity = cast(Entity)decoration;

        } else {
            Log.write(Color.WARNING, "Unknown map entity class %d.", type.classId);
            return null;

        }

        entity.position = pos;
        entity.rotation = angle;

        _entities ~= entity;

        return entity;
    }

    public Entity spawnVehicle(Style style, const VehicleModelIndex model, const Vector3 pos, const float angle, const ubyte remap) {
        VehicleType* vehicleType = style.getVehicleType(model);
        EntityVehicle entity = new EntityVehicle(vehicleType);

        if (gameMode == GameMode.GTA1 && remap > 0) {
            entity.hsl = vehicleType.remapsHSL[remap - 1];
        }

        entity.remap = remap;
        entity.position = pos;
        entity.rotation = angle;

        _entities ~= entity;

        return entity;
    }

    public Entity spawnPowerup(Style style, const string entityTypeName, const Vector3 pos, const uint timer) {
        EntityType type = style.getEntityType(entityTypeName);
        EntityPowerup entity = new EntityPowerup(type, timer);        
        entity.position = pos;
    
        _entities ~= entity;

        return entity;
    }

    public MapCoord getSpawnZ(const MapCoord x, const MapCoord y) {
        const MapCoord bX = cast(MapCoord)(x / BLOCK_SIZE);
        const MapCoord bY = cast(MapCoord)(y / BLOCK_SIZE);

        if (bX < 0 || bX >= _width ||
            bY < 0 || bY >= _height) {
                return 0;
        }

        // TODO: Account for slopes.
        for (MapCoord bZ = cast(MapCoord)(_depth - 1); bZ >= 0; bZ--) {
            if (_blocks[bX][bY][bZ].type != BlockType.AIR) {
                return cast(MapCoord)(bZ * BLOCK_SIZE + BLOCK_SIZE);
            }
        }

        return cast(MapCoord)(_depth * BLOCK_SIZE);
    }

    public void update(const double delta) {
        foreach (Entity entity; _entities) {
            entity.update(delta);
        }
    }

    public void addLight(Light light) {
        _lights ~= light;
    }

    public void process(Style style) {
        _processor.process(style);
    }

    public Block[][][] getBlocks() {
        return _blocks;
    }

    public MapEntity[] getMapEntities() {
        return _mapEntities;
    }

    public Entity[] getEntities() {
        return _entities;
    }

    public Animation[] getAnimations() {
        return _animations;
    }

    public void setShadingLevel(ubyte shadingLevel) {
        shadingLevel = shadingLevel % 32;
        foreach (int index, ref float shade; _shades) {
            shade = 1.0 - log10(index + 1) * (shadingLevel / 31.0);
        }
    }

    @property public MapCoord width() {
        return _width;
    }

    @property public MapCoord height() {
        return _height;
    }

    @property public MapCoord depth() {
        return _depth;
    }

    @property public float[8] shades() {
        return _shades;
    }
}