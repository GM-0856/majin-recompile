> Alpha.2 packaging reuses the later owner-tested 1cc742d binaries, not a new
> compilation of the historical candidate below. See BUILD-EVIDENCE.json,
> FPS_60.md and the October 24 entries in PLAYTEST_VALIDATION.md for current
> runtime/input/performance scope. Original is default; 60 remains opt-in.
> The optional 60 FPS candidate is a later build. See FPS_60.md and its own
> BUILD-EVIDENCE.json; the earlier candidate evidence below is historical.

# Windows security candidate â€” October 23, 2026

Status: private test candidate; not promoted to a public release. The existing
Alpha tag/assets and the user's stable installation remain unchanged.

## What was built

- Game source revision: `5440e78834ba2455ab8acf49211b394733c7e06a`.
- Fresh local Git clone; strict ReXGlue v0.10.0 generation from the user's supported
  European/PAL XEX, followed by a full game Release compilation/link.
- Windows x64, Clang 20.1.8, Visual Studio C++/Windows SDK, CMake/Ninja.
- The experimental internal-1080p probe remains OFF.
- Project changes include the app DLL lookup policy and removal of the automatic
  original-code dump. The launcher uses the supplied replacement background/logo
  and generated M icon. The importer includes the audited input bounds changes.
- Runtime/GPU were not rebuilt again: the unchanged pinned SDK/XMA/logging build
  from the previous clean-source validation was reused and hash-verified against
  the privacy-cleaned Alpha. This is not a claim of a new full SDK rebuild.

## Automated evidence

- All 34,068 regenerated PowerPC function bodies match the validated baseline.
- The candidate checkout passed 1,027 synthetic ISO/XEX and real process-argument
  checks. These do not prove every parser or filesystem race safe.
- Game/native launcher import SetDefaultDllDirectories; the game does not contain
  the removed loaded-text.bin filename. This is limited static binary evidence.
- Diagnostic build paths were neutralized with the existing constrained sanitizer;
  executable sections are identical before/after that privacy step.
- The Windows ZIP was extracted to a separate short path and checked for exact
  file counts/hashes, parsed scripts, bounded visual allowlist, compiled importer,
  isolated save path, native launcher rendering and DLL loading on the development
  PC. The original gameplay data was used only as a local validation input.
- Full-history/archive privacy scans passed during candidate packaging. Matching
  project/SDK/dependency sources are prepared separately. No ISO, game data,
  generated game C++, saves, personal settings, logs or caches belong in the ZIPs.
- CandidateOnly build evidence cannot use the public packaging path without the
  explicit candidate flag; the public path rejects it before writing output.

Five existing local save/configuration files were backed up. A separate local test
copy receives copied saves/settings/cache after ZIP extraction; those personal
files are excluded from distribution. Original saves were hash-checked unchanged.

## Manual checks still required

1. On Intel Arc B580, start with Default. Check menu/loading, representative
   gameplay and menu/battle music, then save, close, restart and reload that save.
2. On Ryzen 5 5500U, repeat with ROV Compatibility and verify rendered cutscenes
   and gameplay. Report existing stutters, A/V drift and input latency separately.
3. Confirm the new backdrop/logo/icon on both machines and the exact candidate ZIP.

A first limited Arc gameplay session was subsequently reported by the owner;
its logs confirm a save write and normal close, with reported stutters and an
initially empty cache. Cache reuse passed a separate startup test. See the
October 23 section in PLAYTEST_VALIDATION.md. Fresh-save reload, representative
audio checks and notebook validation of this executable remain pending.
No multi-hour full-game AddressSanitizer run, full campaign, 4K, internal 1080p,
USA/Japanese edition or Linux/Vulkan validation is claimed.
Known menu-edge/rain artifacts remain documented; no fix is asserted for them.

The pinned SDK XEX-constant exception is owner-approved and documented in
SDK_DISTRIBUTION.md. Other publication gates in SECURITY_AUDIT.md remain explicit.
