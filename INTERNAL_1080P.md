# Internal 1080p investigation — September 14, 2026

Status: investigation only; 1080p internal rendering is NOT implemented or exposed.

## Recovery point

private/backups/before-1080p-20260914-155758 contains 477 files (330739846 bytes), each checked against its source with SHA-256. MANIFEST.csv lists the contents and hashes.

Includes Git history, current scripts/patches/docs/art, prototype sources/generated code, runnable Debug executable and DLLs, launcher configuration, user saves and runtime metadata. This is a local recovery snapshot, not a standalone distribution. It intentionally excludes the original game-data folder, downloaded toolchains, build intermediates and caches; these remain in place and must be retained. Do not delete the current project on the assumption that this snapshot is a full disk backup.

Restore only with the game closed, and preserve newer saves separately before copying any saved user data back. Restore selected files to the same relative paths; never overwrite the whole private directory.

## Findings in pinned ReXGlue v0.10.0

- src/graphics/pipeline/texture/cache.cpp: resolution_scale is int32; GetConfigDrawResolutionScale returns uint32 axes.
- include/rex/graphics/pipeline/render_target/cache.h: scale axes are packed into 3-bit fields in HostDepthStoreRenderTargetConstant.
- src/graphics/d3d12/texture_cache.cpp: texture loading packs integer scale into constants and uses it for mip dimensions and scaled memory allocation.
- src/graphics/pipeline/shader/dxbc_translator.cpp: generated shaders use integer shifts and pixel-position correction derived from the scale.
- src/graphics/shaders/resolve_downscale.cs.hlsl: scaled resolve storage assumes one scale_x * scale_y block per original pixel. At 1.5x this would be 2.25 samples, so changing CVar type alone cannot preserve this layout.
- src/graphics/util/draw.cpp and D3D12 render-target cache couple viewport/scissor coordinates with resolve addressing.

Thus a float launcher value would be insufficient. Rendering at 1440p and shrinking to 1080p is also not the requested 1080p internal mode or its expected workload.

## Proposed implementation sequence

1. Choose and prototype a fractional resolve-storage mapping, with explicit integer rounding at boundaries and matching CPU/shader addressing. Check tiled and odd-sized surfaces, subrectangles, depth and mip levels. Do not change the stable integer path.
2. Integrate the mapping into D3D12 render targets, texture loads/resolves and shader translation. Preserve native guest memory layout and readback behavior. Regenerate affected shader bytecode.
3. Add a separate experimental 3/2 setting only after resource extents and addressing work together; ensure shader cache keys distinguish the new mode.
4. Build the GPU plugin from pinned source and preserve its patch in the build workflow (the existing audio integration only builds rexruntime).
5. Verify with GPU evidence that the principal scene target is 1920x1080, then test HUD, FXAA, depth effects, movies, saves and scene transitions. Compare 720p/1440p regressions.
6. Expose 1080p in the launcher and migrate saved selection by value, not SelectedIndex, so inserting a choice does not silently change existing 1440p/4K settings.

Open design work: mapping fractional samples to the Xbox tiled resolve representation. Stable runtime binaries remain unchanged. The isolated experiment uses its own executable and diagnostic GPU DLL.

## Engine-level alternative under investigation

A guarded startup-size probe is now implemented separately in experiments/1080p. It changes the two initialization pairs to 1920x1080 at GPU scale 1. This is a potentially smaller path than fractional SDK storage; actual target sizes and compatibility are unverified. See experiments/1080p/README.md. Normal builds keep MAJIN_1080P_STARTUP_PROBE=OFF.

## Failed user test — September 14, 2026

User tested the isolated startup probe: menu particles/glow visible but menu content missing; gameplay continues with sound and controller input, while scene rendering is black. This probe is NOT usable 1080p support.

runtime-20260914-162543.log confirms the startup hook applied at 16:25:45.085. The session ended through window close. GPU warnings include invalid texture fetch descriptors (9900, 5812 and 1726 repetitions for three descriptors). Similar warning classes predate this experiment; their presence alone does not establish the cause. No scene target/viewport/resolve size instrumentation was present, so the failing stage remains unidentified.

Do not promote this probe to the launcher or replace the stable build. Next investigation must trace actual scene target extents, depth, viewport/scissor and resolve source/destination sizes, comparing an unchanged baseline against the probe. Mixed hardcoded dimensions are a hypothesis, not a confirmed diagnosis. Avoid globally replacing 1280/720 constants or accepting invalid descriptors without evidence.
## Baseline comparison — 22:01 / 22:02, September 14

Compared resolution-baseline-20260914-220135.log with resolution-probe-20260914-220229.log.

| Stage | Baseline | Probe |
|---|---|---|
| Swap packet / guest texture / host texture | 1280x720 | 1920x1080 |
| Half-size viewport | 640x360 | 960x540 |
| Quarter-size viewport | 320x180 | 480x270 |
| Eighth-size viewport | 160x90 | 240x135 |
| Selected cinematic viewport | 1280x720 | 1920x1080 |
| Its scissor | 0,80,1280,625 | 0,80,1280,544 then 0,0,1280,81 |

Probe resolves include 1920x544 and 1920x536 (sum of heights 1080), then full 1920x1080 resolves. This is evidence of changed tiling, not proof of a broken tiling implementation. Predicated packets and bin masks exist in command_processor.cpp, so do not claim they are unsupported.

Confirmed: engine-size configuration propagates to swap and multiple effect dimensions. A 1920x1080 swap texture alone does not prove complete scene rendering at that resolution. Fixed 1280-wide clipping persists on at least one path, requiring game-side investigation. The exact cause of the missing scene/menu is not established by these logs.

No target-allocation messages were emitted from CreateRenderTarget in either trace; do not infer missing targets from this absence, since that instrumentation covers only the host-render-target allocation path.

Next: identify the game-side scissor/cinematic bounds and trace draw/resolve behavior across the two tiles. Do not widen every GPU scissor globally: many are intentionally subrectangles, clears or shadow maps. No additional user rerun is useful until the diagnostic or implementation changes.

## Game-side rectangle investigation / second diagnostic build

Static analysis identified the following original routines:
- 829E1208 initializes context limits (16-bit fields +664/+666) to 1280/720.
- 829E0ED0 scales a signed-16-bit rectangle using float fields +672/+676 and clamps it to those limits.
- 829E1628 computes the scale as output dimensions (+656/+660) divided by logical dimensions (+648/+652).
- 829E45C8 updates the global context output dimensions and limits; 829E1088 does the same for an individual context. Thus the constructor constants alone are not proof of stale runtime limits.
- 829DB7E8 forwards a rectangle to 8246BB30, which intersects it with the current device viewport and encodes the scissor registers.

Added read-only hooks in game_trace.cpp for rectangle input/output, context dimensions and device scissor callers (maximum 256 unique messages). Added bounded GPU packet-predicate logging for bin selection/mask/pass state. These diagnostics do not alter rectangle coordinates or force discarded draws to execute.

Both test modes now use the same instrumented executable. Baseline sets MAJIN_1080P_STARTUP=0 and calls the original startup unchanged; probe sets it to 1 and applies the existing guarded size change. This is a diagnostic baseline, not the normal launcher binary. The runner restores both environment variables after exit. No blanket scissor correction is applied.

Double-click scripts/test-resolution-720p.cmd, then scripts/test-resolution-1080p.cmd; close the first before starting the second. Reproduce the same menu/start/load sequence in both. Logs are still reports/resolution-baseline-* and resolution-probe-*. Saves remain under private/runtime-1080p-probe.

This build is awaiting runtime comparison. It is not a fix for the missing scene and must not be promoted to the launcher. The additional evidence is needed to distinguish a game-coordinate issue from commands discarded during tiled rendering.
## September 15: diagnostic results and logical-coordinate candidate

Logs resolution-baseline-20260914-223515.log and resolution-probe-20260914-224018.log show that the main context limits DO update to 1920x1080. The constructor clamp is therefore not the explanation. However, authored rectangles such as (0,80,1280,625) arrive unchanged while logical and output dimensions are both 1920x1080 and scale remains 1.0. Baseline receives the same rectangle with 1280x720 logical/output dimensions.

Bin predicates select first-tile bits 0x3 and second-tile bits 0xC. The captured pass/fail combinations agree with bitwise intersection. These records do not establish that all drawing/resolve stages are correct, but do not justify bypassing predication.

A guarded experimental wrapper around 829E1628 now restores 1280x720 logical dimensions only for the four traced main contexts (82BE0A40, 82BE0E70, 82BE12A0, 82BE16D0), and only when current logical/output dimensions and limits all match the 1080p probe. Output remains 1920x1080. The original function computes scaling and projection. Baseline mode bypasses this change. MAJIN_1080P_LOGICAL=0 disables the candidate for diagnosis.

This is a candidate correction, not confirmed restoration of scene rendering. It is not fractional SDK scaling and does not widen all GPU scissors. Re-test the 1080p runner; inspect scale_bits=3FC00000 (1.5) and UI/scene results. A remaining tile/resolve fault may still require separate work.

Previous experimental source and executable saved to private/backups/1080p-before-logical-20260915-080705. Stable executable SHA-256 remains 45F6FD55605992A61D3DEAF4AAEAB7A08667BE2D47A05EECA00804A4BA5025BF.
## September 15, 08:12: logical-coordinate candidate failed visually

User screenshot and resolution-probe-20260915-081204.log confirm the scene and text remain missing. The candidate did execute: scale_bits=3FC00000 on both axes, and the cinematic rectangle changed from (0,80,1280,625) to (0,120,1920,937). Therefore fixing this rectangle scaling is insufficient to restore rendering. Do not describe this candidate as a working correction or promote it.

Some later context logs contain logical=1920x1080 while cached scale=1.5, indicating other code overwrites or copies context fields after the guarded update. This also means the wrapper is not a complete engine-resolution implementation.

The current trace records CPU configuration and selected GPU command decisions, not rendered color/depth contents or every IssueDraw early-return reason. It cannot establish where the main scene becomes empty. Next useful diagnosis needs per-stage draw outcomes / texture bindings and intermediate render-target contents, preferably a GPU frame capture; another unchanged user run adds no evidence. Do not bypass invalid fetch descriptors or bin predicates without identifying the failing draw.

Stable launcher/build are unaffected. The 1080p experiment remains failed and isolated.