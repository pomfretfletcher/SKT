@tool
extends Node

@warning_ignore("unused_signal")
signal node_selected(node: SkillNode)

@warning_ignore("unused_signal")
signal branch_selected(branch: SkillBranch)

@warning_ignore("unused_signal")
signal followpoint_selected(follow_point: BranchFollowPoint)

@warning_ignore("unused_signal")
signal node_moved(node: SkillNode)

@warning_ignore("unused_signal")
signal followpoint_moved(follow_point: BranchFollowPoint)

@warning_ignore("unused_signal")
signal tree_control_deselected(previous_control: Control)
