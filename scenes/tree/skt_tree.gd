@tool
@icon("res://addons/at-icons/control/node_graph.svg")
class_name SKT_Tree
extends Control

# Backend Signallers
@export var tree_update_signaller: SKT_TreeUpdateSignaller
@export var tree_draw_signaller: SKT_TreeDrawSignaller

# Frontend Function Nodes
@export var spawner: SKT_Spawner

# Frontend Managers
@export var progression_tier_manager: SKT_ProgressionTierManager
@export var upgrade_cost_manager: SKT_UpgradeCostManager
@export var grid_node_locker: SKT_GridNodeLocker

# Parents
@export var nodes_parent: SKT_NodesParent
@export var branches_parent: SKT_BranchesParent

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
## TODO: FIX
@warning_ignore("unused_signal")
signal draw_tree

## Event that will trigger a set number of times per second. Emitted only by the
## TreeUpdator node, this can be disabled with its exported can_update boolean or
## by switching to any godot editor screen other than 2D. This is to prevent logic
## issues when editing tool scripts.
## [br][br]
## Other nodes can connect functions to be called whenever the tree is updated. These
## functions may be expensive as it is only called a few times each second. Built in
## processes called by this signal include checking whether nodes and connections are
## unlocked, locked, unlockable etc.
## TODO:FIX
@warning_ignore("unused_signal")
signal update_tree

## Request that will cause the TreeUpdator node to toggle whether it is updating the
## skill tree. Mainly used by the SkillTreePauser plugin to pause tree processing
## when in any screen other than 2D to prevent logic issues when editing tool scripts.
## [br][br]
## Also used to reduce logic errors when loading new data.
@warning_ignore("unused_signal")
signal request_toggle_tree_updating

## Request that will cause the TreeUpdator node to toggle whether it is updating the
## skill tree. Mainly used by the SkillTreePauser plugin to pause tree processing
## when in any screen other than 2D to prevent logic issues when editing tool scripts.
## [br][br]
## Also used to reduce logic errors when loading new data.
@warning_ignore("unused_signal")
signal request_toggle_tree_drawing

@warning_ignore("unused_signal")
signal data_loaded

@warning_ignore("unused_signal")
signal data_saved

@warning_ignore("unused_signal")
signal request_prepare_for_load

@warning_ignore("unused_signal")
signal request_prepare_for_save

@warning_ignore("unused_signal")
signal request_save_data

@warning_ignore("unused_signal")
signal request_load_data

@warning_ignore("unused_signal")
signal tree_setup

@warning_ignore("unused_signal")
signal request_reset_tree

@warning_ignore("unused_signal")
signal request_create_node

@warning_ignore("unused_signal")
signal request_create_branch

@warning_ignore("unused_signal")
signal request_create_followpoint(parent: SkillBranch)

## A signal that can be called in order to request the given node to be progressed
## to its next stage in unlock.
## [br][br]
## For example, a levellable skill will progress to its next level, or a skill with
## only a single stage will be completed.
## [br][br]
## The progression of a skill is processed through the logic node 'SkillProgressor'
## with use of the node's functions.
## [br][br]
## SkillTreeEvent 'skill_progressed' will be emitted as long as the skill is able to
## progressed and is done so correctly. The decision for a skill being able to
## progressed is handled by logic node 'CanProgressChecker'.
## [br][br]
## For explanation of terms, read TODO
@warning_ignore("unused_signal")
signal request_progress_skill(node: SkillNode)

## A signal that can be called in order to request the given node to be regressed
## to its next stage in unlock.
## [br][br]
## For example, a levellable skill will regress to its previous level, or a skill with
## only a single stage will be locked again.
## [br][br]
## The regression of a skill is processed through the logic node 'SkillRegressor'
## with use of the node's functions.
## [br][br]
## SkillTreeEvent 'skill_regressed' will be emitted as long as the skill is able to
## regressed and is done so correctly. The decision for a skill being able to
## regressed is handled by logic node 'CanRegressChecker'.
## [br][br]
## For explanation of terms, read TODO
@warning_ignore("unused_signal")
signal request_regress_skill(node: SkillNode)

@warning_ignore("unused_signal")
signal node_selected(node: SkillNode)

@warning_ignore("unused_signal")
signal branch_selected(branch: SkillBranch)

@warning_ignore("unused_signal")
signal followpoint_selected(follow_point: BranchFollowPoint)

@warning_ignore("unused_signal")
signal tree_control_deselected(control: SkillTreeControl)

@warning_ignore("unused_signal")
signal node_moved(node: SkillNode)

@warning_ignore("unused_signal")
signal followpoint_moved(follow_point: BranchFollowPoint)
