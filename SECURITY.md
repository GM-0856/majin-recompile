# Security policy

This experimental alpha is not a sandbox for hostile game files, saves, shader
caches, scripts or DLLs. Use a supported copy of the game and trusted local files.
Do not run the app as administrator. Extract it into a writable user-owned folder;
the portable app keeps saves/configuration there and does not request elevation.

## Reporting a vulnerability

Do not put credentials, proprietary game files, personal paths, unredacted logs
or working exploit details in a public issue. When GitHub private vulnerability
reporting is enabled, use the repository Security tab's Report a vulnerability
button. If it is unavailable, contact the maintainer through an established
private channel, or request a private reporting channel without posting details.
There is no monitored public security email address advertised by this project.

Include the commit/package hash, affected component, impact and minimal synthetic
reproduction steps. Prefer synthetic files over original game material. Reports
and fixes will be reviewed before a public disclosure; no response deadline or
security support guarantee is promised for this volunteer alpha.

## Current scope and release status

See SECURITY_AUDIT.md for findings, test coverage and release blockers. Source
hardening after the packaged alpha is not automatically present in old binaries.
This publication uses a new repository containing an audited source snapshot,
without the private development history or old releases. See PUBLICATION.md.
Hosting protection results are recorded separately in the release validation;
account two-factor authentication was not verified by this audit.

The launcher has no automatic updater or telemetry uploader. Diagnostic collection
is local and opt-in. Build/CI tools access GitHub for dependencies; the support
documentation links to Microsoft's runtime installer. Runtime/network emulation
inside upstream code has not received a complete network security audit.
Release SHA-256 sums are provided. Current executable files are unsigned; no
code-signing identity or private certificate is shipped in the repository.
