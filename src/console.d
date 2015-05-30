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

module util.console;

import std.stdio;
import std.string;
import std.json;
import std.file;

import util.log;


public enum CVarFlags : ubyte {
    ARCHIVE = 1,
    READ_ONLY = 2,
    USER = 4
}

public union CVarValue {
    long integer;
    double floating;
    string str;
}

public enum CVarType : ubyte {
    INTEGER,
    FLOATING,
    STRING
}


public final class CVar {
    private CVarFlags _flags;
    private CVarValue _value;
    private CVarType _type;

    
    this(const long value, const CVarFlags flags) {
        _value.integer = value;
        _flags = flags;
        _type = CVarType.INTEGER;
    }

    this(const double value, const CVarFlags flags) {
        _value.floating = value;
        _flags = flags;
        _type = CVarType.FLOATING;
    }

    this(const string value, const CVarFlags flags) {
        _value.str = value;
        _flags = flags;
        _type = CVarType.STRING;
    }

    @property public long intVal() {
        return _value.integer;
    }

    @property public double floatVal() {
        return _value.floating;
    }

    @property public string strVal() {
        return _value.str;
    }

    @property public void set(const long value) {
        if (_flags & CVarFlags.READ_ONLY) {
            return;
        }
        _value.integer = value;
    }

    @property public void set(const double value) {
        if (_flags & CVarFlags.READ_ONLY) {
            return;
        }
        _value.floating = value;
    }

    @property public void set(const string value) {
        if (_flags & CVarFlags.READ_ONLY) {
            return;
        }
        _value.str = value;
    }

    @property public CVarType type() {
        return _type;
    }

    @property public CVarFlags flags() {
        return _flags;
    }
}


public static final class CVars {

    private static CVar[string] _cvars;


    public static CVar register(const string name, CVar cvar) {
        if (name in _cvars) {
            throw new Exception(format("Cannot register CVar '%s', a CVar with that name already exists.", name));
        }
        _cvars[name] = cvar;

        return cvar;
    }

    public static CVar get(const string name) {
        CVar cvar = _cvars.get(name, null);
        if (cvar is null) {
            throw new Exception(format("CVar '%s' does not exist.", name));
        }

        return cvar;
    }

    public static void load(const string fileName) {
        if (!exists(fileName)) {
            Log.write(Color.NORMAL, "No configuration file found. Using default values.");
            return;
        }

        const JSONValue json = parseJSON(readText(fileName));

        foreach (string key, JSONValue value; json.object) {
        
            // Set existing value.
            if (key in _cvars) {
                CVar cvar = _cvars[key];

                if (cvar.type == CVarType.INTEGER && (value.type == JSON_TYPE.INTEGER || value.type == JSON_TYPE.UINTEGER)) {
                    cvar.set(value.integer);
                } else if (cvar.type == CVarType.FLOATING && (value.type == JSON_TYPE.INTEGER || value.type == JSON_TYPE.UINTEGER)) {
                    cvar.set(cast(double)value.integer);
                } else if (cvar.type == CVarType.FLOATING && value.type == JSON_TYPE.FLOAT) {
                    cvar.set(value.floating);
                } else if (cvar.type == CVarType.STRING && value.type == JSON_TYPE.STRING) {
                    cvar.set(value.str);
                } else {
                    throw new Exception(format("Unsupported console variable type for '%s'.", key));
                }
        
            // Create new value.
            } else {
                CVar cvar;

                if (value.type == JSON_TYPE.INTEGER || value.type == JSON_TYPE.UINTEGER) {
                    cvar = new CVar(value.integer, cast(CVarFlags)(CVarFlags.USER | CVarFlags.ARCHIVE));
                } else if (value.type == JSON_TYPE.FLOAT) {
                    cvar = new CVar(value.floating, cast(CVarFlags)(CVarFlags.USER | CVarFlags.ARCHIVE));
                } else if (value.type == JSON_TYPE.STRING) {
                    cvar = new CVar(value.str, cast(CVarFlags)(CVarFlags.USER | CVarFlags.ARCHIVE));
                } else {
                    throw new Exception(format("Unsupported console variable type for '%s'.", key));
                }
            
                CVars.register(key, cvar);
            }
        }

        Log.write(Color.NORMAL, "Loaded configuration from '%s'.", fileName);
    }

    public static void save(const string fileName) {
        JSONValue[string] data;

        foreach (string key, CVar cvar; _cvars) {
            JSONValue value;

            if (cvar.type == CVarType.INTEGER) {
                value.integer = cvar.intVal;
            } else if (cvar.type == CVarType.FLOATING) {
                value.floating = cvar.floatVal;
            } else if (cvar.type == CVarType.STRING) {
                value.str = cvar.strVal;
            }

            data[key] = value;
        }

        JSONValue json = data;
        File f = File(fileName, "w");
        f.write(json.toPrettyString());

        Log.write(Color.NORMAL, "Wrote configuration to '%s'.", fileName);
    }

}
