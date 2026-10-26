# Local package validation - September 15, 2026

The user confirmed ISO import, game startup and loading an existing save from the supported European image in the development installation.

A local-only Debug package was created using scripts/package-local-test.ps1. Explicit allowlisted files only: launcher/runtime helpers, stable game executable and three DLLs, documentation and available dependency notices. No game data, saves/settings, game artwork, SDK/tools, PDBs or experimental binaries are included. The stable executable and patched audio runtime fingerprints are checked before copying; PACKAGE-MANIFEST.json records all included file hashes. The ZIP has a SHA256 sidecar.

The ZIP was extracted outside the project into Documents/Majin Alpha Test. scripts/test-local-package.ps1 verified its inventory and every file hash, parsed the scripts, compiled the ISO helper, verified the relocated save root, rendered the launcher without artwork, and loaded all three DLLs on this development PC. No game was started during this automated test. The extracted test copy now has empty runtime/report directories and the launcher preview from validation; the ZIP remains pristine.

## Distribution blocker found

Static import inspection found MSVCP140D.dll, MSVCP140D_ATOMIC_WAIT.dll, VCRUNTIME140D.dll, VCRUNTIME140_1D.dll and ucrtbased.dll. These are Debug development dependencies. They were not copied into the package. This package is explicitly LOCAL TEST ONLY, not a public alpha and not evidence of operation on a PC without development tools.

Next: validate gameplay/new saves in this relocated package; prepare a separate Release build retaining the audio fix and input features; inspect its dependencies and run regression tests; finish project licensing and dependency notice/source obligations review; test on a separate Windows PC. Existing stable Debug binaries must remain preserved.

The copied dependency notices are material for review, not a completed license audit. No project license was selected and no release was uploaded.

## Release candidate - September 15, 2026

The user validated the relocated Debug package end-to-end: new gameplay, save, exit, restart, and reload. A separate Release build has now compiled successfully using the normal build script, strict code generation and the patched XMA runtime. XMA boundary tests passed. CMake confirms Release and MAJIN_1080P_STARTUP_PROBE=OFF. Stable Debug executable/runtime SHA256 values remained unchanged; a further binary backup was saved before building.

Release package: Majin-Recompile-local-test-release-20260915-234025.zip. Relocated under Documents/Majin Release Test. Inventory/hashes, script parsing, ISO helper compilation, launcher layout, isolated save paths, and native DLL loading passed on this development PC. Startup CMD explicitly selects Release; the ordinary development launcher still defaults to Debug.

Static imports of majin.exe, rexruntime.dll and rexgpu-xenos.dll contain no Debug CRT dependencies. Release uses MSVCP140.dll, MSVCP140_ATOMIC_WAIT.dll, VCRUNTIME140.dll, VCRUNTIME140_1.dll and Windows UCRT/system libraries. Tracy is not required by these Release binaries. This resolves the identified Debug CRT packaging blocker, but is NOT a separate-machine test or gameplay validation of optimized code.

Next user test: new game/save/restart/load at 720p or 1440p, input and Esc confirmation, sustained battle/menu music. Performance improvement is not claimed without measurement. Licenses, clean source build/separate-machine validation and public distribution remain pending. No release uploaded.

September 16: user validated Release gameplay/save/restart/reload. Private installer copied to a private removable-drive test folder; every copied file hash verified. Installer extraction and payload hashes tested without installing the prerequisite. Microsoft-signed x64 VC++ installer included from the official download. Destination-machine prerequisite installation, shortcuts and gameplay remain to be tested. No game data or saves included.


September 16 notebook test: installation and ISO import succeeded on Ryzen 5 5500U, but launcher painting raised a zero-height rectangle exception and gameplay/video intermittently went black while sound continued. Fixed launcher callback to skip empty client areas; zero-size regression and layout tests passed. Notebook graphics compatibility remains unresolved pending its runtime logs/driver details. Launcher hotfix and diagnostic collector prepared. Do not mark clean-machine gameplay as passed.
