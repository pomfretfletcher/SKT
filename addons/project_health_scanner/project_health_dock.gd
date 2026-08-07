@tool
extends VBoxContainer

const ProjectHealthScanner := preload("res://addons/project_health_scanner/project_health_scanner.gd")

var editor_interface: EditorInterface
var _scanner := ProjectHealthScanner.new()
var _last_result: Dictionary = {}

var _summary_label: Label
var _status_label: Label
var _tree: Tree
var _scan_button: Button
var _export_button: Button
var _include_addons_check: CheckBox
var _unused_check: CheckBox


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	if get_child_count() > 0:
		return

	var title := Label.new()
	title.text = "Project Health Scanner"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)

	var description := Label.new()
	description.text = "Scan for broken references, missing export presets, invalid autoloads, large files, unsafe names, and likely unused assets."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)

	var options := HBoxContainer.new()
	add_child(options)

	_include_addons_check = CheckBox.new()
	_include_addons_check.text = "Include addons"
	_include_addons_check.tooltip_text = "Off by default to avoid reporting issues from third-party addons."
	options.add_child(_include_addons_check)

	_unused_check = CheckBox.new()
	_unused_check.text = "Unused check"
	_unused_check.button_pressed = true
	_unused_check.tooltip_text = "Reports asset files that are not referenced by scanned text resources. This is heuristic."
	options.add_child(_unused_check)

	var buttons := HBoxContainer.new()
	add_child(buttons)

	_scan_button = Button.new()
	_scan_button.text = "Scan Project"
	_scan_button.pressed.connect(_on_scan_pressed)
	buttons.add_child(_scan_button)

	_export_button = Button.new()
	_export_button.text = "Export Markdown"
	_export_button.disabled = true
	_export_button.pressed.connect(_on_export_pressed)
	buttons.add_child(_export_button)

	_summary_label = Label.new()
	_summary_label.text = "No scan has been run yet."
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary_label)

	_tree = Tree.new()
	_tree.columns = 4
	_tree.set_column_title(0, "Severity")
	_tree.set_column_title(1, "Code")
	_tree.set_column_title(2, "Path")
	_tree.set_column_title(3, "Message")
	_tree.column_titles_visible = true
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_tree)

	_status_label = Label.new()
	_status_label.text = "Tip: double-click a row to open the path when possible."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status_label)

	_tree.item_activated.connect(_on_item_activated)


func _on_scan_pressed() -> void:
	_scan_button.disabled = true
	_export_button.disabled = true
	_status_label.text = "Scanning..."
	_tree.clear()

	_last_result = _scanner.scan(_include_addons_check.button_pressed, _unused_check.button_pressed)
	_render_result(_last_result)

	_scan_button.disabled = false
	_export_button.disabled = false


func _render_result(result: Dictionary) -> void:
	var summary: Dictionary = result.get("summary", {})
	var issues: Array = result.get("issues", [])

	_summary_label.text = "Files: %s | Text files: %s | Errors: %s | Warnings: %s | Info: %s | Time: %s ms" % [
		summary.get("files_scanned", 0),
		summary.get("text_files_scanned", 0),
		summary.get("ERROR", 0),
		summary.get("WARNING", 0),
		summary.get("INFO", 0),
		summary.get("elapsed_ms", 0)
	]

	var root := _tree.create_item()
	for issue in issues:
		var item := _tree.create_item(root)
		item.set_text(0, str(issue.get("severity", "INFO")))
		item.set_text(1, str(issue.get("code", "UNKNOWN")))
		item.set_text(2, str(issue.get("path", "res://")))
		item.set_text(3, str(issue.get("message", "")))
		item.set_metadata(0, issue)
		var tooltip := str(issue.get("detail", ""))
		if not tooltip.is_empty():
			for column in range(4):
				item.set_tooltip_text(column, tooltip)

	if issues.is_empty():
		_status_label.text = "No issues found."
	else:
		_status_label.text = "Scan complete. Review errors, warnings, then info items."


func _on_export_pressed() -> void:
	if _last_result.is_empty():
		_status_label.text = "Run a scan before exporting."
		return

	var report_path := "res://project_health_report.md"
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		_status_label.text = "Could not write %s" % report_path
		return

	file.store_string(_scanner.to_markdown_report(_last_result))
	file.close()
	_status_label.text = "Report saved to %s" % report_path

	if editor_interface != null:
		editor_interface.get_resource_filesystem().scan()


func _on_item_activated() -> void:
	var item := _tree.get_selected()
	if item == null:
		return

	var issue: Dictionary = item.get_metadata(0)
	var path := str(issue.get("path", ""))
	if path.is_empty() or not path.begins_with("res://"):
		return

	if editor_interface != null and FileAccess.file_exists(path):
		if path.get_extension().to_lower() == "tscn":
			editor_interface.open_scene_from_path(path)
		else:
			var resource := load(path)
			if resource != null:
				editor_interface.edit_resource(resource)
