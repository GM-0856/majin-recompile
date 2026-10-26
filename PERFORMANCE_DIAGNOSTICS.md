# Local performance diagnostics

The updated Windows candidate can record guest FPS/frame times without MSI Afterburner.
Older downloaded ZIPs do not gain this feature automatically.

Open **Diagnostics / privacy** in the launcher:

- **Record FPS / frame times locally** is on by default and can be disabled.
- **Include optional CPU, RAM and GPU/driver details** is off by default. Enable it
  only if you want those details recorded for support. Preferences save on Play.
- **Create diagnostic ZIP** exports selected local files for review. Nothing is
  uploaded. You decide whether to share the ZIP and with whom.

## What the measurement means

The SDK timestamps consecutive guest GPU swap packets using its monotonic host
clock. This measures the game's frame-production interval, including waits,
loading, pauses and stalls. It does **not** measure GPU execution, input latency,
unique displayed frames or the monitor's refresh rate. An external presentation
overlay can report a different rate, especially when the same image is presented
more than once. Menus, videos and gameplay can also use different frame rates.

The first zero interval is excluded. FPS is calculated from total valid intervals
divided by their summed duration, not an average of instantaneous FPS readings.
P50/P95/P99 use nearest rank over all valid intervals; long intervals are retained.
The one-second series uses windows of at least one measured second, with the last
partial window retained. A long stall remains its full duration rather than being
compressed into a one-second bucket. Loading and idle intervals are not classified
as gameplay or silently removed. Use the same checkpoint/settings for comparisons.

## Files in reports

Each new `runtime-<session>.log` can have:

| Suffix | Contents |
| --- | --- |
| `.performance.csv` | Buffered per-frame SDK counters; `frame_time_us` is microseconds. The SDK integer `fps` column is coarse; the summary recalculates precise averages. Other SDK counters may remain zero in Release and are not used as evidence. |
| `.performance-1s.csv` | Elapsed measured milliseconds, interval count, window duration, average FPS, mean and maximum frame time. Elapsed time starts at the first measured interval, not process launch. |
| `.performance-summary.json` | FPS, mean/min/max/P50/P95/P99 frame times, counts above 33.333/50/100 ms, warning/error counts, texture occurrence/suppression totals, XMA recovery count and selected GPU. |
| `.settings.json` | Render/input settings and capture choices. The ZIP export omits game-data/cache paths. |
| `.hardware.json` | Optional allowlisted OS/build, CPU model/core counts, usable RAM size, GPU names and driver versions. Created only with opt-in. |

A short FPS/frametime summary is appended to the main log after the game exits.
Existing bounded texture warnings retain their original samples and counts;
diagnostics do not bypass texture validation or select another rendering path.

## Privacy and limits

No hardware serials, UUIDs, user/computer names, SIDs, IP/MAC addresses or installed
application lists are queried or exported as hardware fields. The active graphics
adapter already appears in ordinary runtime logs even with optional hardware off.
All installed adapters may be listed when hardware is included; the summary's active
GPU identifies the adapter selected by the runtime. No utilization, temperatures or
power measurements are inferred from the static hardware inventory.

The regular and assisted collectors export a bounded set of session artifacts,
redact known local/user/network paths, and omit separate hardware artifacts unless
opted in. `-SkipHardware` overrides saved consent and `-IncludeHardware`.
Assisted Windows failure events export only time, event/provider and a small
application/module/version/exception allowlist, not full event XML or messages.
Redaction is best effort: always inspect the resulting ZIP before sharing.

CSV writes are buffered, flushed every 60 rows and capped at 2,000,000 rows per
Release process (roughly 9 hours at 60 FPS). The limit logs a warning and stops
capture while the game continues. The final buffered rows, up to 59, can be lost
on hard exit/crash. Capture adds some disk/CPU work; disable it for an overhead
comparison, especially when running from slow/removable storage.

Offline analysis accepts at most 128 MiB, 2,000,000 rows and 4096 characters per
record. Corrupt rows are counted and excluded; missing samples are not converted
into fictitious zero-frame times. Collector ZIPs copy at most 8 MiB per raw frame
CSV and 2 MiB for other artifacts, within a 25 MiB total. Oversized CSV/logs retain
their tail; the CSV header is preserved and truncation is listed in the inventory.
The complete local summary remains distinct from a truncated raw excerpt.

The current build was exercised with actual Release capture on Intel Arc B580.
The mechanism has no vendor-specific counter dependency, but Radeon/NVIDIA and
multi-hour gameplay testing are still pending. This is diagnostic coverage, not
a performance improvement or hardware certification.

## Validation of the updated candidate

October 23: 52 synthetic checks passed for weighted FPS, percentiles, stalled and
invalid intervals, bounded CSV tails, hardware opt-in/opt-out, path redaction and
Windows failure-event fields. The launcher/privacy layout passed automated checks.
Isolated Release startup/menu sessions on Arc B580 captured 510 valid intervals in
Default and 444 in ROV; a separate opt-out session created no frame CSV. All three
exited normally with no error/critical records. Active saves and caches were verified
unchanged. These short runs prove capture, not gameplay performance or multi-hour
stability, and their averages must not be compared as equivalent workloads.

## Windowed mode and live title FPS

Windowed mode uses a normal resizable Windows frame with minimize, maximize and
close buttons. When the requested output size would exceed the monitor's usable
desktop area, the initial client size is reduced proportionally and centered,
leaving the caption/taskbar accessible. Internal render scale is unchanged.
The chosen output size is therefore an initial maximum rather than permission
to hide the caption beyond the screen. Maximizing/restoring remains available.

The title shows `Majin Recompile | <n> FPS` only in windowed mode. It refreshes
twice per second using the latest completed interval window of at least one
second, rounded to a whole FPS. It measures guest swaps, not monitor refresh or
input latency. The title counter works with CSV recording off, does not create
an overlay and continues after the CSV row limit. Before the first sample it
shows `... FPS`; minimized windows report zero until restored. The SDK integer
FPS column may use this rolling value; offline summaries still derive precise
averages from individual frame intervals.

October 23: 54 native helper checks passed. Isolated real-window tests confirmed
caption/minimize/maximize/system menu/resizing, work-area bounds on the 1360x768
display, minimize/maximize/restore, numeric FPS with CSV off and on, no title FPS
in fullscreen, CSV capture when enabled and normal close. These were startup/menu
tests and do not establish gameplay performance. Both the project Release entry
and the separate candidate are updated together to avoid stale executables.
