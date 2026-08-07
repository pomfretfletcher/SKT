@tool
class_name SingleLevel_UT
extends UnlockType

@export_tool_button("Unlock")
var but_unlock = _progress_skill
@export_tool_button("Lock")
var but_lock = _regress_skill

var changing_unlock_status_by_script := false
@export var unlock_status: bool:
	set(v):
		if _setup and not changing_unlock_status_by_script:
			print("Must use unlock and lock buttons/functions to change unlock status.")
			return
		unlock_status = v

@export var point_cost: int:
	set(v):
		if v < 0:
			print("Cannot set point cost to a negative value.")
			return
		point_cost = v


func _is_completed() -> bool:
	return unlock_status


func _is_unlocked() -> bool:
	return unlock_status


func _progress_skill():
	if attached_node.can_be_progressed:
		changing_unlock_status_by_script = true
		unlock_status = true
		changing_unlock_status_by_script = false
		if attached_node:
			SkillTreeEvents.skill_progressed.emit(attached_node)
	else:
		print("Cannot unlock node.")


func _regress_skill():
	if attached_node.can_be_regressed:
		changing_unlock_status_by_script = true
		unlock_status = false
		changing_unlock_status_by_script = false
	else:
		print("Cannot lock node.")


# No progression in unlocking this type
func _get_progress_text() -> String:
	return ""


func _decide_single_upgrade_point_cost() -> int:
	return point_cost


func _decide_full_upgrade_point_cost() -> int:
	return point_cost

	#func _init() -> void:
	#super()
	#POINT_COST_PROPERTY_NAME = "point_cost"

#func _init() -> void:
#super()
#POINT_COST_PROPERTY_NAME = "point_cost"
