# Optional 60 FPS test mode

Select **60 FPS (test)** beside VSync in the Windows launcher. **Original**
remains the default and preserves the previous runtime behavior, including its
uncapped behavior with VSync off. The 60 FPS option caps menu and game swaps,
uses a 120 Hz guest vblank signal, and corrects the title menu's frame-counted
attract timer to its original approximately 29-second idle duration.

The engine's existing time calculation, fixed/variable flag, audio timestamps,
game constants and prerecorded movie data are unchanged. Movies may still run
at their original 30 FPS. This is not frame interpolation and cannot guarantee
60 unique displayed frames or 60 FPS on hardware without sufficient headroom.

Start with 720p internal rendering. Default/ROV selection, saves and persistent
shader caches keep their previous paths. Stutters on first seeing a shader can
remain. Return to Original if a scene, animation or cinematic behaves incorrectly.

### What VSync means in this build

The opt-in mode keeps its 60 swap/s cap and 120 Hz guest vblank signal with
VSync either On or Off. Turning VSync Off does not uncap the 60 FPS mode.
The option still changes some command-processor waits and can affect cadence
and CPU scheduling. In Original mode it also changes guest vblank timing;
Original with VSync Off retains the previous uncapped behavior.

The pinned D3D12 presenter uses Present(0, ...) independently of this option,
with tearing allowed where supported. This setting is therefore not equivalent
to a conventional monitor-synchronized VSync switch and must not be described
as guaranteeing tear-free output. OS composition, display and driver behavior
remain separate. Both On/Off selections are valid tests of the 60 FPS mode.

See the October 24 entry in PLAYTEST_VALIDATION.md for the owner's Arc session
and the notebook Original-mode A/B. The main Arc candidate remains configured
to 60 FPS / Default / VSync On. Notebook/ROV did not sustain the 60 FPS target.

## Validation scope

October 23 development tests used the supported European/PAL revision and an
Intel Arc B580. Automated tests compared copied saves at 30/60 FPS, native title
idle/demo transitions, movement/actions, pause and map. Guest engine delta traces
advanced approximately one simulated second per real second on those routes.
An earlier experiment that forced another engine time path caused black scenery
and was rejected. That flag mutation is absent from the final source.

Input injection and game-only readback were private validation instrumentation;
they are excluded from production. Clean production startup/performance checks
and observer gameplay checks must be recorded separately. Frame CSV measures
guest swap intervals, including loading/pauses, rather than display refresh or
GPU execution. No full campaign, universal-hardware, cutscene A/V, input latency
or multi-hour full-game sanitizer certification is claimed. This mode is still
an opt-in candidate pending broader play-testing, not a stable public release.

## Build and review

`prototype/src/timing.cpp` contains authored wrappers around the original PAL
functions; no generated game function bodies are distributed. The SDK change is
`patches/rexglue-0.10.0/fps60.patch`, applied after the Release frame-counter patch.
The build verifies normalized hashes of both modified graphics source files and
rejects unrelated graphics edits. The source companion includes both modified
SDK files and the host deadline helper.

Run `scripts/test-frame-timing.ps1` for boundary tests, optionally with
`-AddressSanitizer`. This covers the standalone helpers only. Run
`scripts/test-frame-rate.ps1` with locally supplied supported game data to check
launcher flags, cache/save paths and invalid options without launching the game.

The final authored timing code passed an instrumented route/save/restart/reload
cycle on copied data. The save path reported all 40,928 bytes written and displayed
Save complete; the next process loaded that updated slot. Original saves were
kept separate. In the 105-second route test, the boot/loading-inclusive average
was 58.58 guest swaps/s, P95 18.43 ms, P99 19.76 ms, maximum 901.20 ms. The median
of the final 15 one-second windows was 60.02 FPS (59.86–60.16). Readback adds
overhead; the long loading interval is retained, not discarded as an outlier.

The launcher also detects older native binaries. Original remains usable without
passing the new unsupported flag; the 60 FPS choice is disabled for those older
files. Open the separate matching candidate to test the new mode. Capability
detection is not an integrity/authenticity check; use the published package hashes.
