@tool
extends EditorPlugin

func _ready() -> void:
	if not Engine.is_editor_hint():
		_on_main_screen_changed("2D")


func _enter_tree():
	if Engine.is_editor_hint():
		main_screen_changed.connect(_on_main_screen_changed)


func _exit_tree():
	if Engine.is_editor_hint():
		main_screen_changed.disconnect(_on_main_screen_changed)


func _on_main_screen_changed(screen_name: String):
	if screen_name == "2D":
		SkillTreeRequests.request_toggle_tree_updating.emit(true)
		SkillTreeRequests.request_toggle_tree_drawing.emit(true)
	else:
		SkillTreeRequests.request_toggle_tree_updating.emit(false)
		SkillTreeRequests.request_toggle_tree_drawing.emit(false)
