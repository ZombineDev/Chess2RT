Chess2RT [![Build Status](https://travis-ci.org/ZombineDev/Chess2RT.svg?branch=master)](https://travis-ci.org/ZombineDev/Chess2RT)
========
A raytracer renderer, written in D, which will eventually be used for a
3d rendered chess game (and/or a variation of it).

What works
----------
+ Simple geometry objects: spheres, cubes and a horizontal plane.
+ CSG combinations of supported geometry  objects (including CSG objects).
+ Procedural textures.
+ Lambert and Phong shading.
+ Loading scenes from `.sdl` or `.json` files. You can find sample scene files in `data/`.
+ Interactive camera movement (`←`, `↑`, `→`, `↓` for movement, `Shift + ←`, `Shift + ↓`, `Shift + →`, `Shift + ↓` for mouse look, `Ctrl + ←`, `Ctrl + →` for rotation and `Ctrl + ↑`, `Ctrl + ↓` for up and down moving).

Performance statistics
----------------------
Available [here](https://github.com/ZombineDev/Chess2RT/blob/master/perf-results.md).

Build Instructions
------------------
1. Install what's needed (if you haven't yet):
    + [D][1] compiler with frontend >= **v2.067** (e.g. [DMD][2])
    + [dub][3] package manager >= **v0.9.23**
    + [SDL 2][4] binaries >= **v2.0.0** (SDL 2.0.3 DLLs are included for windows)
2. Git clone:
    ```
    git clone https://github.com/ZombineDev/Chess2RT.git
    ```

3. Run DUB:
    ```
    cd ./Chess2RT
    dub
    ```

Scene files
-----------
Scene files are written in [SDLang][5] or JSON and are usually put in the `data/` folder.
To render a specific scene you can either:
+ call the app from the command-line like this:
    ```
    ./Chess2RT/bin/<OS>/chess2rt --file=data/scene1.sdl
    ```

+ place the path to scene you wish to load in `data/default_scene.path` and call chess2rt without arguments.

Acknowledgement
---------------
This project uses:
+ [SDL 2][4] (SDL 2.0.3 binaries for Windows x86 and x86_64
  are included in `lib/`)
+ [GFM][6] (package on http://code.dlang.org)
+ [SDLang-D][5] (package on http://code.dlang.org)

[1]: http://dlang.org/
[2]: http://dlang.org/download
[3]: http://code.dlang.org/download
[4]: http://www.libsdl.org/download-2.0.php
[5]: https://github.com/Abscissa/SDLang-D
[6]: https://github.com/d-gamedev-team/gfm
