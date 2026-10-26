# SDK distribution review — October 23, 2026

This review covers the pinned ReXGlue SDK and the existing private Alpha source
and Windows companions. It does not publish a release, approve every game/artwork
right, or establish jurisdiction-specific legal clearance.

## Conclusion

There is no established SDK-license requirement to rewrite the loader or remove
its generic XEX constants. ReXGlue's BSD-3-Clause license permits source/binary
redistribution subject to its notice, disclaimer and non-endorsement conditions.
This permission covers rights held/licensed by upstream; it is not a grant from
Microsoft or the game's rights holders and does not settle anti-circumvention law.

The earlier finding is a verified upstream component, not a proven personal
credential leak or an established SDK-license violation. On October 23, 2026,
the owner explicitly approved keeping the documented SDK with an exception to
the blanket zero-keys criterion. This resolves that publication-policy choice;
jurisdiction-specific legal clearance is not established. The strict criterion
is recorded as an accepted exception, not as a zero-keys scan that passed.

## Verified provenance and runtime purpose

- SDK: ReXGlue v0.10.0, revision
  `f5337cdc947ff6d4c4196737e2c807a48f2a1fc2`.
- Local `src/system/xex_module.cpp` is byte-identical to that pinned upstream file:
  SHA-256 `AD048F1DB3AFA24BED6989CD44C64A84724C3835B1E5B65FAEBEF36008486E4E`.
- Its file header preserves Ben Vanik's Xenia copyright/BSD attribution and
  identifies Tom Clay's adaptation. The bundled SDK license matches upstream.
- The two named generic constants match Xenia at
  `95a5c3ee250f80c3b9d139658649d9ffb6db3eec`. They are neither personal account
  credentials nor console-unique CPU/DVD keys. No key values are reproduced here.
- XenonRecomp also includes the same retail constant in `XenonUtils/xex.h` at
  `ddd128bcca99fe8bfbb99bea583c972351fa6ace`, and its XEX loader uses it. This is
  relevant provenance/context, not a legal safe harbor for this project.
- ReXGlue's runtime target includes the XEX loader. `ReadImage` uses the generic
  constant to recover the XEX's per-file session key and load encrypted sections.
  Existing runtime binary inspection already confirmed the retail constant.
- Read-only inspection of the supported user-supplied XEX reports
  `XEX_ENCRYPTION_NORMAL` and `XEX_COMPRESSION_BASIC`. No game data, per-file key or
  decrypted executable was exported by this review.

Deleting/zeroing the constants would interfere with this load path. Compiling
PowerPC functions ahead of time does not remove the runtime's use of the player's
original executable for image/data loading. Moving the same values into a separate
DLL, encoding them, or stripping them only from the source ZIP would not meet a
no-embedded-keys goal or resolve the legal question.

## Distribution obligations and existing materials

| Area | Review result / obligation |
| --- | --- |
| ReXGlue/Xenia BSD | Preserve source attribution and the full license/disclaimer with binaries; do not imply upstream endorsement. |
| Project GPL-3.0-only | Retain the chosen project license. BSD-3-Clause is GPL-compatible; changing to GPL-2.0 is unnecessary for this SDK issue. |
| FFmpeg/libmspack LGPL | They are built into the runtime DLL. Provide their corresponding source, local modifications and sufficient build/relink materials; a list of license names alone is insufficient. |
| Matching sources | The existing private Sources ZIP inventories 14,518 files and all 14 dependency revisions used for this Windows build. It includes the pinned loader, SDK license, LGPL texts and build instructions. |
| Binary notices | The existing Windows ZIP includes the SDK license and all 31 notices in the dependency notice inventory, with matching SHA-256 hashes. |
| Replacing libraries | The build instructions explain rebuilding the runtime and replacing its DLL. Prior clean-source SDK/runtime build evidence is retained; no new full build or modified-library gameplay test was performed in this review. |
| Game material | The source inventory declares original game data and generated game C++ excluded. The player must supply the supported game data. This is not complete rights clearance for the recompilation itself. |

These checks apply to the frozen private companions. The new launcher artwork and
security source changes still require newly matched binary/source packages and
validation; the old companions must not be relabeled as if they contained them.

## Owner-approved publication-policy exception

On October 23, 2026, the owner selected: "Manter SDK documentado, com exceção ao
critério de zero chaves" (keep the documented SDK with an exception to zero keys).
Preserve the pinned SDK and the documented generic XEX constants, together with
their upstream attribution, licenses and corresponding source/build materials.

The exception is limited to the reviewed generic constants in this pinned SDK.
It does not authorize personal credentials, console-unique CPU/DVD keys, original
game data, unexplained additional key material or future SDK changes without
review. Record the criterion as an accepted exception rather than "no keys found".
This decision does not establish legal clearance or authorize public release by
itself. No SDK/runtime code, binary, release tag or visibility was changed.

**Alternative not selected by the owner:** a zero-embedded-constants policy would
require designing a separate
user-supplied-key or compatible locally prepared-input path, inspect every shipped
tool/runtime artifact and corresponding source, and rebuild/retest. Merely asking
users to provide a value is not itself a legal exemption. Such a path would also
change the current simple ISO-import experience; it is not implemented here.

Public availability in Xenia/XenonRecomp is evidence of origin, not a guarantee
against a claim. GitHub handles anti-circumvention claims separately from ordinary
code-license questions. The applicable legal analysis depends on facts and
jurisdiction; qualified legal advice is needed for a legal clearance opinion.
This technical review makes neither an automatic illegality finding nor a blanket
legality assurance.

## Primary references

- [Pinned ReXGlue license](https://github.com/rexglue/rexglue-sdk/blob/f5337cdc947ff6d4c4196737e2c807a48f2a1fc2/LICENSE)
- [Pinned ReXGlue XEX loader](https://github.com/rexglue/rexglue-sdk/blob/f5337cdc947ff6d4c4196737e2c807a48f2a1fc2/src/system/xex_module.cpp)
- [Xenia loader reference](https://github.com/xenia-project/xenia/blob/95a5c3ee250f80c3b9d139658649d9ffb6db3eec/src/xenia/cpu/xex_module.cc)
- [XenonRecomp XEX loader](https://github.com/hedge-dev/XenonRecomp/blob/ddd128bcca99fe8bfbb99bea583c972351fa6ace/XenonUtils/xex.cpp)
- [GNU license compatibility list](https://www.gnu.org/licenses/license-list.html)
- [GNU FAQ: static/dynamic LGPL linking](https://www.gnu.org/licenses/gpl-faq.en.html#LGPLStaticVsDynamic)
- [FFmpeg distribution guidance](https://ffmpeg.org/legal.html)
- [GitHub anti-circumvention claim policy](https://docs.github.com/en/site-policy/content-removal-policies/dmca-takedown-policy#c-what-about-circumvention-claims)
- [17 USC 1201, including conditional interoperability provisions](https://uscode.house.gov/view.xhtml?req=granuleid:USC-prelim-title17-section1201&num=0&edition=prelim)
