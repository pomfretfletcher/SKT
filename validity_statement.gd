## An object designed to be a return result from a check function. This allows a boolean result
## from the check to be obtained (Whether said check ended true or false). It also allows a
## reason string to be accessed for why the check did or did not pass.
## [br][br]
## This is an alternative to an array design, with the original being an Array[bool, String]
## which would store the validity statement as [validity, reason]. For example,
## [false, "Cannot divide by zero."]. Using this object abstracts this array method and makes
## it easier to produce and read from.
## [br][br]
## To create a validity statement with the needed data, use ValidityStatement.new(validity, reason).
## The reason variable will default to "" if no value is given, so you could simply use for 
## example, ValidityStatement.new(true) if no reason is needed.
## [br][br]
## The validity and reasons can then be accessed like in this example:	[br]
## var result = ValidityStatement.new(false, "Cannot divide by zero")	[br]
## if result.validity == false: print(result.reason)
@tool
class_name ValidityStatement

## The boolean value stored by the _init method. Should be used to store whether the check
## function did or did not pass.
var validity: bool
## The string value stored by the _init method. Should be used to store the reason the check
## function did or did not pass.
var reason: String


## Setups the validity statement with the given validity value and reason string. A reason
## is not required, and if it is not given, "" will be stored instead, which acts as a null
## value.
func _init(v: bool, r: String = ""):
	validity = v
	reason = r
