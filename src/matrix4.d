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

module util.matrix4;

import std.stdio;
import std.math;

import util.vector3;


public alias float[16] Matrix4;


public Matrix4 matrix4Create() {
    Matrix4 dest;
    dest[] = 0.0;

    return dest;
}

public Matrix4 matrix4CreateFrom(const Matrix4 mat) {
    Matrix4 dest;
    dest[] = mat[];

    return dest;
}

public Matrix4 matrix4Set(const Matrix4 src) {
    Matrix4 dest;
    dest[] = src[];

    return dest;
}

public Matrix4 matrix4Identity() {
    return [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    ];
}

public Matrix4 matrix4Transpose(const Matrix4 src) {
    Matrix4 dest;

    dest[0] = src[0];
    dest[1] = src[4];
    dest[2] = src[8];
    dest[3] = src[12];
    dest[4] = src[1];
    dest[5] = src[5];
    dest[6] = src[9];
    dest[7] = src[13];
    dest[8] = src[2];
    dest[9] = src[6];
    dest[10] = src[10];
    dest[11] = src[14];
    dest[12] = src[3];
    dest[13] = src[7];
    dest[14] = src[11];
    dest[15] = src[15];

    return dest;
}

public Matrix4 matrix4Rotation(const Matrix4 src) {
    Matrix4 dest;

    dest[0] = src[0];
    dest[1] = src[1];
    dest[2] = src[2];
    dest[3] = src[3];
    dest[4] = src[4];
    dest[5] = src[5];
    dest[6] = src[6];
    dest[7] = src[7];
    dest[8] = src[8];
    dest[9] = src[9];
    dest[10] = src[10];
    dest[11] = src[11];
    dest[12] = 0;
    dest[13] = 0;
    dest[14] = 0;
    dest[15] = 1;

    return dest;
}

public Matrix4 matrix4Multiply(const Matrix4 mat, const Matrix4 mat2) {
    // Cache the matrix values.
    const float a00 = mat[0],  a01 = mat[1],  a02 = mat[2],  a03 = mat[3],
          a10 = mat[4],  a11 = mat[5],  a12 = mat[6],  a13 = mat[7],
          a20 = mat[8],  a21 = mat[9],  a22 = mat[10], a23 = mat[11],
          a30 = mat[12], a31 = mat[13], a32 = mat[14], a33 = mat[15],

          b00 = mat2[0],  b01 = mat2[1],  b02 = mat2[2],  b03 = mat2[3],
          b10 = mat2[4],  b11 = mat2[5],  b12 = mat2[6],  b13 = mat2[7],
          b20 = mat2[8],  b21 = mat2[9],  b22 = mat2[10], b23 = mat2[11],
          b30 = mat2[12], b31 = mat2[13], b32 = mat2[14], b33 = mat2[15];
    Matrix4 dest;

    dest[0] = b00 * a00 + b01 * a10 + b02 * a20 + b03 * a30;
    dest[1] = b00 * a01 + b01 * a11 + b02 * a21 + b03 * a31;
    dest[2] = b00 * a02 + b01 * a12 + b02 * a22 + b03 * a32;
    dest[3] = b00 * a03 + b01 * a13 + b02 * a23 + b03 * a33;
    dest[4] = b10 * a00 + b11 * a10 + b12 * a20 + b13 * a30;
    dest[5] = b10 * a01 + b11 * a11 + b12 * a21 + b13 * a31;
    dest[6] = b10 * a02 + b11 * a12 + b12 * a22 + b13 * a32;
    dest[7] = b10 * a03 + b11 * a13 + b12 * a23 + b13 * a33;
    dest[8] = b20 * a00 + b21 * a10 + b22 * a20 + b23 * a30;
    dest[9] = b20 * a01 + b21 * a11 + b22 * a21 + b23 * a31;
    dest[10] = b20 * a02 + b21 * a12 + b22 * a22 + b23 * a32;
    dest[11] = b20 * a03 + b21 * a13 + b22 * a23 + b23 * a33;
    dest[12] = b30 * a00 + b31 * a10 + b32 * a20 + b33 * a30;
    dest[13] = b30 * a01 + b31 * a11 + b32 * a21 + b33 * a31;
    dest[14] = b30 * a02 + b31 * a12 + b32 * a22 + b33 * a32;
    dest[15] = b30 * a03 + b31 * a13 + b32 * a23 + b33 * a33;

    return dest;
}

public Vector3 matrix4MultiplyVec3(const Matrix4 mat, const Vector3 vec) {
    Vector3 dest;

    dest.x = mat[0] * vec.x + mat[4] * vec.y + mat[8] * vec.z + mat[12];
    dest.y = mat[1] * vec.x + mat[5] * vec.y + mat[9] * vec.z + mat[13];
    dest.z = mat[2] * vec.x + mat[6] * vec.y + mat[10] * vec.z + mat[14];

    return dest;
}

public float[4] matrix4MultiplyVec4(const Matrix4 mat, const float[4] vec) {
    float[4] dest;

    dest[0] = mat[0] * vec[0] + mat[4] * vec[1] + mat[8] * vec[2] + mat[12] * vec[3];
    dest[1] = mat[1] * vec[0] + mat[5] * vec[1] + mat[9] * vec[2] + mat[13] * vec[3];
    dest[2] = mat[2] * vec[0] + mat[6] * vec[1] + mat[10] * vec[2] + mat[14] * vec[3];
    dest[3] = mat[3] * vec[0] + mat[7] * vec[1] + mat[11] * vec[2] + mat[15] * vec[3];

    return dest;
}

public Matrix4 matrix4Translate(const Matrix4 mat, const Vector3 vec) {
    Matrix4 dest;

    const float a00 = mat[0]; const float a01 = mat[1]; const float a02 = mat[2]; const float a03 = mat[3];
    const float a10 = mat[4]; const float a11 = mat[5]; const float a12 = mat[6]; const float a13 = mat[7];
    const float a20 = mat[8]; const float a21 = mat[9]; const float a22 = mat[10]; const float a23 = mat[11];

    dest[0] = a00; dest[1] = a01; dest[2] = a02; dest[3] = a03;
    dest[4] = a10; dest[5] = a11; dest[6] = a12; dest[7] = a13;
    dest[8] = a20; dest[9] = a21; dest[10] = a22; dest[11] = a23;

    dest[12] = a00 * vec.x + a10 * vec.y + a20 * vec.z + mat[12];
    dest[13] = a01 * vec.x + a11 * vec.y + a21 * vec.z + mat[13];
    dest[14] = a02 * vec.x + a12 * vec.y + a22 * vec.z + mat[14];
    dest[15] = a03 * vec.x + a13 * vec.y + a23 * vec.z + mat[15];

    return dest;
}

public Matrix4 matrix4Scale(const Matrix4 mat, const Vector3 vec) {
    Matrix4 dest;

    dest[0] = mat[0] * vec.x;
    dest[1] = mat[1] * vec.x;
    dest[2] = mat[2] * vec.x;
    dest[3] = mat[3] * vec.x;
    dest[4] = mat[4] * vec.y;
    dest[5] = mat[5] * vec.y;
    dest[6] = mat[6] * vec.y;
    dest[7] = mat[7] * vec.y;
    dest[8] = mat[8] * vec.z;
    dest[9] = mat[9] * vec.z;
    dest[10] = mat[10] * vec.z;
    dest[11] = mat[11] * vec.z;
    dest[12] = mat[12];
    dest[13] = mat[13];
    dest[14] = mat[14];
    dest[15] = mat[15];

    return dest;
}

public Matrix4 matrix4Frustum(const float left, const float right, const float bottom, const float top, const float near, const float far) {
    const float rl = right - left;
    const float tb = top - bottom;
    const float fn = far - near;

    Matrix4 dest;
    dest[0] = (near * 2) / rl;
    dest[1] = 0;
    dest[2] = 0;
    dest[3] = 0;
    dest[4] = 0;
    dest[5] = -((near * 2) / tb);
    dest[6] = 0;
    dest[7] = 0;
    dest[8] = (right + left) / rl;
    dest[9] = (top + bottom) / tb;
    dest[10] = -(far + near) / fn;
    dest[11] = -1;
    dest[12] = 0;
    dest[13] = 0;
    dest[14] = -(far * near * 2) / fn;
    dest[15] = 0;

    return dest;
}

public Matrix4 matrix4Perspective(const float fovy, const float aspect, const float near, const float far) {
    const float top = near * tan(fovy * PI / 360.0);
    const float right = top * aspect;

    return matrix4Frustum(-right, right, -top, top, near, far);
}

public Matrix4 matrix4Ortho(const float left, const float right, const float bottom, const float top, const float near, const float far) {
    const float rl = (right - left);
    const float tb = (top - bottom);
    const float fn = (far - near);
    Matrix4 dest;

    dest[0] = 2 / rl;
    dest[1] = 0;
    dest[2] = 0;
    dest[3] = 0;
    dest[4] = 0;
    dest[5] = 2 / tb;
    dest[6] = 0;
    dest[7] = 0;
    dest[8] = 0;
    dest[9] = 0;
    dest[10] = -2 / fn;
    dest[11] = 0;
    dest[12] = -(left + right) / rl;
    dest[13] = -(top + bottom) / tb;
    dest[14] = -(far + near) / fn;
    dest[15] = 1;

    return dest;
}

public Matrix4 matrix4Inverse(const Matrix4 src) {
    // Cache the matrix values (makes for huge speed increases!).
    const float a00 = src[0], a01 = src[1], a02 = src[2], a03 = src[3];
    const float a10 = src[4], a11 = src[5], a12 = src[6], a13 = src[7];
    const float a20 = src[8], a21 = src[9], a22 = src[10], a23 = src[11];
    const float a30 = src[12], a31 = src[13], a32 = src[14], a33 = src[15];
    const float b00 = a00 * a11 - a01 * a10;
    const float b01 = a00 * a12 - a02 * a10;
    const float b02 = a00 * a13 - a03 * a10;
    const float b03 = a01 * a12 - a02 * a11;
    const float b04 = a01 * a13 - a03 * a11;
    const float b05 = a02 * a13 - a03 * a12;
    const float b06 = a20 * a31 - a21 * a30;
    const float b07 = a20 * a32 - a22 * a30;
    const float b08 = a20 * a33 - a23 * a30;
    const float b09 = a21 * a32 - a22 * a31;
    const float b10 = a21 * a33 - a23 * a31;
    const float b11 = a22 * a33 - a23 * a32;
    
    // Calculate the determinant.
    const float d = (b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06);
    if (!d) {
        return matrix4Identity();
    }

    Matrix4 dest;
    const float invDet = 1 / d;
    dest[0] = (a11 * b11 - a12 * b10 + a13 * b09) * invDet;
    dest[1] = (-a01 * b11 + a02 * b10 - a03 * b09) * invDet;
    dest[2] = (a31 * b05 - a32 * b04 + a33 * b03) * invDet;
    dest[3] = (-a21 * b05 + a22 * b04 - a23 * b03) * invDet;
    dest[4] = (-a10 * b11 + a12 * b08 - a13 * b07) * invDet;
    dest[5] = (a00 * b11 - a02 * b08 + a03 * b07) * invDet;
    dest[6] = (-a30 * b05 + a32 * b02 - a33 * b01) * invDet;
    dest[7] = (a20 * b05 - a22 * b02 + a23 * b01) * invDet;
    dest[8] = (a10 * b10 - a11 * b08 + a13 * b06) * invDet;
    dest[9] = (-a00 * b10 + a01 * b08 - a03 * b06) * invDet;
    dest[10] = (a30 * b04 - a31 * b02 + a33 * b00) * invDet;
    dest[11] = (-a20 * b04 + a21 * b02 - a23 * b00) * invDet;
    dest[12] = (-a10 * b09 + a11 * b07 - a12 * b06) * invDet;
    dest[13] = (a00 * b09 - a01 * b07 + a02 * b06) * invDet;
    dest[14] = (-a30 * b03 + a31 * b01 - a32 * b00) * invDet;
    dest[15] = (a20 * b03 - a21 * b01 + a22 * b00) * invDet;

    return dest;
}

public Matrix4 matrix4LookAt(const Vector3 eye, const Vector3 center, const Vector3 up) {
    float x0, x1, x2, y0, y1, y2, z0, z1, z2, len;
    Matrix4 dest;

    z0 = eye.x - center.x;
    z1 = eye.y - center.y;
    z2 = eye.z - center.z;

    // Vector3.normalize(z);
    len = 1.0 / sqrt(z0 * z0 + z1 * z1 + z2 * z2);
    z0 *= len;
    z1 *= len;
    z2 *= len;

    // Vector3.normalize(Vector3.cross(up, z, x));
    x0 = up.y * z2 - up.z * z1;
    x1 = up.z * z0 - up.x * z2;
    x2 = up.x * z1 - up.y * z0;
    len = 1.0 / sqrt(x0 * x0 + x1 * x1 + x2 * x2);
    x0 *= len;
    x1 *= len;
    x2 *= len;

    // Vector3.normalize(Vector3.cross(z, x, y));
    y0 = z1 * x2 - z2 * x1;
    y1 = z2 * x0 - z0 * x2;
    y2 = z0 * x1 - z1 * x0;
    len = 1.0 / sqrt(y0 * y0 + y1 * y1 + y2 * y2);
    y0 *= len;
    y1 *= len;
    y2 *= len;

    dest[0] = x0;
    dest[1] = y0;
    dest[2] = z0;
    dest[3] = 0;
    dest[4] = x1;
    dest[5] = y1;
    dest[6] = z1;
    dest[7] = 0;
    dest[8] = x2;
    dest[9] = y2;
    dest[10] = z2;
    dest[11] = 0;
    dest[12] = -(x0 * eye.x + x1 * eye.y + x2 * eye.z);
    dest[13] = -(y0 * eye.x + y1 * eye.y + y2 * eye.z);
    dest[14] = -(z0 * eye.x + z1 * eye.y + z2 * eye.z);
    dest[15] = 1;

    return dest;
}

Matrix4 matrix4Rotate(const Matrix4 mat, const float angle, Vector3 axis) {
    float len = sqrt(axis.x * axis.x + axis.y * axis.y + axis.z * axis.z);

    if (len != 1) {
        len = 1 / len;
        axis.x *= len;
        axis.y *= len;
        axis.z *= len;
    }

    const float s = sin(angle);
    const float c = cos(angle);
    const float t = 1 - c;
    const float a00 = mat[0]; const float a01 = mat[1]; const float a02 = mat[2]; const float a03 = mat[3];
    const float a10 = mat[4]; const float a11 = mat[5]; const float a12 = mat[6]; const float a13 = mat[7];
    const float a20 = mat[8]; const float a21 = mat[9]; const float a22 = mat[10]; const float a23 = mat[11];
    
    // Construct the elements of the rotation matrix
    const float b00 = axis.x * axis.x * t + c; const float b01 = axis.y * axis.x * t + axis.z * s; const float b02 = axis.z * axis.x * t - axis.y * s;
    const float b10 = axis.x * axis.y * t - axis.z * s; const float b11 = axis.y * axis.y * t + c; const float b12 = axis.z * axis.y * t + axis.x * s;
    const float b20 = axis.x * axis.z * t + axis.y * s; const float b21 = axis.y * axis.z * t - axis.x * s; const float b22 = axis.z * axis.z * t + c;
    
    Matrix4 dest = mat;
    
    // Perform rotation-specific matrix multiplication
    dest[0] = a00 * b00 + a10 * b01 + a20 * b02;
    dest[1] = a01 * b00 + a11 * b01 + a21 * b02;
    dest[2] = a02 * b00 + a12 * b01 + a22 * b02;
    dest[3] = a03 * b00 + a13 * b01 + a23 * b02;
    dest[4] = a00 * b10 + a10 * b11 + a20 * b12;
    dest[5] = a01 * b10 + a11 * b11 + a21 * b12;
    dest[6] = a02 * b10 + a12 * b11 + a22 * b12;
    dest[7] = a03 * b10 + a13 * b11 + a23 * b12;
    dest[8] = a00 * b20 + a10 * b21 + a20 * b22;
    dest[9] = a01 * b20 + a11 * b21 + a21 * b22;
    dest[10] = a02 * b20 + a12 * b21 + a22 * b22;
    dest[11] = a03 * b20 + a13 * b21 + a23 * b22;

    return dest;
}

Matrix4 matrix4RotateX(const Matrix4 mat, const float angle) {
    const float s = sin(angle);
    const float c = cos(angle);

    const float a10 = mat[4];
    const float a11 = mat[5];
    const float a12 = mat[6];
    const float a13 = mat[7];
    const float a20 = mat[8];
    const float a21 = mat[9];
    const float a22 = mat[10];
    const float a23 = mat[11];

    Matrix4 dest = mat;
    
    // Perform axis-specific matrix multiplication
    dest[4] = a10 * c + a20 * s;
    dest[5] = a11 * c + a21 * s;
    dest[6] = a12 * c + a22 * s;
    dest[7] = a13 * c + a23 * s;
    dest[8] = a10 * -s + a20 * c;
    dest[9] = a11 * -s + a21 * c;
    dest[10] = a12 * -s + a22 * c;
    dest[11] = a13 * -s + a23 * c;

    return dest;
}

Matrix4 matrix4RotateY(const Matrix4 mat, const float angle) {
    const float s = sin(angle);
    const float c = cos(angle);

    const float a00 = mat[0];
    const float a01 = mat[1];
    const float a02 = mat[2];
    const float a03 = mat[3];
    const float a20 = mat[8];
    const float a21 = mat[9];
    const float a22 = mat[10];
    const float a23 = mat[11];

    Matrix4 dest = mat;
    
    // Perform axis-specific matrix multiplication
    dest[0] = a00 * c + a20 * -s;
    dest[1] = a01 * c + a21 * -s;
    dest[2] = a02 * c + a22 * -s;
    dest[3] = a03 * c + a23 * -s;
    dest[8] = a00 * s + a20 * c;
    dest[9] = a01 * s + a21 * c;
    dest[10] = a02 * s + a22 * c;
    dest[11] = a03 * s + a23 * c;

    return dest;
}

Matrix4 matrix4RotateZ(const Matrix4 mat, const float angle) {
    const float s = sin(angle);
    const float c = cos(angle);

    const float a00 = mat[0];
    const float a01 = mat[1];
    const float a02 = mat[2];
    const float a03 = mat[3];
    const float a10 = mat[4];
    const float a11 = mat[5];
    const float a12 = mat[6];
    const float a13 = mat[7];

    Matrix4 dest = mat;

    // Perform axis-specific matrix multiplication
    dest[0] = a00 * c + a10 * s;
    dest[1] = a01 * c + a11 * s;
    dest[2] = a02 * c + a12 * s;
    dest[3] = a03 * c + a13 * s;
    dest[4] = a00 * -s + a10 * c;
    dest[5] = a01 * -s + a11 * c;
    dest[6] = a02 * -s + a12 * c;
    dest[7] = a03 * -s + a13 * c;

    return dest;
}
