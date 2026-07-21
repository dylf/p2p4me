extends Control

func _ready() -> void:
	show_menu()
	
func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			start_game()
		else:
			show_menu()

func _on_join_pressed() -> void:
	NetworkManager.start_client()
	start_game()

func _on_host_pressed() -> void:
	NetworkManager.start_server()
	start_game()

func show_menu() -> void:
	show()
	GameState.in_menu = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func start_game() -> void:
	hide()
	GameState.in_menu = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
