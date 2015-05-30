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

module game.map.maprenderer;

import std.stdio;
import std.math;
import std.algorithm;

import derelict.opengl3.gl3;

import game.style.style;

import game.map.block;
import game.map.blockgeometries;
import game.map.map;
import game.map.geometry;

import render.program;
import render.shader;
import render.uniformbuffer;
import render.texturearray;

import util.console;
import util.matrix4;
import util.rectangle;


// Shader program data.
private align(1) struct ShaderData {

    // View-Projection matrix.
    Matrix4 vp;

    // Ambient color.
    float[4] ambientColor = [1.0, 1.0, 1.0, 1.0];

    // Texture indices that remap to other indices, for animation.
    GLuint[MAX_BLOCKTEXTURE_INDICES * 4] remap;

}


public final class MapRenderer {

    private Map _map;
    private Style _style;
    private BlockGeometries _blocks;

    private Geometry[][] _geometry;
    
    private MapCoord _sectorSize;
    private Rectangle _drawArea;

    private Program _program;
    private GLint _uboBlockIndex;
    private GLint _uSamplerBlockTextures;

    private Program _programDiscard;
    private GLint _uboBlockIndexDiscard;
    private GLint _uSamplerDiscardBlockTextures;

    private ShaderData _shaderData;
    private UniformBuffer!ShaderData _ubo;

    private TextureArray _blockTextures;

    private CVar _cvarBorder;
    private CVar _cvarSectorSize;

    private static immutable GLint UBO_BIND_POINT = 0;


    this(Map map, Style style, BlockGeometries blocks) {
        _cvarSectorSize = CVars.get("m_sectorsize");
        _cvarBorder = CVars.get("m_border");

        _map = map;
        _style = style;
        _blocks = blocks;
        _sectorSize = cast(MapCoord)_cvarSectorSize.intVal();

        // Programs for opaque and transparent rendering.
        _program = new Program(
            new Shader("data/shaders/block_vertex.glsl", ShaderType.VERTEX),
            new Shader("data/shaders/block_opaque_fragment.glsl", ShaderType.FRAGMENT)
        );
        _programDiscard = new Program(
            new Shader("data/shaders/block_vertex.glsl", ShaderType.VERTEX),
            new Shader("data/shaders/block_trans_fragment.glsl", ShaderType.FRAGMENT)
        );

        // Uniform Buffer Object for this grid's shader uniforms.
        _ubo = new UniformBuffer!ShaderData();

        // Opaque shader program settings.
        _program.use();
        _uboBlockIndex = _program.getUniformBlockIndex("ShaderData");
        _program.uniformBlockBinding(_uboBlockIndex, UBO_BIND_POINT);
        _uSamplerBlockTextures = _program.getUniformLocation("samplerBlockTextures");
        glUniform1i(_uSamplerBlockTextures, 0);

        // Transparent shader program settings.
        _programDiscard.use();
        _uboBlockIndexDiscard = _program.getUniformBlockIndex("ShaderData");
        _program.uniformBlockBinding(_uboBlockIndexDiscard, UBO_BIND_POINT);
        _uSamplerDiscardBlockTextures = _programDiscard.getUniformLocation("samplerBlockTextures");
        glUniform1i(_uSamplerDiscardBlockTextures, 0);

        generate();
    }

    private void generate() {
        const MapCoord width = cast(MapCoord)(_map.width / _sectorSize);
        const MapCoord height = cast(MapCoord)(_map.height / _sectorSize);

        _geometry = new Geometry[][](
            cast(uint)(width + _cvarBorder.intVal * 2),
            cast(uint)(height + _cvarBorder.intVal * 2)
        );

        const MapCoord minx = cast(MapCoord)-_cvarBorder.intVal;
        const MapCoord maxx = cast(MapCoord)(width + _cvarBorder.intVal);
        const MapCoord miny = cast(MapCoord)-_cvarBorder.intVal;
        const MapCoord maxy = cast(MapCoord)(height + _cvarBorder.intVal);

        for (MapCoord sy = miny; sy < maxy; sy++) {
            for (MapCoord sx = minx; sx < maxx; sx++) {
                Geometry geometry = new Geometry(_map, _style, _blocks);
                geometry.generate(
                    cast(MapCoord)(sx * _sectorSize),
                    cast(MapCoord)(sy * _sectorSize),
                    cast(MapCoord)(sx * _sectorSize + _sectorSize),
                    cast(MapCoord)(sy * _sectorSize + _sectorSize)
                );
                _geometry[cast(MapCoord)(sx + _cvarBorder.intVal)][cast(MapCoord)(sy + _cvarBorder.intVal)] = geometry;
            }
        }
    }

    public void prepareForDrawing(const Rectangle rect) {

        // Determine the sectors to draw.
        _drawArea.x1 = cast(int)floor((rect.x1 / cast(float)BLOCK_SIZE) / _sectorSize) + cast(uint)_cvarBorder.intVal;
        _drawArea.y1 = cast(int)floor((rect.y1 / cast(float)BLOCK_SIZE) / _sectorSize) + cast(uint)_cvarBorder.intVal;
        _drawArea.x2 = cast(int)ceil((rect.x2 / cast(float)BLOCK_SIZE) / _sectorSize) + cast(uint)_cvarBorder.intVal;
        _drawArea.y2 = cast(int)ceil((rect.y2 / cast(float)BLOCK_SIZE) / _sectorSize) + cast(uint)_cvarBorder.intVal;
        
        // Clamp sectors to draw.
        _drawArea.x1 = max(_drawArea.x1, 0);
        _drawArea.y1 = max(_drawArea.y1, 0);
        _drawArea.x2 = min(_drawArea.x2, _map.width / _sectorSize + cast(uint)_cvarBorder.intVal * 2);
        _drawArea.y2 = min(_drawArea.y2, _map.height / _sectorSize + cast(uint)_cvarBorder.intVal * 2);

        // Copy shader data to UBO.
        _ubo.update(_shaderData);
    }

    // Draws all opaque geometry for the current sector rectangle.
    public void drawOpaqueGeometry() {
        _program.use();
        _ubo.bindBase(_uboBlockIndex);
        glDisable(GL_BLEND);

        _blockTextures.bind();

        for (int y = _drawArea.y1; y < _drawArea.y2; y++) {
            for (int x = _drawArea.x1; x < _drawArea.x2; x++) {
                _geometry[x][y].setup();
                _geometry[x][y].drawOpaque();
            }
        }
    }

    // Draws all transparent geometry for the current sector rectangle.
    public void drawTransparentGeometry() {
        _programDiscard.use();
        _ubo.bindBase(_uboBlockIndexDiscard);
        glEnable(GL_BLEND);

        _blockTextures.bind();

        for (int y = _drawArea.y1; y < _drawArea.y2; y++) {

            for (int x = _drawArea.x1; x < _drawArea.x2; x++) {
                _geometry[x][y].setup();
                _geometry[x][y].drawTransparent();
            }
        }
    }

    public void setBlockTextures(TextureArray blockTextures) {
        _blockTextures = blockTextures;
    }

    public void setTextureRemaps(const GLuint[] remaps) {
        _shaderData.remap = remaps;
    }

    public void setMatrix(const Matrix4 matrix) {
        _shaderData.vp = matrix;
    }

    public void setAmbientColor(const float[4] color) {
        _shaderData.ambientColor = color;
    }
    
}