# Majin Recompile v0.1.0-alpha.3

Public source publication: the independent repository at GM-0856/majin-recompile
contains a fresh audited snapshot and only the current Alpha.3 downloads. The
private development history and previous downloads are not transferred. Native
executables and current artwork are unchanged; repository links, documentation
and package/source-snapshot metadata are refreshed. See PUBLICATION.md.


October 25, 2026 â€” launcher artwork refresh. The current background is the
owner-supplied scenery-only ruins image, replacing the previous replacement
background with characters. The logo and M icon are retained.

Game/GPU/audio and native launcher binaries are byte-identical to Alpha.2.
Original remains default and 60 FPS stays opt-in/experimental. Existing controller,
keyboard, performance, graphics and security limitations still apply. Matching
Windows/source ZIPs and SHA-256 files identify this visual revision.

The source companion retains the Alpha.2 exclusion of optional prebuilt test/
example tools. Repository visibility and historical-artwork review are unchanged.

---

# Majin Recompile v0.1.0-alpha.2

Windows x64 / Direct3D 12 experimental community Alpha, prepared October 25,
2026. This is an unofficial project. **Original remains the default; 60 FPS
is an opt-in test mode, not a universal or full-campaign stability guarantee.**

**Tested input: European/PAL Xbox 360**, Title ID `4E4D0816`, Media ID
`67BD87EF`, version `0.0.0.3`, supported `default.xex` SHA-256
`660CAE389F0A45100739F935472437D282B2568FCFC2C60FC5A9B2B7B48CE1EC`.
**American/USA and Japanese editions have not been tested.**

## Changes since alpha.1

- Optional **60 FPS (test)** mode with a 60 guest-swap/s cap, 120 Hz guest vblank
  and a correction to the title screen's frame-counted idle timer. Engine/audio
  clocks and prerecorded movies are preserved. VSync On/Off remain selectable;
  the cap stays active either way in the 60 mode. See [FPS_60.md](FPS_60.md).
- **Shift running**, with E interaction, Tab map and Enter pause retained.
  Shift combinations preserve movement/jump/attack/commands. Original Xbox
  prompts remain in-game; keyboard glyphs and remapping are future work.
- Local frame CSV/frametime summaries, bounded texture-warning statistics and
  a **Diagnostics / privacy** panel. Extra hardware details require opt-in.
- Decorated window mode with minimize/maximize/close, monitor-work-area fitting
  and a guest FPS counter in the title bar only in windowed mode.
- Audited ISO/XEX extraction bounds, argument handling, DLL lookup policies and
  removal of the automatic original-code dump from project startup.
- Replacement launcher background, logo and M icon. The README now includes
  the project logo, controller status and controller/keyboard tables.

The default controller path is SDL3, with an optional SDK XInput backend.
An **8BitDo Ultimate 2 Wireless** was owner-tested. PS4/PS5 gamepad families
exist in SDL, but they **have not been play-tested in this project**. See
[CONTROLLERS.md](CONTROLLERS.md) for precise status and mapping references.

## Measured scope

| Configuration | Observed result |
| --- | --- |
| Arc B580, Default, 1x/720p, 60 mode, VSync On | About 7 minutes, 57.96 FPS overall including loading/pauses; one-second FPS median 59.99. Save completion and normal exit confirmed. |
| Arc B580, Default, 2x/1440p selected, 60 mode, VSync On | About 14 minutes; 49.37 FPS overall, periods near 60 and lower portions around 40â€“50. No recorded fatal error; **not constant 60 FPS at 1440p**. |
| Ryzen 5 5500U, ROV, native scale, Original, VSync Off | Previous/candidate comparison both around 19 FPS in slow portions. An earlier enabled-60 run also did not sustain 60. |

The comparison did not show a large new slowdown in Original, but is not a
controlled CPU/GPU benchmark or proof of absolute equivalence. Metrics count
guest swap intervals rather than GPU execution or unique displayed frames.
Private observer and standalone helper tests are distinguished from owner
production play-tests in the build evidence and [PLAYTEST_VALIDATION.md](PLAYTEST_VALIDATION.md).

## Install and update

1. Extract **Majin-Recompile-v0.1.0-alpha.2-Windows-x64.zip** completely to a
   short, writable local SSD folder, such as `C:\Games\Majin`.
2. Open **Majin FK Launcher.exe**; no manual terminal command is needed.
3. Import your own supported uncompressed ISO, or Browse to extracted data.
4. Start with native 720p / Original / Default. Use ROV when needed for image
   compatibility. Select **60 FPS (test)** to try the timing option.
5. Back up `private/runtime/user` before replacing another installation. This
   portable Alpha has no automatic migration or installer/uninstaller.

If required, install the Microsoft Visual C++ x64 runtime. Your own ISO, game
data, DLC, saves, settings and shader caches are **not** bundled. A private USB
test kit is not a redistributable download. The replacement visual assets are
documented separately from the GPL code license.

## Known issues and remaining validation

- Menu-edge stretching, noisy rain/particles and shader stutters remain.
- Default can lose the image on some integrated GPUs; ROV can help but costs
  performance. ROV is a compatibility option, not a low-end speed preset.
- Some notebook cutscenes showed A/V/legend drift and perceived input latency.
  Full cinematic timing and full-campaign compatibility remain unverified.
- 2x/1440p is experimental: draw scaling can report an unscaled 1280x720
  resolve/swap source. It is not proof of native 1440p through every stage.
- Internal 1080p is unsupported; 4K, all controller models/actions, Linux/Vulkan
  and DLC import remain unvalidated or unimplemented.
- Earlier cache startup crashes and deep paths remain documented; short paths
  are a precaution, not a proven universal fix.
- No multi-hour whole-game AddressSanitizer run or hostile-input sandbox
  guarantee is claimed. See [SECURITY_AUDIT.md](SECURITY_AUDIT.md).

## Diagnostics, source and attribution

After closing the game, **Collect Diagnostics.cmd** creates a local ZIP in
`reports`. It excludes ISO/game data/saves/cache contents and does not upload.
The active GPU is in runtime logs; extra hardware details are opt-in. Review
the export before sharing it.

The matching **Sources.zip** includes project source, the corresponding patched
SDK and pinned dependencies; GitHub's automatic source archives contain the
project only. `SHA256SUMS.txt` records supplied asset hashes. Executables are
unsigned. Project code is **GPL-3.0-only**, with upstream notices preserved.

Development involved extensive **ChatGPT / OpenAI Codex** assistance, guided
and play-tested by the project owner. See [AI_USAGE.md](AI_USAGE.md),
[COPYRIGHT.md](COPYRIGHT.md) and [THIRD_PARTY.md](THIRD_PARTY.md).

## Repository/publication status

This update is being prepared in the existing private repository. The previous
Alpha and historical commits contain the old launcher artwork. Current Alpha.2
inputs use the replacements; this does not remove historical copies. Review
the audit's publication section before changing repository visibility. Preparing
this version is not a claim that the old history received legal clearance.
