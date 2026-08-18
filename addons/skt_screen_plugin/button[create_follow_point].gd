@tool
extends SKT_Button

var selected_branch: SkillBranch


func _ready() -> void:
	set_button_inactive()
	TreeInteractionSignals.branch_selected.connect(
		func(branch):
			selected_branch = branch
			set_button_active()
	)
	TreeInteractionSignals.tree_control_deselected.connect(set_button_inactive)
