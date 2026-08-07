@tool
extends EditorPlugin

const ProjectHealthDock := preload("res://addons/project_health_scanner/project_health_dock.gd")

var _dock: Control
var _bottom_button: Button


func _enter_tree() -> void:
	call_deferred("_add_health_scanner_panel")


func _add_health_scanner_panel() -> void:
	if not is_inside_tree() or is_instance_valid(_dock):
		return

	_dock = ProjectHealthDock.new()
	_dock.name = "Health Scanner"
	_dock.editor_interface = get_editor_interface()
	_dock.custom_minimum_size = Vector2(0, 180)

	_bottom_button = add_control_to_bottom_panel(_dock, "Health Scanner")


func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
	_dock = null
	_bottom_button = null
