@tool
class_name SkillNode
extends Control

@export var skill_data: SkillData:
	set(v):
		skill_data = v
		if skill_data:
			skill_data.attached_node = self

@export var orb: TextureRect
@export var shader_orb: TextureRect

var previous_connections: Array[SkillNodeConnection]
var result_connections: Array[SkillNodeConnection]

var can_be_progressed: bool = false
var can_be_regressed: bool = true

# Allows a form of abstraction by not needing to call
# xxx_node.skill_data.unlock_type
# Makes code cleaner to read and smaller
var unlock_type: UnlockType:
	set(v):
		skill_data.unlock_type = v
	get:
		return skill_data.unlock_type


# Tool Logic - Preset unlock condition value
func _ready() -> void:
	set_notify_transform(true)
	skill_data.attached_node = self

	if !SkillTreeEvents.update_tree.is_connected(update_name):
		SkillTreeEvents.update_tree.connect(update_name)


func update_name():
	name = skill_data.name + "SkillNode"


func is_unlocked() -> bool:
	if !skill_data or !skill_data.unlock_type:
		return false
	return skill_data.unlock_type._is_unlocked()


func is_completed() -> bool:
	if !skill_data or !skill_data.unlock_type:
		return false
	return skill_data.unlock_type._is_completed()


func _gui_input(event: InputEvent) -> void:
	print(event)
