# Launcher visual assets

background.png is the scenery-only replacement supplied by the project owner
on October 25, 2026. It replaces the October 23 background with characters;
the current launcher uses the supplied ruins/landscape without those characters.
logo.png is the replacement supplied on October 23 in the project's AI-art
workflow. Both current supplied PNGs retain their original bytes. Their original
generation prompts/model identifiers have not been recorded here.

icon-source.png was generated with the built-in OpenAI image-generation tool
using the supplied logo as a palette/material reference. The tool did not report
a model identifier. The project owner approved an uppercase M icon. Its prompt:

> A single large uppercase M for a square Windows launcher icon, with a legible
> thick serif silhouette, antique gold bevel, stone interior, subtle green moss
> and a small leaf accent. Transparent background, safe padding, no characters,
> scenery, other text, watermark or official game art. Use the supplied replacement
> logo only as a material and color reference; simplify details for small sizes.

majin-fk.ico is a mechanical multi-resolution conversion of icon-source.png:
16, 24, 32, 48, 64, 128 and 256 pixels. Regenerate it with
scripts/convert-launcher-icon.ps1, then run scripts/build-launcher.ps1.

The launcher displays the supplied logo proportionally and ignores its outer
transparent padding when drawing. Neither supplied PNG has been painted over,
resampled or otherwise changed. ASSETS.json records SHA-256 fingerprints.

This publication includes only these replacement assets. Older development
history and frozen archives are retained separately in a private repository;
they are not copied into this publication repository or its release assets.

The GPL code license does not automatically apply to these images. AI generation
does not establish exclusivity, public-domain status or complete rights clearance.
No separate public artwork license or legal clearance is asserted by this record.
