# Alpha source and rebuild materials

The independent public snapshot maps the unchanged compiled project inputs to its
new Git revision. BUILD-EVIDENCE.json retains OriginalBuildGameSourceRevision and
the byte-for-byte comparison in PublicSourceSnapshot; GameSourceRevision identifies
the equivalent public source snapshot used by packaging checks. This mapping does
not mean the native binaries were recompiled. See PUBLICATION.md.


BUILD-EVIDENCE.json identifies the compiled game-source revision, pinned SDK/dependency revisions, compiler, configuration and exact binary hashes. Alpha.2 reuses the owner-tested 1cc742d game/GPU/audio bytes; documentation and packaging may have a later project revision without changing those compiled inputs. The matching source companion contains the corresponding patched SDK. This is not a claim of bit-for-bit reproducibility: game code generation can partition identical functions differently between translation units.

Publish the matching source companion ZIP and its SHA256 beside the binary ZIP. The companion contains Project (original project code, manifests, patches and notices) and ReXGlue (the patched SDK source and all 14 pinned dependencies used for this Windows build). SOURCE-INVENTORY.json fingerprints each source file. SDK headers/sources with embedded notices retain those notices. Windows libmspack symlink placeholders are materialized within that dependency. No game-derived generated source, original executable, ISO, DLC, saves, caches, compiler binaries or Microsoft system runtime is supplied.

## Rebuild the runtime and SDK

Use Windows x64, Visual Studio 2022 C++ tools plus Windows SDK, Clang 20.1.8, CMake 3.25+ and Ninja. Start a Visual Studio x64 developer shell and put the Clang/CMake/Ninja binaries on PATH. The validated environment used Visual Studio developer tools 17.14.40. See BUILD-EVIDENCE.json for actual build identifiers. These are build prerequisites, not the player's minimum system requirements.

From the exported companion root, the ReXGlue sources already include the XMA recovery, bounded-warning/flush, Release frame metrics and optional 60-FPS patches. Do not apply them a second time. To modify LGPL audio/decompression components, edit their source in ReXGlue/thirdparty and rebuild the complete runtime DLL; the game loads that DLL dynamically.

```powershell
Set-Location .\ReXGlue
cmake --preset win-amd64 -DREXGLUE_BUILD_TESTS=OFF
cmake --build out/build/win-amd64 --config Release --parallel 2
cmake --install out/build/win-amd64 --config Release --prefix "../sdk/win-amd64"
Set-Location ..
```

The original Git workflow is also available in Project/scripts/build-patched-runtime.ps1. That script expects a pinned Git checkout and applies the patches itself, whereas the exported source companion is already patched. The CMake preset and FFmpeg overlay/configuration sources are included; this audio build does not enable FFmpeg GPL or nonfree components.

## Rebuild the game executable

Provide your own extracted data from the supported revision at Project/private/game-data; default.xex must have SHA256 660CAE389F0A45100739F935472437D282B2568FCFC2C60FC5A9B2B7B48CE1EC. The project manifest points there. The user-supplied data is only an input and is never part of the source companion.

```powershell
Set-Location .\Project\prototype
$alphaSdk = (Resolve-Path "../../sdk/win-amd64").Path
& "$alphaSdk/bin/rexglue.exe" codegen majin_manifest.toml
cmake --preset win-amd64-release "-DCMAKE_PREFIX_PATH=$alphaSdk" -DMAJIN_1080P_STARTUP_PROBE=OFF
cmake --build --preset win-amd64-release --parallel 2
```

The clean candidate's game code was initially generated and linked with the official ReXGlue v0.10.0 Windows SDK. Its runtime and GPU DLLs were rebuilt from the included pinned sources, then copied beside majin.exe. The independently built code-generation tool and SDK install recipe are checked separately. Using the source-built generator/install for a complete game rebuild is a supported development route, not a promise of identical binary hashes.

After rebuilding or replacing a DLL, test startup, gameplay, battle/menu audio, saving, restart and reload. Use Default on the development Arc B580 first and ROV Compatibility on the Ryzen 5 5500U. Changes can invalidate shader/pipeline caches; preserve saves and the old binary package. See ALPHA_RELEASE.md for remaining public-release gates.

## Remove build paths before distribution

Compiler macros can embed the build user's absolute source paths in Release binaries.
The published binaries undergo a deterministic metadata-only postprocess. It accepts
unsigned x64 PE files with a zero PE checksum, changes only same-length ASCII source
paths in read-only .rdata and refuses any change outside the declared string ranges.
No executable section, import table, image size or layout is changed. The tool writes
new files and BINARY-PRIVACY.json with the before/after hashes and changed ranges.

From the source companion's Project directory, supply a folder containing the three
freshly built runtime files and a new output folder:

```powershell
python scripts/sanitize-release-binaries.py --InputDirectory ./compiled-runtime --OutputDirectory ./public-runtime
python scripts/check-public-privacy.py --Root . --History --Archive ./release.zip
```

Use the sanitized files for distribution. Build evidence records both original
compiled and distributed hashes. This is a privacy step, not a new gameplay patch.
Files with signed/checksummed images or unexpected path storage need a rebuild/review.
The checker also runs inside both packaging scripts and fails on remaining local-user
paths, the current build account name and common credential signatures. Legal upstream
copyright attribution and dummy upstream parser-test paths are retained.

## Build the Windows launcher entry point

The Windows package starts through Majin FK Launcher.exe, a small native Windows
GUI entry point. It opens the PowerShell launcher relative to its own location,
without a console window, and includes the multi-resolution Majin icon. It does
not replace the game executable or rendering runtime. Its C++ runtime is static.

From Project, with Git and the C++/Windows SDK tools available:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-launcher.ps1
```

The default output is private/build/launcher. LAUNCHER-BUILD.json records its
hash and exact source/resource inputs. The background and icon live under
assets/launcher and retain separate artwork scope. The source companion includes
the native launcher sources, replacement background/logo, icon conversion script
and generated M icon source.

## Private candidate packages

When a new game executable has not yet passed gameplay/save/reload validation,
use scripts/package-public-alpha.py with --Candidate and a build record carrying
CandidateOnly=true. Existing source/binary fingerprints and privacy gates still
apply. The resulting filename and manifest identify a private candidate, and
CANDIDATE_NOTES.txt separates new pending checks from historical Alpha tests.
The public packaging path refuses a CandidateOnly record without --Candidate.
This does not publish, upload, promote a candidate or modify the previous release.

## Source-companion exclusions

The Alpha.2 source companion omits the SDK's bundled prebuilt GNU binutils /
Cygwin PPC test toolchain, two precompiled GLFW libraries from ImGui examples
and the SDL Android Gradle wrapper JAR.
These are not required by the documented Windows runtime/codegen build with
REXGLUE_BUILD_TESTS=OFF; runtime/game source and compiled dependency inputs are
retained. Upstream PPC assembly tests use cmake/ppc_test_pipeline.cmake and need
a separately obtained, appropriately licensed PowerPC binutils toolchain. ImGui
GLFW examples need a separately built GLFW library; Android builds need a
separately obtained Gradle wrapper. Their upstream paths and
hashes are recorded as ExcludedPrebuiltTools in SOURCE-INVENTORY.json; existing
notices remain. This does not claim those old tools were malicious or confer
legal clearance on earlier archives that included them. The source exporter also
rejects unexpected PE/ELF/Mach-O/native-archive content instead of silently
redistributing a newly introduced compiled binary.
