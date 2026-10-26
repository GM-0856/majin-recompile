# Current Windows Alpha priorities — October 25, 2026

The owner chose to prepare **v0.1.0-alpha.2** after the recorded Arc sessions
and final notebook comparison. The current runtime is an experimental Alpha,
with Original as default and 60 FPS as an opt-in test. ROV remains a graphics
compatibility choice. No stable/universal 60 FPS or end-to-end native 1440p
claim follows from the limited tests.

1. Update the existing private GitHub repository and versioned Windows/source
   archives after the scoped security/privacy/package audit. Preserve the
   supported European/PAL requirement and honest controller/input status.
2. For public visibility, explicitly resolve old artwork in Alpha.1/history or
   choose a clean publication repository. Earlier references to a public repo
   below are historical; the current GitHub API reports the repository private.
3. Collect community reports on checkpoints, cinematic A/V, frame pacing and
   GPU/controller compatibility. The current owner's notebook test round is
   concluded; its Original-mode A/B did not show a large new slowdown.
4. Post-Alpha: keyboard glyphs/remapping, wider input/campaign coverage, then
   DLC import and Linux/Vulkan. Internal 1080p remains deferred; 4K unvalidated.

Read README.md, RELEASE_NOTES.md, PLAYTEST_VALIDATION.md and SECURITY_AUDIT.md
for the current state. Dated milestones below remain as history.

---

# Roadmap

Updated October 2, 2026. Planned features are not availability promises.

1. **Saves â€” validated on the tested route.** False write-failure result corrected. Save completion and reload after restarting confirmed. Continue slot/checkpoint regression checks.
2. **Audio/video/performance â€” music interruption fixed on tested paths.** A guarded XMA recovery preserves the input buffer when an empty packet is followed by a valid frame. The user confirmed uninterrupted Caprakan battle music and corrected menu music, then reported the follow-up test succeeded. Full-campaign audio compatibility and menu-demo video synchronization remain unverified. Performance profiling and optimized builds remain open. The source patch and boundary tests are now preserved under patches/rexglue-0.10.0. The normal build prepares the pinned SDK, runs the recovery tests and installs the patched runtime after the game build. Debug build and deployed DLL hash verified locally; clean-machine validation remains pending.
3. **Everyday use â€” implemented.** Desktop shortcut, launcher and Escape confirmation. Further focus/shutdown testing and automatic pause remain possible improvements.
4. **Display/controls â€” initial implementation tested.** Persistent launcher, window/fullscreen, FXAA, VSync and integer scales. Customized panoramic background and fantasy-style title validated by the user. 720p/1440p tested; validate 4K. Internal 1080p work is paused after failed isolated experiments; it is not supported. September 14: recovery snapshot verified; integer-only GPU storage/shader constraints mapped in INTERNAL_1080P.md. 1080p is not implemented yet. Experimental keyboard/mouse profile now selectable in the launcher, with sensitivity and a command reference. Launcher and launch arguments checked; the user confirmed initial keyboard/mouse gameplay works. Full command coverage, camera feel and focus handling remain to be validated. Original Xbox prompts remain; see KEYBOARD_MOUSE.md.
5. **Frame rates â€” research.** Investigate 30/60/120 FPS without accelerating simulation, cutscenes or audio. Offer only validated modes.
6. **Distribution/community â€” in progress.** Document setup, AI assistance and limitations; audit licenses and package contents, validate clean checkout, then develop own-data import and standalone packaging. Investigate languages and DLC separately.
7. **Linux/Vulkan â€” planned.** Validate backend and dependencies, port the Windows launcher/platform integration and test saves/input. Existing presets are not evidence of support.

Campaign testing continues alongside development. Preserve checkpoints and report build revision, area and reproduction steps. No release date or full-campaign compatibility claim yet.

## Active priorities toward an alpha

1. Consolidate the tested Windows build, synchronize public documentation and preserve recovery points. Keep failed 1080p experiments opt-in and out of alpha packages.
2. Validate relocation with no existing settings/cache, then a clean source build and a separate Windows machine. These are three distinct checks; see CLEAN_INSTALL.md.
3. Extracted game-data folder selection, validation and persistence implemented; automated configuration/launch-argument tests passed. The user validated folder selection. Initial ISO identification/import is implemented for the supported revision, with region-mask display and isolated extraction; see ISO_IMPORT.md. Gameplay from the imported folder remains to be validated. DLC support requires its own investigation.
4. GPL-3.0-only is confirmed. Finish final candidate testing and source/binary distribution review, then publish both versioned archives with instructions and useful logs. Do not ship original game data or personal saves.
5. Finish keyboard/mouse command, camera, menu and focus testing; investigate in-game keyboard glyphs afterward.
6. Profile performance and revisit menu-demo synchronization, untested 4K, frame-rate modes, Linux/Vulkan and internal 1080p.

Campaign testing continues in parallel. The owner selected GPL-3.0 for project-authored code on October 2; LICENSE and COPYRIGHT.md define GPL-3.0-only scope. Dependency/source review remains separate.

September 15 package milestone: user validated supported ISO import/startup/save loading. Local-only ZIP built and relocated outside the repository; manifest, launcher, helper and DLL-load checks passed. Debug CRT dependencies discovered: a separately validated Release build is required before public packaging. Relocated gameplay, clean-machine testing and licensing remain open. See LOCAL_PACKAGE.md.


Release follow-up: user validated the relocated Debug package including save/reload. A separate Release candidate now compiles with the XMA fix; static imports have no Debug CRT dependencies. Relocated package checks pass on the development PC. Optimized-build gameplay/audio and clean-machine validation are pending; this remains a local test, not a public release.


## October 2: alpha preparation and notebook compatibility

Release gameplay/save/reload and supported ISO import have been validated by the tester on the development PC. On the Ryzen 5 5500U notebook, ROV restored the image on the tested route; cache reuse improved the reported experience. The latest monitored session lasted about 22 minutes, reached a save point and ended normally. GPU usage was predominantly 95-99%; FPS and frametime counters did not directly agree. Cutscene audio/video synchronization and perceived input latency remain unresolved. ROV Compatibility is now selectable in the launcher with a persistent separate cache; it remains optional and is not a universal default. Updated-launcher gameplay was subsequently reported successful on the development PC; exact candidate notebook follow-up is recorded below.

The immediate work is the release checklist in [ALPHA_RELEASE.md](ALPHA_RELEASE.md): launcher compatibility selection with reusable caches, packaging the painting fix, source/build reconciliation, license/dependency review, and exact-package separate-machine regression tests. Earlier milestone notes are historical; do not treat the notebook as fully validated or publish the old USB installer as the alpha.

## Release candidate v0.1.0-alpha.1

October 2: the owner deferred cosmetic menu-edge/rain investigation to prioritise a community alpha. Native 720p without FXAA and ROV Compatibility reproduce the menu smear; forced RTV fails on the Arc B580 and is excluded. The corrected bounded logger was validated in a game session. Draft release notes, bug-report template and a diagnostic collector are prepared. Exact candidate notebook startup and saved-game reload were subsequently reported successful with ROV. Next: remaining fresh-import/upgrade checks, source/build reconciliation and dependency/license review, then GitHub publication. Version naming is approved; publication is not claimed. Preserve known issues in the release notes.

## October 2: candidate notebook and DLC inventory

The owner reports successful ROV testing and restarting into a save from the exact alpha.1 ZIP copied to USB. Default still loses the image on the notebook. The supplied videos show the launcher and rendered scenes/menu; this is a limited route check, not campaign or full-cutscene certification. See ALPHA_RELEASE.md for the archive identity and remaining gates.

Read-only inspection identified one local `Special Challenge Pack` STFS/LIVE container, Title ID `4E4D0816`, containing 30 PAK files under three resource groups. A Portuguese package display name does not establish Portuguese dubbing. The local folder named Portuguese contains scanned manual/cover JPGs. Game audio has several language suffixes, including `_po`, whose language mapping and voice content remain unconfirmed. Next DLC work: separate own-file import, identity/bounds validation, isolated content storage and runtime enumeration, then in-game/save regression tests. No DLC implementation or bundled DLC is claimed; see DLC_INVESTIGATION.md.

## October 2: clean alpha source build

GPL-3.0-only confirmed; project notices and dependency license inventory committed. Clean Release game/runtime/GPU compilation succeeded in a separate checkout. Generated functions match the tested code; binary hashes differ. A distinct clean-source candidate and corresponding source companion are the next test artifacts. Final candidate gameplay/save/reload on Arc B580 and Ryzen 5 5500U ROV, exact-package fresh import and upgrade/data-preservation checks still precede publication. The current tested installation remains unchanged.

## October 22: public alpha.1 authorized

The owner authorized GitHub/public alpha publication and declined another latest-save reload check. The clean-candidate 5500U ROV session ran about 34 minutes, completed an observed save write and ended normally; latest reload remains unverified. European/PAL ISO tested, American/USA and Japanese editions not tested. Preserve those runtime binaries, ship a short ZIP wrapper, assisted diagnostics and matching SDK/dependency source, and disclose all known issues. Post-alpha priorities: path/cache failure handling, wider hardware/campaign/input testing, then DLC, Linux/Vulkan and paused internal-1080p work. See PLAYTEST_VALIDATION.md.

Public release completed October 22: repository visibility is public and v0.1.0-alpha.1 is published as a GitHub pre-release. Anonymous downloads and SHA-256 hashes of Windows/source/checksum/validation assets passed. European/PAL ISO validation, American/USA untested status and remaining known issues are explicit in the README/release notes. Latest notebook save reload remains an accepted unverified check, not a passed test.

## October 23: keyboard controls confirmed; glyphs after Alpha

The owner confirmed Shift running, E item collection/interaction, Tab map and
Enter pause in the locally patched Release candidate. The follow-up session
reused its shader/pipeline cache, completed a save write and ended normally;
see PLAYTEST_VALIDATION.md. Full command/focus/campaign coverage remains open.
In-game keyboard/mouse glyph investigation is explicitly deferred until after
the Alpha release. First locate the original prompt rendering and input source
selection, then assess replacement or an overlay; no implementation is promised.

## Optional 60 FPS candidate — October 23

- Implemented an opt-in host cap and the verified title idle counter correction.
- Preserve the original engine/audio clocks; the rejected time-path override is excluded.
- Complete broad gameplay, cinematic A/V and second-machine checks before promoting 60 FPS as stable. See FPS_60.md.
