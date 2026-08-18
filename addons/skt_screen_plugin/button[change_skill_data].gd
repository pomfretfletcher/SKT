@tool
extends SKT_Button

var selected_node: SkillNode


func _ready() -> void:
	set_button_inactive()
	TreeInteractionSignals.node_selected.connect(
		func(node):
			selected_node = node
			set_button_active()
	)
	TreeInteractionSignals.tree_control_deselected.connect(set_button_inactive)
