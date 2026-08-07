# Project Health Scanner

Project Health Scanner is a Godot 4 editor plugin that adds a dock for finding common project problems before export.

## Checks in 1.0.0

- Broken `res://` references in text resources and scripts.
- Missing or invalid `project.godot` metadata.
- Missing main scene.
- Missing or broken project icon.
- Broken or duplicate autoload paths.
- Missing or empty export presets.
- Large files over 5 MB.
- File paths with spaces or special characters.
- Case-only path collisions that can break on case-insensitive file systems.
- Screenshot or preview folders that may need `.gdignore`.
- Likely unused asset files.

The unused asset check is heuristic. Dynamic loads, export filters, generated resources, and resources referenced outside text files can produce false positives.

## Installation

1. Copy `addons/project_health_scanner` into the target Godot project.
2. Open Godot.
3. Go to Project > Project Settings > Plugins.
4. Enable `Project Health Scanner`.
5. Open the `Health Scanner` dock and click `Scan Project`.

## Exporting a report

After a scan, click `Export Markdown`. The plugin writes `res://project_health_report.md`.

## License

MIT.
