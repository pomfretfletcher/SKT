@tool
extends SKT_Button

var selected_node: SkillNode
@export var panel: SKT

func _ready() -> void:
	set_button_inactive()
	panel.selected_control_changed.connect(
		func(control):
			if control is SkillNode:
				set_button_active()
			else:
				set_button_inactive()
	)
