@tool
extends Node

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
signal request_reset_tree

@warning_ignore("unused_signal")
signal request_save_data

@warning_ignore("unused_signal")
signal request_load_data

@warning_ignore("unused_signal")
signal request_create_node

@warning_ignore("unused_signal")
signal request_create_branch

@warning_ignore("unused_signal")
signal request_create_followpoint(parent: SkillBranch)

## Request that will cause the TreeUpdator node to toggle whether it is updating the
## skill tree. Mainly used by the SkillTreePauser plugin to pause tree processing
## when in any screen other than 2D to prevent logic issues when editing tool scripts.
## [br][br]
## Also used to reduce logic errors when loading new data.
@warning_ignore("unused_signal")
signal request_toggle_tree_drawing(mode: bool)

## Request that will cause the TreeUpdator node to toggle whether it is updating the
## skill tree. Mainly used by the SkillTreePauser plugin to pause tree processing
## when in any screen other than 2D to prevent logic issues when editing tool scripts.
## [br][br]
## Also used to reduce logic errors when loading new data.
@warning_ignore("unused_signal")
signal request_toggle_tree_updating(mode: bool)

@warning_ignore("unused_signal")
signal request_prepare_for_save

@warning_ignore("unused_signal")
signal request_prepare_for_load
