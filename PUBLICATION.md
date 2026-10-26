# Clean public source publication — October 25, 2026

The project owner authorized publication in a new, independent repository:
https://github.com/GM-0856/majin-recompile

The development repository remains private. This repository was initialized from
an audited archive of the current tracked source, without copying its .git
directory, old commits/tags, releases, issues, Actions artifacts or caches. It is
not a GitHub fork. Earlier launcher artwork and removed personal build-path
history are not transferred. The old repository is neither deleted nor renamed.

The public Alpha.3 repack retains the exact game, GPU, audio and native launcher
bytes already tested for the private Alpha.3. Only publication documentation,
repository links and packaging/provenance metadata are updated. No new gameplay
patch, automatic fullscreen gesture or save migration is introduced. The supplied
scenery-only background, logo and M icon remain unchanged.

BUILD-EVIDENCE.json records the original build revision as a private provenance
identifier and maps its unchanged project inputs to the new public snapshot.
Every prototype file in this snapshot is byte-identical to the corresponding
compiled source snapshot. The source companion provides the matching patched
SDK and pinned dependencies; generated game C++, ISO/XEX, game assets, saves,
shader caches, personal settings and private audit reports are excluded.

See SECURITY_AUDIT.md for the scoped checks and known limitations. This is an
experimental Alpha with unsigned executables, not security/legal certification,
whole-game sanitizer validation or a universal performance guarantee. The SDK's
documented generic public XEX constants remain under the owner's accepted scoped
exception. Current artwork provenance remains separate from the code license.
