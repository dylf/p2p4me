extends Control

@onready var joinBtn: Button = $MenuItems/MultiplayerButtons/HBoxContainer/Join
@onready var ipAddressInput: LineEdit = $MenuItems/MultiplayerButtons/HBoxContainer/IpAddress
@onready var menuItems: Container = $MenuItems
@onready var multiBtn: Container = $MenuItems/MultiplayerButtons
@onready var errorUI: Container = $ErrorUI
@onready var errorMsg: Label = $ErrorUI/ErrorMessage

func _ready() -> void:
	NetworkManager.client_connected.connect(start_game)
	NetworkManager.client_connection_failed.connect(_on_client_connection_failed)

	if GameState.is_menu():
		show_menu()
	elif GameState.is_error():
		show_error()
	
func _input(event) -> void:
	if GameState.is_error():
		if event.is_action_pressed("ui_accept"):
			_on_okay_pressed()
		return

	if event.is_action_pressed("ui_cancel"):
		if visible and !multiBtn.visible:
			start_game()
		elif !visible:
			show_menu()

func _process(_delta: float) -> void:
	if !visible and GameState.is_menu():
		show_menu()
	if GameState.is_error():
		show_error()
	else:
		errorUI.hide()

func _on_join_pressed() -> void:
	var address := ipAddressInput.text.strip_edges()
	if address.is_empty():
		address = NetworkManager.DEFAULT_IP_ADDRESS
	NetworkManager.start_client(address)

func _on_host_pressed() -> void:
	NetworkManager.start_server()
	start_game()

func show_menu() -> void:
	show()
	menuItems.show()
	errorUI.hide()
	GameState.menu()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func show_error() -> void:
	show()
	menuItems.hide()
	errorMsg.text = GameState.error_msg
	errorUI.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_okay_pressed() -> void:
	show_menu()

func _on_client_connection_failed(_error_message: String) -> void:
	show_error()
	
func start_game() -> void:
	hide()
	multiBtn.hide()
	GameState.game()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_quit_pressed() -> void:
	get_tree().quit()
