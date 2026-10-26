# Controller support

Majin Recompile's default controller backend is **SDL3**. The pinned Windows
SDK also has an optional **XInput** driver; the current launcher uses the SDL
default. SDL exposes recognized devices through a common gamepad interface,
which the runtime translates into the Xbox 360 state expected by the game.

## Validation status

| Device / family | Evidence |
| --- | --- |
| **8BitDo Ultimate 2 Wireless** | Owner play-tested on the development PC; runtime logs identify the controller by this name. This does not validate every connection or firmware mode. |
| Xbox / other XInput-compatible controllers | Supported by the runtime's SDL/XInput input paths; individual models and features have not all been tested here. |
| PS4 DualShock 4 / PS5 DualSense | SDL defines PlayStation gamepad types. **Not play-tested in this project yet**; recognition and complete gameplay compatibility remain separate checks. |
| Other recognized SDL gamepads | Depends on the device, driver and available mapping. Report the exact model/mode when testing. |

The SDK initializes SDL's gamepad subsystem and uses recognized controller
mappings. An optional `gamecontrollerdb.txt` can supplement SDL's built-in
mappings; the Alpha does not add an external mapping database. A warning that
this optional file is missing does not by itself mean the built-in gamepad
support failed. Do not download mapping executables or drivers from an issue
comment without checking their provenance.

For controllers with several modes, choose a mode/layout consistent with the
game's Xbox-style button prompts. Some 8BitDo layouts and connection modes
report different button labels. Rumble, extra buttons, gyro and touchpad support
are not certified by the existing gameplay tests. No PlayStation-specific
in-game glyphs have been added.

## Button reference

| Game input | Xbox-style name | PlayStation position reference | Keyboard / mouse profile |
| --- | --- | --- | --- |
| Left stick | LS movement | Left stick | W / A / S / D |
| Right stick | RS movement | Right stick | Mouse / I / J / K / L |
| A | A | Cross | Space |
| B | B | Circle | E; hold Shift while moving to run |
| X | X | Square | Left mouse |
| Y | Y | Triangle | R |
| Left trigger | LT | L2 | Q |
| Right trigger | RT | R2 | Right mouse |
| Left shoulder | LB | L1 | F |
| Right shoulder | RB | R1 | C |
| D-pad | D-pad | D-pad | Arrow keys |
| Left stick click | LS click | L3 | V |
| Right stick click | RS click | R3 | Middle mouse |
| Start | Start / Menu | Options position | Enter |
| Back | Back / View | Share / Create position | Tab |

PlayStation labels describe equivalent physical positions in a standard
mapping. They are not evidence of a tested PS4/PS5 controller. The game's own
prompts remain Xbox buttons. Input actions depend on context; see the full
[action table](README.md#controls) and [keyboard notes](KEYBOARD_MOUSE.md).

## What to include in a controller report

Use the model, selected device mode, USB/Bluetooth/receiver connection, Windows
version, observed button mismatch and reproducible in-game action. Do not post
serial numbers, pairing identifiers or unrelated system details. The local
diagnostic collector does not upload anything automatically.

## Implementation references

- Pinned ReXGlue SDK: `src/input/input_system.cpp`, `src/input/sdl/sdl_input_driver.cpp`, and `src/input/xinput/xinput_input_driver.cpp`.
- SDL primary documentation: [gamepad types](https://wiki.libsdl.org/SDL3/SDL_GamepadType) and [SDL_IsGamepad](https://wiki.libsdl.org/SDL3/SDL_IsGamepad).
- Windows keyboard profile: `scripts/run.ps1`.
