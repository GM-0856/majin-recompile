# Third-party credits and distribution notes

Majin Recompile uses [ReXGlue SDK](https://github.com/rexglue/rexglue-sdk) v0.10.0 at `f5337cdc947ff6d4c4196737e2c807a48f2a1fc2`, including runtime/GPU work derived from [Xenia](https://github.com/xenia-project). Tom Clay, Ben Vanik and Xenia contributors retain their copyrights. ReXGlue/Xenia BSD-3-Clause terms are preserved in LICENSES/ReXGlue.txt. ReXGlue credits XenonRecomp and rexdex's recompiler; its upstream README specifically acknowledges XenonRecomp work underlying parts of code-generation analysis and instruction translation. This project invokes ReXGlue codegen directly rather than running the standalone XenonRecomp toolchain.

The project-authored code is GPL-3.0-only; see LICENSE and COPYRIGHT.md. That selection does not replace upstream terms.

## Dependency notices

LICENSES/DEPENDENCY-NOTICES.json records notice paths and hashes. The package must copy these repository-controlled notices, including nested licenses that were absent from the earlier top-level-only copy.

| Component | License / notice | Use |
| --- | --- | --- |
| FFmpeg libavcodec/libavutil | LGPL-2.1-or-later | XMA/audio decoding, statically linked into runtime |
| libmspack LZX | LGPL-2.1 | XEX decompression |
| fmt, spdlog, SIMDe, toml++, ImGui, aes_128, DES, o1heap, Disruptor++ | MIT | Runtime support |
| utfcpp | Boost Software License 1.0 | UTF handling |
| xxHash | BSD-2-Clause | Hashing |
| SDL 3 | zlib; nested HIDAPI/YUV notices preserved | Window/input support |
| tiny-AES-c | Unlicense; supplemental upstream notice | XEX encryption support |
| RenderDoc API header | MIT embedded notice | Optional capture integration; RenderDoc itself is not bundled |
| DXBC checksum | AMD and RSA MD5 embedded notices | Derived from the RSA Data Security, Inc. MD5 Message Digest Algorithm |
| DXC API headers | University of Illinois/NCSA and upstream notices | API declarations; compiler DLLs are loaded from the system, not bundled |
| CLI11, inja, nlohmann-json | BSD-3-Clause / MIT | SDK tooling/headers; CLI tool is not in the runtime ZIP |
| Tracy | BSD-3-Clause | Debug profiling; Tracy DLL is excluded from Release |

The inspected FFmpeg Windows x64 configuration sets `CONFIG_GPL=0`, `CONFIG_NONFREE=0`, `CONFIG_VERSION3=0`; the SDK CMake source list and codec overlays select the audio libraries directly. No x264 or nonfree external library is enabled in that configuration. Source and build details must accompany distribution of those components, including the project's runtime patches. See [FFmpeg's distribution guidance](https://ffmpeg.org/legal.html).

## Sources and remaining verification

Do not declare redistribution ready solely because license files are copied. The pinned SDK source, dependency revisions, build configuration and local patches must correspond to shipped binaries. Source/relink materials and availability are being prepared alongside the clean source validation. Compiler binaries and Microsoft system runtimes are external prerequisites. The original game, game-derived generated source, ISO, DLC, saves and caches are not included. Launcher background and icon are supplied separately from code; see assets/launcher/README.md.

Supplemental notice sources: [Disruptor++](https://github.com/lewissbaker/disruptorplus/blob/master/LICENSE.txt), [tiny-AES-c](https://github.com/kokke/tiny-AES-c/blob/master/unlicense.txt), [DirectXShaderCompiler](https://github.com/microsoft/DirectXShaderCompiler/blob/main/LICENSE.TXT). Upstream terms and existing source notices remain intact.

The clean-source candidate has a companion archive containing pinned dependency source, patched runtime source, build configurations and instructions in SOURCE_BUILD.md. Publish both archives together; do not reuse the old binary ZIP and claim its hashes belong to the rebuilt candidate. Verify the source-companion identity before public distribution.

The pinned SDK distribution and generic XEX-constant review is documented in [SDK_DISTRIBUTION.md](SDK_DISTRIBUTION.md). It separates upstream license conditions from the still-open strict no-keys publication criterion and jurisdiction-specific legal questions.
