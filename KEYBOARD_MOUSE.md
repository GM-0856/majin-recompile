# Keyboard and mouse — first experimental profile

Select **Keyboard + mouse (test)** under Input in the launcher. The main launcher displays a command guide. **Controls / sensitivity** also displays the bindings and adjusts mouse sensitivity. Settings are saved when Play is selected. Controller mode remains the default for existing settings. See [CONTROLLERS.md](CONTROLLERS.md) for the SDL/XInput backend, tested 8BitDo status and project-untested PlayStation references.

The SDK translates keyboard/mouse input into the game's controller state. This is not direct mouse camera input: camera response still follows the game's right-stick behavior. Controller input remains available alongside the experimental profile.

| Input | Controller equivalent / action |
|---|---|
| WASD | Left stick / movement |
| Mouse or IJKL | Right stick / camera |
| Space | A / jump, confirm |
| Hold Shift + WASD | B + left stick / run, dash |
| E | B / interact, back |
| Left mouse | X |
| R | Y / roll |
| Hold Q | LT / crouch |
| Right mouse | RT / command Majin |
| F | LB / throw mode |
| C | RB / ability |
| Arrow keys | D-pad |
| V / middle mouse | Left / right stick click |
| Enter | Start / pause menu |
| Tab | Back / map |
| Escape | Existing quit confirmation |

Actions remain context-dependent. Shift and E both send the game's B button: Shift is the convenient running binding, while E remains available for interaction and going back. This does not separate the game's contextual B actions; E can still dash and Shift can interact or go back depending on context. For example, the game's X+A combination maps to left mouse + Space. Keyboard movement is digital.

The SDK matches modifiers exactly. The launcher supplies Shift-prefixed alternatives for movement and other mapped actions, and `Shift+Shift` for the modifier key itself, so holding Shift does not disable WASD, jump, attack or commands. Ctrl/Alt shortcuts do not activate these gameplay bindings.

## Validation

Launcher layout, input selection and command-line arguments for both profiles checked locally. The user confirmed initial movement, jumping, attacks and Majin commands working. Remaining combinations, focus recovery, menus, quit-dialog mouse behavior and camera feel still require play-testing. Alt+Tab should release mouse capture through the SDK's focus handler; verify reacquisition after returning.

First short test: load a safe checkpoint, walk and turn the camera, hold Shift while moving forward and diagonally, release Shift without releasing movement, jump and attack while holding Shift, move while holding Q, interact with E, navigate menus and try RT combinations. Check Escape -> No and Alt+Tab for stuck keys or mouse capture. Then test combat combinations and switching between physical controller and keyboard.

October 23, 2026: the owner confirmed Shift running, E item collection/interaction, Tab opening the map and Enter opening pause in the locally patched Release candidate. The Shift bindings also passed 399 automated checks against the actual SDK key parser/matcher, including modifier release, movement diagonals and concurrent jump/attack/command bindings. These checks do not establish complete in-game command, focus or campaign coverage. In-game keyboard/mouse glyphs are deferred until after the Alpha release.

## Later stages

1. Adjust bindings and sensitivity from play-test feedback; investigate frame-rate-dependent camera response if observed.
2. Add user remapping and deliberate mouse capture/release behavior for game menus.
3. Locate the game's prompt rendering/assets and implement input-aware keyboard/mouse glyphs. Original Xbox glyphs remain in this first profile.
4. Validate the new glyphs for tutorials, menus and combinations across the campaign.

No new in-game icons have been added yet.
