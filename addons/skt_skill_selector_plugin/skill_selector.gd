@tool
extends EditorPlugin

var cur_obj: SkillTreeControl


func _handles(object):
	return object is SkillTreeControl


func _edit(object: Object) -> void:
	if cur_obj != object:
		if object is SkillTreeControl:
			TreeInteractionSignals.tree_control_deselected.emit(object)

	if object != cur_obj:
		cur_obj = object as SkillTreeControl
	else:
		return

	if cur_obj is SkillNode:
		var skill_node: SkillNode = cur_obj
		TreeInteractionSignals.node_selected.emit(skill_node)
	if cur_obj is SkillBranch:
		var skill_branch: SkillBranch = cur_obj
		TreeInteractionSignals.branch_selected.emit(skill_branch)


func _enter_tree() -> void:
	main_screen_changed.connect(_on_msc)


func _on_msc(screen_name: String):
	# Makes it so whenever the main screen is changed (screens including 2D, Script,
	# SKT etc), the active node in the 2D scene tree is deselected. Removes an issue
	# where loading save data while in SKT screen when a node is selected in 2D screen
	# would cause a signal disconnection issues.
	# Said error:
	# ERROR: Disconnecting nonexistent signal 'draw' in '<Object#0>'.
	var editor_interface = get_editor_interface()
	if editor_interface:
		var selection = editor_interface.get_selection()
		selection.clear()

		if cur_obj != null:
			TreeInteractionSignals.tree_control_deselected.emit(cur_obj)
			cur_obj = null
