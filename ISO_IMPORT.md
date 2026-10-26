# Disc image import

The launcher accepts an extracted game folder (Browse) or a single uncompressed Xbox 360 disc image (Import ISO). Images are inspected before import. No mounting, administrator access or external extractor is required.

The supported executable SHA256 is `660CAE389F0A45100739F935472437D282B2568FCFC2C60FC5A9B2B7B48CE1EC`, Title ID `4E4D0816`, Media ID `67BD87EF`, version `0.0.0.3`. Other executables are identified but cannot be imported. Modified executables are also rejected. PS3 images, compressed archives, split images, DLC containers and other revisions are not supported in this first implementation.

The identity dialog shows the executable region permission mask, not a guaranteed retail edition or language list. A region-free/multi-region executable must not be labeled as a unique European, American or Japanese release. Each additional executable revision needs independent recompile compatibility work and testing. No source/provenance claim is made from a filename or metadata. Use your own disc dump; game files are not distributed by this project.

**Validation uses a European/PAL Xbox 360 ISO. The American/USA and Japanese editions have not been tested.** A matching executable hash can be accepted without implying that another edition has been play-tested.

## Import behavior

- Validates filesystem bounds, directory structure and Windows-safe output paths; rejects duplicate paths and malformed/truncated file extents.
- Checks executable identity/hash and presence of the main asset directories before extraction. This is not full original-disc integrity certification.
- Checks free space (payload plus 256 MB reserve).
- Copies into a new `private/imports/incomplete-<id>` directory, validates the extracted game, then renames it and saves the selected path. The original ISO is read-only. Existing installations are never overwritten.
- Saves remain in `private/runtime/user`. Import does not start the game.
- On failure, previous configuration remains selected; incomplete files are retained for inspection/manual removal. No automatic resume or cancel is implemented yet. Keep the launcher open during import.
- Reimporting creates another copy; existing installations are not deduplicated.

## Validation

`scripts/test-disc-import.ps1 -IsoPath <path>` imports into an isolated validation root and compares every existing local game file by SHA256. It uses the existing local data as reference and does not change active settings/saves. The test needs approximately 2.4 GB extra disk space. Real gameplay from the imported folder and other-region images still require user testing.

## Format references

Original implementation using the project's earlier read-only `compare_iso.py` reader as a starting point. XDVDFS layout/partition detection cross-checked against the [Xenia disc reader](https://github.com/xenia-project/xenia/blob/master/src/xenia/vfs/devices/disc_image_device.cc). XEX execution/security field offsets and region masks checked against the pinned ReXGlue 0.10.0 `include/rex/system/util/xex2_info.h`. No third-party extractor is bundled.

September 15, 2026 local validation: imported the available PAL-compatible image (11,314 files, 2,355,921,156 bytes) into an isolated test root. All 11,312 files in the existing game folder matched SHA256; the image additionally contains system-update files. Invalid-image/path tests and synthetic region-mask checks passed. Launcher layout rendered and inspected. These tests do not certify American/Japanese disc compatibility or complete-disc authenticity. The reader currently rejects single files larger than 2 GB and names outside printable ASCII.

October 22, 2026: European ISO import and the clean-candidate notebook ROV session are recorded in PLAYTEST_VALIDATION.md. Latest notebook save write completed; restart/load was not repeated by owner choice before the public pre-release.
