# Public Windows Alpha.3 — October 25, 2026

Repository: https://github.com/GM-0856/majin-recompile

Release: https://github.com/GM-0856/majin-recompile/releases/tag/v0.1.0-alpha.3

This is the first publication in this independent clean repository. The private
development repository, old history and Alpha.1/Alpha.2 downloads remain private.
See PUBLICATION.md for the source-snapshot and binary-provenance mapping.

Download the Windows-x64 ZIP to play and the corresponding Sources ZIP for the
project, patched SDK and 14 pinned dependencies. SHA256SUMS.txt fingerprints the
downloads; RELEASE-VALIDATION.json records the scoped checks. The binaries are
unchanged from the owner-tested Alpha.3. Their package hashes change because the
repository links, source-snapshot identifiers and documentation were updated.

European/PAL Xbox 360 executable revision is tested; USA/Japanese editions are
untested. Supply your own supported original game data through Import ISO.
Original remains default; 60 FPS is optional/experimental. Default rendering was
tested on Arc B580; the 5500U needed ROV for missing images at lower performance.
No universal 60-FPS, full-campaign or full-cinematic validation is claimed.

No ISO/XEX, original game assets, generated game C++, DLC, personal saves,
configuration, shader caches or USB test kit is included. Launcher artwork is
the replacement scenery/logo/M icon documented under assets/launcher.

Back up private/runtime/user before updates. After extracting a new copy, create
private/runtime if needed and copy only your trusted user save folder there,
with the game closed. Do not delete the backup until save loading is confirmed.

Known graphical/cinematic issues and the threat model are in RELEASE_NOTES.md,
PLAYTEST_VALIDATION.md and SECURITY_AUDIT.md. The launcher window behavior is
unchanged; a double-click fullscreen feature is not part of this Alpha.
