# Open3D-bin-vcpkg-port
A rudimentary overlay port of the Open3D public repository that uses their pre-built releases, as a proper package doesn't exist yet.
Only tested in Manifest mode.
## Usage
1. Add this project as a submodule
2. Add the following to `vcpkg-configuration`:
   ```json
   {
      "overlay-ports": [
       "<path to submodule root>"
     ]
   }
   ```
3. Add package: `vcpkg add port open3d-bin`

## Important Notes
- This port is currently set up for version 0.15.1 of Open3D because I required this specific one.
It may be possible to use a different version by adjusting `version` in `vcpkg.json` and `VERSION` in `portfile.cmake`
- This project is also not well tested and likely still very unstable. Use at your own risk.
