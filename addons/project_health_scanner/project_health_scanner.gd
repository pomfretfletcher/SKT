@tool
extends RefCounted

const SEVERITY_ERROR := "ERROR"
const SEVERITY_WARNING := "WARNING"
const SEVERITY_INFO := "INFO"

const TEXT_EXTENSIONS := {
	"gd": true,
	"cs": true,
	"tscn": true,
	"tres": true,
	"theme": true,
	"cfg": true,
	"godot": true,
	"json": true,
	"txt": true,
	"md": true,
	"po": true,
	"csv": true,
	"translation": true,
	"gdshader": true,
	"shader": true
}

const ASSET_EXTENSIONS := {
	"png": true,
	"jpg": true,
	"jpeg": true,
	"webp": true,
	"svg": true,
	"ogg": true,
	"wav": true,
	"mp3": true,
	"flac": true,
	"glb": true,
	"gltf": true,
	"fbx": true,
	"obj": true,
	"dae": true,
	"blend": true,
	"ttf": true,
	"otf": true,
	"woff": true,
	"woff2": true,
	"mp4": true,
	"ogv": true
}

var large_file_threshold_mb := 5.0
var unused_file_limit := 250
var _reference_regex := RegEx.new()
var _safe_name_regex := RegEx.new()


func _init() -> void:
	_reference_regex.compile("res://[^\\\"'\\)\\]\\s,;]+")
	_safe_name_regex.compile("^[a-z0-9_./-]+$")


func scan(include_addons := false, include_unused_check := true) -> Dictionary:
	var started_msec := Time.get_ticks_msec()
	var issues: Array[Dictionary] = []
	var files := _collect_files("res://", include_addons)
	var referenced_files := {}
	var text_files: Array[String] = []

	_check_project_config(issues, referenced_files)
	_check_export_presets(issues)
	_check_screenshot_folder_metadata(files, issues)
	_check_file_names(files, issues)
	_check_duplicate_paths_by_case(files, issues)
	_check_large_files(files, issues)

	for path in files:
		if _is_text_file(path):
			text_files.append(path)
			_check_text_file_references(path, issues, referenced_files)

	if include_unused_check:
		_check_likely_unused_assets(files, referenced_files, issues)

	var summary := _summarize(issues)
	summary["files_scanned"] = files.size()
	summary["text_files_scanned"] = text_files.size()
	summary["elapsed_ms"] = Time.get_ticks_msec() - started_msec

	return {
		"summary": summary,
		"issues": issues
	}


func to_markdown_report(result: Dictionary) -> String:
	var summary: Dictionary = result.get("summary", {})
	var issues: Array = result.get("issues", [])
	var lines: Array[String] = []
	lines.append("# Project Health Scanner Report")
	lines.append("")
	lines.append("Generated: %s" % Time.get_datetime_string_from_system())
	lines.append("")
	lines.append("## Summary")
	lines.append("")
	lines.append("- Files scanned: %s" % summary.get("files_scanned", 0))
	lines.append("- Text files scanned: %s" % summary.get("text_files_scanned", 0))
	lines.append("- Errors: %s" % summary.get(SEVERITY_ERROR, 0))
	lines.append("- Warnings: %s" % summary.get(SEVERITY_WARNING, 0))
	lines.append("- Info: %s" % summary.get(SEVERITY_INFO, 0))
	lines.append("- Elapsed: %s ms" % summary.get("elapsed_ms", 0))
	lines.append("")
	lines.append("## Issues")
	lines.append("")

	if issues.is_empty():
		lines.append("No issues found.")
		return "\n".join(lines)

	for issue in issues:
		lines.append("### %s: %s" % [issue.get("severity", SEVERITY_INFO), issue.get("code", "UNKNOWN")])
		lines.append("")
		lines.append("- Path: `%s`" % issue.get("path", "res://"))
		lines.append("- Message: %s" % issue.get("message", ""))
		var detail := str(issue.get("detail", ""))
		if not detail.is_empty():
			lines.append("- Detail: %s" % detail)
		lines.append("")

	return "\n".join(lines)


func _collect_files(root: String, include_addons: bool) -> Array[String]:
	var files: Array[String] = []
	_walk_directory(root, include_addons, files)
	files.sort()
	return files


func _walk_directory(path: String, include_addons: bool, files: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with(".") and entry not in [".gdignore"]:
			entry = dir.get_next()
			continue

		var child_path := path.path_join(entry)
		if dir.current_is_dir():
			if not _should_skip_directory(child_path, include_addons):
				_walk_directory(child_path, include_addons, files)
		else:
			files.append(child_path)
		entry = dir.get_next()

	dir.list_dir_end()


func _should_skip_directory(path: String, include_addons: bool) -> bool:
	var name := path.get_file()
	if name in [".godot", ".git", ".import", "tmp", ".tmp", "build", "dist", "exports"]:
		return true
	if not include_addons and path == "res://addons":
		return true
	return false


func _is_text_file(path: String) -> bool:
	return TEXT_EXTENSIONS.has(path.get_extension().to_lower())


func _is_asset_file(path: String) -> bool:
	return ASSET_EXTENSIONS.has(path.get_extension().to_lower())


func _check_project_config(issues: Array[Dictionary], referenced_files: Dictionary) -> void:
	if not FileAccess.file_exists("res://project.godot"):
		_add_issue(issues, SEVERITY_ERROR, "PROJECT_CONFIG_MISSING", "res://project.godot", "project.godot was not found.", "Open this folder as a Godot project or restore project.godot.")
		return

	var config := ConfigFile.new()
	var err := config.load("res://project.godot")
	if err != OK:
		_add_issue(issues, SEVERITY_ERROR, "PROJECT_CONFIG_INVALID", "res://project.godot", "project.godot could not be parsed.", "ConfigFile.load returned error code %s." % err)
		return

	var project_name := str(config.get_value("application", "config/name", "")).strip_edges()
	if project_name.is_empty():
		_add_issue(issues, SEVERITY_WARNING, "PROJECT_NAME_MISSING", "res://project.godot", "The project has no application/config/name value.", "Set Project > Project Settings > Application > Config > Name.")

	var icon_path := str(config.get_value("application", "config/icon", "")).strip_edges()
	if icon_path.is_empty():
		_add_issue(issues, SEVERITY_WARNING, "PROJECT_ICON_MISSING", "res://project.godot", "The project has no configured icon.", "Set Project > Project Settings > Application > Config > Icon.")
	else:
		referenced_files[icon_path] = true
		if not _resource_exists(icon_path):
			_add_issue(issues, SEVERITY_ERROR, "PROJECT_ICON_BROKEN", icon_path, "The configured project icon does not exist.", "Update application/config/icon or restore the missing file.")

	var main_scene := str(config.get_value("application", "run/main_scene", "")).strip_edges()
	if main_scene.is_empty():
		_add_issue(issues, SEVERITY_WARNING, "MAIN_SCENE_MISSING", "res://project.godot", "No main scene is configured.", "Set Project > Project Settings > Application > Run > Main Scene before exporting.")
	else:
		referenced_files[main_scene] = true
		if not _resource_exists(main_scene):
			_add_issue(issues, SEVERITY_ERROR, "MAIN_SCENE_BROKEN", main_scene, "The configured main scene does not exist.", "Update application/run/main_scene or restore the missing scene.")

	_check_autoloads(config, issues, referenced_files)


func _check_autoloads(config: ConfigFile, issues: Array[Dictionary], referenced_files: Dictionary) -> void:
	if not config.has_section("autoload"):
		return

	var autoload_paths := {}
	for key in config.get_section_keys("autoload"):
		var raw_value := str(config.get_value("autoload", key, "")).strip_edges()
		var path := raw_value.trim_prefix("*")
		referenced_files[path] = true
		if path.is_empty():
			_add_issue(issues, SEVERITY_ERROR, "AUTOLOAD_EMPTY", "res://project.godot", "Autoload `%s` has no path." % key, "Remove it or assign a script or scene path.")
		elif not _resource_exists(path):
			_add_issue(issues, SEVERITY_ERROR, "AUTOLOAD_BROKEN", path, "Autoload `%s` points to a missing file." % key, "Update the autoload path or restore the missing file.")

		if autoload_paths.has(path):
			_add_issue(issues, SEVERITY_WARNING, "AUTOLOAD_DUPLICATE_PATH", path, "Multiple autoloads point to the same file.", "`%s` and `%s` both use this path." % [autoload_paths[path], key])
		else:
			autoload_paths[path] = key


func _check_export_presets(issues: Array[Dictionary]) -> void:
	if not FileAccess.file_exists("res://export_presets.cfg"):
		_add_issue(issues, SEVERITY_WARNING, "EXPORT_PRESETS_MISSING", "res://export_presets.cfg", "No export_presets.cfg file was found.", "Create at least one export preset before release testing.")
		return

	var text := FileAccess.get_file_as_string("res://export_presets.cfg")
	if text.find("[preset.") == -1:
		_add_issue(issues, SEVERITY_WARNING, "EXPORT_PRESETS_EMPTY", "res://export_presets.cfg", "export_presets.cfg exists but no presets were detected.", "Open Project > Export and create or repair export presets.")


func _check_text_file_references(path: String, issues: Array[Dictionary], referenced_files: Dictionary) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return

	for match_result in _reference_regex.search_all(text):
		var ref := _clean_reference(match_result.get_string())
		if ref.is_empty():
			continue
		referenced_files[ref] = true
		if not _resource_exists(ref):
			_add_issue(issues, SEVERITY_ERROR, "BROKEN_REFERENCE", path, "Missing resource reference: %s" % ref, "This reference appears inside %s." % path)


func _clean_reference(reference: String) -> String:
	var ref := reference.strip_edges()
	while not ref.is_empty() and ref.substr(ref.length() - 1, 1) in [".", ":", "]", ")"]:
		ref = ref.substr(0, ref.length() - 1)
	return ref


func _resource_exists(path: String) -> bool:
	if path.is_empty():
		return false
	if FileAccess.file_exists(path):
		return true
	if ResourceLoader.exists(path):
		return true
	var dir := DirAccess.open(path)
	return dir != null


func _check_large_files(files: Array[String], issues: Array[Dictionary]) -> void:
	var threshold_bytes := int(large_file_threshold_mb * 1024.0 * 1024.0)
	for path in files:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var length := file.get_length()
		if length >= threshold_bytes:
			var mb := float(length) / 1024.0 / 1024.0
			_add_issue(issues, SEVERITY_WARNING, "LARGE_FILE", path, "Large file detected: %.2f MB." % mb, "Check whether this file should be compressed, resized, streamed, or excluded from exports.")


func _check_file_names(files: Array[String], issues: Array[Dictionary]) -> void:
	for path in files:
		var normalized := path.replace("res://", "").to_lower()
		if normalized.find(" ") != -1:
			_add_issue(issues, SEVERITY_INFO, "FILE_NAME_HAS_SPACES", path, "File path contains spaces.", "Spaces are allowed, but snake_case paths are easier to use safely across platforms and tools.")

		if _safe_name_regex.search(normalized) == null:
			_add_issue(issues, SEVERITY_INFO, "FILE_NAME_HAS_SPECIAL_CHARACTERS", path, "File path contains characters outside a-z, 0-9, underscore, dash, slash, or dot.", "Consider renaming for better cross-platform safety.")


func _check_duplicate_paths_by_case(files: Array[String], issues: Array[Dictionary]) -> void:
	var seen := {}
	for path in files:
		var lower := path.to_lower()
		if seen.has(lower) and seen[lower] != path:
			_add_issue(issues, SEVERITY_WARNING, "CASE_COLLISION", path, "Another file only differs by letter casing.", "Conflicts with %s on case-insensitive file systems." % seen[lower])
		else:
			seen[lower] = path


func _check_screenshot_folder_metadata(files: Array[String], issues: Array[Dictionary]) -> void:
	var screenshot_dirs := {}
	for path in files:
		var lower := path.to_lower()
		if lower.find("screenshot") != -1 or lower.find("preview") != -1:
			if _is_asset_file(path):
				screenshot_dirs[path.get_base_dir()] = true

	for dir_path in screenshot_dirs.keys():
		var marker := str(dir_path).path_join(".gdignore")
		if not FileAccess.file_exists(marker):
			_add_issue(issues, SEVERITY_INFO, "SCREENSHOT_FOLDER_MISSING_GDIGNORE", dir_path, "A screenshot or preview folder may be imported by Godot.", "Add a .gdignore file if these images are only for documentation or store previews.")


func _check_likely_unused_assets(files: Array[String], referenced_files: Dictionary, issues: Array[Dictionary]) -> void:
	var count := 0
	for path in files:
		if count >= unused_file_limit:
			_add_issue(issues, SEVERITY_INFO, "UNUSED_CHECK_LIMIT_REACHED", "res://", "Unused asset reporting stopped after %s entries." % unused_file_limit, "Raise unused_file_limit in project_health_scanner.gd if we need a deeper report.")
			return
		if not _is_asset_file(path):
			continue
		if path.begins_with("res://addons/"):
			continue
		if referenced_files.has(path):
			continue
		if path.to_lower().find("screenshot") != -1 or path.to_lower().find("preview") != -1:
			continue
		_add_issue(issues, SEVERITY_INFO, "LIKELY_UNUSED_ASSET", path, "This asset was not referenced by scanned text resources.", "This is heuristic. Keep it if loaded dynamically, included by export filters, or referenced by code generated at runtime.")
		count += 1


func _summarize(issues: Array[Dictionary]) -> Dictionary:
	var summary := {
		SEVERITY_ERROR: 0,
		SEVERITY_WARNING: 0,
		SEVERITY_INFO: 0
	}
	for issue in issues:
		var severity := str(issue.get("severity", SEVERITY_INFO))
		if not summary.has(severity):
			summary[severity] = 0
		summary[severity] += 1
	return summary


func _add_issue(issues: Array[Dictionary], severity: String, code: String, path: String, message: String, detail := "") -> void:
	issues.append({
		"severity": severity,
		"code": code,
		"path": path,
		"message": message,
		"detail": detail
	})
