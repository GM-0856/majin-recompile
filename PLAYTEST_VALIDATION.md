# Alpha.1 validation record

Updated October 22, 2026. This describes limited evidence and accepted gaps, not a hardware certification or full-campaign guarantee.

## Disc and platforms

European/PAL Xbox 360 ISO tested. **American/USA and Japanese editions have not been tested.** Executable: Title ID 4E4D0816, Media ID 67BD87EF, version 0.0.0.3, SHA-256 660CAE389F0A45100739F935472437D282B2568FCFC2C60FC5A9B2B7B48CE1EC. Matching region permissions are not a retail-edition guarantee.

| Environment | Evidence | Limits |
| --- | --- | --- |
| Intel Arc B580 development PC | Default; internal 720p/1440p; combat/checkpoint/save/reload reports on earlier Release packages | No full campaign or exact-final-repack gameplay claim |
| Ryzen 5 5500U, Windows 11, Radeon driver 31.0.12042.4 | October 22 clean-candidate session; ROV; internal 720p; windowed 1280x720; Original AA; VSync | Default black-image history; reduced performance, stutters, latency and A/V drift |

## October 22 successful clean-candidate session

The owner's report is corroborated by runtime-20261022-220306.log: the session name through final timestamp spans about 34 minutes. The original log was 3,247,871 bytes; the collector retained its final 2 MiB, so the missing startup segment cannot be certified error-free. At 22:37:05 a write completed with status 0 and 40928/40928 bytes; at 22:37:21 the log records window closure, execution complete and process termination. No error/critical severity records appear in the collected tail.

Earlier October 22 sessions show cache reuse (25 shaders and 20 pipelines in one run) and window-driven shutdown. Windows also recorded an earlier transient hang. October 17 crashes ended near shader storage initialization; a pipeline-cache filename in the old nested installation reached approximately 282 characters. Path length remains a hypothesis because other conditions, including fullscreen/windowed mode and location, changed too.

## Runtime identity / corresponding source

The privacy-cleaned public repack has the following hashes. Equal-length source-path strings in read-only diagnostic data were replaced with neutral virtual paths; all executable sections and every byte outside the listed string ranges are identical to the play-tested clean candidate. BINARY-PRIVACY.json records the input/output hashes and changed ranges. The source companion includes the deterministic postprocessing script.

| File | SHA-256 |
| --- | --- |
| majin.exe | D5B33A188A873AB66C9815FF28D1272381FD45547E3E7BFE3D0251CA7F33A990 |
| rexruntime.dll | 7E2316EADD991609FD4D1BC8B1C6E374B6F1097F12D73EEF430EFC0EDD456B2A |
| rexgpu-xenos.dll | 23DA3EC329211B2FCF8F37C3BAE636C5018F9E523ED5AF834E298AED29DFCADC |

Compiled project inputs: 71c8053d0e720451ce699e7da2cd8ad23b72b0e6. SDK: f5337cdc947ff6d4c4196737e2c807a48f2a1fc2. BUILD-EVIDENCE.json identifies the pinned dependencies and clean build; its pending-gameplay fields describe that earlier build-time snapshot. This document records subsequent play-testing. Packaging-only source commits do not alter prototype inputs. Fresh code generation matched all 34,068 function bodies by name despite different partition/order. Runtime/GPU built from the included pinned source; XMA and bounded-logging tests passed. This is not bit-for-bit reproducibility of the older development binaries.

## Disclosed gaps accepted for the public pre-release

The owner authorized public release on October 22 and explicitly declined another reopen/load test. The latest notebook save was written, but loading it after restart is not verified. Earlier packages had save/reload reports; those are distinct evidence. The final public ZIP changes wrapper naming, docs, diagnostic tooling and embedded diagnostic source paths; no further gameplay rerun of that repack is claimed. Automated DLL loading, launcher checks and binary byte-range comparisons validate the privacy postprocessing separately.

Full-campaign compatibility, complete cutscene synchronization, 4K, all input actions, other retail editions and upgrade/uninstall preservation are not certified. The portable package has no installer/uninstaller; users must preserve their own private/runtime/user folder. These limits remain in the release notes and are not silently marked passed.

## October 23: current security candidate on Intel Arc B580

The owner reports successful gameplay with stutters. The complete runtime log
spans about 3 minutes 38 seconds: Release, Default, 1920x1080 fullscreen output,
scale 2 (configured internal-1440p target), FXAA and VSync. The three loaded runtime
binary fingerprints match the candidate record. No error/critical/fatal severity
records were found; a 40928/40928-byte save write completed with status 0, followed
by window closure and Execution complete. Fresh-save reload and full audio/campaign
validation are not established by that one session.

The settings record CacheFilesBefore=0 in the Release/Default/scale-2 profile.
Previously copied Debug/legacy caches were in other directories. A separate short
windowed startup using copies of the newly populated cache reused 200 shaders
and recreated 202 graphics pipelines from cached descriptions, with preload
times of 18 ms and 579 ms respectively. It closed normally, without
error-severity records; active saves/cache/settings were unchanged. This is a cache
startup test, not gameplay frametime data. Changing output dimensions alone keeps
the cache profile; changing internal scale selects another profile.

Cold-cache compilation is a plausible contributor, not a proven sole cause of
stutters. No per-frame timing was captured, so the same route/settings with an
already populated cache remains the relevant follow-up. Known texture-fetch/
unscaled-resolve warnings and two XMA recovery events do not establish causation.
No performance fix or rendering-path change is claimed from this investigation.

## October 23: Shift controls follow-up

The owner confirmed that Shift runs, E collects items and interacts, Tab opens
the map, and Enter opens pause in the locally patched Release candidate.
The complete follow-up log covers approximately 4 minutes 33 seconds on the
Arc B580: Default, 1920x1080 fullscreen output, scale 2, FXAA and VSync.
It records 621 info and 89 warning messages, with no error/critical/fatal
severity records. A 40928/40928-byte save write completed with status 0,
followed by window closure, Execution complete and process termination.
Individual key presses are not logged; input behavior is owner-confirmed.

The existing cache loaded 200 shaders in 13 ms and recreated 202 graphics
pipelines from cached descriptions in 478 ms. Existing texture-fetch and
unscaled-resolve warnings remain; the bounded texture-warning summary reports
152642 occurrences, with 152597 suppressed. Three guarded XMA recovery events
were recorded. No per-frame timing or complete audio/cutscene validation is
available from this session. No rendering/audio changes were made for this review.
The previously generated ZIP has not been replaced by this local controls patch.

## October 23: local performance diagnostic candidate

The updated game connects the SDK CSV writer before GPU startup. A small pinned
SDK patch enables opt-out guest swap timing in Release without changing render,
texture or shader logic. The audio runtime is unchanged. Synthetic metric/privacy
checks passed (52). Isolated Arc B580 startup/menu tests recorded 510 intervals in
Default, no CSV with recording disabled, and 444 intervals in ROV. All three ended
normally without error/critical log records; active saves/caches stayed unchanged.
These are collection smoke tests, not gameplay benchmarks. Radeon/NVIDIA, full
gameplay/save/reload and long-duration capture remain unverified for these binaries.
Hardware inventory is optional and off by default; see PERFORMANCE_DIAGNOSTICS.md.
The earlier release ZIP and its corresponding source archive remain frozen.

## October 23: window frame and title FPS

The latest owner sessions were launched from the project copy, where new scripts
were present alongside an older Release executable. Their summaries have no frame
CSV or valid FPS samples; no gameplay rate can be inferred retrospectively. The
follow-up updates both that Release path and the separate candidate. It also makes
the ordinary launcher default to Release instead of silently selecting Debug.

On the 1360x768 display, a requested 1920x1080 window fitted to a 1182x665 client
within the usable desktop area, with normal caption/minimize/maximize/close and
resizing flags. Native minimize/maximize/restore and normal close passed. Separate
windowed runs with CSV off/on showed numeric FPS in the title; a fullscreen run
had no FPS title. CSV-enabled startup tests captured 205 and 218 intervals.
54 window-layout/live-rate helper checks passed. These short startup/menu runs
validate the window/counter behavior, not the owner's gameplay performance.

## October 23 — optional 60 FPS candidate, automated laboratory

The authored timing hooks were compiled into a Release candidate with the normal
engine time path preserved. Private observer siblings supplied game-only readback
and input for route checks; that instrumentation is absent from production.
Supported PAL data, copied saves and separate caches were used on Arc B580.
Original-rate and 60 FPS routes exercised movement, jump, attack, roll, pause and
map. A copied save completed a 40,928-byte write; closing/reopening loaded the
updated slot. Pure timer checks retain approximately 29 seconds of title idle
at 30/45/60/120 updates per second. Native idle/demo and exact production startup
results are recorded separately in candidate build evidence.

The rejected fixed/variable-time flag mutation caused black scenery and is not
in the final source. Existing 30 FPS movies, graphics artifacts and first-shader
stutters must not be relabeled fixed. Full campaign, cinematic A/V, input latency,
ROV/notebook and other GPU-vendor checks remain open for this new timing mode.
This is an opt-in candidate, not a stable high-FPS release certification.

## October 24: owner Arc session and notebook comparison

The owner reported a successful controller session in the isolated 1cc742d
60 FPS candidate on Intel Arc B580. The session recorded 425.62 seconds with
57.96 guest swaps/s overall, including loading/pauses/stalls. The median of
one-second FPS windows was 59.99; frame P95/P99 were 18.55/19.87 ms and the
maximum interval was 1,707.95 ms. Release, Default, 1x/720p internal, windowed
1280x720 and VSync On were selected. The runtime confirmed the 120 Hz guest
vblank signal and 60 swap/s cap. A 40,928-byte save completed, followed by normal
shutdown. No error/critical/fatal records were reported. Existing sampled and
suppressed invalid-texture warnings remained; this is not a graphics-fix claim.
This limited session does not certify full-campaign timing, cinematic A/V or
multi-hour stability. The metrics measure guest swap cadence, not GPU execution
or unique displayed frames. Prerecorded movies retain their original cadence.

On the Ryzen 5 5500U notebook, the owner compared preserved pre-60-FPS binaries
(reference ea634d9) against the 1cc742d candidate, BOTH in Original mode.
The shared settings were Release, ROV, 1x/720p internal, VSync Off, windowed
1920x1080 requested (1663x935 effective client), Original AA and controller.
The preparation tool copied the same saves and local caches into two separate
installations; native hashes and identical settings were verified from each
diagnostic. Audio runtime was identical; only game/GPU binaries differed.
The one-second FPS medians were 19.41 (previous) and 19.35 (candidate). In the
same elapsed-time range of 60-180 seconds, weighted guest swap rates were
19.04 and 18.82 FPS. Frame P95 for the whole sessions was 58.35/61.55 ms.
Both exited normally with no error/critical/fatal records and reused
168 shaders / 166 pipelines. Attached Windows crash events were historical.

The owner confirmed the >100 FPS periods were menus; gameplay fell to about
18 FPS. Menu-inclusive averages of 27.90/30.57 FPS are not gameplay averages.
Durations/routes are not guaranteed identical and there was no final A repeat
or CPU/GPU/thermal profile. The comparison shows the sustained low rate also
exists in the previous build; it does not establish absolute performance
equivalence or identify a hardware/rendering bottleneck. Both runs being in
Original, this A/B does not certify 60 FPS performance on the notebook. An
earlier enabled-60 notebook session also stayed around 17 FPS in slow portions.

The owner concluded this notebook test round and chose to focus subsequent
60 FPS validation on the main Arc PC. ROV remains a graphics compatibility
option; it is not classified as a low-end performance preset. Original and
the opt-in 60 mode remain separate. No universal 60 FPS guarantee is made.

## October 24: Arc session with 2x scale

The owner subsequently selected a 2560x1440 window and 2x/1440p draw scaling
in the isolated 1cc742d candidate, with Default, 60 FPS mode, VSync On,
Original AA and controller. Effective window client was 2304x1296. The owner
reported enjoyable, smooth playback often near 60 FPS. Settings and active
Intel Arc B580 adapter were confirmed in the runtime diagnostic.

The session recorded 842.04 seconds, 49.37 guest swaps/s overall and a median
of 49.19 FPS over 832 one-second windows. There were 199 windows at 58-62 FPS;
558 were between 40 and less than 58 FPS. Frame P95/P99 were 25.34/27.45 ms,
maximum 741.94 ms. Some sustained portions were around 40-50 FPS. These are
guest swap metrics including loading/pauses, not GPU execution time or unique
displayed frames; scenes are not labeled automatically. The earlier 720p run
used a different route/duration and is not a controlled resolution benchmark.

The process shut down normally with no error/critical/fatal records. Existing
texture warnings were sampled/suppressed (985,143 occurrences, 248 samples);
six XMA recovery events were recorded. There is no new save-write completion
in this log, so no new save/reload or cinematic A/V certification is inferred.
The cap and 120 Hz guest vblank were active; preexisting cache was reused.

The SDK also warned that draw scaling was enabled while the swap source was
an unscaled 1280x720 resolve. Selecting 2x is therefore not evidence of native
1440p throughout every render/presentation stage. The existing experimental
classification remains. No new graphics fix or cause of the FPS limit is claimed.

This supports a roughly 14-minute crash-free owner test with good reported
fluidity, but not constant 60 FPS at 2x/1440p. Subsequent release claims must
retain that distinction. Owner-selected settings were preserved; collection
was local, with extra hardware details disabled and no automatic upload.
