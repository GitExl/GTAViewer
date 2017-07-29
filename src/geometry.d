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

module game.map.geometry;

import std.stdio;
import std.string;
import std.algorithm;

import derelict.opengl;

import game.style.style;

import game.map.map;
import game.map.block;
import game.map.blockgeometries;

import render.vertexbuffer;
import render.enums;

import util.vector3;


public final class Geometry {

    private Map _map;
    private Style _style;
    private BlockGeometries _blockGeometry;

    private VertexBuffer!FaceVertex _vertexBuffer;

    private static immutable FaceIndex[] FACE_OPPOSITE = [
        FaceIndex.RIGHT,
        FaceIndex.LEFT,
        FaceIndex.BOTTOM,
        FaceIndex.TOP
    ];

    private static immutable Vector3[] FACE_TRANSFORM_OPPOSITE = [
        Vector3(-1.0, 0, 0),
        Vector3(1.0 - 0.006, 0, 0),
        Vector3(0, -1.0, 0),
        Vector3(0, 1.0 - 0.006, 0)
    ];
    

    this(Map map, Style style, BlockGeometries blockGeometry) {
        _map = map;
        _style = style;
        _blockGeometry = blockGeometry;
        
        _vertexBuffer = new VertexBuffer!FaceVertex(PrimitiveType.TRIANGLES, 2, BufferUsage.STATIC_DRAW, true);
    }

    public void generate(const MapCoord x1, const MapCoord y1, const MapCoord x2, const MapCoord y2) {
        Block[][][] blocks = _map.getBlocks();
        MapCoord ox, oy, oz;

        oz = 0;
        for (MapCoord cz = 0; cz < _map.depth; cz++) {

            oy = cast(MapCoord)(y1 * BLOCK_SIZE);
            for (MapCoord cy = y1; cy < y2; cy++) {
                const MapCoord by = cast(MapCoord)max(min(cy, _map.height - 1), 0);

                ox = cast(MapCoord)(x1 * BLOCK_SIZE);
                for (MapCoord cx = x1; cx < x2; cx++) {
                    const MapCoord bx = cast(MapCoord)max(min(cx, _map.width - 1), 0);

                    const Block block = blocks[bx][by][cz];
                    addFaceGeometry(ox, oy, oz, block, FaceIndex.TOP);
                    addFaceGeometry(ox, oy, oz, block, FaceIndex.LEFT);
                    addFaceGeometry(ox, oy, oz, block, FaceIndex.BOTTOM);
                    addFaceGeometry(ox, oy, oz, block, FaceIndex.RIGHT);
                    addFaceGeometry(ox, oy, oz, block, FaceIndex.LID);

                    ox += BLOCK_SIZE;
                }

                oy += BLOCK_SIZE;
            }

            oz += BLOCK_SIZE;  
        }

        _vertexBuffer.generate();
        _vertexBuffer.clear();
    }

    private void addFaceGeometry(const MapCoord ox, const MapCoord oy, const MapCoord oz, const Block block, const FaceIndex faceIndex) {
        const BlockFace face = block.faces[faceIndex];        

        // If this face is opaque and opposite of a double sided one, do not output it at all.
        if (faceIndex != FaceIndex.LID && !(face.flags & BlockFaceFlags.DOUBLESIDED)) {
            if (block.faces[FACE_OPPOSITE[faceIndex]].flags & BlockFaceFlags.DOUBLESIDED) {
                return;
            }
        }

        const uint subBuffer = (face.flags & BlockFaceFlags.FLAT) || (face.flags & BlockFaceFlags.DOUBLESIDED) ? 1 : 0;

        // Double sided faces are transparent and use the opposite face as it's other side.
        const BlockGeometry* shape = _blockGeometry.getBlock(block.shape);
        if (!(shape.flags & BlockGeometryFlags.NODOUBLESIDE) &&
            face.flags & BlockFaceFlags.DOUBLESIDED &&
            faceIndex != FaceIndex.LID) {

            const FaceIndex doubleFaceIndex = FACE_OPPOSITE[faceIndex];
            BlockFace doubleFace = block.faces[doubleFaceIndex];
            
            if (doubleFace.texture) {
                FaceGeometry doubleFaceGeometry = getFace(ox, oy, oz, block, doubleFaceIndex);
                Vector3 transform = FACE_TRANSFORM_OPPOSITE[faceIndex];
                transform.x = transform.x * shape.width * BLOCK_SIZE;
                transform.y = transform.y * shape.height * BLOCK_SIZE;
                doubleFaceGeometry.transform(transform);
            
                // Flip texture.
                if (doubleFace.flags & BlockFaceFlags.FLIP) {
                    doubleFaceGeometry.flipTextureHorizontal();
                }

                // Rotate texture.
                if (doubleFace.rotation != 0.0) {
                    doubleFaceGeometry.rotateTexture(doubleFace.rotation);
                }

                _vertexBuffer.add(doubleFaceGeometry.vertices, doubleFaceGeometry.indices, subBuffer);
            }
        }

        if (face.texture) {
            FaceGeometry faceGeometry = getFace(ox, oy, oz, block, faceIndex);

            // Flat bottom and right faces are moved to the top and left.
            if (face.flags & BlockFaceFlags.FLAT) {
                if (faceIndex == FaceIndex.BOTTOM) {
                    faceGeometry.transform(Vector3(0, -cast(float)BLOCK_SIZE, 0));
                    faceGeometry.flipTextureHorizontal();
                } else if (faceIndex == FaceIndex.RIGHT) {
                    faceGeometry.transform(Vector3(-cast(float)BLOCK_SIZE, 0, 0));
                    faceGeometry.flipTextureHorizontal();
                }
            }

            // Flip texture.
            if (face.flags & BlockFaceFlags.FLIP) {
                faceGeometry.flipTextureHorizontal();
            }

            // Rotate texture.
            if (face.rotation != 0.0) {
                faceGeometry.rotateTexture(face.rotation);
            }

            // Add face to opaque or transparent vertex buffer.
            _vertexBuffer.add(faceGeometry.vertices, faceGeometry.indices, subBuffer);
        }
    }

    private FaceGeometry getFace(const int ox, const int oy, const int oz, const Block block, const FaceIndex faceIndex) {
        FaceGeometry geometry = _blockGeometry.getFace(block.shape, faceIndex);

        foreach (ref FaceVertex v; geometry.vertices) {
            v.x = ox + v.x * BLOCK_SIZE;
            v.y = oy + v.y * BLOCK_SIZE;
            v.z = oz + v.z * BLOCK_SIZE;
            v.texture = block.faces[faceIndex].texture;
            v.brightness = block.faces[faceIndex].brightness;
        }

        return geometry;
    }

    public void setup() {
        _vertexBuffer.bind();

        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, FaceVertex.sizeof, cast(void*)FaceVertex.x.offsetof);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, FaceVertex.sizeof, cast(void*)FaceVertex.u.offsetof);
        glVertexAttribPointer(2, 1, GL_FLOAT, GL_FALSE, FaceVertex.sizeof, cast(void*)FaceVertex.texture.offsetof);
        glVertexAttribPointer(3, 1, GL_FLOAT, GL_FALSE, FaceVertex.sizeof, cast(void*)FaceVertex.brightness.offsetof);

        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
        glEnableVertexAttribArray(2);
        glEnableVertexAttribArray(3);
    }

    public void drawOpaque() {
        _vertexBuffer.draw(0);
    }

    public void drawTransparent() {
        _vertexBuffer.draw(1);
    }
}
