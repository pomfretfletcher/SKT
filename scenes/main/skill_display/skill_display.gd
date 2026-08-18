@tool
class_name SKT_SkillDisplay
extends Panel

var cur_skill: SkillNode

@export var locked_tick_box_texture: Texture2D
@export var partial_unlocked_tick_box_texture: Texture2D
@export var fully_unlocked_tick_box_texture: Texture2D

@export_subgroup("Visual Component References")
@export var skill_name: Label
@export var skill_icon: TextureRect
@export var skill_description: Label
@export var unlock_tick_box: TextureRect
@export var progress_label: Label


func _ready() -> void:
	TreeInteractionSignals.node_selected.connect(
		func(node: SkillNode):
			cur_skill = node
	)
	SkillTreeEvents.update_tree.connect(
		func():
			if cur_skill == null or cur_skill.skill_data == null or cur_skill.skill_data.unlock_type == null:
				return

			var cur_skill_data = cur_skill.skill_data
			skill_name.text = cur_skill_data.name
			skill_icon.texture = cur_skill_data.icon
			skill_description.text = cur_skill_data.description

			var partially_unlocked: bool = cur_skill.is_unlocked()
			var fully_unlocked: bool = cur_skill.is_completed()
			if not partially_unlocked and not fully_unlocked:
				unlock_tick_box.texture = locked_tick_box_texture
			elif partially_unlocked and not fully_unlocked:
				unlock_tick_box.texture = partial_unlocked_tick_box_texture
			elif partially_unlocked and fully_unlocked:
				unlock_tick_box.texture = fully_unlocked_tick_box_texture

			var progress_text: String = cur_skill_data.unlock_type._get_progress_text()
			if progress_text != "":
				progress_label.text = progress_text
			else:
				progress_label.text = ""
	)
