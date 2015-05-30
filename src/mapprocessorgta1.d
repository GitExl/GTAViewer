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

module game.map.mapprocessorgta1;

import game.map.map;
import game.map.mapprocessor;
import game.map.block;

import game.style.style;


public final class MapProcessorGTA1 : MapProcessor {

    this(Map map) {
        super(map);
    }

    override public void process(Style style) {
        remapBlockTextures(style);
    }

    private void remapBlockTextures(Style style) {
        Block[][][] blocks = _map.getBlocks();

        const uint normalTextureCount = style.getBlockTextures().length / 4;
        for (MapCoord y = 0; y < _map.height; y++) {
            for (MapCoord x = 0; x < _map.width; x++) {
                foreach (ref Block block; blocks[x][y]) {
                    // Lid texture offset and remap;
                    if (block.faces[FaceIndex.LID].texture) {
                        block.faces[FaceIndex.LID].texture += style.sideTextureCount;
                        block.faces[FaceIndex.LID].texture += block.lidTextureRemap * normalTextureCount;
                    }

                    // Shadowing.
                    if (block.faces[FaceIndex.BOTTOM].texture) {
                        block.faces[FaceIndex.BOTTOM].texture += normalTextureCount * 1;
                    }
                    if (block.faces[FaceIndex.LEFT].texture) {
                        block.faces[FaceIndex.LEFT].texture += normalTextureCount * 2;
                    }
                    if (block.faces[FaceIndex.RIGHT].texture) {
                        block.faces[FaceIndex.RIGHT].texture += normalTextureCount * 3;
                    }                    
                }
            }
        }
    }

}