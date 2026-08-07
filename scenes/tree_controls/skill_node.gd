@tool
class_name SkillNode
extends Control

@export var skill_data: SkillData:
	set(v):
		skill_data = v
		if skill_data:
			skill_data.attached_node = self

@export_range(0, 100) var progression_tier: int:
	set(v):
		for branch in result_branches:
			if branch.end_node.progression_tier < v:
				print("Cannot change progression tier as the tier for this skill must be less than or equal to the tier for any resulting skills.")
				return
		progression_tier = v

@export_subgroup("Visual Component References")
@export var orb: TextureRect
@export var shader_orb: TextureRect

var previous_branches: Array[SkillBranch]
var result_branches: Array[SkillBranch]

var can_be_progressed: bool = false
var can_be_regressed: bool = true

# Allows a form of abstraction by not needing to call
# xxx_node.skill_data.unlock_type
# Makes code cleaner to read and smaller
# Instead just use xxx_node.unlock_type
var unlock_type: UnlockType:
	set(v):
		skill_data.unlock_type = v
	get:
		return skill_data.unlock_type

var ready_has_occured := false


func _ready() -> void:
	set_notify_transform(true)
	skill_data.attached_node = self
	ready_has_occured = true
	if not SkillTreeEvents.update_tree.is_connected(update_name):
		SkillTreeEvents.update_tree.connect(update_name)


func update_name():
	name = skill_data.name + "SkillNode"


func is_unlocked() -> bool:
	if skill_data == null or skill_data.unlock_type == null:
		return false
	return skill_data.unlock_type._is_unlocked()


func is_completed() -> bool:
	if skill_data == null or skill_data.unlock_type == null:
		return false
	return skill_data.unlock_type._is_completed() and skill_data.unlock_type._is_unlocked()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		SkillTreeEvents.skill_selected.emit(self)

#region - Warnings and Inspector Display Methods -
func _enter_tree() -> void:
	if not editor_state_changed.is_connected(update_configuration_warnings):
		editor_state_changed.connect(update_configuration_warnings)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if result_branches.is_empty() and previous_branches.is_empty():
		warnings.append("Skill Node is not connected to any other skill node.")
	if skill_data == null:
		warnings.append("Skill Node must have a skill data resource.")
	if skill_data and skill_data.unlock_type == null:
		warnings.append("Skill data must have an unlock type chosen.")

	return warnings


func _validate_property(property: Dictionary) -> void:
	if not ready_has_occured:
		return
	if property.name == "progression_tier":
		if not SkillTreeChecks.should_show_progression_tiers():
			property.usage = PROPERTY_USAGE_NO_EDITOR
#endregion
