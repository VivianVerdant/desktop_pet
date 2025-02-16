extends Control

@onready var _MainWindow: Window = get_window()
var dragging:bool = false
var cursor_offset: Vector2i = Vector2i.ZERO

@onready var character_dropdown = %CharacterDropdown

func _ready() -> void:
	%SpawnButton.connect("button_up", get_parent().on_spawn_button_press)

func _process(_delta: float) -> void:
	if dragging:
		follow_mouse()

func follow_mouse():
	var cursor_pos = DisplayServer.mouse_get_position()
	DisplayServer.window_set_position(cursor_pos - cursor_offset, 0)


func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		print(event)
		cursor_offset = get_viewport().get_mouse_position() as Vector2i
		dragging = true
	if event.is_action_released("left_click"):
		print(event)
		dragging = false

func _on_minimize_button_up() -> void:
	get_viewport().mode = Window.MODE_MINIMIZED


func _on_close_button_up() -> void:
	get_tree().quit()
