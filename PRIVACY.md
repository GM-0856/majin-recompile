# Distribution privacy

Public source and release archives exclude private game data, saves, runtime settings,
diagnostic logs, shader caches, local build folders and development account paths.
scripts/check-public-privacy.py checks tracked files, reachable Git history and ZIP
contents, including byte strings in executables and DLLs. Both packaging scripts
require this check. The check detects defined patterns; it is not a mathematical
guarantee that every possible kind of identifying information can be recognized.

The public author is GM-0856 using the GitHub noreply identity. Upstream author names,
copyright notices and license text remain intact. Generic installation examples and
dummy test paths supplied by upstream libraries do not describe the project owner's
computer. Binary source-location strings use neutral virtual build paths; see
BINARY-PRIVACY.json and SOURCE_BUILD.md for the deterministic sanitization procedure.

Runtime settings and privately generated diagnostic ZIPs may contain the player's
actual local paths and system details. They are not release assets and nothing is
uploaded automatically. Review diagnostics before sharing them on a public issue.

The initial publication's Git history and assets were replaced after a privacy audit.
Anyone with an older clone should create a fresh clone rather than merge the old
history back. Copies already downloaded and hosting-provider caches are outside the
scope of this repository scan; history rewriting does not guarantee their deletion.

## Updated local diagnostics

Frame-time recording is local and can be disabled in **Diagnostics / privacy**.
Additional CPU, RAM and GPU/driver details require opt-in, disabled by default.
The selected graphics adapter remains part of ordinary renderer logs. Hardware
fields exclude user/computer names, serials, UUIDs, SIDs, network identifiers and
installed software. Diagnostic ZIPs redact known local paths and sanitize Windows
failure-event fields; review the ZIP before sharing. No automatic upload occurs.
See [PERFORMANCE_DIAGNOSTICS.md](PERFORMANCE_DIAGNOSTICS.md) for precise measurement
definitions, limits, retention/truncation and hardware opt-out behavior.
