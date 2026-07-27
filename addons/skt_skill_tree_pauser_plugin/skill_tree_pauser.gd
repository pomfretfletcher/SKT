@tool
extends EditorPlugin

func _enter_tree():
	main_screen_changed.connect(_on_main_screen_changed)


func _exit_tree():
	main_screen_changed.disconnect(_on_main_screen_changed)


func _on_main_screen_changed(screen_name: String):
	if screen_name == "2D":
		SkillTreeEvents.toggle_updating.emit(true)
		SkillTreeEvents.toggle_drawing.emit(true)
	else:
		SkillTreeEvents.toggle_updating.emit(false)
		SkillTreeEvents.toggle_drawing.emit(false)
