# Installation and build validation

These are distinct checks; one does not imply another has passed.

1. **Relocated archive checks:** file/hash inventory, absence of bundled game/art/saves, PowerShell 5.1 parsing, ISO helper compilation, isolated save path, launcher paint/layout and same-PC DLL loading.
2. **Clean source build:** fresh pinned project/SDK/dependency checkouts; user-supplied executable; regenerated code; Release build with 1080p probes off; XMA/log tests. Corresponding source and build instructions are distributed separately.
3. **Separate-machine gameplay:** notebook/desktop observations, exact settings, hardware, startup, saving/reload and shutdown. Limited-route evidence is not a campaign or minimum-spec certification.

The clean source candidate ran on the Ryzen 5 5500U with ROV on October 22 for about 34 minutes, completed an observed save write and closed normally. The owner chose not to repeat loading that newest save before public release. Earlier Release packages had save/reload validation. These facts are separately recorded in PLAYTEST_VALIDATION.md.

The public Windows ZIP preserves those binaries and updates packaging/docs/diagnostics. It has a short Majin-Recompile root; use a short writable local SSD folder. A 282-character cache filename in an earlier nested installation is a startup-failure hypothesis, not a proven fix.

This is a portable alpha, with no installer/uninstaller or automatic save migration. Back up private/runtime/user before upgrades/deletion. Missing Visual C++ runtime, all possible display/driver combinations, full campaign, all cutscenes and every input mapping are not universally validated. European/PAL input was tested; American/USA/Japanese editions were not.
