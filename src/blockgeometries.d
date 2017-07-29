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

module game.map.blockgeometries;

import std.stdio;
import std.json;
import std.file;
import std.string;
import std.math;

import derelict.opengl;

import game.map.block;

import util.vector3;
import util.log;


private immutable size_t MAX_BLOCK_SHAPES = 68;


public enum BlockGeometryFlags : ubyte {
    NONE = 0,
    NODOUBLESIDE = 0x1,
    ISVALID = 0x2,
}


public align(1) struct FaceVertex {
    GLfloat x;
    GLfloat y;
    GLfloat z;
    
    GLfloat u;
    GLfloat v;

    GLfloat texture;
    GLfloat brightness;
}


public struct FaceGeometry {

    FaceVertex[] vertices;
    GLushort[] indices;


    this(this) {
        vertices = vertices.dup;
        indices = indices.dup;
    }

    public void transform(const Vector3 transform) {
        foreach (ref FaceVertex v; vertices) {
            v.x += transform.x;
            v.y += transform.y;
            v.z += transform.z;
        }
    }

    public void flipTextureHorizontal() {
        foreach (ref FaceVertex v; vertices) {
            v.u = 1.0 - v.u;
        }
    }

    public void flipTextureVertical() {
        foreach (ref FaceVertex v; vertices) {
            v.v = 1.0 - v.v;
        }
    }

    public void rotateTexture(const float rotation) {
        const float theta = rotation * (PI / 180.0);
        const float s = sin(theta);
        const float c = cos(theta);

        foreach (ref FaceVertex vert; vertices) {
            const float u = vert.u;
            const float v = vert.v;
            vert.u = (u - 0.5) * c - (v - 0.5) * s + 0.5;
            vert.v = (u - 0.5) * s + (v - 0.5) * c + 0.5;
        }
    }

    public void rotateGeometry(const float rotation) {
        const float theta = rotation * (PI / 180.0);
        const float s = sin(theta);
        const float c = cos(theta);

        foreach (ref FaceVertex vert; vertices) {
            const float x = vert.x;
            const float y = vert.y;
            vert.x = (x - 0.5) * c - (y - 0.5) * s + 0.5;
            vert.y = (x - 0.5) * s + (y - 0.5) * c + 0.5;
        }
    }
}


public struct BlockGeometry {

    FaceGeometry[5] faces;
    BlockGeometryFlags flags;
    float width;
    float height;


    public void calculateSize() {
        float minX = float.max_exp;
        float minY = float.max_exp;
        float maxX = float.min_exp;
        float maxY = float.min_exp;

        foreach (ref FaceGeometry face; faces) {
            foreach (ref FaceVertex vert; face.vertices) {
                if (vert.x < minX) {
                    minX = vert.x;
                } else if (vert.x > maxX) {
                    maxX = vert.x;
                }
                if (vert.y < minY) {
                    minY = vert.y;
                } else if (vert.y > maxY) {
                    maxY = vert.y;
                }
            }
        }

        width = maxX - minX;
        height = maxY - minY;
    }

    public void cornerLower(const JSONValue[] params) {
        const uint cornerIndex = cast(uint)params[0].integer;
        const float amount = params[1].floating;

        float vx;
        float vy;

        // Determine vertex coordinate of the corner to transform.
        switch (cornerIndex) {
            case 0:
                vx = 1.0;
                vy = 1.0;
                break;
            case 1:
                vx = 0.0;
                vy = 1.0;
                break;
            case 2:
                vx = 0.0;
                vy = 0.0;
                break;
            case 3:
                vx = 1.0;
                vy = 0.0;
                break;
            default:
                throw new Exception(format("Invalid corner index %d.", cornerIndex));
        }

        // Transform all vertices whose coordinates match that of the corner.
        foreach (FaceIndex faceIndex, ref FaceGeometry face; faces) {
            foreach (ref FaceVertex vertex; face.vertices) {
                if (vertex.x == vx && vertex.y == vy && vertex.z == 1.0) {
                    vertex.z += amount;
                    if (faceIndex != FaceIndex.LID) {
                        vertex.v += -amount;
                    }
                }
            }
        }
    }

    public void transform(const JSONValue[] params) {
        const float x = params[0].floating;
        const float y = params[1].floating;

        // Move vertices.
        foreach (FaceIndex faceIndex, ref FaceGeometry face; faces) {
            foreach (ref FaceVertex vertex; face.vertices) {
                vertex.x += x;
                vertex.y += y;
            }
        }

        // Move lid texture offset.
        foreach (ref FaceVertex vertex; faces[FaceIndex.LID].vertices) {
            vertex.u += x;
            vertex.v += y;
        }
        
        // Move side face texture offsets. This might not always be waht you want.
        foreach (ref FaceVertex vertex; faces[FaceIndex.BOTTOM].vertices) {
            vertex.u += x;
        }
        foreach (ref FaceVertex vertex; faces[FaceIndex.TOP].vertices) {
            vertex.u -= x;
        }
        foreach (ref FaceVertex vertex; faces[FaceIndex.LEFT].vertices) {
            vertex.u += x;
        }
        foreach (ref FaceVertex vertex; faces[FaceIndex.RIGHT].vertices) {
            vertex.u -= x;
        }
    }

    public void rotate(const int angle) {

        // Rotate face geometry.
        foreach (ref FaceGeometry face; faces) {
            face.rotateGeometry(angle);
        }
        
        // Rotate faces themselves.
        for (int rotation = 0; rotation < angle / 90; rotation++) {
            FaceGeometry top = faces[FaceIndex.TOP];
            FaceGeometry left = faces[FaceIndex.LEFT];
            FaceGeometry bottom = faces[FaceIndex.BOTTOM];
            FaceGeometry right = faces[FaceIndex.RIGHT];

            faces[FaceIndex.RIGHT] = top;
            faces[FaceIndex.BOTTOM] = right;
            faces[FaceIndex.LEFT] = bottom;
            faces[FaceIndex.TOP] = left;
        }

        // Rotate face texture;
        faces[FaceIndex.LID].rotateTexture(angle);
    }

    public void transformGeometry(const JSONValue[] transforms) {
        foreach (JSONValue data; transforms) {
            JSONValue[] cmd = data.array;

            switch (cmd[0].str) {
                case "corner offset":
                    cornerLower(cmd[1..$]);
                    break;
                case "rotate":
                    rotate(cast(int)cmd[1].integer);
                    break;
                case "transform":
                    transform(cmd[1..$]);
                    break;
                default:
                    throw new Exception(format("Unknown block geometry transform command '%s'.", cmd[0].str));
            }
        }
    }
    
    public void parseFaces(const JSONValue val) {
        if ("top" in val) {
            faces[FaceIndex.TOP] = parseFace(val["top"]);
        }
        if ("bottom" in val) {
            faces[FaceIndex.BOTTOM] = parseFace(val["bottom"]);
        }
        if ("left" in val) {
            faces[FaceIndex.LEFT] = parseFace(val["left"]);
        }
        if ("right" in val) {
            faces[FaceIndex.RIGHT] = parseFace(val["right"]);
        }
        if ("lid" in val) {
            faces[FaceIndex.LID] = parseFace(val["lid"]);
        }
    }

    private FaceGeometry parseFace(JSONValue val) {
        FaceGeometry face;
        
        JSONValue[] vertices = val.object["vertex"].array;
        for (int index = 0; index < vertices.length; index += 5) {
            face.vertices ~= FaceVertex(
                vertices[index + 0].floating,
                vertices[index + 1].floating,
                vertices[index + 2].floating,
                vertices[index + 3].floating,
                vertices[index + 4].floating
            );
        }

        JSONValue[] indices = val.object["index"].array;
        for (int index = 0; index < indices.length; index++) {
            face.indices ~= cast(GLushort)indices[index].integer;
        }

        return face;
    }
}


public final class BlockGeometries {

    private uint[string] _blockGeometryIndices;
    private BlockGeometry[MAX_BLOCK_SHAPES] _blockGeometry;


    this(const string fileName) {
        Log.write(Color.NORMAL, "Reading block geometry from %s...", fileName);

        const JSONValue json = parseJSON(readText(fileName));

        foreach (string name; json.object.keys) {
            parseBlock(name, json.object);
        }
    }

    private void parseBlock(const string name, const JSONValue[string] obj) {
        if (name in _blockGeometryIndices) {
            return;
        }

        const JSONValue val = obj[name];

        // Parse base geometry definition.
        if ("base" in val && val["base"].str !in _blockGeometryIndices) {
            const string baseName = val["base"].str;
            parseBlock(baseName, obj);
        }

        BlockGeometry geometry;

        const uint index = cast(uint)val["index"].integer;
        if (index >= MAX_BLOCK_SHAPES) {
            throw new Exception(format("Block geometry shape %d is out of bounds. The maximum amount block shapes is %d.", index, MAX_BLOCK_SHAPES));
        }

        if ("base" in val) {
            geometry = getByName(val["base"].str);
        }
        if ("faces" in val) {
            geometry.parseFaces(val["faces"]);
        }
        if ("transforms" in val) {
            geometry.transformGeometry(val["transforms"].array);
        }
        if ("noDoubleSide" in val && val["noDoubleSide"].type == JSON_TYPE.TRUE) {
            geometry.flags |= BlockGeometryFlags.NODOUBLESIDE;
        }

        geometry.flags |= BlockGeometryFlags.ISVALID;
        geometry.calculateSize();

        _blockGeometryIndices[name] = index;
        _blockGeometry[index] = geometry;
    }

    private BlockGeometry getByName(const string name) {
        return _blockGeometry[_blockGeometryIndices[name]];
    }

    public FaceGeometry getFace(const BlockShape shape, const FaceIndex face) {
        if (_blockGeometry[shape].flags & BlockGeometryFlags.ISVALID) {
            return _blockGeometry[shape].faces[face];
        } else {
            return _blockGeometry[BlockShape.CUBE].faces[face];
        }
    }

    public BlockGeometry* getBlock(const BlockShape shape) {
        return &_blockGeometry[shape];
    }
}