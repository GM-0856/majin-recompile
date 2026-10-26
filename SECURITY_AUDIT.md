# Scoped publication security review — October 25, 2026

This independent source snapshot is prepared for the owner's authorized public
Alpha.3 release. It does not copy the private development Git history or earlier
release assets. PUBLICATION.md explains the privacy boundary. This is a scoped
technical review, not security/legal certification or a guarantee of zero bugs.

## Historical privacy and artwork — isolated from this publication

The old private repository contains earlier artwork and a removed Git object with
a developer-specific Windows path that is still retrievable through its API.
Simply changing its visibility would expose material removed from its current
branch. It therefore remains private. This publication uses git archive followed
by a fresh git init; no old objects, branches/tags, issues, workflow artifacts or
release assets are imported. It is not created as a GitHub fork. Only the current
scenery-only background, replacement logo and M icon are included. The artwork
provenance does not establish public-domain status or make the images GPL code.

## Checks and unchanged build evidence

- Gitleaks 8.30.1, verified by SHA-256, found zero secrets in all 29 reachable
  development commits. That result alone did not certify removed GitHub objects;
  the historical object check is why a separate repository is used.
- The tracked snapshot, reachable metadata and both Alpha.2/Alpha.3 source and
  Windows archives passed the personal-path/identity/credential-signature scan.
  The fresh publication history and final public packages are scanned separately;
  results and exact fingerprints are recorded in RELEASE-VALIDATION.json.
- Final archive verification checks ZIP integrity, every manifest/inventory file
  hash, native binary identity and replacement-artwork hashes. Native executables
  use Release runtime dependencies and remain unsigned. SHA-256 is an integrity
  check, not a code-signing identity.
- The unchanged implementation previously passed 1,027 synthetic ISO/XEX,
  traversal/bounds and actual Windows argv checks; 52 diagnostics/privacy checks;
  six bounded native-capability checks; and 21 source-export policy checks.
- Standalone timing/menu helpers passed AddressSanitizer, including 3,616 deadline
  assertions. This is helper coverage, not a multi-hour instrumented game run.
  Successful owner Arc/notebook gameplay/save tests and performance limits are
  documented separately in PLAYTEST_VALIDATION.md.

## Native code and launcher limitations

MEM-01 remains open: guest-pointer translation, kernel wrappers and game/save/
shader-cache parsers have not received complete memory-safety validation or
comprehensive fuzzing. The runtime is not a hostile-input sandbox. Use supported
original game files and trusted saves/caches. Full-game ASAN/CodeQL and complete
campaign/cinematic/controller validation are not claimed.

ISO import validates the supported executable hash, bounds/counts, Windows-safe
paths and a 16-GiB extraction ceiling. It uses fresh staging paths and CreateNew
writes. A process that can alter installation directories could still exploit
reparse-point/TOCTOU races; those are not proven absent. Process arguments use
tested Windows quoting and fixed executable paths rather than shell input.

Native launcher/game DLL policies prefer application/System32 paths but do not
protect deliberately replaced application DLLs or cover all upstream bare-name
loads. The bootstrap requests asInvoker; no automatic updater/elevation or
telemetry upload is added. Diagnostics stay local; extra hardware details are
opt-in and the active GPU is already logged. The entire upstream networking
implementation has not received an independent network security audit.

The optional timing patch adds no parser, network request or shell execution;
keeps engine/audio clocks intact; checks caller/span/vtable/state; and avoids
guest-object access after the delegated scene call returns. These are guards,
not proof that every arbitrary guest pointer is valid.

## Dependencies, distribution and accepted SDK-constant exception

SDK/dependencies are pinned in DEPENDENCIES.lock.json; licenses/notices and the
matching patched source companion are retained. Optional precompiled PPC/Cygwin
test tools, two ImGui GLFW example libraries and the Android Gradle wrapper are
excluded; 39 omissions are fingerprinted in SOURCE-INVENTORY.json. The exporter
rejects unexpected native binaries. This does not imply malware in old tools.

IP-01 retains the owner's scoped exception for generic publicly distributed SDK
XEX constants. They are distinct from personal/API/console-unique secrets. No
zero-constants or legal-clearance claim follows; see SDK_DISTRIBUTION.md. The
prior libmspack KWAJ advisory concerned a parser outside this SDK's linked
lzxd-only target. Dependencies are unchanged; that prior applicability review is
not a new universal CVE scan. Reassess dependencies and licensing when changed.

## GitHub safeguards and review limits

The workflow pins Actions and Gitleaks downloads, scans reachable history and
privacy patterns, runs malformed-input/timing/source-export tests and builds the
native launcher. CodeQL is scoped to that launcher, not the complete runtime.
The private workflow skipped CodeQL; public runs and enabled hosting protections
are recorded separately after eligibility changes. Do not treat a skipped job
as analysis. Dependabot Actions updates do not monitor every C++ dependency.

Secret scanning/push protection, private vulnerability reporting and branch
protection are enabled/verified where available during publication; the exact
API results belong in release validation rather than being assumed here.
Account 2FA was not independently verified. No credential/recovery codes are
requested or published. SECURITY.md describes private reporting and limitations.
