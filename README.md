GTA Viewer
==========
This is an engine\viewer for the top-down Grand Theft Auto games.

It supports the following GTA games:

* GTA 1
* GTA 1 demos (regular, 3DFX, ECTS)
* GTA London (1969 and 1961)
* GTA 2
* GTA 2 demo

It is not feature complete, lacking the following abilities:
* GTA 2 sound sequences (causing wrong ambient sounds to play).
* Map meta-data like routes, spawn points and drive arrows are not displayed.
* GTA 2 point lights are not rendered.

Usage
-----
In order to run GTA Viewer you will need to place files from a valid GTA game in an appropriately named subdirectory of the /base directory. You can use one of the following subdirectory names:

* gta1: GTA 1
* gta1demo: GTA 1 Demo
* gta1demo3dfx: GTA 1 3DFX Demo
* gta1demoects: GTA 1 ECTS Demo
* uk: GTA London 1969
* uk1961: GTA London 1961
* gta2: GTA 2
* gta2demo: GTA 2 Demo

For the GTA 1 and GTA: London games, copy all data inside the /gtadata directory into the corresponding /base/gta1* or /base/uk* directories. For GTA 2 games, copy all data inside the /data directory into the corresponding /base/gta2* directory. Any version of the game's data files should work, including versions released through Steam.

To configure what game directory should be used, edit the /data/config.json file, and modify the g_basedir value to the directory name containing the game data you want to use.

Configuration
-------------
The /data/config.json file contains a number of variables that can be modified. The most useful ones are:

* g_basedir: sets the directory inside the /base directory that contains the files to run GTA Viewer with.
* r_width & r_height: these values set the width and height of the window to diusplay the viewer in, or the resolution of the fullscreen mode (see r_fullscreen).
* g_dusk: set to 1 if GTA 2 levels should be played in dusk lighting mode.
* g_fov: sets the field of view of the camera.
* g_mission: sets the mission index to view. This will load the appropriate map, script and style for the specified mission.
* r_aasamples: sets the number of anti-aliasing samples to use to smooth out edges.
* r_anisotropy: sets the number of anisotropy samples to use to produce more accurate texture filtering at steep angles.
* r_dumpblocktextures: if set to 1, all of the loaded style's block textures will be written to the /blocktextures directory.
* r_dumpsprites: if set to 1, all of the loaded style's sprites will be written to the /sprites directory.
* r_dumpspritetextures: if set to 1, all of the loaded style's sprites will be written to the /spritetextures directory as sprite sheets.
* r_filter: if set to 1, texture filtering will be applied. To emulate GTA 1's lack of texture filtering, set this to 0.
* r_frameratelimit: if r_vsync is 0, this will dictate the maximum framerate to render at.
* r_fullscreen: if set to 1, will display the viewer in fullscreen mode instead of in a window.
* r_shadows: if set to 1, draws faux shadows under sprites. This also works in GTA 1 games.
* r_vsync: if set to 1, will enable vsync to synchronize screen refreshes with the display refresh rate, leading to smoother motion.

Compiling
---------
GTA Viewer can be compiled using the included Visual Studio 2013 project, as well as an installation of D and Visual D. The following libraries are also required:

* Derelict SDL2: https://github.com/DerelictOrg/DerelictSDL2
* Derelict OpenGL 3: https://github.com/DerelictOrg/DerelictGL3
* Derelict OpenAL: https://github.com/DerelictOrg/DerelictAL

Notices
-------
* Contains code based on Epic GTA2 Script Decompiler by T.M.
* fast-hash implementation converted from https://code.google.com/p/fast-hash/
* Matrix math functions adapted from https://github.com/coreh/gl-matrix.c by Marco Aurélio
* Bin packing functionality adapted from https://github.com/jakesgordon/bin-packing by Jake Gordon
* Grand Theft Auto, Grand Theft Auto 2, Grand Theft Auto London 1969 and Grand Theft Auto London 1961 are registered trademarks from Rockstar Games, Inc.
