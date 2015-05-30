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

module game.map.mapprocessorgta2;

import std.stdio;

import game.map.map;
import game.map.mapprocessor;
import game.map.block;

import game.style.style;

import game.entities.entity;


public final class MapProcessorGTA2 : MapProcessor {

    this(Map map) {
        super(map);
    }

    override public void process(Style style) {
        processBlocks(style);
        settleMapEntities();
    }

    private void settleMapEntities() {
        MapEntity[] entities = _map.getMapEntities();

        foreach (ref MapEntity entity; entities) {
            entity.z = _map.getSpawnZ(cast(MapCoord)entity.x, cast(MapCoord)entity.y);
        }
    }

    private void processBlocks(Style style) {
        Block[][][] blocks = _map.getBlocks();
        float[] shades = _map.shades;

        for (MapCoord y = 0; y < _map.height; y++) {
            for (MapCoord x = 0; x < _map.width; x++) {
                foreach (ref Block block; blocks[x][y]) {

                    // Side face shadowing.
                    block.faces[FaceIndex.LEFT].brightness = shades[1];
                    block.faces[FaceIndex.BOTTOM].brightness = shades[3];
                    block.faces[FaceIndex.TOP].brightness = shades[5];
                    block.faces[FaceIndex.RIGHT].brightness = shades[7];

                    const BlockFaceFlags flags = block.faces[FaceIndex.LID].flags;
                    if ((flags & BlockFaceFlags.SHADE0) && (flags & BlockFaceFlags.SHADE1)) {
                        block.faces[FaceIndex.LID].brightness = shades[3];
                    } else if (flags & BlockFaceFlags.SHADE1) {
                        block.faces[FaceIndex.LID].brightness = shades[2];
                    } else if (flags & BlockFaceFlags.SHADE0) {
                        block.faces[FaceIndex.LID].brightness = shades[1];
                    } else {
                        block.faces[FaceIndex.LID].brightness = shades[0];
                    }
                    
                    // Slope shadowing. Map brightness overwrites this.
                    if (block.faces[FaceIndex.LID].brightness == 1.0) {
                        
                        // Up
                        if (block.shape >= 9 && block.shape <= 16 ||
                            block.shape >= 1 && block.shape <= 2 ||
                            block.shape == 41) {
                            block.faces[FaceIndex.LID].brightness = shades[2];
                    
                        // Down
                        } else if (block.shape >= 17 && block.shape <= 24 ||
                            block.shape >= 3 && block.shape <= 4 ||
                            block.shape == 42) {
                            block.faces[FaceIndex.LID].brightness = shades[4];
                        
                        // Left
                        } else if (block.shape >= 25 && block.shape <= 32 ||
                            block.shape >= 5 && block.shape <= 6 ||
                            block.shape == 43) {
                            block.faces[FaceIndex.LID].brightness = shades[6];
                        
                        // Right
                        } else if (block.shape >= 33 && block.shape <= 40 ||
                            block.shape >= 7 && block.shape <= 8 ||
                            block.shape == 44) {
                            block.faces[FaceIndex.LID].brightness = shades[1];
                        
                        // Top left diagonal
                        } else if (block.shape == 45) {
                            block.faces[FaceIndex.LEFT].brightness = shades[3];

                        // Top right diagonal
                        } else if (block.shape == 46) {
                            block.faces[FaceIndex.RIGHT].brightness = shades[6];

                        // Bottom left diagonal
                        } else if (block.shape == 47) {
                            block.faces[FaceIndex.LEFT].brightness = shades[2];

                        // Bottom right diagonal
                        } else if (block.shape == 48) {
                            block.faces[FaceIndex.RIGHT].brightness = shades[5];

                        // Top left 3\4 sided
                        } else if (block.shape == 49 || block.shape == 64) {
                            block.faces[FaceIndex.LEFT].brightness = shades[2];

                        // Top right 3\4 sided
                        } else if (block.shape == 50 || block.shape == 65) {
                            block.faces[FaceIndex.RIGHT].brightness = shades[5];

                        // Bottom left 3\4 sided
                        } else if (block.shape == 51 || block.shape == 66) {
                            block.faces[FaceIndex.RIGHT].brightness = shades[1];

                        // Bottom right 3\4 sided
                        } else if (block.shape == 52 || block.shape == 67) {
                            block.faces[FaceIndex.LEFT].brightness = shades[4];
                        
                        }
                    }
                }
            }
        }
    }

}