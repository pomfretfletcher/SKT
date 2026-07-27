@tool
extends Node

## Event that will trigger a set number of times per second. Emitted only by the
## TreeUpdator node, this can be disabled with its exported can_update boolean or
## by switching to any godot editor screen other than 2D. This is to prevent logic
## issues when editing tool scripts.
## [br][br]
## Other nodes can connect functions to be called whenever the tree is updated. These
## functions may be expensive as it is only called a few times each second. Built in
## processes called by this signal include checking whether nodes and connections are
## unlocked, locked, unlockable etc.
@warning_ignore("unused_signal")
signal update_tree

## Event that will trigger a set number of times per second. Emitted only by the
## TreeDrawer node, this can be disabled with its exported can_draw boolean or
## by switching to any godot editor screen other than 2D. This is to prevent logic
## issues when editing tool scripts.
## [br][br]
## Other nodes can connect functions to be called whenever the tree should be drawn.
## These functions should not be expensive as that could cause perfomance issues. 
## (This should instead be handled by the update_tree signal). Built in processes called
## by this signal include positioning arcs between nodes and skill node image orbs
## correctly for viewing the skill tree.
@warning_ignore("unused_signal")
signal draw_tree

## Event that will trigger whenever a skill node is selected by the operator. Currently
## only used in editor by selecting nodes within the 2D screen or scene tree. This uses
## the SkillSelector plugin.
## [br][br]
## Main uses include displaying the selected skill's information within the side 
## display panel.
@warning_ignore("unused_signal")
signal skill_selected(node: SkillNode)

## Event that will cause the TreeUpdator node to toggle whether it is updating the
## skill tree. Mainly used by the SkillTreePauser plugin to pause tree processing
## when in any screen other than 2D to prevent logic issues when editing tool scripts.
@warning_ignore("unused_signal")
signal toggle_updating(active: bool)

## Event that will cause the TreeUpdator node to toggle whether it is updating the
## skill tree. Mainly used by the SkillTreePauser plugin to pause tree processing
## when in any screen other than 2D to prevent logic issues when editing tool scripts.
@warning_ignore("unused_signal")
signal toggle_drawing(active: bool)

@warning_ignore("unused_signal")
signal tree_setup

@warning_ignore("unused_signal")
signal data_loaded

@warning_ignore("unused_signal")
signal data_saved

@warning_ignore("unused_signal")
signal skill_regressed(node: SkillNode)

@warning_ignore("unused_signal")
signal skill_progressed(node: SkillNode)

@warning_ignore("unused_signal")
signal skill_locked(node: SkillNode)

@warning_ignore("unused_signal")
signal skill_unlocked(skill_node: SkillNode)

@warning_ignore("unused_signal")
signal skill_completed(node: SkillNode)
