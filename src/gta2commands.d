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

module game.script.gta2commands;

public enum GTA2Command : ushort {
    CMD1_PASSED_FLAG = 0x015B,
    CMD2_PASSED_FLAG = 0x015C,
    CMD3_PASSED_FLAG = 0x015D,
    ADD_CHAR_TO_GANG = 0x0102,
    ADD_CHAR_TO_GROUP = 0x00EB,
    ADD_GROUP = 0x0099,
    ADD_LIVES = 0x0119,
    ADD_MULTIPLIER = 0x011A,
    ADD_NEW_BLOCK = 0x00B6,
    ADD_ONSCREEN_COUNTER = 0x019E,
    ADD_PATROL_POINT = 0x00CD,
    ADD_SCORE1 = 0x008D,
    ADD_SCORE2 = 0x0156,
    ADD_TIME = 0x01B1,
    ADDSCORE_NO_MULT = 0x0188,
    ALT_WANTED_LEVEL = 0x00A4,
    ALTER_WANTED_LEVEL = 0x01A5,
    AND = 0x0048,
    ANSWER_PHONE = 0x00A8,
    ANY_WEAPON_HIT_CAR = 0x016E,
    ARROW_COLOUR = 0x0073,
    ARROW_DEC = 0x0017,
    BEEN_PUNCHED_BY = 0x0108,
    BONUS_DECLARE = 0x0191,
    BRIEF_ONSCREEN = 0x0145,
    CAR_BULLETPROOF = 0x0137,
    CAR_DAMAGE_POS = 0x00C8,
    CAR_DEC = 0x0009,
    CAR_DECSET_2D = 0x000A,
    CAR_DECSET_2D_STR = 0x000C,
    CAR_DECSET_3D = 0x000B,
    CAR_DECSET_3D_STR = 0x000D,
    CAR_DRIVE_AWAY = 0x00AF,
    CAR_FLAMEPROOF = 0x0139,
    CAR_GOT_DRIVER = 0x00FA,
    CAR_IN_AIR = 0x00BF,
    CAR_IN_AREA = 0x010E,
    CAR_ROCKETPROOF = 0x0138,
    CAR_SUNK = 0x00BE,
    CAR_WRECK_IN_LOCATION = 0x00BD,
    CARBOMB_ACTIVE = 0x0131,
    CHANGE_BLOCK_LID = 0x00BA,
    CHANGE_BLOCK_SIDE = 0x00B9,
    CHANGE_BLOCK_TYPE = 0x00BB,
    CHANGE_CAR_LOCK = 0x0116,
    CHANGE_CAR_REMAP = 0x009B,
    CHANGE_CHAR_REMAP = 0x009C,
    CHANGE_COLOUR = 0x00DD,
    CHANGE_GANG_RESP = 0x0189,
    CHANGE_INTENSITY = 0x00DC,
    CHANGE_POLICE = 0x01A2,
    CHANGE_RADIUS = 0x00DE,
    CHANGE_RESPECT = 0x0106,
    CHAR_AREA_ANY_MEANS = 0x01B2,
    CHAR_ARRESTED = 0x0163,
    CHAR_DEC = 0x0006,
    CHAR_DECSET_2D = 0x0007,
    CHAR_DECSET_3D = 0x0008,
    CHAR_DO_NOTHING = 0x0168,
    CHAR_DRIVE_AGGR = 0x0132,
    CHAR_DRIVE_SPEED = 0x0133,
    CHAR_IN_AIR = 0x00CA,
    CHAR_INTO_CAR = 0x014A,
    CHAR_INVINCIBLE = 0x016B,
    CHAR_SUNK = 0x00CB,
    CHAR_TO_BACKDOOR = 0x00AB,
    CHAR_TO_DRIVE_CAR = 0x00A7,
    CHECK_BONUS1 = 0x0124,
    CHECK_BONUS2 = 0x0125,
    CHECK_BONUS3 = 0x0126,
    CHECK_CAR_BOTH = 0x009F,
    CHECK_CAR_DAMAGE = 0x0081,
    CHECK_CAR_DRIVER = 0x0082,
    CHECK_CAR_MODEL = 0x009D,
    CHECK_CAR_REMAP = 0x009E,
    CHECK_CAR_SPEED = 0x00D0,
    CHECK_CURRENT_WEAPON = 0x01A4,
    CHECK_DEATH_ARR = 0x01BB,
    CHECK_HEADS = 0x013E,
    CHECK_HEALTH = 0x007E,
    CHECK_MAX_PASS = 0x00F4,
    CHECK_MULT = 0x00C4,
    CHECK_NUM_ALIVE = 0x00EA,
    CHECK_NUM_LIVES = 0x00C0,
    CHECK_OBJ_MODEL = 0x016A,
    CHECK_PHONE = 0x00E3,
    CHECK_PHONETIMER = 0x00E4,
    CHECK_RESPECT_GREATER = 0x00C6,
    CHECK_RESPECT_IS = 0x00E7,
    CHECK_RESPECT_LESS = 0x00C7,
    CHECK_SCORE = 0x00C2,
    CHECK_WEAPONHIT = 0x0140,
    CLEAR_BRIEFS = 0x013D,
    CLEAR_CLOCK_ONLY = 0x01A0,
    CLEAR_COUNTER = 0x019F,
    CLEAR_KF_WEAPON = 0x019C,
    CLEAR_NO_COLLIDE = 0x00AE,
    CLEAR_TIMERS = 0x0078,
    CLEAR_WANTED_LEVEL = 0x00A3,
    CLOSE_DOOR = 0x00B2,
    CMD0 = 0x0000,
    CMD1 = 0x0001,
    CMD2 = 0x0002,
    CMD3 = 0x0003,
    CMD4 = 0x0004,
    CONVEYOR_DEC = 0x0019,
    CONVEYOR_DECSET1 = 0x001A,
    CONVEYOR_DECSET2 = 0x001B,
    COUNTER = 0x0015,
    COUNTER_SAVE = 0x0113,
    COUNTER_SET = 0x0016,
    COUNTER_SET_SAVE = 0x0114,
    CRANE2TARGET_DEC = 0x0027,
    CRANE_BASIC_DEC = 0x0025,
    CRANE_DEC = 0x0024,
    CRANE_TARGET_DEC = 0x0026,
    CREATE_CAR_2D = 0x002B,
    CREATE_CAR_2D_STR = 0x002D,
    CREATE_CAR_3D = 0x002C,
    CREATE_CAR_3D_STR = 0x002E,
    CREATE_CHAR_2D = 0x0029,
    CREATE_CHAR_3D = 0x002A,
    CREATE_CONVEYOR_2D = 0x0035,
    CREATE_CONVEYOR_3D = 0x0036,
    CREATE_DESTRUCTOR_2D = 0x0039,
    CREATE_DESTRUCTOR_3D = 0x003A,
    CREATE_GANG_CAR1 = 0x018A,
    CREATE_GANG_CAR2 = 0x018B,
    CREATE_GANG_CAR3 = 0x018C,
    CREATE_GANG_CAR4 = 0x018D,
    CREATE_GENERATOR_2D = 0x0037,
    CREATE_GENERATOR_3D = 0x0038,
    CREATE_LIGHT1 = 0x00DB,
    CREATE_LIGHT2 = 0x012E,
    CREATE_OBJ_2D = 0x002F,
    CREATE_OBJ_2D_INT = 0x0032,
    CREATE_OBJ_2D_STR = 0x0034,
    CREATE_OBJ_3D = 0x0030,
    CREATE_OBJ_3D_INT = 0x0031,
    CREATE_OBJ_3D_STR = 0x0033,
    CREATE_SOUND = 0x0148,
    CREATE_THREAD = 0x003D,
    CRUSHER_BASIC = 0x0028,
    DEATH_ARR_STATE = 0x01B0,
    DEC_DEATH_BASE_1 = 0x01B3,
    DEC_DEATH_BASE_2 = 0x01B4,
    DEC_DEATH_BASE_3 = 0x01B5,
    DEC_GANG_1_FLAG = 0x01AD,
    DEC_GANG_2_FLAG = 0x01AE,
    DEC_GANG_3_FLAG = 0x01AF,
    DECIDE_POWERUP = 0x0162,
    DECLARE_CARLIST = 0x0161,
    DECLARE_MISSION = 0x00F0,
    DECLARE_POLICE = 0x0130,
    DECREMENT = 0x0061,
    DEL_GROUP_IN_CAR = 0x014B,
    DELAY = 0x00A2,
    DELAY_HERE = 0x00A1,
    DELETE_ITEM = 0x008C,
    DESTROY_GROUP = 0x01A3,
    DESTRUCTOR_DEC = 0x0021,
    DESTRUCTOR_DECSET1 = 0x0022,
    DESTRUCTOR_DECSET2 = 0x0023,
    DISABLE_CRANE = 0x00F9,
    DISABLE_THREAD = 0x00D8,
    DISPLAY_BRIEF = 0x0076,
    DISPLAY_BRIEF_NOW = 0x0117,
    DISPLAY_BRIEF_SOON = 0x0141,
    DISPLAY_MESSAGE = 0x0075,
    DISPLAY_TIMER = 0x0077,
    DO_BASIC_KF = 0x01A7,
    DO_CRANE_POWERUP = 0x01B7,
    DO_EASY_PHONE = 0x0149,
    DO_NOWT = 0x0101,
    DO_SAVE_GAME = 0x01B6,
    DO_WHILE = 0x0042,
    DOOR_DECLARE_D1 = 0x017A,
    DOOR_DECLARE_D2 = 0x017B,
    DOOR_DECLARE_D3 = 0x017C,
    DOOR_DECLARE_S1 = 0x0177,
    DOOR_DECLARE_S2 = 0x0178,
    DOOR_DECLARE_S3 = 0x0179,
    DRIVER_OUT_CAR = 0x00A6,
    ELSE = 0x004C,
    EMERG_LIGHTS = 0x0169,
    EMERG_LIGHTS_ON = 0x01A1,
    ENABLE_CRANE = 0x00F8,
    ENABLE_THREAD = 0x00D7,
    EXPLODE = 0x008E,
    EXPLODE_BUILDING = 0x008F,
    EXPLODE_ITEM = 0x0090,
    EXPLODE_LARGE1 = 0x018E,
    EXPLODE_LARGE2 = 0x018F,
    EXPLODE_NO_RING1 = 0x0195,
    EXPLODE_NO_RING2 = 0x0196,
    EXPLODE_SMALL1 = 0x0193,
    EXPLODE_SMALL2 = 0x0194,
    FINISH_LEVEL = 0x013F,
    FINISH_MISSION = 0x0187,
    FINISH_SCORE = 0x0157,
    FOR_LOOP = 0x0041,
    FORCE_CLEANUP = 0x01BC,
    FORWARD_DECLARE = 0x0063,
    FUNCTION = 0x0043,
    GANG_1_MISSION_TOTAL = 0x0182,
    GANG_2_MISSION_TOTAL = 0x0183,
    GANG_3_MISSION_TOTAL = 0x0184,
    GENERATOR_DEC = 0x001C,
    GENERATOR_DECSET1 = 0x001D,
    GENERATOR_DECSET2 = 0x001E,
    GENERATOR_DECSET3 = 0x001F,
    GENERATOR_DECSET4 = 0x0020,
    GET_CAR_FROM_CRANE = 0x00BC,
    GET_CAR_SPEED = 0x00CE,
    GET_CHAR_CAR_SPEED = 0x00CF,
    GET_LAST_PUNCHED = 0x00FC,
    GET_MAX_SPEED = 0x00D1,
    GET_MULT = 0x00C5,
    GET_NUM_LIVES = 0x00C1,
    GET_PASSENGER_NUM = 0x00C9,
    GET_SCORE = 0x00C3,
    GIVE_CAR_ALARM = 0x0136,
    GIVE_DRIVER_BRAKE = 0x00AA,
    GIVE_WEAPON1 = 0x008A,
    GIVE_WEAPON2 = 0x010A,
    GOSUB = 0x004E,
    GOTO = 0x004D,
    GROUP_IN_AREA = 0x0199,
    HAS_CAR_WEAPON = 0x00F1,
    HAS_CHAR_DIED = 0x007F,
    I_MINUS_S = 0x0053,
    I_PLUS_S = 0x0050,
    IF = 0x004A,
    IF_JUMP = 0x0062,
    INCREMENT = 0x0060,
    IS_ALARM_RINGING = 0x013A,
    IS_BUS_FULL = 0x0171,
    IS_CAR_CRUSHED = 0x010B,
    IS_CAR_IN_BLOCK = 0x008B,
    IS_CAR_ON_TRAIL = 0x00F7,
    IS_CAR_WRECKED = 0x009A,
    IS_CHAR_FIRE_ONSCREEN = 0x00A5,
    IS_CHAR_FIRING_AREA = 0x00B0,
    IS_CHAR_HORN = 0x00F3,
    IS_CHAR_IN_ANY_CAR = 0x007B,
    IS_CHAR_IN_CAR = 0x0079,
    IS_CHAR_IN_GANG = 0x00E8,
    IS_CHAR_IN_MODEL = 0x007A,
    IS_CHAR_IN_ZONE = 0x00F2,
    IS_CHAR_MOM_FAT = 0x0171,
    IS_CHAR_OBJ_FAIL = 0x0087,
    IS_CHAR_OBJ_PASS = 0x0086,
    IS_CHAR_ON_FIRE = 0x0144,
    IS_CHAR_STOPPED = 0x007C,
    IS_CHAR_STUNNED = 0x007D,
    IS_GROUP_IN_CAR = 0x00FE,
    IS_ITEM_ONSCREEN = 0x00A0,
    IS_TRAILER_ATT = 0x00F6,
    KILL_ALL_PASSENG = 0x00FD,
    KILL_CHAR = 0x0173,
    LAST_WEAPON_HIT = 0x00CC,
    LAUNCH_MISSION = 0x0112,
    LEVEL_END_ARROW1 = 0x01B8,
    LEVEL_END_ARROW2 = 0x01B9,
    LEVELEND = 0x003C,
    LEVELSTART = 0x003B,
    LIGHT_DEC = 0x00D9,
    LIGHT_DECSET1 = 0x00DA,
    LIGHT_DECSET2 = 0x012D,
    LOC_SEC_CHAR_ANY = 0x017E,
    LOC_SEC_CHAR_CAR = 0x017D,
    LOC_SECOND_CHAR = 0x016F,
    LOCATE_CHAR_ANY = 0x0091,
    LOCATE_CHAR_BY_CAR = 0x0093,
    LOCATE_CHAR_ONFOOT = 0x0092,
    LOWER_LEVEL = 0x00B8,
    MAKE_CAR_DUMMY = 0x0064,
    MAKE_LEADER = 0x0103,
    MAKE_MUGGERS = 0x016D,
    MAP_ZONE1 = 0x0065,
    MAP_ZONE2 = 0x0143,
    MAP_ZONE_SET = 0x0066,
    MISSIONEND = 0x0111,
    MISSIONSTART = 0x0110,
    MODEL_CHECK = 0x012C,
    NO_CHARS_OFF_BUS = 0x0172,
    NOT = 0x0047,
    OBJ_DEC = 0x000E,
    OBJ_DECSET_2D = 0x000F,
    OBJ_DECSET_2D_INT = 0x0011,
    OBJ_DECSET_2D_STR = 0x0013,
    OBJ_DECSET_3D = 0x0010,
    OBJ_DECSET_3D_INT = 0x0012,
    OBJ_DECSET_3D_STR = 0x0014,
    ONSCREEN_ACCURACY = 0x0164,
    ONSCREEN_COUNTER_DEC = 0x019D,
    OPEN_DOOR = 0x00B1,
    OR = 0x0049,
    PARK = 0x0104,
    PARK_FINISHED = 0x0105,
    PARK_NO_RESPAWN = 0x0118,
    PARKED_CAR_DECSET_2D = 0x01A9,
    PARKED_CAR_DECSET_2D_STR = 0x01AB,
    PARKED_CAR_DECSET_3D = 0x01AA,
    PARKED_CAR_DECSET_3D_STR = 0x01AC,
    PASSED_FLAG = 0x015A,
    PED_GRAPHIC = 0x016C,
    PHONE_TEMPLATE = 0x0107,
    PLAY_SOUND = 0x00AC,
    PLAYER_PED = 0x0005,
    POINT_ARROW_3D = 0x0072,
    POINT_ARROW_AT = 0x0071,
    POINT_ONSCREEN = 0x011C,
    PUNCHED_SOMEONE = 0x00FF,
    PUT_CAR_ON_TRAILER = 0x013C,
    RADIOSTATION_DEC = 0x011F,
    REMOTE_CONTROL = 0x010F,
    REMOVE_ARROW = 0x0074,
    REMOVE_BLOCK = 0x00B7,
    REMOVE_CHAR = 0x00EC,
    REMOVE_WEAPON = 0x0100,
    RESTORE_RESPECT = 0x01BE,
    RETURN = 0x0044,
    ROAD_ON_OFF = 0x00B5,
    S_EQUAL_I = 0x005E,
    S_EQUAL_S = 0x005F,
    S_GEQUAL_I = 0x005C,
    S_GEQUAL_S = 0x005D,
    S_GREATER_I = 0x005A,
    S_GREATER_S = 0x005B,
    S_IS_S_DIV_I = 0x014E,
    S_IS_S_DIV_S = 0x0151,
    S_IS_S_MINUS_I = 0x014C,
    S_IS_S_MINUS_S = 0x0134,
    S_IS_S_MOD_I = 0x0150,
    S_IS_S_MOD_S = 0x0153,
    S_IS_S_MULT_I = 0x014F,
    S_IS_S_MULT_S = 0x0152,
    S_IS_S_PLUS_I = 0x014D,
    S_IS_S_PLUS_S = 0x0135,
    S_LEQUAL_I = 0x0058,
    S_LEQUAL_S = 0x0059,
    S_LESS_I = 0x0056,
    S_LESS_S = 0x0057,
    S_MINUS_I = 0x0052,
    S_MINUS_S = 0x0054,
    S_PLUS_I = 0x004F,
    S_PLUS_S = 0x0051,
    SAVE_GAME = 0x0115,
    SAVE_RESPECT = 0x01BD,
    SECRETS_FAILED = 0x0186,
    SECRETS_PASSED = 0x0185,
    SEND_CAR_TO_BLOCK = 0x00A9,
    SEND_CHAR_CAR = 0x0089,
    SEND_CHAR_FOOT = 0x0088,
    SET = 0x0055,
    SET_ALL_CONTROLS = 0x0197,
    SET_AMBIENT = 0x00E2,
    SET_BAD_CAR = 0x0069,
    SET_BONUS_RATING = 0x01A8,
    SET_CAR_DENSITY = 0x0067,
    SET_CAR_GRAPHIC = 0x012F,
    SET_CAR_JAMMED = 0x0176,
    SET_CARTHIEF = 0x006D,
    SET_CHAR_BRAVERY = 0x00EF,
    SET_CHAR_MOM_FAT = 0x00DF,
    SET_CHAR_OBJ1 = 0x0083,
    SET_CHAR_OBJ2 = 0x0084,
    SET_CHAR_OBJ3 = 0x0085,
    SET_CHAR_OBJ_FOLLOW = 0x013B,
    SET_CHAR_OCCUPATION = 0x019A,
    SET_CHAR_RESPECT = 0x00E1,
    SET_CHAR_SHOOT = 0x00EE,
    SET_COUNTER_INT = 0x0154,
    SET_COUNTER_VAR = 0x0155,
    SET_DIR_OF_TVVAN = 0x011B,
    SET_DOOR_AUTO = 0x00B3,
    SET_DOOR_INFO = 0x00E6,
    SET_DOOR_MANUAL = 0x00B4,
    SET_ELVIS = 0x006E,
    SET_EMPTY_STATION = 0x011E,
    SET_ENTER_STATUS = 0x0190,
    SET_FAV_CAR = 0x0198,
    SET_GANG = 0x006F,
    SET_GANG_INFO1 = 0x00DF,
    SET_GANG_INFO2 = 0x0142,
    SET_GANG_RESPECT = 0x00E0,
    SET_GANGCARRATIO = 0x0174,
    SET_GOOD_CAR = 0x0068,
    SET_GROUP_TYPE = 0x0167,
    SET_KF_WEAPON = 0x019B,
    SET_MIN_ALIVE = 0x00ED,
    SET_MODEL_WANTED = 0x01BA,
    SET_MUGGER = 0x006C,
    SET_NO_COLLIDE = 0x00AD,
    SET_PED_DENSITY = 0x006B,
    SET_PHONE_DEAD = 0x00F5,
    SET_POLICE_CAR = 0x006A,
    SET_POLICE_PED = 0x0070,
    SET_RUN_SPEED = 0x017F,
    SET_SHADING_LEV = 0x0175,
    SET_STATION = 0x011D,
    SET_STATION_1 = 0x012A,
    SET_STATION_2 = 0x0129,
    SET_STATION_3 = 0x0128,
    SET_STATION_4 = 0x0127,
    SET_STAY_IN_CAR = 0x0180,
    SET_THREAT_REACT = 0x0098,
    SET_THREAT_SEARCH = 0x0097,
    SET_USE_CAR_WEAPON = 0x0181,
    SETUP_MODEL_CHECK = 0x012B,
    SOUND = 0x0146,
    SOUND_DECSET = 0x0147,
    SPOTTED_PLAYER = 0x00FB,
    START_BASIC_KF = 0x01A6,
    START_BONUS1 = 0x0120,
    START_BONUS2 = 0x0121,
    START_BONUS3 = 0x0122,
    START_BONUS4 = 0x0123,
    START_EXEC = 0x003F,
    STOP_CAR_DRIVE = 0x0170,
    STOP_EXEC = 0x0040,
    STOP_LOCATE_CHAR_ANY = 0x0094,
    STOP_LOCATE_CHAR_CAR = 0x0096,
    STOP_LOCATE_CHAR_FOOT = 0x0095,
    STOP_PHONE_RING = 0x00E5,
    STOP_THREAD = 0x003E,
    STORE_BONUS = 0x0192,
    STORE_CAR_INFO = 0x0080,
    SUPPRESS_MODEL = 0x015E,
    SWITCH_GENERATOR1 = 0x010C,
    SWITCH_GENERATOR2 = 0x010D,
    SWITCH_GENERATOR3 = 0x015F,
    SWITCH_GENERATOR4 = 0x0160,
    THEN = 0x004B,
    THREAD_DECLARE1 = 0x00D2,
    THREAD_DECLARE2 = 0x00D3,
    THREAD_DECLARE3 = 0x00D4,
    THREAD_DECLARE4 = 0x00D5,
    THREAD_DECLARE5 = 0x00D6,
    THREAD_ID = 0x0018,
    TIMER_DECLARE = 0x00E9,
    TOTAL_MISSIONS = 0x0158,
    TOTAL_SECRETS = 0x0159,
    UPDATE_DOOR = 0x0109,
    WARP_CHAR = 0x0165,
    WEAP_HIT_CAR = 0x0166,
    WHILE = 0x0045,
    WHILE_EXEC = 0x0046,
}