@tool
class_name SingleLevel_UT
extends UnlockType

# Internal status variables
var changing_unlock_status_by_script := false

# Variables for progressing through skill node
@export var unlock_status: bool:
	set(v):
		if _setup and not changing_unlock_status_by_script:
			SkillTreeRequests.request_log_issue.emit("Must use unlock and lock buttons/functions to change unlock status.")
		unlock_status = v
@export var point_cost: int:
	set(v):
		if v < 0:
			SkillTreeRequests.request_log_issue.emit("Cannot set point cost to a negative value.")
			return
		point_cost = v

#region Inspector Tool Buttons
@export_tool_button("Unlock")
var but_unlock = func():
	SkillTreeRequests.request_progress_skill.emit(attached_node)
@export_tool_button("Lock")
var but_lock = func():
	SkillTreeRequests.request_regress_skill.emit(attached_node)
#endregion

#region Override Unlock Type Methods
func _is_completed() -> bool:
	return unlock_status


func _is_unlocked() -> bool:
	return unlock_status


func _progress_skill():
	if attached_node.can_be_progressed:
		changing_unlock_status_by_script = true
		unlock_status = true
		changing_unlock_status_by_script = false
		if attached_node != null:
			SkillTreeEvents.skill_progressed.emit(attached_node)
	else:
		SkillTreeRequests.request_log_issue.emit("Cannot unlock node.")


func _regress_skill():
	if attached_node.can_be_regressed:
		changing_unlock_status_by_script = true
		unlock_status = false
		changing_unlock_status_by_script = false
	else:
		SkillTreeRequests.request_log_issue.emit("Cannot lock node.")


# No progression in unlocking this type
func _get_progress_text() -> String:
	return ""


func _decide_single_upgrade_point_cost() -> int:
	return point_cost


func _decide_full_upgrade_point_cost() -> int:
	return point_cost


func _store_upgrade_cost_property_name():
	UPGRADE_COST_PROPERTY_NAME = "point_cost"
#endregion
