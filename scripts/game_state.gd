extends Node

enum State { MENU, GAME, ERROR }

var current_state: State = State.MENU
var error_msg: String = ""

func menu() -> void:
	current_state = State.MENU
	
func error(err_str: String = "An unknown error occurred.") -> void:
	error_msg = err_str
	current_state = State.ERROR

func game() -> void:
	current_state = State.GAME

func is_menu() -> bool:
	return current_state == State.MENU

func is_error() -> bool:
	return current_state == State.ERROR
