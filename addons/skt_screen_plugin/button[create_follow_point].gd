@tool
extends SKT_Button

var selected_branch: SkillBranch
@export var panel: SKT

func _ready() -> void:
	set_button_inactive()
	panel.selected_control_changed.connect(
		func(control):
			if control is SkillBranch:
				set_button_active()
			else:
				set_button_inactive()
	)
