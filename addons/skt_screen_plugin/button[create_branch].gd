@tool
extends SKT_Button

func _ready() -> void:
	TreeInteractionSignals.node_selected.connect(set_button_inactive)
	TreeInteractionSignals.branch_selected.connect(set_button_inactive)
	TreeInteractionSignals.followpoint_selected.connect(set_button_inactive)
	TreeInteractionSignals.tree_control_deselected.connect(set_button_active)
