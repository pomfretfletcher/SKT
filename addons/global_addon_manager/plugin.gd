@tool
extends EditorPlugin


enum PendingAction {
	NONE,
	OVERWRITE_PROJECT,
	OVERWRITE_GLOBAL,
	REMOVE_PROJECT,
}


enum AddonType {
	UNKNOWN,
	EDITOR_PLUGIN,
	GDEXTENSION,
	HYBRID,
}


const LEGACY_CONFIG_PATH := "user://global_addon_manager.cfg"
const CONFIG_DIRECTORY_NAME := "Godot"
const CONFIG_FILE_NAME := "global_addon_manager.cfg"
const CONFIG_SECTION := "settings"
const CONFIG_KEY_GLOBAL_PATH := "global_addons_path"

const PROJECT_ADDONS_RES := "res://addons"
const SELF_ADDON_FOLDER := "global_addon_manager"
const MAX_GDEXTENSION_SEARCH_DEPTH := 8

const GDEXTENSION_SEARCH_IGNORED_FOLDERS := [
	"example",
	"examples",
	"demo",
	"demos",
	"test",
	"tests",
	"docs",
	"documentation",
]


var main_panel: Control

var global_path_edit: LineEdit

var global_search_edit: LineEdit
var global_addon_list: ItemList
var global_details_label: Label
var global_count_label: Label
var global_install_button: Button
var global_update_project_button: Button

var project_search_edit: LineEdit
var project_addon_list: ItemList
var project_details_label: Label
var project_count_label: Label
var project_toggle_button: Button
var project_add_to_global_button: Button
var project_update_global_button: Button
var project_remove_button: Button

var status_label: Label

var folder_dialog: FileDialog
var confirmation_dialog: ConfirmationDialog

var selected_global_addon_folder := ""
var selected_project_addon_folder := ""
var last_saved_global_path := ""

var global_addon_count := 0
var project_addon_count := 0

var pending_action := PendingAction.NONE
var pending_addon_folder := ""

var editor_file_system: EditorFileSystem
var filesystem_refresh_queued := false
var resource_import_in_progress := false

var addon_type_cache: Dictionary = {}
var gdextension_path_cache: Dictionary = {}


# ==============================================================================
# Editor lifecycle
# ==============================================================================


func _enter_tree() -> void:
	_build_ui()

	var editor_main_screen := EditorInterface.get_editor_main_screen()
	editor_main_screen.add_child(main_panel)

	main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_connect_editor_filesystem()
	_make_visible(false)
	_initialize_global_library()


func _exit_tree() -> void:
	filesystem_refresh_queued = false
	resource_import_in_progress = false

	_disconnect_editor_filesystem()

	if is_instance_valid(main_panel):
		main_panel.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if is_instance_valid(main_panel):
		main_panel.visible = visible


func _get_plugin_name() -> String:
	return "Addons"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(
		"PluginScript",
		"EditorIcons"
	)


# ==============================================================================
# Editor filesystem monitoring
# ==============================================================================


func _connect_editor_filesystem() -> void:
	editor_file_system = EditorInterface.get_resource_filesystem()

	if editor_file_system == null:
		return

	var filesystem_changed_callback := Callable(
		self,
		"_on_editor_filesystem_changed"
	)
	var reimporting_callback := Callable(
		self,
		"_on_resources_reimporting"
	)
	var reimported_callback := Callable(
		self,
		"_on_resources_reimported"
	)

	if not editor_file_system.filesystem_changed.is_connected(
		filesystem_changed_callback
	):
		editor_file_system.filesystem_changed.connect(
			filesystem_changed_callback
		)

	if not editor_file_system.resources_reimporting.is_connected(
		reimporting_callback
	):
		editor_file_system.resources_reimporting.connect(
			reimporting_callback
		)

	if not editor_file_system.resources_reimported.is_connected(
		reimported_callback
	):
		editor_file_system.resources_reimported.connect(
			reimported_callback
		)


func _disconnect_editor_filesystem() -> void:
	if editor_file_system == null:
		return

	var filesystem_changed_callback := Callable(
		self,
		"_on_editor_filesystem_changed"
	)
	var reimporting_callback := Callable(
		self,
		"_on_resources_reimporting"
	)
	var reimported_callback := Callable(
		self,
		"_on_resources_reimported"
	)

	if editor_file_system.filesystem_changed.is_connected(
		filesystem_changed_callback
	):
		editor_file_system.filesystem_changed.disconnect(
			filesystem_changed_callback
		)

	if editor_file_system.resources_reimporting.is_connected(
		reimporting_callback
	):
		editor_file_system.resources_reimporting.disconnect(
			reimporting_callback
		)

	if editor_file_system.resources_reimported.is_connected(
		reimported_callback
	):
		editor_file_system.resources_reimported.disconnect(
			reimported_callback
		)


func _on_editor_filesystem_changed() -> void:
	_queue_filesystem_refresh()


func _on_resources_reimporting(
	_resources: PackedStringArray
) -> void:
	resource_import_in_progress = true


func _on_resources_reimported(
	_resources: PackedStringArray
) -> void:
	resource_import_in_progress = false
	_queue_filesystem_refresh()


func _queue_filesystem_refresh() -> void:
	if filesystem_refresh_queued:
		return

	filesystem_refresh_queued = true
	call_deferred("_perform_queued_filesystem_refresh")


func _perform_queued_filesystem_refresh() -> void:
	# Clear this first. Refreshing may indirectly cause another filesystem
	# notification, which should be allowed to queue another refresh.
	filesystem_refresh_queued = false

	if not is_instance_valid(main_panel):
		return

	var previous_project_count := project_addon_count

	# These lists use DirAccess directly, so they do not need to wait
	# for EditorFileSystem.scan() to finish.
	_refresh_all(false)

	if (
		main_panel.visible
		and project_addon_count > previous_project_count
	):
		_set_status(
			"Detected %d new project addon(s)."
			% (project_addon_count - previous_project_count)
		)


func _request_editor_filesystem_scan() -> void:
	# Do not keep a persistent pending state. A deferred, best-effort scan
	# avoids re-entering the current file operation and cannot become stuck
	# if this @tool script is reloaded.
	call_deferred("_perform_requested_editor_filesystem_scan")


func _perform_requested_editor_filesystem_scan() -> void:
	var filesystem := editor_file_system

	if not is_instance_valid(filesystem):
		filesystem = EditorInterface.get_resource_filesystem()
		editor_file_system = filesystem

	if filesystem == null:
		return

	# The plugin's own lists have already been refreshed through DirAccess.
	# If Godot is busy, let the active scan/import finish instead of starting
	# a second scan or keeping a request that can remain locked after reload.
	if resource_import_in_progress or filesystem.is_scanning():
		return

	filesystem.scan()


# ==============================================================================
# UI construction
# ==============================================================================


func _build_ui() -> void:
	main_panel = Control.new()
	main_panel.name = "GlobalAddonManagerMainScreen"
	main_panel.custom_minimum_size = Vector2.ZERO
	main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.clip_contents = true

	var root_margin := MarginContainer.new()
	root_margin.name = "RootMargin"
	root_margin.custom_minimum_size = Vector2.ZERO
	root_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.add_child(root_margin)
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	root_margin.add_theme_constant_override("margin_left", 16)
	root_margin.add_theme_constant_override("margin_top", 14)
	root_margin.add_theme_constant_override("margin_right", 16)
	root_margin.add_theme_constant_override("margin_bottom", 14)

	var main_scroll := ScrollContainer.new()
	main_scroll.name = "MainScroll"
	main_scroll.custom_minimum_size = Vector2.ZERO
	main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_margin.add_child(main_scroll)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.custom_minimum_size = Vector2.ZERO
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	main_scroll.add_child(content)

	_build_header(content)
	_build_addon_section(content)
	_build_status_bar(content)
	_build_dialogs()


func _build_header(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_column)

	var title := Label.new()
	title.text = "Global Addon Manager"
	title.add_theme_font_size_override("font_size", 23)
	text_column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = (
		"Manage editor plugins and GDExtensions across Godot projects."
	)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(subtitle)

	var path_column := VBoxContainer.new()
	path_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_column.add_theme_constant_override("separation", 6)
	row.add_child(path_column)

	var heading := Label.new()
	heading.text = "Global Library Location"
	heading.add_theme_font_size_override("font_size", 17)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_column.add_child(heading)

	var path_row := HBoxContainer.new()
	path_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_row.add_theme_constant_override("separation", 6)
	path_column.add_child(path_row)

	global_path_edit = LineEdit.new()
	global_path_edit.placeholder_text = (
		"Select a custom global addon library folder"
	)
	global_path_edit.tooltip_text = (
		"Press Enter to save a typed path. Leaving the field without "
		+ "pressing Enter restores the last saved path."
	)
	global_path_edit.clear_button_enabled = true
	global_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	global_path_edit.text_submitted.connect(
		_on_global_path_submitted
	)
	global_path_edit.focus_exited.connect(
		_on_global_path_focus_exited
	)
	path_row.add_child(global_path_edit)

	var browse_button := Button.new()
	browse_button.text = "Browse"
	browse_button.pressed.connect(_browse_for_global_folder)
	path_row.add_child(browse_button)

	var refresh_button := Button.new()
	refresh_button.text = "Refresh"
	refresh_button.tooltip_text = (
		"Rescan the current project and the external global library."
	)
	refresh_button.pressed.connect(_refresh_addons)
	row.add_child(refresh_button)


func _build_addon_section(parent: VBoxContainer) -> void:
	var split := HSplitContainer.new()
	split.name = "AddonSplit"
	split.custom_minimum_size = Vector2(0, 360)
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.clip_contents = true
	parent.add_child(split)

	_build_global_panel(split)
	_build_project_panel(split)


func _build_global_panel(parent: HSplitContainer) -> void:
	var card := _create_card(parent, true)

	var heading_row := HBoxContainer.new()
	heading_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(heading_row)

	var heading := Label.new()
	heading.text = "Global Library"
	heading.add_theme_font_size_override("font_size", 18)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)

	global_count_label = Label.new()
	global_count_label.text = "0 items"
	heading_row.add_child(global_count_label)

	global_search_edit = LineEdit.new()
	global_search_edit.placeholder_text = "Search global addons..."
	global_search_edit.clear_button_enabled = true
	global_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	global_search_edit.text_changed.connect(
		_on_global_search_changed
	)
	card.add_child(global_search_edit)

	var global_list_frame := _create_list_frame(card)

	global_addon_list = ItemList.new()
	global_addon_list.select_mode = ItemList.SELECT_SINGLE
	global_addon_list.allow_reselect = true
	global_addon_list.custom_minimum_size = Vector2(0, 200)
	global_addon_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	global_addon_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	global_addon_list.item_selected.connect(
		_on_global_addon_selected
	)
	global_list_frame.add_child(global_addon_list)

	global_details_label = Label.new()
	global_details_label.text = (
		"Select a global addon to install or update it."
	)
	global_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(global_details_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 6)
	card.add_child(actions)

	global_install_button = Button.new()
	global_install_button.text = "Install"
	global_install_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	global_install_button.pressed.connect(
		_copy_selected_global_to_project
	)
	actions.add_child(global_install_button)

	global_update_project_button = Button.new()
	global_update_project_button.text = "Update Project"
	global_update_project_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	global_update_project_button.pressed.connect(
		_request_overwrite_project
	)
	actions.add_child(global_update_project_button)


func _build_project_panel(parent: HSplitContainer) -> void:
	var card := _create_card(parent, true)

	var heading_row := HBoxContainer.new()
	heading_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(heading_row)

	var heading := Label.new()
	heading.text = "Current Project"
	heading.add_theme_font_size_override("font_size", 18)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)

	project_count_label = Label.new()
	project_count_label.text = "0 items"
	heading_row.add_child(project_count_label)

	project_search_edit = LineEdit.new()
	project_search_edit.placeholder_text = "Search project addons..."
	project_search_edit.clear_button_enabled = true
	project_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	project_search_edit.text_changed.connect(
		_on_project_search_changed
	)
	card.add_child(project_search_edit)

	var project_list_frame := _create_list_frame(card)

	project_addon_list = ItemList.new()
	project_addon_list.select_mode = ItemList.SELECT_SINGLE
	project_addon_list.allow_reselect = true
	project_addon_list.custom_minimum_size = Vector2(0, 200)
	project_addon_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	project_addon_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	project_addon_list.item_selected.connect(
		_on_project_addon_selected
	)
	project_list_frame.add_child(project_addon_list)

	project_details_label = Label.new()
	project_details_label.text = "Select a project addon to manage it."
	project_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(project_details_label)

	project_toggle_button = Button.new()
	project_toggle_button.text = "Enable Plugin"
	project_toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	project_toggle_button.pressed.connect(
		_toggle_selected_project_plugin
	)
	card.add_child(project_toggle_button)

	var global_actions := HBoxContainer.new()
	global_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	global_actions.add_theme_constant_override("separation", 6)
	card.add_child(global_actions)

	project_add_to_global_button = Button.new()
	project_add_to_global_button.text = "Add to Global"
	project_add_to_global_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	project_add_to_global_button.pressed.connect(
		_copy_selected_project_to_global
	)
	global_actions.add_child(project_add_to_global_button)

	project_update_global_button = Button.new()
	project_update_global_button.text = "Update Global"
	project_update_global_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	project_update_global_button.pressed.connect(
		_request_overwrite_global
	)
	global_actions.add_child(project_update_global_button)

	project_remove_button = Button.new()
	project_remove_button.text = "Remove From Project"
	project_remove_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	project_remove_button.pressed.connect(
		_request_remove_project_addon
	)
	card.add_child(project_remove_button)


func _build_status_bar(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)

	status_label = Label.new()
	status_label.text = "Initializing global addon library..."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(status_label)


func _build_dialogs() -> void:
	folder_dialog = FileDialog.new()
	folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	folder_dialog.mode_overrides_title = false
	folder_dialog.title = "Select Global Addon Library"
	folder_dialog.access = FileDialog.ACCESS_FILESYSTEM
	folder_dialog.use_native_dialog = true
	folder_dialog.dir_selected.connect(
		_on_global_folder_selected
	)
	main_panel.add_child(folder_dialog)

	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.title = "Confirm Action"
	confirmation_dialog.confirmed.connect(
		_on_confirmation_accepted
	)
	confirmation_dialog.canceled.connect(
		_clear_pending_action
	)
	main_panel.add_child(confirmation_dialog)


func _create_list_frame(parent: Control) -> MarginContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2.ZERO
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(frame)

	var editor_theme := EditorInterface.get_editor_theme()
	var frame_style := StyleBoxFlat.new()

	var background_color := Color(0.08, 0.08, 0.08, 0.55)
	var border_color := Color(1.0, 1.0, 1.0, 0.22)

	if editor_theme.has_color("dark_color_2", "Editor"):
		background_color = editor_theme.get_color(
			"dark_color_2",
			"Editor"
		)

	if editor_theme.has_color("contrast_color_1", "Editor"):
		border_color = editor_theme.get_color(
			"contrast_color_1",
			"Editor"
		)

	frame_style.bg_color = background_color
	frame_style.border_color = border_color
	frame_style.border_width_left = 1
	frame_style.border_width_top = 1
	frame_style.border_width_right = 1
	frame_style.border_width_bottom = 1
	frame_style.corner_radius_top_left = 4
	frame_style.corner_radius_top_right = 4
	frame_style.corner_radius_bottom_right = 4
	frame_style.corner_radius_bottom_left = 4

	frame.add_theme_stylebox_override("panel", frame_style)

	var inner_margin := MarginContainer.new()
	inner_margin.custom_minimum_size = Vector2.ZERO
	inner_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner_margin.add_theme_constant_override("margin_left", 4)
	inner_margin.add_theme_constant_override("margin_top", 4)
	inner_margin.add_theme_constant_override("margin_right", 4)
	inner_margin.add_theme_constant_override("margin_bottom", 4)
	frame.add_child(inner_margin)

	return inner_margin


func _create_card(
	parent: Control,
	expand_vertical: bool
) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2.ZERO
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if expand_vertical:
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.custom_minimum_size = Vector2.ZERO
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if expand_vertical:
		margin.size_flags_vertical = Control.SIZE_EXPAND_FILL

	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2.ZERO
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if expand_vertical:
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL

	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)

	return content


# ==============================================================================
# Initialization and configuration
# ==============================================================================


func _initialize_global_library() -> void:
	var saved_path := _load_saved_global_path()
	var is_first_run := saved_path == ""

	if is_first_run:
		saved_path = _get_default_global_path()

	saved_path = _normalize_absolute_path(saved_path)
	last_saved_global_path = saved_path
	global_path_edit.text = saved_path

	var folder_already_existed := DirAccess.dir_exists_absolute(
		saved_path
	)
	var create_error := DirAccess.make_dir_recursive_absolute(
		saved_path
	)

	if create_error != OK:
		_refresh_project_addon_list()
		_set_status(
			"Could not create the global addon folder at %s. %s"
			% [saved_path, _error_text(create_error)]
		)
		return

	var save_error := _save_global_path_to_config(saved_path)

	if save_error != OK:
		_set_status(
			(
				"The folder is available, but its path could not be "
				+ "saved globally. %s"
			) % _error_text(save_error)
		)
		return

	_refresh_all(false)

	if is_first_run and not folder_already_existed:
		_set_status(
			"Global addon folder created at %s. It is ready."
			% saved_path
		)
	elif global_addon_count == 0:
		_set_status(
			"Global addon folder is ready and contains no addons."
		)
	else:
		_set_status(
			"Global addon folder contains %d addon(s)."
			% global_addon_count
		)


func _load_saved_global_path() -> String:
	var config_paths := [
		_get_config_path(),
		LEGACY_CONFIG_PATH,
	]

	for config_path in config_paths:
		var config := ConfigFile.new()

		if config.load(config_path) != OK:
			continue

		var saved_path := _normalize_absolute_path(
			str(
				config.get_value(
					CONFIG_SECTION,
					CONFIG_KEY_GLOBAL_PATH,
					""
				)
			)
		)

		if saved_path != "":
			return saved_path

	return ""


func _get_default_global_path() -> String:
	var documents_path := OS.get_system_dir(
		OS.SYSTEM_DIR_DOCUMENTS
	)

	if documents_path.strip_edges() == "":
		documents_path = OS.get_data_dir()

	if documents_path.strip_edges() == "":
		documents_path = OS.get_user_data_dir().get_base_dir()

	return documents_path.path_join("Godot").path_join(
		"GlobalAddons"
	)


func _get_config_path() -> String:
	var config_root := OS.get_config_dir()

	if config_root.strip_edges() == "":
		config_root = OS.get_data_dir()

	if config_root.strip_edges() == "":
		config_root = OS.get_user_data_dir().get_base_dir()

	return _normalize_absolute_path(
		config_root.path_join(CONFIG_DIRECTORY_NAME).path_join(
			CONFIG_FILE_NAME
		)
	)


func _save_global_path_to_config(
	global_path: String
) -> Error:
	var config_path := _get_config_path()
	var create_error := DirAccess.make_dir_recursive_absolute(
		config_path.get_base_dir()
	)

	if create_error != OK:
		return create_error

	var config := ConfigFile.new()
	config.set_value(
		CONFIG_SECTION,
		CONFIG_KEY_GLOBAL_PATH,
		global_path
	)

	return config.save(config_path)


func _save_config() -> void:
	var candidate_path := _normalize_absolute_path(
		global_path_edit.text
	)

	if candidate_path == "":
		_restore_last_saved_global_path()
		_set_status(
			"The global addon library path cannot be empty."
		)
		return

	var create_error := DirAccess.make_dir_recursive_absolute(
		candidate_path
	)

	if create_error != OK:
		_restore_last_saved_global_path()
		_set_status(
			"Could not create the global folder. %s"
			% _error_text(create_error)
		)
		return

	var save_error := _save_global_path_to_config(candidate_path)

	if save_error != OK:
		_restore_last_saved_global_path()
		_set_status(
			"Could not save the global folder path. %s"
			% _error_text(save_error)
		)
		return

	last_saved_global_path = candidate_path
	global_path_edit.text = candidate_path
	selected_global_addon_folder = ""

	_refresh_all(false)

	if global_addon_count == 0:
		_set_status(
			"Global library path saved. It currently contains no addons."
		)
	else:
		_set_status(
			"Global library path saved. It contains %d addon(s)."
			% global_addon_count
		)


func _restore_last_saved_global_path() -> void:
	if not is_instance_valid(global_path_edit):
		return

	global_path_edit.text = last_saved_global_path


func _browse_for_global_folder() -> void:
	if last_saved_global_path != "":
		folder_dialog.current_dir = last_saved_global_path

	folder_dialog.popup_centered_ratio(0.7)


func _on_global_folder_selected(path: String) -> void:
	global_path_edit.text = _normalize_absolute_path(path)
	_save_config()


func _on_global_path_submitted(_new_text: String) -> void:
	_save_config()


func _on_global_path_focus_exited() -> void:
	if global_path_edit.text != last_saved_global_path:
		_restore_last_saved_global_path()


# ==============================================================================
# Search and selection
# ==============================================================================


func _on_global_search_changed(_new_text: String) -> void:
	_refresh_global_addon_list()
	_update_action_states()


func _on_project_search_changed(_new_text: String) -> void:
	_refresh_project_addon_list()
	_update_action_states()


func _on_global_addon_selected(index: int) -> void:
	selected_global_addon_folder = str(
		global_addon_list.get_item_metadata(index)
	)
	_update_action_states()


func _on_project_addon_selected(index: int) -> void:
	selected_project_addon_folder = str(
		project_addon_list.get_item_metadata(index)
	)
	_update_action_states()


func _addon_matches_search(
	addon_path: String,
	addon_folder: String,
	search_text: String
) -> bool:
	var normalized_search := search_text.strip_edges().to_lower()

	if normalized_search == "":
		return true

	var searchable_text := (
		addon_folder
		+ " "
		+ _get_addon_name(addon_path, addon_folder)
		+ " "
		+ _get_addon_version(addon_path)
		+ " "
		+ _get_addon_type_label(_get_addon_type(addon_path))
	).to_lower()

	return searchable_text.contains(normalized_search)


# ==============================================================================
# Refresh and display
# ==============================================================================


func _refresh_addons() -> void:
	# Refresh the plugin UI immediately. Both the project and global
	# library are read directly through DirAccess.
	_refresh_all(true)

	# Separately ask Godot to update its own FileSystem dock and
	# resource database.
	_request_editor_filesystem_scan()


func _refresh_all(report_status: bool) -> void:
	_clear_addon_detection_cache()
	_refresh_global_addon_list()
	_refresh_project_addon_list()
	_update_action_states()

	if report_status:
		_set_status(_get_refresh_summary_text())


func _get_refresh_summary_text() -> String:
	if global_addon_count == 0:
		return (
			"Global library contains no addons. Current project "
			+ "contains %d addon(s)."
		) % project_addon_count

	return (
		"Global library contains %d addon(s). Current project "
		+ "contains %d addon(s)."
	) % [global_addon_count, project_addon_count]


func _refresh_global_addon_list() -> void:
	global_addon_list.clear()
	global_addon_count = 0

	var global_path := _get_global_path()

	if (
		global_path == ""
		or not DirAccess.dir_exists_absolute(global_path)
	):
		selected_global_addon_folder = ""
		global_count_label.text = "Unavailable"
		return

	var addon_folders := _collect_addon_folders(global_path)
	global_addon_count = addon_folders.size()

	var selected_item_found := false
	var visible_count := 0

	for addon_folder in addon_folders:
		var addon_path := global_path.path_join(addon_folder)

		if not _addon_matches_search(
			addon_path,
			addon_folder,
			global_search_edit.text
		):
			continue

		var index := global_addon_list.get_item_count()
		global_addon_list.add_item(
			_get_global_addon_display_text(
				addon_path,
				addon_folder
			)
		)
		global_addon_list.set_item_metadata(index, addon_folder)
		visible_count += 1

		if addon_folder == selected_global_addon_folder:
			global_addon_list.select(index, true)
			global_addon_list.ensure_current_is_visible()
			selected_item_found = true

	if not selected_item_found:
		selected_global_addon_folder = ""

	global_count_label.text = _format_visible_count(
		visible_count,
		global_addon_count
	)


func _refresh_project_addon_list() -> void:
	project_addon_list.clear()
	project_addon_count = 0

	var project_path := _get_project_addons_absolute_path()

	if not DirAccess.dir_exists_absolute(project_path):
		selected_project_addon_folder = ""
		project_count_label.text = "0 items"
		return

	var addon_folders := _collect_addon_folders(project_path)
	project_addon_count = addon_folders.size()

	var selected_item_found := false
	var visible_count := 0

	for addon_folder in addon_folders:
		var addon_path := project_path.path_join(addon_folder)

		if not _addon_matches_search(
			addon_path,
			addon_folder,
			project_search_edit.text
		):
			continue

		var index := project_addon_list.get_item_count()
		project_addon_list.add_item(
			_get_project_addon_display_text(
				addon_path,
				addon_folder
			)
		)
		project_addon_list.set_item_metadata(index, addon_folder)
		visible_count += 1

		if addon_folder == selected_project_addon_folder:
			project_addon_list.select(index, true)
			project_addon_list.ensure_current_is_visible()
			selected_item_found = true

	if not selected_item_found:
		selected_project_addon_folder = ""

	project_count_label.text = _format_visible_count(
		visible_count,
		project_addon_count
	)


func _collect_addon_folders(
	parent_path: String
) -> Array[String]:
	var addon_folders: Array[String] = []
	var dir := DirAccess.open(parent_path)

	if dir == null:
		return addon_folders

	dir.list_dir_begin()
	var entry_name := dir.get_next()

	while entry_name != "":
		if (
			dir.current_is_dir()
			and entry_name != "."
			and entry_name != ".."
			and not entry_name.begins_with(".")
			and entry_name != SELF_ADDON_FOLDER
		):
			var addon_path := parent_path.path_join(entry_name)

			if _get_addon_type(addon_path) != AddonType.UNKNOWN:
				addon_folders.append(entry_name)

		entry_name = dir.get_next()

	dir.list_dir_end()
	addon_folders.sort()
	return addon_folders


func _update_action_states() -> void:
	_update_global_action_states()
	_update_project_action_states()


func _update_global_action_states() -> void:
	if selected_global_addon_folder == "":
		global_details_label.text = (
			"Select a global addon to install or update it."
		)
		global_install_button.disabled = true
		global_update_project_button.disabled = true
		return

	var addon_folder := selected_global_addon_folder
	var global_addon_path := _get_global_path().path_join(
		addon_folder
	)
	var global_addon_type := _get_addon_type(global_addon_path)
	var type_label := _get_addon_type_label(global_addon_type)
	var is_in_project := _is_project_addon_installed(addon_folder)
	var project_addon_type := AddonType.UNKNOWN
	var project_plugin_is_enabled := false

	if is_in_project:
		project_addon_type = _get_addon_type(
			_get_project_addon_absolute_path(addon_folder)
		)

		if _addon_has_editor_plugin(project_addon_type):
			project_plugin_is_enabled = (
				EditorInterface.is_plugin_enabled(addon_folder)
			)

	if not is_in_project:
		global_details_label.text = (
			"%s is a %s available only in the global library."
			% [addon_folder, type_label]
		)
	elif _addon_has_editor_plugin(project_addon_type):
		var state_text := (
			"enabled" if project_plugin_is_enabled else "disabled"
		)
		global_details_label.text = (
			(
				"%s is a %s installed in this project; its editor "
				+ "plugin is %s."
			) % [addon_folder, type_label, state_text]
		)
	else:
		global_details_label.text = (
			(
				"%s is a GDExtension installed in this project. "
				+ "It has no editor-plugin toggle."
			) % addon_folder
		)

	global_install_button.disabled = is_in_project
	global_update_project_button.disabled = (
		not is_in_project or project_plugin_is_enabled
	)


func _update_project_action_states() -> void:
	if selected_project_addon_folder == "":
		project_details_label.text = (
			"Select a project addon to manage it."
		)
		project_toggle_button.text = "Enable Plugin"
		project_toggle_button.disabled = true
		project_add_to_global_button.disabled = true
		project_update_global_button.disabled = true
		project_remove_button.disabled = true
		return

	var addon_folder := selected_project_addon_folder
	var addon_path := _get_project_addon_absolute_path(addon_folder)
	var addon_type := _get_addon_type(addon_path)
	var type_label := _get_addon_type_label(addon_type)
	var has_editor_plugin := _addon_has_editor_plugin(addon_type)
	var is_enabled := false

	if has_editor_plugin:
		is_enabled = EditorInterface.is_plugin_enabled(addon_folder)

	var is_in_global := _is_global_addon_installed(addon_folder)
	var global_text := (
		"stored globally" if is_in_global else "not stored globally"
	)

	if addon_type == AddonType.GDEXTENSION:
		var descriptor := _get_gdextension_descriptor_name(addon_path)
		project_details_label.text = (
			(
				"%s is a GDExtension and is %s. Godot manages it "
				+ "through %s."
			) % [addon_folder, global_text, descriptor]
		)
		project_toggle_button.text = "No Enable/Disable Toggle"
		project_toggle_button.disabled = true
	else:
		var enabled_text := "enabled" if is_enabled else "disabled"
		project_details_label.text = (
			(
				"%s is a %s, its editor plugin is %s, and it is %s."
			) % [
				addon_folder,
				type_label,
				enabled_text,
				global_text,
			]
		)
		project_toggle_button.text = (
			"Disable Plugin" if is_enabled else "Enable Plugin"
		)
		project_toggle_button.disabled = false

	project_add_to_global_button.disabled = is_in_global
	project_update_global_button.disabled = not is_in_global
	project_remove_button.disabled = has_editor_plugin and is_enabled


func _format_visible_count(
	visible_count: int,
	total_count: int
) -> String:
	if visible_count == total_count:
		return "%d items" % total_count

	return "%d of %d" % [visible_count, total_count]


func _get_global_addon_display_text(
	addon_path: String,
	addon_folder: String
) -> String:
	var display_name := _get_addon_display_name(
		addon_path,
		addon_folder
	)
	var type_label := _get_addon_type_label(
		_get_addon_type(addon_path)
	)
	var location_label := (
		"In project"
		if _is_project_addon_installed(addon_folder)
		else "Global only"
	)

	return "%s  •  %s  •  %s" % [
		display_name,
		type_label,
		location_label,
	]


func _get_project_addon_display_text(
	addon_path: String,
	addon_folder: String
) -> String:
	var display_name := _get_addon_display_name(
		addon_path,
		addon_folder
	)
	var addon_type := _get_addon_type(addon_path)
	var type_label := _get_addon_type_label(addon_type)
	var global_label := (
		"Global copy"
		if _is_global_addon_installed(addon_folder)
		else "Project only"
	)

	if _addon_has_editor_plugin(addon_type):
		var enabled_label := (
			"Enabled"
			if EditorInterface.is_plugin_enabled(addon_folder)
			else "Disabled"
		)
		return "%s  •  %s  •  %s  •  %s" % [
			display_name,
			type_label,
			enabled_label,
			global_label,
		]

	return "%s  •  %s  •  %s" % [
		display_name,
		type_label,
		global_label,
	]


# ==============================================================================
# Addon type detection
# ==============================================================================


func _clear_addon_detection_cache() -> void:
	addon_type_cache.clear()
	gdextension_path_cache.clear()


func _get_addon_type(addon_path: String) -> int:
	var normalized_path := _normalize_absolute_path(addon_path)

	if addon_type_cache.has(normalized_path):
		return int(addon_type_cache[normalized_path])

	var has_plugin_cfg := FileAccess.file_exists(
		normalized_path.path_join("plugin.cfg")
	)
	var gdextension_path := _find_gdextension_descriptor(
		normalized_path
	)
	var has_gdextension := gdextension_path != ""
	var addon_type := AddonType.UNKNOWN

	if has_plugin_cfg and has_gdextension:
		addon_type = AddonType.HYBRID
	elif has_plugin_cfg:
		addon_type = AddonType.EDITOR_PLUGIN
	elif has_gdextension:
		addon_type = AddonType.GDEXTENSION

	addon_type_cache[normalized_path] = addon_type
	gdextension_path_cache[normalized_path] = gdextension_path
	return addon_type


func _find_gdextension_descriptor(
	directory_path: String,
	depth: int = 0
) -> String:
	var normalized_path := _normalize_absolute_path(directory_path)

	if depth == 0 and gdextension_path_cache.has(normalized_path):
		return str(gdextension_path_cache[normalized_path])

	if depth > MAX_GDEXTENSION_SEARCH_DEPTH:
		return ""

	var dir := DirAccess.open(normalized_path)

	if dir == null:
		return ""

	var child_directories: Array[String] = []
	dir.list_dir_begin()
	var entry_name := dir.get_next()

	while entry_name != "":
		if entry_name != "." and entry_name != "..":
			var entry_path := normalized_path.path_join(entry_name)

			if dir.current_is_dir():
				if _should_search_gdextension_directory(entry_name):
					child_directories.append(entry_path)
			elif entry_name.get_extension().to_lower() == "gdextension":
				dir.list_dir_end()

				if depth == 0:
					gdextension_path_cache[normalized_path] = entry_path

				return entry_path

		entry_name = dir.get_next()

	dir.list_dir_end()

	for child_directory in child_directories:
		var descriptor_path := _find_gdextension_descriptor(
			child_directory,
			depth + 1
		)

		if descriptor_path != "":
			if depth == 0:
				gdextension_path_cache[normalized_path] = descriptor_path

			return descriptor_path

	if depth == 0:
		gdextension_path_cache[normalized_path] = ""

	return ""


func _should_search_gdextension_directory(
	directory_name: String
) -> bool:
	if directory_name.begins_with("."):
		return false

	return not GDEXTENSION_SEARCH_IGNORED_FOLDERS.has(
		directory_name.to_lower()
	)


func _addon_has_editor_plugin(addon_type: int) -> bool:
	return (
		addon_type == AddonType.EDITOR_PLUGIN
		or addon_type == AddonType.HYBRID
	)


func _get_addon_type_label(addon_type: int) -> String:
	match addon_type:
		AddonType.EDITOR_PLUGIN:
			return "Editor Plugin"
		AddonType.GDEXTENSION:
			return "GDExtension"
		AddonType.HYBRID:
			return "Editor Plugin + GDExtension"
		_:
			return "Unknown"


func _get_gdextension_descriptor_name(
	addon_path: String
) -> String:
	var descriptor_path := _find_gdextension_descriptor(addon_path)

	if descriptor_path == "":
		return "its .gdextension descriptor"

	return descriptor_path.get_file()


# ==============================================================================
# Enable and disable
# ==============================================================================


func _toggle_selected_project_plugin() -> void:
	var addon_folder := _get_selected_project_addon_folder()

	if addon_folder == "":
		return

	var addon_path := _get_project_addon_absolute_path(addon_folder)
	var addon_type := _get_addon_type(addon_path)

	if not _addon_has_editor_plugin(addon_type):
		_set_status(
			(
				"%s is a GDExtension and does not have an "
				+ "editor-plugin toggle."
			) % addon_folder
		)
		return

	var currently_enabled := EditorInterface.is_plugin_enabled(
		addon_folder
	)
	EditorInterface.set_plugin_enabled(
		addon_folder,
		not currently_enabled
	)

	var actual_state := EditorInterface.is_plugin_enabled(
		addon_folder
	)

	if actual_state == currently_enabled:
		_set_status(
			"Godot could not change the state of %s."
			% addon_folder
		)
		return

	selected_project_addon_folder = addon_folder
	_refresh_project_addon_list()
	_update_action_states()

	if actual_state:
		_set_status("Enabled project plugin: %s" % addon_folder)
	else:
		_set_status("Disabled project plugin: %s" % addon_folder)


# ==============================================================================
# Copy actions
# ==============================================================================


func _copy_selected_global_to_project() -> void:
	var addon_folder := _get_selected_global_addon_folder()

	if addon_folder == "":
		return

	if _is_project_addon_installed(addon_folder):
		_set_status(
			"That addon is already installed. Use Update Project."
		)
		return

	var source_path := _get_global_path().path_join(addon_folder)
	var target_path := _get_project_addon_absolute_path(
		addon_folder
	)
	var addon_type := _get_addon_type(source_path)
	var copy_error := _copy_addon_folder(
		source_path,
		target_path,
		false
	)

	if copy_error != OK:
		_set_status(
			"Could not install the addon. %s"
			% _error_text(copy_error)
		)
		return

	selected_global_addon_folder = addon_folder
	selected_project_addon_folder = addon_folder

	_scan_editor_filesystem()
	_refresh_all(false)

	match addon_type:
		AddonType.EDITOR_PLUGIN:
			_set_status(
				(
					"Installed %s in this project. Its editor plugin "
					+ "is disabled."
				) % addon_folder
			)
		AddonType.GDEXTENSION:
			_set_status(
				(
					"Installed %s in this project. Godot manages it "
					+ "through its .gdextension descriptor."
				) % addon_folder
			)
		AddonType.HYBRID:
			_set_status(
				(
					"Installed %s. Its editor plugin is disabled; "
					+ "its GDExtension component is managed by Godot."
				) % addon_folder
			)
		_:
			_set_status(
				"Installed %s in this project."
				% addon_folder
			)


func _copy_selected_project_to_global() -> void:
	var addon_folder := _get_selected_project_addon_folder()

	if addon_folder == "":
		return

	if _is_global_addon_installed(addon_folder):
		_set_status(
			"That addon already has a global copy. Use Update Global."
		)
		return

	var global_path := _ensure_global_folder_exists()

	if global_path == "":
		return

	var source_path := _get_project_addon_absolute_path(
		addon_folder
	)
	var target_path := global_path.path_join(addon_folder)
	var copy_error := _copy_addon_folder(
		source_path,
		target_path,
		false
	)

	if copy_error != OK:
		_set_status(
			"Could not copy the addon globally. %s"
			% _error_text(copy_error)
		)
		return

	selected_global_addon_folder = addon_folder
	selected_project_addon_folder = addon_folder
	_refresh_all(false)
	_set_status("Added %s to the global library." % addon_folder)


# ==============================================================================
# Confirmation actions
# ==============================================================================


func _request_overwrite_project() -> void:
	var addon_folder := _get_selected_global_addon_folder()

	if addon_folder == "":
		return

	if not _is_project_addon_installed(addon_folder):
		_set_status("The addon is not installed in this project.")
		return

	var project_path := _get_project_addon_absolute_path(
		addon_folder
	)
	var project_type := _get_addon_type(project_path)

	if (
		_addon_has_editor_plugin(project_type)
		and EditorInterface.is_plugin_enabled(addon_folder)
	):
		_set_status(
			"Disable the editor plugin before updating its files."
		)
		return

	pending_action = PendingAction.OVERWRITE_PROJECT
	pending_addon_folder = addon_folder
	confirmation_dialog.title = "Update Project Addon"
	confirmation_dialog.dialog_text = (
		"Replace the project copy of '%s' with the global version?\n\n"
		+ "The existing project files will be replaced safely."
	) % addon_folder
	confirmation_dialog.get_ok_button().text = "Update"
	confirmation_dialog.popup_centered()


func _request_overwrite_global() -> void:
	var addon_folder := _get_selected_project_addon_folder()

	if addon_folder == "":
		return

	if not _is_global_addon_installed(addon_folder):
		_set_status("The addon does not have a global copy.")
		return

	pending_action = PendingAction.OVERWRITE_GLOBAL
	pending_addon_folder = addon_folder
	confirmation_dialog.title = "Update Global Addon"
	confirmation_dialog.dialog_text = (
		(
			"Replace the global copy of '%s' with the current project "
			+ "version?\n\nThe existing global files will be replaced safely."
		) % addon_folder
	)
	confirmation_dialog.get_ok_button().text = "Update"
	confirmation_dialog.popup_centered()


func _request_remove_project_addon() -> void:
	var addon_folder := _get_selected_project_addon_folder()

	if addon_folder == "":
		return

	var addon_path := _get_project_addon_absolute_path(addon_folder)
	var addon_type := _get_addon_type(addon_path)

	if (
		_addon_has_editor_plugin(addon_type)
		and EditorInterface.is_plugin_enabled(addon_folder)
	):
		_set_status("Disable the editor plugin before removing it.")
		return

	pending_action = PendingAction.REMOVE_PROJECT
	pending_addon_folder = addon_folder
	confirmation_dialog.title = "Remove Project Addon"
	confirmation_dialog.dialog_text = (
		"Remove '%s' from this project?\n\n"
		+ "Its global copy will not be affected."
	) % addon_folder
	confirmation_dialog.get_ok_button().text = "Remove"
	confirmation_dialog.popup_centered()


func _on_confirmation_accepted() -> void:
	match pending_action:
		PendingAction.OVERWRITE_PROJECT:
			_overwrite_project_from_global(pending_addon_folder)
		PendingAction.OVERWRITE_GLOBAL:
			_overwrite_global_from_project(pending_addon_folder)
		PendingAction.REMOVE_PROJECT:
			_remove_project_addon(pending_addon_folder)

	_clear_pending_action()


func _clear_pending_action() -> void:
	pending_action = PendingAction.NONE
	pending_addon_folder = ""


func _overwrite_project_from_global(
	addon_folder: String
) -> void:
	if addon_folder == "":
		return

	var project_path := _get_project_addon_absolute_path(
		addon_folder
	)
	var project_type := _get_addon_type(project_path)

	if (
		_addon_has_editor_plugin(project_type)
		and EditorInterface.is_plugin_enabled(addon_folder)
	):
		_set_status("Disable the editor plugin before updating it.")
		return

	var source_path := _get_global_path().path_join(addon_folder)
	var copy_error := _copy_addon_folder(
		source_path,
		project_path,
		true
	)

	if copy_error != OK:
		_set_status(
			(
				"Could not update the project addon. %s If it is a "
				+ "loaded GDExtension, close Godot and try again."
			) % _error_text(copy_error)
		)
		return

	selected_global_addon_folder = addon_folder
	selected_project_addon_folder = addon_folder
	_scan_editor_filesystem()
	_refresh_all(false)
	_set_status("Updated the project copy of %s." % addon_folder)


func _overwrite_global_from_project(
	addon_folder: String
) -> void:
	if addon_folder == "":
		return

	var global_path := _ensure_global_folder_exists()

	if global_path == "":
		return

	var source_path := _get_project_addon_absolute_path(
		addon_folder
	)
	var target_path := global_path.path_join(addon_folder)
	var copy_error := _copy_addon_folder(
		source_path,
		target_path,
		true
	)

	if copy_error != OK:
		_set_status(
			"Could not update the global addon. %s"
			% _error_text(copy_error)
		)
		return

	selected_global_addon_folder = addon_folder
	selected_project_addon_folder = addon_folder
	_refresh_all(false)
	_set_status("Updated the global copy of %s." % addon_folder)


func _remove_project_addon(addon_folder: String) -> void:
	if addon_folder == "":
		return

	var addon_path := _get_project_addon_absolute_path(addon_folder)
	var addon_type := _get_addon_type(addon_path)

	if (
		_addon_has_editor_plugin(addon_type)
		and EditorInterface.is_plugin_enabled(addon_folder)
	):
		_set_status("Disable the editor plugin before removing it.")
		return

	var remove_error := _remove_dir_recursive(addon_path)

	if remove_error != OK:
		_set_status(
			(
				"Could not remove the addon. %s If it is a loaded "
				+ "GDExtension, close Godot and remove it before "
				+ "reopening the project."
			) % _error_text(remove_error)
		)
		return

	selected_project_addon_folder = ""
	_scan_editor_filesystem()
	_refresh_all(false)
	_set_status("Removed %s from this project." % addon_folder)


# ==============================================================================
# Filesystem helpers
# ==============================================================================


func _copy_addon_folder(
	source_path: String,
	target_path: String,
	overwrite_existing: bool
) -> Error:
	var normalized_source := _normalize_absolute_path(source_path)
	var normalized_target := _normalize_absolute_path(target_path)

	if normalized_source == normalized_target:
		return ERR_INVALID_PARAMETER

	if not DirAccess.dir_exists_absolute(normalized_source):
		return ERR_DOES_NOT_EXIST

	_clear_addon_detection_cache()

	if _get_addon_type(normalized_source) == AddonType.UNKNOWN:
		return ERR_FILE_UNRECOGNIZED

	var target_exists := DirAccess.dir_exists_absolute(
		normalized_target
	)

	if target_exists and not overwrite_existing:
		return ERR_ALREADY_EXISTS

	var parent_path := normalized_target.get_base_dir()
	var create_error := DirAccess.make_dir_recursive_absolute(
		parent_path
	)

	if create_error != OK:
		return create_error

	var temporary_path := _get_unique_transaction_path(
		normalized_target,
		"tmp"
	)
	var backup_path := _get_unique_transaction_path(
		normalized_target,
		"backup"
	)

	var copy_error := _copy_dir_recursive(
		normalized_source,
		temporary_path
	)

	if copy_error != OK:
		_cleanup_directory_best_effort(temporary_path)
		return copy_error

	_clear_addon_detection_cache()

	if _get_addon_type(temporary_path) == AddonType.UNKNOWN:
		_cleanup_directory_best_effort(temporary_path)
		return ERR_FILE_UNRECOGNIZED

	if (
		not target_exists
		and DirAccess.dir_exists_absolute(normalized_target)
	):
		_cleanup_directory_best_effort(temporary_path)
		return ERR_ALREADY_EXISTS

	if target_exists:
		var backup_error := DirAccess.rename_absolute(
			normalized_target,
			backup_path
		)

		if backup_error != OK:
			_cleanup_directory_best_effort(temporary_path)
			return backup_error

	var activate_error := DirAccess.rename_absolute(
		temporary_path,
		normalized_target
	)

	if activate_error != OK:
		if target_exists:
			var restore_error := DirAccess.rename_absolute(
				backup_path,
				normalized_target
			)

			if restore_error != OK:
				push_error(
					(
						"Global Addon Manager could not restore the "
						+ "previous addon after a failed update. Backup: %s"
					) % backup_path
				)

		_cleanup_directory_best_effort(temporary_path)
		_clear_addon_detection_cache()
		return activate_error

	if target_exists:
		var cleanup_error := _remove_dir_recursive(backup_path)

		if cleanup_error != OK:
			push_warning(
				(
					"Addon update succeeded, but its temporary backup "
					+ "could not be removed: %s"
				) % backup_path
			)

	_clear_addon_detection_cache()
	return OK


func _get_unique_transaction_path(
	target_path: String,
	label: String
) -> String:
	var parent_path := target_path.get_base_dir()
	var folder_name := target_path.get_file()
	var index := 0

	while true:
		var suffix := label if index == 0 else "%s_%d" % [label, index]
		var candidate := parent_path.path_join(
			".%s.global_addon_manager_%s" % [folder_name, suffix]
		)

		if (
			not DirAccess.dir_exists_absolute(candidate)
			and not FileAccess.file_exists(candidate)
		):
			return candidate

		index += 1

	return ""


func _cleanup_directory_best_effort(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return

	var cleanup_error := _remove_dir_recursive(path)

	if cleanup_error != OK:
		push_warning(
			"Could not clean temporary addon directory: %s"
			% path
		)


func _copy_dir_recursive(
	source_path: String,
	target_path: String
) -> Error:
	if not DirAccess.dir_exists_absolute(source_path):
		return ERR_DOES_NOT_EXIST

	var create_error := DirAccess.make_dir_recursive_absolute(
		target_path
	)

	if create_error != OK:
		return create_error

	var source_dir := DirAccess.open(source_path)

	if source_dir == null:
		return DirAccess.get_open_error()

	source_dir.list_dir_begin()
	var entry_name := source_dir.get_next()

	while entry_name != "":
		if entry_name == "." or entry_name == "..":
			entry_name = source_dir.get_next()
			continue

		var source_item := source_path.path_join(entry_name)
		var target_item := target_path.path_join(entry_name)

		if source_dir.current_is_dir():
			var directory_error := _copy_dir_recursive(
				source_item,
				target_item
			)

			if directory_error != OK:
				source_dir.list_dir_end()
				return directory_error
		else:
			var copy_error := DirAccess.copy_absolute(
				source_item,
				target_item
			)

			if copy_error != OK:
				source_dir.list_dir_end()
				return copy_error

		entry_name = source_dir.get_next()

	source_dir.list_dir_end()
	return OK


func _remove_dir_recursive(path: String) -> Error:
	if not DirAccess.dir_exists_absolute(path):
		return OK

	var dir := DirAccess.open(path)

	if dir == null:
		return DirAccess.get_open_error()

	dir.list_dir_begin()
	var entry_name := dir.get_next()

	while entry_name != "":
		if entry_name == "." or entry_name == "..":
			entry_name = dir.get_next()
			continue

		var item_path := path.path_join(entry_name)

		if dir.current_is_dir():
			var directory_error := _remove_dir_recursive(item_path)

			if directory_error != OK:
				dir.list_dir_end()
				return directory_error
		else:
			var remove_error := DirAccess.remove_absolute(item_path)

			if remove_error != OK:
				dir.list_dir_end()
				return remove_error

		entry_name = dir.get_next()

	dir.list_dir_end()
	return DirAccess.remove_absolute(path)


# ==============================================================================
# Addon metadata
# ==============================================================================


func _get_addon_display_name(
	addon_path: String,
	fallback_folder_name: String
) -> String:
	var plugin_name := _get_addon_name(
		addon_path,
		fallback_folder_name
	)
	var plugin_version := _get_addon_version(addon_path)

	if plugin_version == "":
		return plugin_name

	return "%s  v%s" % [plugin_name, plugin_version]


func _get_addon_name(
	addon_path: String,
	fallback_folder_name: String
) -> String:
	var plugin_config_path := addon_path.path_join("plugin.cfg")

	if not FileAccess.file_exists(plugin_config_path):
		return fallback_folder_name

	var config := ConfigFile.new()
	var load_error := config.load(plugin_config_path)

	if load_error != OK:
		return fallback_folder_name

	return str(
		config.get_value(
			"plugin",
			"name",
			fallback_folder_name
		)
	)


func _get_addon_version(addon_path: String) -> String:
	var plugin_config_path := addon_path.path_join("plugin.cfg")

	if not FileAccess.file_exists(plugin_config_path):
		return ""

	var config := ConfigFile.new()
	var load_error := config.load(plugin_config_path)

	if load_error != OK:
		return ""

	return str(config.get_value("plugin", "version", ""))


func _get_selected_global_addon_folder() -> String:
	if selected_global_addon_folder != "":
		return selected_global_addon_folder

	_set_status("Select a global addon first.")
	return ""


func _get_selected_project_addon_folder() -> String:
	if selected_project_addon_folder != "":
		return selected_project_addon_folder

	_set_status("Select a project addon first.")
	return ""


func _is_project_addon_installed(
	addon_folder: String
) -> bool:
	return DirAccess.dir_exists_absolute(
		_get_project_addon_absolute_path(addon_folder)
	)


func _is_global_addon_installed(
	addon_folder: String
) -> bool:
	var global_path := _get_global_path()

	if global_path == "":
		return false

	return DirAccess.dir_exists_absolute(
		global_path.path_join(addon_folder)
	)


# ==============================================================================
# Paths
# ==============================================================================


func _get_global_path() -> String:
	return last_saved_global_path


func _ensure_global_folder_exists() -> String:
	var global_path := _get_global_path()

	if global_path == "":
		_set_status(
			"Select a global addon library folder first."
		)
		return ""

	var create_error := DirAccess.make_dir_recursive_absolute(
		global_path
	)

	if create_error != OK:
		_set_status(
			"Could not create the global folder. %s"
			% _error_text(create_error)
		)
		return ""

	return global_path


func _normalize_absolute_path(path: String) -> String:
	var normalized := path.strip_edges().replace("\\", "/")

	while normalized.ends_with("/") and normalized.length() > 3:
		normalized = normalized.left(normalized.length() - 1)

	return normalized


func _get_project_addons_absolute_path() -> String:
	return ProjectSettings.globalize_path(PROJECT_ADDONS_RES)


func _get_project_addon_absolute_path(
	addon_folder: String
) -> String:
	return _get_project_addons_absolute_path().path_join(
		addon_folder
	)


func _scan_editor_filesystem() -> void:
	_request_editor_filesystem_scan()


# ==============================================================================
# Status
# ==============================================================================


func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message

	print("[Global Addon Manager] ", message)


func _error_text(error: Error) -> String:
	return "%s (%d)" % [error_string(error), error]
