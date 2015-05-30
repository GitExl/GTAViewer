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

module game.gamestate_level;

import std.stdio;
import std.path;
import std.string;
import std.conv;
import std.algorithm;

import derelict.sdl2.sdl;

import audio.source;

import game.game;
import game.gamestate;
import game.audiobank;
import game.animations;
import game.spritetextures;

import game.style.style;

import game.map.map;
import game.map.block;
import game.map.blockgeometries;
import game.map.maprenderer;

import game.entities.entity;
import game.entities.typenames;

import game.script.missionlist;

import render.camera;
import render.texturearray;
import render.spritebatch;
import render.enums;

import util.console;
import util.vector3;
import util.rectangle;
import util.color;
import util.bmp;
import util.log;


public final class GameStateLevel : GameState {

    private Map _map;
    private Style _style;
    private AudioBank _audioBank;
    private Game _game;
    private Animations _anims;
    private BlockGeometries _blocks;
    private SpriteTextures _spriteTextures;
    private Camera _camera;
    private MapRenderer _mapRender;
    private TextureArray _blockTextures;
    private SpriteBatch _spriteBatch;
    private TypeNames!EntityTypeIndex _entityTypeNames;
    private Mission _mission;

    private float[4] _ambientColor = [1.0, 1.0, 1.0, 1.0];
    private bool _shadows;

    private CVar _cvarFOV;
    private CVar _cvarBlockMipMaps;
    private CVar _cvarBaseDir;
    private CVar _cvarDusk;
    private CVar _cvarDumpSprites;
    private CVar _cvarDumpBlockTextures;


    this(Game game, Mission mission) {
        _cvarFOV = CVars.get("g_fov");
        _cvarBlockMipMaps = CVars.get("r_blockmipmaps");
        _cvarDumpSprites = CVars.get("r_dumpsprites");
        _cvarDumpBlockTextures = CVars.get("r_dumpblocktextures");
        _cvarBaseDir = CVars.get("g_basedir");
        _cvarDusk = CVars.get("g_dusk");

        _shadows = (CVars.get("r_shadows").intVal == true);

        _game = game;
        _mission = mission;

        Log.write(Color.NORMAL, "Starting %s mission '%s: %s'.", toLower(to!string(_mission.type)), _mission.cityName, _mission.name);

        // Read entity type names.
        string typeNameFile;
        if (gameMode == GameMode.GTA1) {
            typeNameFile = "data/entitytypenames_gta1.json";
        } else if (gameMode == GameMode.GTA2) {
            typeNameFile = "data/entitytypenames_gta2.json";
        }
        Log.write(Color.NORMAL, "Reading entity type names...");
        _entityTypeNames = new TypeNames!EntityTypeIndex(typeNameFile);

        // Load map and corresponding data.
        _map = new Map(buildPath("base", _cvarBaseDir.strVal, baseName(_mission.mapName)), _entityTypeNames);
        _audioBank = new AudioBank(buildPath("base", _cvarBaseDir.strVal, _mission.audioName));
        _style = new Style(buildPath("base", _cvarBaseDir.strVal, _mission.styleName), _entityTypeNames);
        
        // Dump sprites.
        if (_cvarDumpSprites.intVal) {
            Log.write(Color.NORMAL, "Dumping sprites...");
            _style.dumpSprites();
        }
        
        // Setup animated block textures.
        _style.addAnimations(_map.getAnimations());
        _anims = new Animations(_style);

        // Generate block textures.
        buildBlockTextures();

        // Setup sprite rendering.
        _spriteTextures = new SpriteTextures(_style);
        _spriteBatch = new SpriteBatch();
        
        // Setup camera.
        _camera = new Camera(_game.renderer.width, game.renderer.height, _cvarFOV.floatVal, 40.0, 3840.0);
        _camera.move(Vector3(_map.width * BLOCK_SIZE / 2, _map.height * BLOCK_SIZE / 2, 1280));

        // Setup map.
        Log.write(Color.NORMAL, "Map initialization...");
        _mission.script.init(this, _style, _map);
        _map.process(_style);
        _map.spawnMapEntities(_style);

        // Generate static map geometry.
        Log.write(Color.NORMAL, "Generating map geometry...");
        _blocks = new BlockGeometries("data/block_geometry.json");
        _mapRender = new MapRenderer(_map, _style, _blocks);
        _mapRender.setBlockTextures(_blockTextures);

        // Set the desired ambient color;
        if (_cvarDusk.intVal) {
            _mapRender.setAmbientColor(_ambientColor);
            _spriteBatch.setAmbientColor(_ambientColor);
        } else {
            _mapRender.setAmbientColor([1.0, 1.0, 1.0, 1.0]);
            _spriteBatch.setAmbientColor([1.0, 1.0, 1.0, 1.0]);
        }
        
        _mission.script.run();
    }

    private void buildBlockTextures() {
        Log.write(Color.NORMAL, "Generating geometry textures...");
        if (_cvarDumpBlockTextures.intVal) {
            Log.write(Color.NORMAL, "Dumping geometry textures...");
        }

        _blockTextures = new TextureArray(BLOCKTEXTURE_DIMENSION, InternalTextureFormat.RGBA, TextureFormat.BGRA);
        _blockTextures.mipmapLevels = cast(int)_cvarBlockMipMaps.intVal;

        foreach (BlockTextureIndex index, ref BlockTexture texture; _style.getBlockTextures()) {
            ubyte[] data = _style.getBlockTextureBGRA(index);
            if (_cvarDumpBlockTextures.intVal) {
                writeBMP32(format("blocktextures/%s_%.4d.bmp", to!string(gameMode), index), BLOCKTEXTURE_DIMENSION, BLOCKTEXTURE_DIMENSION, data);
            }

            _blockTextures.addTexture(data);
        }

        _blockTextures.generate();
    }

    override public void update(const double delta) {
        _camera.interpolateStart();
        _camera.update(delta);
        _map.update(delta);
        _anims.update(delta);
        _mapRender.setTextureRemaps(_anims.getIndices());
    }

    override public void render(const double lerp) {
        _camera.interpolateEnd(lerp);
        const Rectangle rect = _camera.unproject();

        renderAudio(rect);
        
        _mapRender.setMatrix(_camera.projectionViewMatrix);
        _mapRender.prepareForDrawing(rect);
        _mapRender.drawOpaqueGeometry();
        _mapRender.drawTransparentGeometry();
        drawSprites(rect);
    }

    private void renderAudio(Rectangle rect) {
        // TODO: Set listener position to player ped position!
        Vector3 pos = _camera.position;
        pos.z = 128;
        _game.audio.setListenerPosition(pos);
        _game.audio.setListenerVelocity(_camera.velocity);

        rect.x1 -= 64 * 8;
        rect.y1 -= 64 * 8;
        rect.x2 += 64 * 8;
        rect.y2 += 64 * 8;

        // What happens when a sound entity is deleted?
        foreach (ref Entity entity; _map.getEntities()) {
            const bool inActive = (entity.flags & EntityFlags.DISABLED) ||
                                  (entity.position.x < rect.x1) || (entity.position.x > rect.x2 ||
                                  (entity.position.y < rect.y1) || entity.position.y > rect.y2);

            // Prune inactive audio sources.
            if (inActive) {
                if (entity.audioSource !is null) {
                    entity.audioSource.stop();
                    _game.audio.returnSource(entity.audioSource);
                    entity.audioSource = null;
                }

            // Allocate new audio source if needed.
            } else if (entity.soundType != SoundType.NONE) {
                if (entity.audioSource is null) {
                    const bool loop = (entity.soundType == SoundType.LOOP);
                    const AudioSourceType type = loop ? AudioSourceType.LOOPING : AudioSourceType.SINGLE;

                    entity.audioSource = _game.audio.getSource(type);
                    entity.audioSource.bindBuffer(_audioBank.getChunk(entity.sound).buffer);
                    entity.audioSource.setLooping(loop);
                    entity.audioSource.play();
                
                // Update audio source.
                } else {
                    if (entity.audioSource.getState() == AudioSourceState.STOPPED) {
                        entity.audioSource.stop();
                        _game.audio.returnSource(entity.audioSource);
                        entity.audioSource = null;
                    } else {
                        entity.audioSource.setPosition(entity.position);
                    }

                }
            }

        }
    }

    private void drawSprites(const Rectangle rect) {
        foreach (ref Entity entity; _map.getEntities()) {
            if ((entity.flags & EntityFlags.INVISIBLE) || (entity.flags & EntityFlags.DISABLED)) {
                continue;
            }

            const SpriteFrame frame = _style.getSpriteFrame(cast(SpriteFrameIndex)(entity.baseFrame + entity.frame));
            
            // Determine if sprite is visible.
            if (entity.position.x < rect.x1 - frame.width / 2 || entity.position.x > rect.x2 + frame.width / 2 ||
                entity.position.y < rect.y1 - frame.height / 2 || entity.position.y > rect.y2 + frame.height / 2) {
                continue;
            }

            // Generate new sprite texture if needed.
            if (entity.spriteTexture is null) {
                const PaletteIndex palette = entity.palette(frame);
                const ushort logicalPalette = _style.getLogicalPaletteIndex(palette);
                const SpriteRef spriteRef = SpriteRef(entity.baseFrame, entity.frameCount, logicalPalette, entity.hsl, entity.deltaMask);
                entity.spriteTexture = _spriteTextures.get(spriteRef);
            }
            const SubTexture subTexture = entity.spriteTexture.subTextures[entity.frame];

            // Shadow.
            // TODO: Higher camera Z = shadows further away.
            if (_shadows && !(entity.flags & EntityFlags.NO_SHADOW)) {
                _spriteBatch.add(Sprite(
                    Vector3(
                        cast(float)entity.position.x + 4,
                        cast(float)entity.position.y + 4,
                        cast(float)entity.position.z + 0.025
                    ),
                    frame.width, frame.height,
                    entity.spriteTexture.texture,
                    subTexture.u, subTexture.v,
                    entity.rotation, (1.0 / 3) * 2, 0.0
                ));
            }

            _spriteBatch.add(Sprite(
                Vector3(
                    cast(float)entity.position.x,
                    cast(float)entity.position.y,
                    cast(float)entity.position.z + 0.050
                ),
                frame.width, frame.height,
                entity.spriteTexture.texture,
                subTexture.u, subTexture.v,
                entity.rotation, 1.0, 1.0
            ));
        }

        _spriteBatch.setMatrix(_camera.projectionViewMatrix);
        _spriteBatch.draw();
    }

    override public void input(ubyte* keys) {
        Vector3 thrust;

        const float speed = _camera.position.z / 1000.0;
        if (keys[SDL_SCANCODE_LEFT]) {
            thrust.x = -26 * speed;
        } else if (keys[SDL_SCANCODE_RIGHT]) {
            thrust.x = 26 * speed;
        }

        if (keys[SDL_SCANCODE_UP]) {
            thrust.y = -26 * speed;
        } else if (keys[SDL_SCANCODE_DOWN]) {
            thrust.y = 26 * speed;
        }

        if (keys[SDL_SCANCODE_KP_PLUS] || keys[SDL_SCANCODE_EQUALS]) {
            thrust.z = -24 * speed;
        } else if (keys[SDL_SCANCODE_KP_MINUS] || keys[SDL_SCANCODE_MINUS]) {
            thrust.z = 24 * speed;
        }

        if (thrust.x || thrust.y || thrust.z) {
            _camera.setThrust(thrust);
        }
    }

    public void setShadingLevel(const ubyte shadingLevel) {
        _map.setShadingLevel(shadingLevel);
    }

    @property public void ambientColor(float[4] color) {
        _ambientColor = color;
    }

    @property public Camera camera() {
        return _camera;
    }

    @property public AudioBank audioBank() {
        return _audioBank;
    }
}