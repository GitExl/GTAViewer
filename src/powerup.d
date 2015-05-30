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

module game.entities.powerup;

import game.entities.entity;

import game.style.style;


public final class EntityPowerup : Entity {

    private uint _value;
    private double _animTime = 0.0;


    this(EntityType type, const uint value) {
        super();

        this.initializeFromType(type);

        _value = value;
        // TODO: Value == 0 means use a default value.
        // >= 100 for weapons means its a kill frenzy. Number indicates amount of frames the kill frenzy lasts, 25 FPS. 100 = infinite kill frenzy.
        // 1 - 32 for info shields are fxt text references for help
    }

    override public void update(const double delta) {
        super.update(delta);

        if (_spriteTexture !is null && _spriteTexture.subTextures.length) {
            _animTime += delta;
            if (_animTime >= 0.12) {
                _frame += 1;
                if (_frame >= _spriteTexture.subTextures.length) {
                    _frame = 0;
                }
                _animTime = 0;
            }
        }
    }
}
