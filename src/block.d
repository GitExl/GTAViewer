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

module game.map.block;

import game.map.map;

import game.style.style;


public immutable MapCoord BLOCK_SIZE = 64;


public enum FaceIndex : ubyte {
    LEFT,
    RIGHT,
    TOP,
    BOTTOM,
    LID
}

public enum BlockDirection : ushort {
    NONE = 0x0,
    NORMAL_UP = 0x1,
    NORMAL_DOWN = 0x2,
    NORMAL_LEFT = 0x4,
    NORMAL_RIGHT = 0x8,
    SPECIAL_UP = 0x100,
    SPECIAL_DOWN = 0x200,
    SPECIAL_LEFT = 0x400,
    SPECIAL_RIGHT = 0x800
}

public enum BlockType : ubyte {
    AIR = 0,
    WATER = 1,
    ROAD = 2,
    PAVEMENT = 3,
    FIELD = 4,
    BUILDING = 5
}

public enum BlockFlags : ubyte {
    NONE = 0,
    RAILWAY = 1,
    TRAFFIC_LIGHT_1 = 2,
    TRAFFIC_LIGHT_2 = 4,
    TRAFFIC_LIGHT_3 = 8,
    TRAFFIC_LIGHT_4 = 16
}

public enum BlockShape : ubyte {
    CUBE = 0,
    
    SLOPE_UP26_LOW = 1,
    SLOPE_UP26_HIGH = 2,
    SLOPE_DOWN26_LOW = 3,
    SLOPE_DOWN26_HIGH = 4,
    SLOPE_LEFT26_LOW = 5,
    SLOPE_LEFT26_HIGH = 6,
    SLOPE_RIGHT26_LOW = 7,
    SLOPE_RIGHT26_HIGH = 8,

    SLOPE_UP7_1 = 9,
    SLOPE_UP7_2 = 10,
    SLOPE_UP7_3 = 11,
    SLOPE_UP7_4 = 12,
    SLOPE_UP7_5 = 13,
    SLOPE_UP7_6 = 14,
    SLOPE_UP7_7 = 15,
    SLOPE_UP7_8 = 16,

    SLOPE_DOWN7_1 = 17,
    SLOPE_DOWN7_2 = 18,
    SLOPE_DOWN7_3 = 19,
    SLOPE_DOWN7_4 = 20,
    SLOPE_DOWN7_5 = 21,
    SLOPE_DOWN7_6 = 22,
    SLOPE_DOWN7_7 = 23,
    SLOPE_DOWN7_8 = 24,

    SLOPE_LEFT7_1 = 25,
    SLOPE_LEFT7_2 = 26,
    SLOPE_LEFT7_3 = 27,
    SLOPE_LEFT7_4 = 28,
    SLOPE_LEFT7_5 = 29,
    SLOPE_LEFT7_6 = 30,
    SLOPE_LEFT7_7 = 31,
    SLOPE_LEFT7_8 = 32,

    SLOPE_RIGHT7_1 = 33,
    SLOPE_RIGHT7_2 = 34,
    SLOPE_RIGHT7_3 = 35,
    SLOPE_RIGHT7_4 = 36,
    SLOPE_RIGHT7_5 = 37,
    SLOPE_RIGHT7_6 = 38,
    SLOPE_RIGHT7_7 = 39,
    SLOPE_RIGHT7_8 = 40,

    SLOPE_UP45 = 41,
    SLOPE_DOWN45 = 42,
    SLOPE_LEFT45 = 43,
    SLOPE_RIGHT45 = 44,

    DIAG_UPLEFT = 45,
    DIAG_UPRIGHT = 46,
    DIAG_DOWNLEFT = 47,
    DIAG_DOWNRIGHT = 48,

    DIAG_SLOPE4_TOPLEFT = 49,
    DIAG_SLOPE4_TOPRIGHT = 50,
    DIAG_SLOPE4_BOTTOMLEFT = 51,
    DIAG_SLOPE4_BOTTOMRIGHT = 52,

    PART_LEFT = 53,
    PART_RIGHT = 54,
    PART_TOP = 55,
    PART_BOTTOM = 56,

    PART_TOPLEFT = 57,
    PART_TOPRIGHT = 58,
    PART_BOTTOMRIGHT = 59,
    PART_BOTTOMLEFT = 60,

    PART_CENTRE = 61,

    UNUSED = 62,

    SLOPE_ABOVE = 63,

    DIAG_SLOPE3_TOPLEFT = 64,
    DIAG_SLOPE3_TOPRIGHT = 65,
    DIAG_SLOPE3_BOTTOMLEFT = 66,
    DIAG_SLOPE3_BOTTOMRIGHT = 67
}


public enum BlockFaceFlags : ubyte {
    NONE = 0x0,
    WALL = 0x1,
    BULLET_WALL = 0x2,
    FLAT = 0x4,
    FLIP = 0x8,
    DOUBLESIDED = 0x10,
    SHADE0 = 0x20,
    SHADE1 = 0x40,
}

public struct BlockFace {
    BlockTextureIndex texture;
    BlockFaceFlags flags;
    float brightness = 1.0;
    float rotation = 0.0;
}

public struct Block {
    BlockDirection directions;
    BlockType type;
    BlockFlags flags;
    BlockShape shape;
    ubyte lidTextureRemap;

    BlockFace[5] faces;
}
