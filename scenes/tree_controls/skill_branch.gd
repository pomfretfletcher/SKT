@tool
@icon("res://addons/at-icons/control/node_graph_connection.svg")
class_name SkillBranch
extends SkillTreeControl

@export var start_node: SkillNode:
	set(v):
		if start_node != null and self in start_node.result_branches:
			start_node.result_branches.erase(self)
		start_node = v
		if start_node != null:
			start_node.result_branches.append(self)
@export var end_node: SkillNode:
	set(v):
		if not _setup:
			if end_node != null and self in end_node.previous_branches:
				end_node.previous_branches.erase(self)
			end_node = v
			if end_node != null:
				end_node.previous_branches.append(self)
			return
		if v == null and end_node != null:
			if len(end_node.previous_branches) and end_node.is_unlocked():
				MessageLogger.log_issue("Cannot change end node to null as this branch is the only branch to a partially unlocked node.")
		elif v == null:
			if end_node != null and self in end_node.previous_branches:
				end_node.previous_branches.erase(self)
			end_node = v
			return

		# Prevents loops in skill trees. For example A-B-C-A as this would cause
		# none of the nodes from being able to be progressed as they are all reliant
		# on one another.
		var nd: Array[SkillNode]
		SkillTreeFunctions.get_skills_resulting_from_node(v, nd)
		if start_node != null and start_node in nd:
			MessageLogger.log_issue("Cannot choose end node as it would cause a loop in the tree.")
			return
		if v == null and end_node != null:
			if len(end_node.previous_branches) and end_node.is_unlocked():
				MessageLogger.log_issue("Cannot change end node to null as this branch is the only branch to a partially unlocked node.")
		
		if end_node != null and self in end_node.previous_branches:
			end_node.previous_branches.erase(self)
		end_node = v
		if end_node != null:
			end_node.previous_branches.append(self)

@export var unlock_condition: UnlockCondition:
	set(v):
		# When reconstructing a saved skill tree, we simply need to produce the saved state.
		# However during this recreation phase, the checks done within SkillTreeChecks will
		# almost always come out as false as only part of it is completed and 'valid' until
		# recreation is fully done. We use the _setup variable to make sure that we can recreate
		# the saved state without having to check validity.
		if not _setup:
			unlock_condition = v
			if unlock_condition:
				unlock_condition.attached_branch = self
			return

		var result: ValidityStatement = SkillTreeChecks.is_new_unlock_condition_valid(v, self)
		if result == null:
			return
		elif result.validity == true:
			unlock_condition = v
			if unlock_condition != null:
				unlock_condition.attached_branch = self
		else:
			MessageLogger.log_issue(result.reason)
var branch_follow_points: Array[BranchFollowPoint]:
	get:
		var result: Array[BranchFollowPoint] = []
		for child in get_children():
			if child is BranchFollowPoint:
				result.append(child)
		return result

@export var arrow_visible := true

@export_subgroup("Visual Component References")
@export var node_arc: ColorRect
@export var shader_arc: ColorRect
@export var arrow: TextureRect
@export var shader_arrow: TextureRect

@export_subgroup("Tool Buttons")
@export_tool_button("Create Follow Point")
var but_createfollowpoint = func():
	tree.request_create_followpoint.emit(self)

var _setup := false
var tree: SKT_Tree


func setup_data(t: SKT_Tree) -> void:
	tree = t
	tree.tree_setup.connect(
		func():
			_setup = true
	)
	
	if unlock_condition != null:
		unlock_condition.attached_branch = self


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tree.branch_selected.emit(self)

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
