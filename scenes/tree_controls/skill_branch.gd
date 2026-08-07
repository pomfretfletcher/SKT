@tool
class_name SkillBranch
extends Control

@export var start_node: SkillNode
@export var end_node: SkillNode
@export var unlock_condition: UnlockCondition:
	set(v):
		# When reconstructing a saved skill tree, we simply need to produce the saved state.
		# However during this recreation phase, the checks done within SkillTreeChecks will
		# almost always come out as false as only part of it is completed and 'valid' until
		# recreation is fully done. We use the _setup variable to make sure that we can recreate
		# the saved state without having to check validity.
		if not _setup:
			unlock_condition = v

		var result: ValidityStatement = SkillTreeChecks.is_new_unlock_condition_valid(v, self)
		if result == null:
			return
		elif result.validity:
			unlock_condition = v
			if unlock_condition:
				unlock_condition.attached_branch = self
		else:
			print(result.reason)
var branch_follow_points: Array[BranchFollowPoint]:
	get:
		var result: Array[BranchFollowPoint] = []
		for child in get_children():
			if child is BranchFollowPoint:
				result.append(child)
		return result

@export var arrow_visible: bool = true

@export_subgroup("Visual Component References")
@export var node_arc: ColorRect
@export var shader_arc: ColorRect
@export var arrow: TextureRect
@export var shader_arrow: TextureRect

@export_subgroup("Tool Buttons")
@export_tool_button("Create Follow Point")
var but_createfollowpoint = func():
	SkillTreeRequests.request_create_followpoint.emit(self)

var _setup := false


func _init() -> void:
	SkillTreeEvents.tree_setup.connect(
		func():
			_setup = true
	)

#region - Warnings and Inspector Display Methods -
func _enter_tree() -> void:
	if not editor_state_changed.is_connected(update_configuration_warnings):
		editor_state_changed.connect(update_configuration_warnings)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if start_node == null:
		warnings.append("Branch must have a start node chosen.")
	if end_node == null:
		warnings.append("Branch must have a end node chosen.")
	if unlock_condition == null:
		warnings.append("Branch must have a unlock condition chosen.")

	return warnings
#endregion
