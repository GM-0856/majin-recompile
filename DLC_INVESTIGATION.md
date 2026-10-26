# DLC and language investigation

October 2, 2026. Read-only local inspection; no DLC installation or runtime changes.

## Identified package

- Local file: `DLC/Special Challenge Pack`, 89,837,568 bytes (about 89.8 MB / 85.7 MiB).
- SHA256: `A79D8E4CEBB32A246653C3CB61B8192EE9D2714B3E2104BAB820EB9C3BCAFB63`.
- Header: `LIVE`, STFS volume, metadata version 2, MarketplaceContent type `00000002`, Title ID `4E4D0816` matching the supported game.
- English display name: Special Challenge Pack. Portuguese metadata display name: Pacote de desafios especiais. Metadata language slots describe the package listing, not its spoken languages.
- Directory listing: six directories and 30 `.pak` files under `resource00/dlc`, `resource01/dlc`, `resource02/dlc`, with character packages and maps 704-709. The container was not extracted, mounted, cryptographically authenticated or play-tested. Matching Title ID alone does not certify compatibility with the compiled executable.

Header and directory offsets were read using the pinned SDK definitions in `include/rex/filesystem/devices/stfs_xbox.h`, `include/rex/system/xcontent.h`, and `src/filesystem/devices/stfs_container_device.cpp`.

## Portuguese uncertainty

The local folder named `Majin and the Forsaken Kingdom (Português)` contains JPG scans of manual pages, covers and disc/flyer art. It is not a separate voice package.

Both the original extracted game folder and the active ISO import contain sound resources with suffixes `du`, `en`, `fr`, `ge`, `it`, `po`, `ru`, `sp`: 1,314 `.gtd` files per non-English suffix, 1,316 English `.gtd` files, and 17 `_en.ged` files. Sample `.gtd` files start with `GHS `; they are not simply plain-text language labels. These suffixes are inventory evidence only. In particular, `_po` has not been mapped conclusively to Portuguese or Polish, and its spoken content has not been decoded/auditioned. No Portuguese dubbing support is claimed.

## Implementation sequence to evaluate

1. Add a separate own-file DLC import flow; keep it distinct from disc ISO import. Validate package format, Title ID, size/bounds, directory/block chains and safe paths before any writes.
2. Store imported content separately from base-game files and saves; preserve source containers and provide atomic import/failure recovery.
3. Connect content enumeration and mounting to the runtime. The SDK content manager stores MarketplaceContent under a common profile and enumerates extracted content directories; merely copying this container beside the ISO is not a verified import path.
4. Validate the game recognizing/unlocking the challenges, loading maps, saving/reloading and disabling/reimporting without harming base-game saves. Test both rendering choices where supported.
5. Investigate language selection and actual voice content separately before offering a Portuguese option.

DLC is outside the current alpha claims and is not bundled in distributable packages. This inventory is a starting point for subsequent implementation, not proof of working DLC support.
