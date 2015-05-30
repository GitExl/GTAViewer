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

module game.style.style;

import std.stdio;
import std.string;
import std.path;
import std.json;
import std.file;
import std.traits;
import std.conv;

import render.texture;

import game.game;
import game.delta;

import game.map.block;

import game.style.stylereader;
import game.style.stylereadergta1;
import game.style.stylereadergta2;

import game.entities.entity;
import game.entities.vehicle;
import game.entities.typenames;

import util.binaryfile;
import util.bmp;
import util.color;
import util.log;


public alias BlockTextureIndex = ushort;
public alias VirtualPalette = ushort;
public alias FontIndex = ubyte ;
public alias EntityTypeIndex = ushort;
public alias VehicleModelIndex = ubyte;
public alias SpriteFrameIndex = ushort;

private alias PageIndex = ushort;


public immutable uint BLOCKTEXTURE_DIMENSION = 64;
public immutable uint BLOCKTEXTURE_SIZE = BLOCKTEXTURE_DIMENSION * BLOCKTEXTURE_DIMENSION;

public immutable uint MAX_BLOCKTEXTURE_INDICES = 2048;

public immutable uint MAX_SPRITE_DELTAS = 32;


public enum PaletteType : ubyte {
    TILE = 0,
    SPRITE = 1,
    VEHICLE = 2,
    PED = 3,
    CODE_ENTITY = 4,
    MAP_ENTITY = 5,
    USER_ENTITY = 6,
    FONT = 7
}

public struct PaletteIndex {
    PaletteType type;
    ushort index;
}


public struct Animation {
    BlockTextureIndex textureIndex;
    float delay;
    BlockTextureIndex[] frames;

    this(this) {
        textureIndex = textureIndex;
        delay = delay;
        frames = frames.dup;
    }
}


public struct SpriteFrame {
    ubyte width;
    ubyte height;
    PaletteIndex palette;

    uint ptr;
    
    Delta[MAX_SPRITE_DELTAS] deltas;
    ubyte[] image;
}


public struct Font {
    SpriteFrameIndex frameCount;
    SpriteFrameIndex firstFrame;
}


public enum BlockTextureMaterial : ubyte {
    GRASS_DIRT,
    ROAD_SPECIAL,
    WATER,
    ELECTRIFIED,
    ELECTRIFIED_PLATFORM,
    WOOD,
    METAL,
    METAL_WALL,
    GRASS_DIRT_WALL,
    INFER
}

public struct BlockTexture {
    ubyte[BLOCKTEXTURE_SIZE] data;
    BlockTextureMaterial material;
}


public final class Style {

    private BlockTexture[] _blockTextures;
    private Animation[] _animations;
    private Palette[] _palettes;
    private VirtualPalette[] _virtualPalettes;
    private VehicleType[] _vehicleTypes;
    private EntityType[string] _entityTypes;
    private SpriteFrame[] _spriteFrames;
    private Font[] _fonts;
    private ushort[] _paletteBases;
    
    private TypeNames!EntityTypeIndex _entityTypeNames;
    private size_t[VehicleModelIndex] _vehicleModels;

    private ushort _blockTexturePaletteCount;   
    private BlockTextureIndex _sideTextureCount;


    this(const string fileName, TypeNames!EntityTypeIndex entityTypeNames) {
        StyleReader reader;
        BinaryFile file = new BinaryFile(fileName);

        const string ext = extension(fileName).toLower();
        if (ext == ".g24") {
            Log.write(Color.NORMAL, "Reading GTA1 style %s...", file.name);
            reader = new StyleReaderGTA1(file);

        } else if (ext == ".sty") {
            Log.write(Color.NORMAL, "Reading GTA2 style %s...", file.name);
            reader = new StyleReaderGTA2(file);

        }

        _entityTypeNames = entityTypeNames;
        readEntityTypes("data/entitytypes.json");

        reader.readHeader();
        
        _blockTextures = reader.readBlockTextures();
        _sideTextureCount = reader.sideTextureCount;

        _animations = reader.readAnimations();
        _palettes = reader.readPalettes();
        _virtualPalettes = reader.readVirtualPalettes();
        reader.readEntityTypes(_entityTypes, _entityTypeNames);
        _vehicleTypes = reader.readVehicleTypes();
        _spriteFrames = reader.readSpriteFrames();
        _fonts = reader.readFonts();
        _paletteBases = reader.readPaletteBases();

        _blockTexturePaletteCount = reader.blockTexturePaletteCount;

        createVehicleModels();

        file.close();

        Log.write(Color.NORMAL, "%d block textures.", _blockTextures.length);
        Log.write(Color.NORMAL, "%d animations.", _animations.length);
        Log.write(Color.NORMAL, "%d palettes.", _palettes.length);
        Log.write(Color.NORMAL, "%d virtual palettes.", _virtualPalettes.length);
        Log.write(Color.NORMAL, "%d entity types.", _entityTypes.length);
        Log.write(Color.NORMAL, "%d vehicle types.", _vehicleTypes.length);
        Log.write(Color.NORMAL, "%d sprite frames.", _spriteFrames.length);
        Log.write(Color.NORMAL, "%d fonts.", _fonts.length);
    }

    public void readEntityTypes(string fileName) {
        const JSONValue json = parseJSON(readText(fileName));

        foreach (JSONValue obj; json.array) {
            EntityType entityType;
            foreach (string key, JSONValue val; obj.object) {
                switch (key) {
                    case "name":
                        if (val.str in _entityTypes) {
                            throw new Exception(("Duplicate entity type name '%s'.", val.str));
                        }
                        entityType.name = val.str;
                        break;

                    case "class":
                        if (val.str == "OBSTACLE") {
                            entityType.classId = EntityClass.OBSTACLE;
                        } else if (val.str == "DECORATION") {
                            entityType.classId = EntityClass.DECORATION;
                        } else if (val.str == "PROJECTILE") {
                            entityType.classId = EntityClass.PROJECTILE;
                        } else if (val.str == "POWERUP") {
                            entityType.classId = EntityClass.POWERUP;
                        } else if (val.str == "VEHICLE") {
                            entityType.classId = EntityClass.VEHICLE;
                        } else if (val.str == "PED") {
                            entityType.classId = EntityClass.PED;
                        } else {
                            throw new Exception(format("Unknown entity type class '%s'.", val.str));
                        }
                        break;

                    case "baseFrame":
                        entityType.baseFrame = cast(SpriteFrameIndex)val.integer;
                        break;

                    case "frameCount":
                        entityType.frameCount = cast(SpriteFrameIndex)val.integer;
                        break;

                    case "flags":
                        entityType.flags = parseEntityFlags(val.array);
                        break;

                    default:
                        throw new Exception(format("Unknown entity type key '%s'.", key));
                }
            }

            _entityTypes[entityType.name] = entityType;
        }
    }

    private EntityFlags parseEntityFlags(JSONValue[] values) {
        EntityFlags flags;
        foreach (const JSONValue val; values) {
            switch (toUpper(val.str)) {
                case "INVISIBLE": flags |= EntityFlags.INVISIBLE; break;
                case "DISABLED":  flags |= EntityFlags.DISABLED;  break;
                case "NO_SHADOW": flags |= EntityFlags.NO_SHADOW; break;
                default:
                    throw new Exception(format("Unknown entity flags '%s'", val.str));
            }
        }

        return flags;
    }

    public void addAnimations(Animation[] anims) {
        _animations ~= anims;
    }

    private void createVehicleModels() {
        foreach (size_t index, ref VehicleType vehicle; _vehicleTypes) {
            _vehicleModels[vehicle.model] = index;
        }
    }

    // Returns a block texture as an RGBA image.
    public ubyte[] getBlockTextureBGRA(const BlockTextureIndex index) {
        const Palette palette = _palettes[_virtualPalettes[index]];
        
        uint textureIndex = 0;
        ubyte[] data = new ubyte[BLOCKTEXTURE_SIZE * 4];
        foreach (ubyte pixel; _blockTextures[index].data) {
            if (pixel) {
                data[textureIndex + 0] = palette.colors[pixel].b;
                data[textureIndex + 1] = palette.colors[pixel].g;
                data[textureIndex + 2] = palette.colors[pixel].r;
                data[textureIndex + 3] = 0xFF;
            }
            textureIndex += 4;
        }

        return data;
    }
    
    @property public BlockTextureIndex sideTextureCount() {
        return _sideTextureCount;
    }

    public BlockTexture[] getBlockTextures() {
        return _blockTextures;
    }

    public SpriteFrame getSpriteFrame(const SpriteFrameIndex index) {
        return _spriteFrames[index];
    }

    public Palette getPalette(const PaletteIndex index) {
        return _palettes[_virtualPalettes[_paletteBases[index.type] + index.index]];
    }

    public Palette getLogicalPalette(const ushort index) {
        return _palettes[index];
    }

    public ushort getLogicalPaletteIndex(const PaletteIndex index) {
        return _virtualPalettes[_paletteBases[index.type] + index.index];
    }

    public Animation[] getAnimations() {
        return _animations;
    }

    public ref EntityType getEntityType(const string name) {
        if (name !in _entityTypes) {
            throw new Exception(format("Unknown entity type '%s'.", name));
        }

        return _entityTypes[name];
    }

    public string getEntityTypeName(const EntityTypeIndex index) {
        return _entityTypeNames.getName(index);
    }

    public VehicleType* getVehicleType(const VehicleModelIndex model) {
        if (model !in _vehicleModels) {
            throw new Exception(format("Unknown vehicle model '%d'.", model));
        }

        return &_vehicleTypes[_vehicleModels[model]];
    }

    public void dumpSprites() {
        foreach (uint spriteIndex, ref SpriteFrame frame; _spriteFrames) {
            const Palette palette = getPalette(frame.palette);

            int dx;
            int dy = 0;
            ubyte[] data = new ubyte[frame.image.length * 4];
            for (uint index = 0; index < frame.image.length; index++) {
                const ubyte pixel = frame.image[index];
                const uint dest = (dx + (dy * frame.width)) * 4;
                data[dest + 0] = palette.colors[pixel].b;
                data[dest + 1] = palette.colors[pixel].g;
                data[dest + 2] = palette.colors[pixel].r;
                data[dest + 3] = palette.colors[pixel].a;
                
                dx += 1;
                if (dx >= frame.width) {
                    dx = 0;
                    dy += 1;
                }
            }

            writeBMP32(format("sprites/%s_%.4d.bmp", to!string(gameMode), spriteIndex), frame.width, frame.height, data);
        }
    }
}