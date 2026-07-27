@tool
extends EditorPlugin

var cur_obj: Object


func _handles(object):
	return object is SkillNode


func _edit(object: Object) -> void:
	if object != cur_obj:
		cur_obj = object
	if cur_obj is SkillNode:
		var skill_node: SkillNode = cur_obj
		SkillTreeEvents.skill_selected.emit(skill_node)
