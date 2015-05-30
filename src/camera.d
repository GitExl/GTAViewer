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

module render.camera;

import std.stdio;
import std.algorithm;
import std.math;

import util.vector3;
import util.matrix4;
import util.rectangle;


public final class Camera {
    private Vector3 _position;
    private Vector3 _positionLast;
    private Vector3 _positionLerp;

    private Vector3 _velocity;
    
    private float _fov;
    private float _width;
    private float _height;
    private float _aspectRatio;
    
    private float _nearPlane;
    private float _farPlane;

    private Matrix4 _projection;
    private Matrix4 _view;
    private Matrix4 _projectionView;


    private static immutable Vector3 UP = Vector3(0, 1, 0);

    private static immutable float FOV_MIN = 10.0;
    private static immutable float FOV_MAX = 179.0;


    this(const float width, const float height, const float fov, const float nearPlane, const float farPlane) {
        _width = width;
        _height = height;
        _aspectRatio = _width / _height;
        
        _fov = min(max(fov, FOV_MIN), FOV_MAX);
        _nearPlane = nearPlane;
        _farPlane = farPlane;

        setProjection();
    }

    private void setProjection() {
        _projection = matrix4Perspective(_fov, _aspectRatio, _nearPlane, _farPlane);
    }

    public void update(const double delta) {
        _velocity = _velocity * 0.8;
        _position += _velocity;
    }

    public void setThrust(const Vector3 thrust) {
        _velocity = thrust;
    }

    public void setVelocity(const Vector3 velocity) {
        _velocity = velocity;
    }

    public void move(const Vector3 amount) {
        _position += amount;
    }

    public void set(const Vector3 position) {
        _position = position;
    }

    public void interpolateStart() {
        _positionLast = _position;
    }

    public void interpolateEnd(const double t) {
        _positionLerp = _positionLast + (_position - _positionLast) * t;

        Vector3 lookAt = _positionLerp;
        lookAt.z = 0;
        _view = matrix4LookAt(_positionLerp, lookAt, UP);
        _projectionView = matrix4Multiply(_projection, _view);
    }

    public Rectangle unproject() {
        const float Hfar = tan(_fov * (PI / 180.0) / 2.0) * _position.z;
	    const float Wfar = Hfar * _aspectRatio;

        return Rectangle(
            cast(int)(_position.x - Wfar),
            cast(int)(_position.y - Hfar),
            cast(int)(_position.x + Wfar),
            cast(int)(_position.y + Hfar)
        );
    }

    @property public void fov(const float fov) {
        _fov = min(max(fov, FOV_MIN), FOV_MAX);
        setProjection();
    }

    @property public Matrix4 projectionViewMatrix() {
        return _projectionView;
    }

    @property public Vector3 position() {
        return _position;
    }

    @property public Vector3 velocity() {
        return _velocity;
    }

    @property public float width() {
        return _width;
    }

    @property public float height() {
        return _height;
    }
}