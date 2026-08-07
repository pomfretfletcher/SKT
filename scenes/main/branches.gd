@tool
class_name SKT_BranchesParent
extends Control

@export var spawner: SKT_Spawner

@export_tool_button("Create new Branch")
var but_newbranch = func():
	spawner.create_branch()

var branch_count: int = 0:
	get:
		var result: int = 0
		for child in get_children():
			if child is SkillBranch:
				result += 1
		return result
	set(_v):
		assert(false, "")


func get_branches() -> Array[SkillBranch]:
	var result: Array[SkillBranch] = []
	for child in get_children():
		if child is SkillBranch:
			result.append(child)
	return result
