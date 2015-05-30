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

module util.packnode;

import util.rectangle;


// Binary partition based bin packing for arbitrarily sized nodes.
public struct PackNode {
    Rectangle rectangle;
    PackNode* right;
    PackNode* bottom;


    // Creates a new node from absolute coordinates.
    this(const Rectangle size) {
        rectangle = size;
    }

    // Creates a new node from a width and height. X and Y are assumed to be 0.
    this(const int width, const int height) {
        rectangle = Rectangle(0, 0, width, height);
    }

    // Attempts to find space for a new node. Returns the new node if a spot was found, or none if there is no room.
    public PackNode* insert(const int width, const int height) {
        
        // If this node is not a leaf, try to find room in one of it's children.
        if (right || bottom) {
            PackNode* node = right.insert(width, height);
            if (node) {
                return node;
            }
            return bottom.insert(width, height);
        }

        // If this node is a leaf and there is room, create child partitions and return this node's rectangle.
        if (width <= rectangle.width && height <= rectangle.height) {
            right = new PackNode(
                Rectangle(
                    rectangle.x1 + width, rectangle.y1,
                    rectangle.x2, rectangle.y1 + height
                )
            );
            bottom = new PackNode(
                Rectangle(
                    rectangle.x1, rectangle.y1 + height,
                    rectangle.x2, rectangle.y2
                )
            );

            return new PackNode(
                Rectangle(
                    rectangle.x1, rectangle.y1,
                    rectangle.x1 + width, rectangle.y1 + height
                )
            );
        }

        return null;
    }
}