@tool
extends Node

## A function to convert a vector2 in string form ["(0.0, 2.0)" for example], into
## its vector2 for use in editor [(0.0, 2.0)].
## [br][br]
## This is needed due to how skill tree data is saved, within a json file, that is
## only able to store vectors within a string form.
func stringified_vector_to_v2(vector) -> Vector2:
	vector = vector.replace("(", "").replace(")", "")
	var parts = vector.split(",")
	var result: Vector2 = Vector2(float(parts[0]), float(parts[1]))
	return result


func get_skills_resulting_from_node(node: SkillNode, node_dict: Array[SkillNode]):
	for r_branch: SkillBranch in node.result_branches:
		if r_branch.end_node == null:
			continue
		if r_branch.end_node in node_dict:
			continue
		node_dict.append(r_branch.end_node)
		get_skills_resulting_from_node(r_branch.end_node, node_dict)
